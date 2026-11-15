"""Per-frame script audit (2026-11-15, performance; user: "a lot of scripts that we haven't checked could be doing
many operations for no reason").

Usage (repo root): python tools/porting/tick_audit.py [--top N] [--file path.lua]

For every mod script with a per-frame callback (server/client tick, update, draw, postUpdate; v1 tick/update/draw),
counts the costly calls in the callback AND in the same-file functions it calls (two levels): level-wide searches
(Find*), registry listings (ListKeys), engine queries (Query*), Spawn, string splits (Split / gmatch / string.format:
Lua garbage), registry reads / writes (Get* / Set* with a "level." / "savegame." / "game." key), and loops. It also
notes whether the callback returns early in its first lines (an idle guard) and how many prefab / level XMLs
reference the script (a rough number of running copies). Score = weighted calls x (1 + references): a list to
read, not a measurement. Teardown's profiler (SHIFT+ALT+F3) gives the real times.
"""
import os, re, sys, glob, collections

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SKIP = ("tools/", "dev/", ".git/", "docs/")
CALLBACKS = re.compile(r'^function\s+((?:server|client)\.(?:tick|update|draw|postUpdate|render)|tick|update|draw)\s*\(', re.M)
FUNC = re.compile(r'^(?:local\s+)?function\s+([A-Za-z_][\w.:]*)\s*\(', re.M)
WEIGHTS = [
    ("Find* (level search)", re.compile(r'\bFind(?:Shapes|Bodies|Triggers|Locations|Joints|Lights|Vehicles|Screens|Shape|Body|Trigger|Location|Joint|Light|Vehicle)\s*\('), 10),
    ("ListKeys", re.compile(r'\bListKeys\s*\('), 8),
    ("Query*", re.compile(r'\bQuery(?:Raycast|AabbShapes|AabbBodies|ClosestPoint|Path|Shape)\w*\s*\('), 6),
    ("Spawn", re.compile(r'\bSpawn\s*\('), 10),
    ("split / format", re.compile(r'\b(?:Split|splitString|AutoSplit)\s*\(|:gmatch\(|string\.format\(|:format\('), 3),
    ("registry read", re.compile(r'\bGet(?:Bool|Int|Float|String)\s*\(\s*"(?:level|savegame|game)\.'), 1),
    ("registry write", re.compile(r'\b(?:Set(?:Bool|Int|Float|String)|ClearKey)\s*\(\s*"(?:level|savegame|game)\.'), 2),
    ("loop", re.compile(r'\bfor\b'), 1),
]


def bodies(text):
    """{function name: body text} for top-level functions (body ends at the next 'end' in column 0)"""
    out = {}
    for m in FUNC.finditer(text):
        start = m.end()
        e = re.search(r'^end\b', text[start:], re.M)
        out[m.group(1)] = text[start:start + (e.start() if e else len(text) - start)]
    return out


def strip_comments(t):
    t = re.sub(r'--\[(=*)\[.*?\]\1\]', '', t, flags=re.S)
    return re.sub(r'--[^\n]*', '', t)


def cost(body):
    c = collections.Counter()
    for name, rx, w in WEIGHTS:
        n = len(rx.findall(body))
        if n:
            c[name] = n
    return c


def score(c):
    return sum(n * w for (name, rx, w) in WEIGHTS for k, n in c.items() if k == name)


def audit(path, refs):
    text = strip_comments(open(path, encoding="utf-8", errors="replace").read())
    fns = bodies(text)
    rows = []
    for m in CALLBACKS.finditer(text):
        cb = m.group(1)
        body = fns.get(cb, "")
        total = cost(body)
        seen = {cb}
        frontier = [body]
        for depth in range(2):
            nxt = []
            for b in frontier:
                for called in set(re.findall(r'\b([A-Za-z_]\w*)\s*\(', b)):
                    if called in fns and called not in seen:
                        seen.add(called)
                        total += cost(fns[called])
                        nxt.append(fns[called])
            frontier = nxt
        head = "\n".join(body.strip().split("\n")[:4])
        guard = bool(re.search(r'\breturn\b', head))
        rows.append((cb, total, guard))
    return rows


def main():
    os.chdir(REPO)
    top = 40
    only = None
    if "--top" in sys.argv:
        top = int(sys.argv[sys.argv.index("--top") + 1])
    if "--file" in sys.argv:
        only = sys.argv[sys.argv.index("--file") + 1].replace("\\", "/")
    xml_text = ""
    for x in glob.glob("**/*.xml", recursive=True):
        xp = x.replace("\\", "/")
        if not xp.startswith(SKIP):
            xml_text += open(x, encoding="utf-8", errors="replace").read()
    results = []
    for p in glob.glob("**/*.lua", recursive=True):
        p = p.replace("\\", "/")
        if p.startswith(SKIP) or "/history/" in p or p.endswith("teardown_api.lua") or (only and p != only):
            # teardown_api.lua: editor type annotations (every API function as an empty stub), not a running script
            continue
        refs = xml_text.count("MOD/" + p)
        for cb, c, guard in audit(p, refs):
            s = score(c)
            if s:
                results.append((s * (1 + refs), s, refs, p, cb, c, guard))
    results.sort(reverse=True)
    print("%-6s %-5s %-4s %-52s %-14s %-5s %s" % ("score", "cost", "refs", "script", "callback", "guard", "calls"))
    for tot, s, refs, p, cb, c, guard in results[:top]:
        print("%-6d %-5d %-4d %-52s %-14s %-5s %s" % (tot, s, refs, p[-52:], cb, "yes" if guard else "-",
              ", ".join("%s %d" % kv for kv in c.most_common())))


if __name__ == "__main__":
    main()
