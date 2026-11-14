"""Relocate files in the mod and rewrite every path reference to them, provably (Phase 5 reorganization, 2026-11-14).

Usage (repo root):
  python tools/relocate/relocate.py scan              index every path reference, report what can't be resolved
  python tools/relocate/relocate.py plan  MOVES       + compute the new path of every file and reference, check it
  python tools/relocate/relocate.py apply MOVES       + move the files, rewrite the references, verify, roll back on
                                                        any failure (writes tools/relocate/out/manifest.json)
Options: --root DIR (default: the repo), --data DIR (Teardown's data folder), --out DIR (reports).

How the engine finds a file (official mods/castle/main.xml, data/script_defs.lua; checked on this tree by `scan`):
  * `MOD/x`    the mod's root folder (case-insensitive on Windows; `\\` works like `/`).
  * `LEVEL/x`  the folder named after the level file being played (main.xml -> main/). Prefabs use it too, so
               which folder it means depends on the level: every file a LEVEL/ path could mean is PINNED (may not
               move), and a level file with such a folder may not move either.
  * no prefix  in XML: the engine's data folder (`file="fx.lua"` = data/script/fx.lua). A bare XML path that
               also matches a mod file is reported and its mod file is PINNED.
  * `#include` relative to the including file, else the data folder (`script/include/player.lua`). The tool
               rewrites a relative include from both new locations; an include that could match two files is an
               error.
  * paths built at run time (`"MOD/snd/" .. name`) are DYNAMIC: the literal is a prefix. A move is allowed
    only if every existing file under that prefix moves by the same prefix change (then rewriting the literal is
    exact whatever the run-time part is); otherwise the move is refused, naming the site.
  * repo-relative paths in docs, tools and tests (`scripts/MountedGun.lua`) are rewritten the same way; in game
    scripts a full repo path in a string or comment is rewritten, a partial one is DYNAMIC as above.

Checks by `apply` (any failure undoes everything): every rewritten file turns back into the old one byte for
byte when its new spans are replaced by the old ones; a re-scan resolves every reference to the moved target and
finds the same dangling ones; every file's content is unchanged except for the rewritten spans; then
`tools/relocate/check_after.sh` style checks are left to the caller (mock tests, Lua syntax, release dry run).
"""
import hashlib, json, os, re, sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
DEFAULT_DATA = r"C:\Program Files (x86)\Steam\steamapps\common\Teardown\data"

# never scanned or moved: git, the frozen converters (a record of the old paths), this tool (fixtures, reports)
SKIP_DIRS = {".git", "__pycache__"}
SKIP_PREFIXES = ("tools/porting/history/", "tools/relocate/")
TEXT_EXT = {".xml", ".lua", ".txt", ".md", ".json", ".py", ".yml", ".ini", ".sh", ".js", ".gitattributes"}
# files whose plain repo paths (no MOD/) are meant as repo paths: docs, tools, tests, dev configs
DOC_EXT = {".md", ".py", ".json", ".yml", ".sh"}
NAME_CHARS = re.compile(r"[A-Za-z0-9_]")


def norm(p):
    """Canonical key of a path: forward slashes, lower case, no repeated or trailing slash."""
    p = p.replace("\\", "/")
    p = re.sub(r"/+", "/", p)
    return p.strip("/").lower()


# ----------------------------------------------------------------------------------------------- the tree

class Tree:
    def __init__(self, root):
        self.root = root
        self.files = {}   # norm -> real relative path (forward slashes)
        self.dirs = {}    # norm -> real relative path
        for d, ds, fs in os.walk(root):
            rel = os.path.relpath(d, root).replace("\\", "/")
            rel = "" if rel == "." else rel
            ds[:] = sorted(x for x in ds if x not in SKIP_DIRS and not skipped((rel + "/" + x if rel else x) + "/"))
            for x in ds:
                r = rel + "/" + x if rel else x
                self.dirs[norm(r)] = r
            for f in sorted(fs):
                r = rel + "/" + f if rel else f
                if not skipped(r):
                    self.files[norm(r)] = r
        self.trie = {}
        for k in list(self.files) + list(self.dirs):
            node = self.trie
            for c in k:
                node = node.setdefault(c, {})
            node.setdefault("", set()).add("f" if k in self.files else "d")

    def walk(self, text, i, xml=False):
        """Follow text[i:] down the path trie. Returns (file_end, dir_end, walked_end): the end of the longest exact
        file match (or -1), of the longest directory match that is followed by a slash or a non-name char (or -1),
        and how far the text matched any path at all. xml: `&amp;` etc. count as their character."""
        node, j, n = self.trie, i, len(text)
        file_end = dir_end = -1
        prev_slash = False
        while j < n:
            c = text[j]
            step = 1
            if xml and c == "&":
                for ent, ch in XML_ENTITIES:
                    if text.startswith(ent, j):
                        c, step = ch, len(ent)
                        break
            c = "/" if c == "\\" else c.lower()
            if c == "/" and prev_slash:      # MOD/vox//x.vox
                j += step
                continue
            nxt = node.get(c)
            if nxt is None:
                break
            node = nxt
            j += step
            prev_slash = c == "/"
            kinds = node.get("", ())
            after = text[j] if j < n else ""
            # a file ends here unless a longer name goes on ("x.vox.bak"); "x.vox." at the end of a sentence is fine
            dot_on = after == "." and j + 1 < n and NAME_CHARS.match(text[j + 1])
            if "f" in kinds and not NAME_CHARS.match(after or " ") and not dot_on:
                file_end = j
            if "d" in kinds and (after in ("/", "\\") or not NAME_CHARS.match(after or " ")):
                dir_end = j
        return file_end, dir_end, j

    def key_at(self, text, i, j, xml=False):
        return norm(xml_decode(text[i:j]) if xml else text[i:j])


XML_ENTITIES = (("&amp;", "&"), ("&apos;", "'"), ("&quot;", '"'), ("&lt;", "<"), ("&gt;", ">"))


def xml_decode(s):
    for ent, ch in XML_ENTITIES[1:] + XML_ENTITIES[:1]:
        s = s.replace(ent, ch)
    return s


def xml_encode(path, like):
    """A path for an XML attribute, escaped the way the original span was."""
    s = path.replace("&", "&amp;")
    if "&apos;" in like:
        s = s.replace("'", "&apos;")
    return s.replace('"', "&quot;").replace("<", "&lt;")


def skipped(rel):
    return any(rel.startswith(p) for p in SKIP_PREFIXES)


def is_doc(rel):
    """Docs, tools, tests and dev configs: plain repo paths in them are meant as repo paths."""
    return os.path.splitext(rel)[1].lower() in DOC_EXT or rel.startswith(("tools/", "docs/", ".github/")) \
        or os.path.basename(rel).startswith(".")


class DataTree:
    """The engine's data folder, only to tell engine paths from mod paths."""
    def __init__(self, data):
        self.files = set()
        if data and os.path.isdir(data):
            for d, ds, fs in os.walk(data):
                rel = os.path.relpath(d, data).replace("\\", "/")
                for f in fs:
                    self.files.add(norm(f if rel == "." else rel + "/" + f))

    def has(self, p):
        return norm(p) in self.files


# ----------------------------------------------------------------------------------------------- references

class Ref:
    __slots__ = ("file", "start", "end", "text", "kind", "target", "style", "note")

    def __init__(self, file, start, end, text, kind, target=None, style=None, note=None):
        self.file, self.start, self.end, self.text = file, start, end, text
        self.kind, self.target, self.style, self.note = kind, target, style, note

    def where(self, content=None):
        line = content.count("\n", 0, self.start) + 1 if content is not None else "?"
        return "%s:%s" % (self.file, line)

    def as_dict(self):
        return {k: getattr(self, k) for k in self.__slots__}


# kinds:
#   mod      MOD/<file>, target = norm of the file
#   moddir   MOD/<dir>/ (a folder, e.g. a loop prefix) - treated as a prefix
#   prefix   MOD/<partial> or a partial repo path: a run-time path prefix, target = norm prefix
#   include  #include of a mod file (style: "rel" / "root"), target = norm of the file
#   engine   #include / bare XML path of an engine file (never rewritten)
#   repo     a full repo path without MOD/ (docs, tools, tests, comments), target = norm of the file or dir
#   level    LEVEL/<x>: pinned candidates in note
#   pinned   a bare XML path that matches a mod file (engine would read data/): its mod file is pinned
#   dangling a MOD/ or #include path that matches nothing (left as it is)

MOD_RE = re.compile(r"(?<![A-Za-z0-9_])MOD[/\\]", re.I)
LEVEL_RE = re.compile(r"(?<![A-Za-z0-9_])LEVEL[/\\]")
# only at the start of a line: Settings.lua has two indented `#include` lines inside a comment that name no file,
# and the scripts including Settings.lua load (a missing include stops a script loading), so the engine skips them
INCLUDE_RE = re.compile(r'^#include[ \t]+("?)([^"\r\n]+?)\1[ \t]*\r?$', re.M)
LONG_OPEN = re.compile(r"\[(=*)\[")


def lua_spans(text):
    """(start, end, kind) of every comment ("c") and string literal ("s") in Lua source; for strings the span is
    the content without the quotes. Lines starting with # (directives) are skipped."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "#" and (i == 0 or text[i - 1] == "\n"):
            j = text.find("\n", i)
            i = n if j < 0 else j
        elif c == "-" and text.startswith("--", i):
            m = LONG_OPEN.match(text, i + 2)
            if m:
                close = "]" + m.group(1) + "]"
                j = text.find(close, m.end())
                j = n if j < 0 else j + len(close)
            else:
                j = text.find("\n", i)
                j = n if j < 0 else j
            out.append((i, j, "c"))
            i = j
        elif c in "\"'":
            j = i + 1
            while j < n and text[j] != c and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            out.append((i + 1, min(j, n), "s"))
            i = j + 1
        elif c == "[":
            m = LONG_OPEN.match(text, i)
            if m:
                close = "]" + m.group(1) + "]"
                j = text.find(close, m.end())
                j = n if j < 0 else j
                out.append((m.end(), j, "s"))
                i = j + len(close)
            else:
                i += 1
        else:
            i += 1
    return out
XML_ATTR_RE = re.compile(r'([A-Za-z_][\w:.-]*)\s*=\s*("([^"]*)"|\'([^\']*)\')')
# a plain-path token starts after one of these (or at the start of the file)
TOKEN_START = set(" \t\r\n\"'`([<=,:;|*")


def read_text(path):
    with open(path, "rb") as f:
        raw = f.read()
    return raw, raw.decode("latin-1")   # byte <-> char 1:1, so spans are byte-exact


def enc(rel, path, like):
    """New path text for a reference in file rel (XML escaped like the original span)."""
    p = encode_path(path)
    return xml_encode(p, like) if rel.lower().endswith(".xml") else p


def encode_path(p):
    """A real path as it appears in a latin-1 decoded file (files are UTF-8 or ASCII)."""
    return p.encode("utf-8").decode("latin-1")


class Scan:
    def __init__(self, root, data_dir):
        self.root = root
        self.tree = Tree(root)
        self.data = DataTree(data_dir)
        self.refs = []                 # all references
        self.by_file = defaultdict(list)
        self.contents = {}             # rel -> (raw bytes, latin-1 text) of every text file
        self.ambiguous = []            # (where, text, candidates)
        self.levels = {}               # level xml norm -> its LEVEL folder norm (if that folder exists)
        self._find_levels()
        for k, rel in sorted(self.tree.files.items()):
            if os.path.splitext(rel)[1].lower() in TEXT_EXT or os.path.basename(rel).startswith("."):
                self._scan_file(rel)

    # -- levels: XML files whose root element is <scene>
    def _find_levels(self):
        for k, rel in self.tree.files.items():
            if not k.endswith(".xml"):
                continue
            with open(os.path.join(self.root, rel), "rb") as f:
                head = f.read(400).decode("latin-1")
            if re.match(r"\s*(<\?xml[^>]*>\s*)?(<!--.*?-->\s*)*<scene\b", head, re.S):
                stem = k[:-4]
                self.levels[k] = stem if stem in self.tree.dirs else None

    def add(self, ref):
        self.refs.append(ref)
        self.by_file[ref.file].append(ref)

    def _scan_file(self, rel):
        raw, text = read_text(os.path.join(self.root, rel))
        self.contents[rel] = (raw, text)
        ext = os.path.splitext(rel)[1].lower()
        xml = ext == ".xml"
        taken = bytearray(len(text) + 1)   # characters already claimed by a reference, to not match a path twice

        def claim(s, e):
            taken[s:e] = b"\x01" * (e - s)

        def is_taken(i):
            return taken[i] == 1

        # 1. #include lines (Lua): relative to the file, else the engine's data folder
        if ext == ".lua":
            for m in INCLUDE_RE.finditer(text):
                s, e, path = m.start(2), m.end(2), m.group(2)
                self._include(rel, s, e, path, quoted=bool(m.group(1)))
                claim(m.start(), m.end())

        # 2. MOD/ paths, anywhere in any text file
        for m in MOD_RE.finditer(text):
            if is_taken(m.start()):
                continue
            i = m.end()
            fe, de, we = self.tree.walk(text, i, xml)
            quote_after = we < len(text) and text[we] in "\"'"
            p = xml_decode(text[i:we]) if xml else text[i:we]
            if fe != -1:
                self.add(Ref(rel, m.start(), fe, text[m.start():fe], "mod", self.tree.key_at(text, i, fe, xml)))
                claim(m.start(), fe)
            elif quote_after and (p == "" or self._has_prefix(norm(p), p[-1])):
                # "MOD/snd/death" .. i .. ".ogg" / "MOD/img/icon/" .. id: a run-time prefix. A bare "MOD/" ..
                # path has every file under it: no move can keep it right automatically.
                self.add(Ref(rel, m.start(), we, text[m.start():we], "prefix",
                             norm(p) + ("/" if p[-1:] in "/\\" else "") if p else ""))
                claim(m.start(), we)
            elif de != -1 and is_doc(rel):
                # a folder named in prose ("MOD/Vehicles"): rewritten like a repo folder
                self.add(Ref(rel, m.start(), de, text[m.start():de], "moddir", self.tree.key_at(text, i, de, xml)))
                claim(m.start(), de)
            else:
                end = i
                while end < len(text) and text[end] not in "\"'<>\r\n\t":
                    end += 1
                self.add(Ref(rel, m.start(), end, text[m.start():end], "dangling", note="MOD path matches no file"))
                claim(m.start(), end)

        # 3. LEVEL/ paths: what they mean depends on the level played -> pin every candidate
        for m in LEVEL_RE.finditer(text):
            if is_taken(m.start()):
                continue
            i = m.end()
            cands = []
            for lvl, folder in self.levels.items():
                if folder is None:
                    continue
                fe, de, we = self._walk_under(folder, text, i)
                if fe != -1:
                    cands.append(folder + "/" + norm(text[i:fe]))
            end = i
            while end < len(text) and text[end] not in "\"'<>\r\n":
                end += 1
            self.add(Ref(rel, m.start(), end, text[m.start():end], "level", note=sorted(set(cands))))
            claim(m.start(), end)

        # 4. bare paths in XML attributes (the engine reads them from its data folder)
        if ext == ".xml":
            for m in XML_ATTR_RE.finditer(text):
                val = m.group(3) if m.group(3) is not None else m.group(4)
                vs = m.start(3) if m.group(3) is not None else m.start(4)
                if not val or is_taken(vs) or "/" not in val.replace("\\", "/") and "." not in val:
                    continue
                if re.match(r"(?i)(MOD|LEVEL)[/\\]", val) or not re.search(r"\.[A-Za-z0-9]{2,4}$", val):
                    continue
                k = norm(val)
                in_data = self.data.has(k) or self.data.has("script/" + k)
                in_mod = k in self.tree.files
                own = norm(os.path.dirname(rel) + "/" + val) if os.path.dirname(rel) else k
                in_own = own in self.tree.files and own != k
                # also what it would mean under a LEVEL folder (main/): pinned too, to be safe
                lvl = [f + "/" + k for f in self.levels.values() if f and f + "/" + k in self.tree.files]
                if in_mod or in_own or lvl:
                    t = [x for x in (k if in_mod else None, own if in_own else None) if x] + lvl
                    self.add(Ref(rel, vs, vs + len(val), val, "pinned", note=t))
                elif in_data:
                    self.add(Ref(rel, vs, vs + len(val), val, "engine"))
                claim(vs, vs + len(val))

        # 5. plain repo paths (no MOD/), rewritten when they name a whole file or folder:
        #    * docs, tools, tests, dev configs: everywhere (tests load "scripts/X.lua" by repo path);
        #    * game Lua: only in comments. A bare path in a game script's string is an engine path
        #      (`LoadLoop("tools/blowtorch-hit-loop.ogg")` is data/snd/tools/...), never ours: if it looks like one
        #      of our folders and is no engine file, it is reported as a "fragment" (meaning unknown);
        #    * XML and other .txt (spawn.txt categories look like folders): never (a bare XML path is the engine's).
        if ext == ".xml" or (ext == ".txt" and not rel.startswith(("tools/", "docs/"))):
            return
        doc = is_doc(rel)
        if doc:
            regions = [(0, len(text), "c")]
        elif ext == ".lua":
            regions = lua_spans(text)
        else:
            regions = [(0, len(text), "c")]
        for rs, re_, rk in regions:
            if rk == "s":
                self._fragment(rel, text, rs, re_, is_taken, claim)
                continue
            i = rs
            while i < re_:
                if (i == 0 or text[i - 1] in TOKEN_START) and not is_taken(i) and \
                        (NAME_CHARS.match(text[i]) or text[i] in "!."):
                    fe, de, we = self.tree.walk(text, i)
                    if fe != -1 and fe <= re_ and ("/" in text[i:fe].replace("\\", "/") or doc):
                        self.add(Ref(rel, i, fe, text[i:fe], "repo", self.tree.key_at(text, i, fe)))
                        claim(i, fe)
                        i = fe
                        continue
                    if de != -1 and de <= re_ and "/" in text[i:de + 1].replace("\\", "/") and \
                            (doc or de < len(text) and text[de] in "/\\"):
                        end = de + 1 if de < len(text) and text[de] in "/\\" else de
                        self.add(Ref(rel, i, end, text[i:end], "repo", self.tree.key_at(text, i, de) + "/"))
                        claim(i, end)
                        i = end
                        continue
                i += 1

    def _fragment(self, rel, text, s, e, is_taken, claim):
        """A game-script string with a bare path: engine file, or (if it starts like a folder of ours) a fragment."""
        val = text[s:e]
        if not val or is_taken(s) or "/" not in val.replace("\\", "/"):
            return
        k = norm(val)
        top = k.split("/", 1)[0]
        if self.data.has(k) or top not in self.tree.dirs:
            return
        if k in self.tree.files or k in self.tree.dirs or any(f.startswith(k) for f in self.tree.files):
            self.add(Ref(rel, s, e, val, "fragment", k + ("/" if val[-1:] in "/\\" else ""),
                         note="bare path in a game script string: engine path or a piece of ours?"))
            claim(s, e)

    def _walk_under(self, folder, text, i):
        """walk() for a path relative to a folder of the tree."""
        prefix = folder + "/"
        fake = prefix + text[i:i + 400]
        fe, de, we = self.tree.walk(fake, 0)
        off = len(prefix)
        return (fe - off + i if fe >= off else -1, de - off + i if de >= off else -1, max(we - off, 0) + i)

    def _has_prefix(self, k, last):
        if last in "/\\":
            return k in self.tree.dirs or k == ""
        return any(f.startswith(k) for f in self.tree.files)

    def _include(self, rel, s, e, path, quoted):
        here = os.path.dirname(rel)
        cand_rel = norm(os.path.normpath(os.path.join(here, path)).replace("\\", "/"))
        in_mod = cand_rel in self.tree.files and not cand_rel.startswith("..")
        in_data = self.data.has(path)
        root_k = norm(path)
        in_root = root_k in self.tree.files and root_k != cand_rel
        hits = [x for x, ok in (("rel", in_mod), ("data", in_data), ("root", in_root)) if ok]
        if len(hits) > 1 and hits != ["rel", "root"]:
            self.ambiguous.append((rel, path, hits))
        if in_mod:
            self.add(Ref(rel, s, e, path, "include", cand_rel, style="q" if quoted else "u"))
        elif in_data:
            self.add(Ref(rel, s, e, path, "engine"))
        elif in_root:
            self.ambiguous.append((rel, path, ["root only (not how the engine resolves includes?)"]))
            self.add(Ref(rel, s, e, path, "include", root_k, style=("q" if quoted else "u") + "root"))
        else:
            self.add(Ref(rel, s, e, path, "dangling", note="include matches no file"))

    # -- summaries
    def pinned_targets(self):
        pins = defaultdict(list)
        for r in self.refs:
            if r.kind in ("level", "pinned"):
                for t in r.note or []:
                    pins[t].append(r)
        return pins

    def summary(self):
        c = Counter(r.kind for r in self.refs)
        return dict(sorted(c.items()))


# ----------------------------------------------------------------------------------------------- moves

def read_moves(path):
    """moves.txt: `old -> new` per line (files or folders, repo-relative, forward slashes), # comments.
    `ack <file>:<text>` lines accept a run-time prefix site the tool can't rewrite (after checking it by hand)."""
    moves, acks = [], set()
    with open(path, encoding="utf-8") as f:
        for n, line in enumerate(f, 1):
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            if line.startswith("ack "):
                acks.add(line[4:].strip())
                continue
            if "->" not in line:
                sys.exit("%s:%d: expected `old -> new`" % (path, n))
            a, b = (x.strip().strip("/") for x in line.split("->", 1))
            moves.append((a, b, n))
    return moves, acks


class Plan:
    def __init__(self, scan, moves, acks):
        self.scan, self.moves, self.acks = scan, moves, acks
        self.errors, self.warnings = [], []
        t = scan.tree
        self.newpath = {}   # norm old file -> real new relative path
        srcs = []
        for a, b, n in moves:
            ka = norm(a)
            if ka in t.files:
                srcs.append((ka, b, "f", n))
            elif ka in t.dirs:
                srcs.append((ka, b, "d", n))
            else:
                self.errors.append("moves.txt:%d: %s does not exist" % (n, a))
        srcs.sort(key=lambda s: -len(s[0]))   # most specific move wins
        for k, real in t.files.items():
            for ka, b, typ, n in srcs:
                if typ == "f" and k == ka:
                    self.newpath[k] = b
                    break
                if typ == "d" and k.startswith(ka + "/"):
                    self.newpath[k] = b + real[len(ka):]
                    break
            else:
                self.newpath[k] = real
        # collisions (case-insensitive, Windows)
        seen = {}
        for k, newp in self.newpath.items():
            nk = norm(newp)
            if nk in seen:
                self.errors.append("collision: %s and %s both -> %s" % (t.files[seen[nk]], t.files[k], newp))
            seen[nk] = k
        self.new_keys = seen   # norm new -> norm old
        # a folder becoming a file or the other way
        for nk in seen:
            parts = nk.split("/")
            for i in range(1, len(parts)):
                if "/".join(parts[:i]) in seen:
                    self.errors.append("a file and a folder at %s" % "/".join(parts[:i]))
        self.moved = {k for k, v in self.newpath.items() if norm(v) != k or v != t.files[k]}
        self._check_pins()
        self.edits = defaultdict(list)   # rel -> [(start, end, old, new)]
        self._rewrite_all()

    def new_of(self, k):
        return self.newpath[k]

    def new_dir_of(self, kdir):
        """New path of an old folder, if every file under it moves by the same prefix change; else None."""
        return self._prefix_map(kdir + "/")

    def _prefix_map(self, kp):
        """New real prefix for norm prefix kp such that every file starting with kp maps to new prefix + the same
        rest; None if the files under it don't all move the same way (or there are none)."""
        t = self.scan.tree
        files = [k for k in t.files if k.startswith(kp)]
        if not files:
            return None
        newp = None
        for k in files:
            real, new = t.files[k], self.newpath[k]
            rest = real[len(kp):]
            if not new.lower().endswith(rest.lower()) or norm(new[:len(new) - len(rest)] + "x") != norm(new[:len(new) - len(rest)] + "x"):
                return None
            head = new[:len(new) - len(rest)]
            if newp is None:
                newp = head
            elif norm(head + "x") != norm(newp + "x"):
                return None
        return newp

    def _check_pins(self):
        pins = self.scan.pinned_targets()
        for k, refs in pins.items():
            if k in self.moved:
                self.errors.append("PINNED %s moves (LEVEL/ or bare XML path, e.g. %s)" % (
                    self.scan.tree.files.get(k, k), refs[0].where(self.scan.contents[refs[0].file][1])))
        for lvl, folder in self.scan.levels.items():
            if folder and lvl in self.moved:
                self.errors.append("level %s has a LEVEL folder %s/: it may not move" % (lvl, folder))

    def _rewrite_all(self):
        s, t = self.scan, self.scan.tree
        for rel, refs in s.by_file.items():
            k_file = norm(rel)
            content = s.contents[rel][1]
            new_file = self.newpath.get(k_file, rel)
            for r in refs:
                new = self._new_text(r, rel, new_file, content)
                if new is not None and new != r.text:
                    self.edits[rel].append((r.start, r.end, r.text, new))

    def _new_text(self, r, rel, new_file, content):
        t = self.scan.tree
        if r.kind == "mod":
            if r.target not in self.moved:
                return None
            return r.text[:4] + enc(rel, self.newpath[r.target], r.text)
        if r.kind == "moddir":   # docs only
            if not any(k in self.moved for k in t.files if k.startswith(r.target + "/")):
                return None
            nd = self.new_dir_of(r.target)
            if nd is None:
                self.warnings.append("folder %s is split by the moves (%s): not rewritten" % (r.text, r.where(content)))
                return None
            return r.text[:4] + enc(rel, nd.rstrip("/"), r.text) + ("/" if r.text.endswith(("/", "\\")) else "")
        if r.kind in ("prefix", "fragment"):
            kp = r.target
            if not any(k in self.moved for k in t.files if k.startswith(kp)):
                return None
            np_ = self._prefix_map(kp) if kp else None
            if np_ is None or r.kind == "fragment":
                return self._prefix_fail(r, content)
            # the new prefix, including the literal's trailing partial name ("MOD/snd/death" -> ".../death")
            return r.text[:4] + enc(rel, np_, r.text)
        if r.kind == "include":
            if r.target not in self.moved and new_file == rel:
                return None
            tgt_new = self.newpath[r.target]
            if r.style.endswith("root"):
                return encode_path(tgt_new)
            here = os.path.dirname(new_file)
            relp = os.path.relpath(tgt_new, here or ".").replace("\\", "/")
            if r.text.startswith("./") and not relp.startswith("."):
                relp = "./" + relp
            return encode_path(relp)
        if r.kind == "repo":
            if r.target.endswith("/"):
                kd = r.target[:-1]
                if not any(k in self.moved for k in t.files if k.startswith(kd + "/")):
                    return None
                nd = self.new_dir_of(kd)
                if nd is None:
                    # repo folders are only matched in docs and in game-script comments: prose, not paths the game reads
                    self.warnings.append("folder %s is split by the moves (%s): not rewritten" % (r.text, r.where(content)))
                    return None
                return encode_path(nd.rstrip("/")) + ("/" if r.text.endswith(("/", "\\")) else "")
            if r.target not in self.moved:
                return None
            return encode_path(self.newpath[r.target])
        return None

    def _prefix_fail(self, r, content):
        site = "%s:%s" % (r.file, r.text)
        if site in self.acks:
            self.warnings.append("acknowledged run-time prefix %s (%s)" % (r.text, r.where(content)))
            return None
        self.errors.append("run-time path prefix %r at %s: the files under it don't all move the same way "
                           "(fix the moves, rewrite the code, or `ack %s` after checking it by hand)"
                           % (r.text, r.where(content), site))
        return None

    def file_moves(self):
        t = self.scan.tree
        return [(t.files[k], self.newpath[k]) for k in sorted(self.moved)]


# ----------------------------------------------------------------------------------------------- apply / verify

def apply_edits(text, edits):
    out, pos = [], 0
    for s, e, old, new in sorted(edits):
        assert text[s:e] == old, "span changed"
        out.append(text[pos:s])
        out.append(new)
        pos = e
    out.append(text[pos:])
    return "".join(out)


def inverse(new_text, edits):
    """Undo the edits on the rewritten text using the recorded spans."""
    out, pos, shift = [], 0, 0
    for s, e, old, new in sorted(edits):
        ns = s + shift
        assert new_text[ns:ns + len(new)] == new, "rewritten span not found"
        out.append(new_text[pos:ns])
        out.append(old)
        pos = ns + len(new)
        shift += len(new) - (e - s)
    out.append(new_text[pos:])
    return "".join(out)


def md5(b):
    return hashlib.md5(b).hexdigest()


def rename(root, a, b):
    src, dst = os.path.join(root, a), os.path.join(root, b)
    os.makedirs(os.path.dirname(dst) or root, exist_ok=True)
    if a.lower() == b.lower():     # case-only rename on Windows
        tmp = dst + ".relocate_tmp"
        os.rename(src, tmp)
        os.rename(tmp, dst)
    else:
        if os.path.exists(dst):
            raise RuntimeError("target exists: " + b)
        os.rename(src, dst)


def do_apply(scan, plan, out_dir):
    root = scan.root
    journal = []   # ("move", old, new) / ("write", new_rel, old_bytes), undone in reverse order
    existing = existing_dirs(root)
    try:
        # in memory first: every rewrite must undo exactly
        new_texts = {}
        for rel, edits in plan.edits.items():
            text = scan.contents[rel][1]
            new_texts[rel] = apply_edits(text, edits)
            if inverse(new_texts[rel], edits) != text:
                raise RuntimeError("round trip failed (in memory) for " + rel)
        moved_dirs = [o for o, n in plan.file_moves()]
        for old, new in plan.file_moves():
            rename(root, old, new)
            journal.append(("move", old, new))
        for rel, new_text in new_texts.items():
            new_rel = plan.newpath.get(norm(rel), rel)
            journal.append(("write", new_rel, scan.contents[rel][0]))
            with open(os.path.join(root, new_rel), "wb") as f:
                f.write(new_text.encode("latin-1"))
        remove_empty_dirs(root, moved_dirs)
        problems = verify(scan, plan)
        if problems:
            raise RuntimeError("verification failed:\n  " + "\n  ".join(problems[:50]))
    except BaseException as ex:
        print("ROLLING BACK:", ex)
        rollback(root, journal, existing)
        return 1
    return 0
    manifest = {"files": plan.file_moves(),
                "edits": {plan.newpath.get(norm(r), r): [list(x) for x in e] for r, e in plan.edits.items()}}
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, indent=1)
    print("applied: %d files moved, %d files rewritten (%d references); manifest in %s" % (
        len(plan.file_moves()), len(plan.edits), sum(len(e) for e in plan.edits.values()), out_dir))


def write_manifest(plan, out_dir):
    manifest = {"files": plan.file_moves(),
                "edits": {plan.newpath.get(norm(r), r): [list(x) for x in sorted(e)] for r, e in plan.edits.items()}}
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, indent=1)
    print("applied: %d files moved, %d files rewritten (%d references); manifest in %s" % (
        len(plan.file_moves()), len(plan.edits), sum(len(e) for e in plan.edits.values()), out_dir))


def existing_dirs(root):
    out = set()
    for d, ds, fs in os.walk(root):
        ds[:] = [x for x in ds if x not in SKIP_DIRS]
        out.add(os.path.normcase(os.path.abspath(d)))
    return out


def rollback(root, journal, existing):
    for kind, a, b in reversed(journal):
        if kind == "write":
            with open(os.path.join(root, a), "wb") as f:
                f.write(b)
        else:
            rename(root, b, a)
    # remove the folders the moves created (only those)
    for d, ds, fs in sorted(os.walk(root, topdown=False), key=lambda x: -len(x[0])):
        if os.path.normcase(os.path.abspath(d)) not in existing and os.path.isdir(d) and not os.listdir(d):
            os.rmdir(d)
    print("rolled back: %d moves undone, %d files restored" % (
        sum(1 for j in journal if j[0] == "move"), sum(1 for j in journal if j[0] == "write")))


def remove_empty_dirs(root, old_files):
    dirs = set()
    for o in old_files:
        d = os.path.dirname(o)
        while d:
            dirs.add(d)
            d = os.path.dirname(d)
    for d in sorted(dirs, key=lambda x: -len(x)):
        p = os.path.join(root, d)
        if os.path.isdir(p) and not os.listdir(p):
            os.rmdir(p)


def verify(old_scan, plan):
    """Re-scan the moved tree and compare with the old scan mapped through the plan."""
    problems = []
    new_scan = Scan(old_scan.root, old_scan.data_dir)
    t_old, t_new = old_scan.tree, new_scan.tree
    # files: every old file is at its new path, content unchanged unless rewritten (then the round trip holds)
    expect = {norm(v): k for k, v in plan.newpath.items()}
    if set(expect) != set(t_new.files):
        extra = sorted(set(t_new.files) - set(expect))[:10]
        missing = sorted(set(expect) - set(t_new.files))[:10]
        problems.append("file set differs: extra %s, missing %s" % (extra, missing))
    edits_by_new = {norm(plan.newpath.get(norm(r), r)): e for r, e in plan.edits.items()}
    for nk, ok in expect.items():
        if nk not in t_new.files:
            continue
        path_new = os.path.join(old_scan.root, t_new.files[nk])
        with open(path_new, "rb") as f:
            nb = f.read()
        old_rel = t_old.files[ok]
        if old_rel in old_scan.contents:
            ob = old_scan.contents[old_rel][0]
        else:
            with open(os.path.join(old_scan.root, t_new.files[nk]), "rb") as f:
                ob = f.read()   # binary files: compare with md5 recorded below
        if nk in edits_by_new:
            if inverse(nb.decode("latin-1"), edits_by_new[nk]).encode("latin-1") != ob:
                problems.append("round trip differs: " + t_new.files[nk])
        elif old_rel in old_scan.contents and nb != ob:
            problems.append("content changed without an edit: " + t_new.files[nk])
    for k, h in old_scan.binary_md5.items():
        nk = norm(plan.newpath[k])
        if nk in t_new.files:
            with open(os.path.join(old_scan.root, t_new.files[nk]), "rb") as f:
                if md5(f.read()) != h:
                    problems.append("binary file changed: " + t_new.files[nk])
    # references: the same references, each pointing at the moved target
    def sig(scan, r, mapper):
        if r.kind in ("mod", "include", "repo") and r.target is not None:
            tgt = r.target
            if r.kind == "repo" and tgt.endswith("/"):
                return (r.kind, "dir")
            return (r.kind, mapper(tgt))
        if r.kind in ("dangling", "engine", "level", "pinned"):
            return (r.kind, r.text)
        return (r.kind, None)
    old_sigs = defaultdict(Counter)
    for r in old_scan.refs:
        old_sigs[norm(plan.newpath.get(norm(r.file), r.file))][sig(old_scan, r, lambda k: norm(plan.newpath[k]))] += 1
    new_sigs = defaultdict(Counter)
    for r in new_scan.refs:
        new_sigs[norm(r.file)][sig(new_scan, r, lambda k: k)] += 1
    for f in set(old_sigs) | set(new_sigs):
        a, b = old_sigs.get(f, Counter()), new_sigs.get(f, Counter())
        if a != b:
            diff = (a - b) + (b - a)
            problems.append("references differ in %s: %s" % (f, list(diff.items())[:4]))
    old_amb = [(norm(plan.newpath.get(norm(a), a)), b, c) for a, b, c in old_scan.ambiguous]
    for x in sorted(set((norm(a), b, tuple(c)) for a, b, c in new_scan.ambiguous)):
        if (x[0], x[1], list(x[2])) not in old_amb:
            problems.append("ambiguous include after the move: %s" % (x,))
    return problems


# ----------------------------------------------------------------------------------------------- CLI

def report_scan(scan, out):
    s = scan.summary()
    print("files: %d (%d text), references: %s" % (len(scan.tree.files), len(scan.contents), s))
    print("levels with a LEVEL folder: %s" % {k: v for k, v in scan.levels.items() if v})
    lines = []
    for r in scan.refs:
        if r.kind in ("dangling", "prefix", "level", "pinned"):
            lines.append("%-8s %s  %s  %s" % (r.kind, r.where(scan.contents[r.file][1]), r.text,
                                              r.note if r.note else (r.target if r.kind == "prefix" else "")))
    for a, b, c in scan.ambiguous:
        lines.append("ambig    %s  %s  %s" % (a, b, c))
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "scan.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print("details (dangling / prefix / level / pinned / ambiguous): %s" % os.path.join(out, "scan.txt"))


def main(argv):
    args = list(argv)

    def opt(name, default):
        if name in args:
            i = args.index(name)
            v = args[i + 1]
            del args[i:i + 2]
            return v
        return default
    root = os.path.abspath(opt("--root", REPO))
    data = opt("--data", DEFAULT_DATA)
    out = opt("--out", os.path.join(HERE, "out"))
    if not args:
        print(__doc__)
        return 2
    cmd = args[0]
    scan = make_scan(root, data)
    if cmd == "scan":
        report_scan(scan, out)
        return 0
    if cmd not in ("plan", "apply") or len(args) < 2:
        print(__doc__)
        return 2
    moves, acks = read_moves(args[1])
    plan = Plan(scan, moves, acks)
    write_plan_report(scan, plan, out)
    if plan.errors:
        print("%d errors (see %s):" % (len(plan.errors), os.path.join(out, "plan.txt")))
        for e in plan.errors[:30]:
            print("  " + e)
        return 1
    if cmd == "apply":
        if do_apply(scan, plan, out):
            return 1
        write_manifest(plan, out)
    return 0


def make_scan(root, data):
    scan = Scan(root, data)
    scan.data_dir = data
    scan.binary_md5 = {}
    for k, rel in scan.tree.files.items():
        if rel not in scan.contents:
            with open(os.path.join(root, rel), "rb") as f:
                scan.binary_md5[k] = md5(f.read())
    return scan


def write_plan_report(scan, plan, out):
    os.makedirs(out, exist_ok=True)
    moves = plan.file_moves()
    n_refs = sum(len(e) for e in plan.edits.values())
    with open(os.path.join(out, "plan.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write("files moved: %d, files rewritten: %d, references rewritten: %d\n\n" % (len(moves), len(plan.edits), n_refs))
        for e in plan.errors:
            f.write("ERROR " + e + "\n")
        for w in plan.warnings:
            f.write("warn  " + w + "\n")
        f.write("\n== moves\n")
        for o, n in moves:
            f.write("%s -> %s\n" % (o, n))
        f.write("\n== rewrites\n")
        for rel in sorted(plan.edits):
            text = scan.contents[rel][1]
            for s, e, old, new in sorted(plan.edits[rel]):
                f.write("%s:%d  %s  ->  %s\n" % (rel, text.count("\n", 0, s) + 1, old, new))
    print("plan: %d files moved, %d files rewritten (%d references), %d errors, %d warnings -> %s" % (
        len(moves), len(plan.edits), n_refs, len(plan.errors), len(plan.warnings), os.path.join(out, "plan.txt")))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
