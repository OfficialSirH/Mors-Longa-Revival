"""Phase 5: build the release copy of the mod for the Workshop upload (user decision 2026-11-13: "Release copy").

Usage (repo root): python tools/porting/make_release.py [--dry-run] [--dest <folder>]

The game's local mod folder (Documents/Teardown/mods/Mors Longa Revival) is a junction to this repo, so uploading it
would send .git (~370 MB) and every dev file. This copies only what the game loads into a separate local mod,
default Documents/Teardown/mods/Mors Longa Revival (Release); upload that one from the game's mod manager.

* Left out: EXCLUDE_DIRS / EXCLUDE_FILES / EXCLUDE_EXT below (git, tools, docs, unused/, dev notes, editor files).
* info.txt: the repo's, with " (dev)" taken off the name; refuses to build while it still says AUTHOR_NAME.
* id.txt: the Workshop item the upload updates. The repo's has no id (the original mod's item 2906369984 was
  removed, 2026-11-13: an upload would have tried to update Overdrive Studios' item). After the first upload the
  game writes the new item's id into the release folder's id.txt: a rebuild keeps that file.
* Rebuild: the release folder is emptied first (except id.txt), only if it carries this script's marker file
  (MARKER), so it never clears a folder it did not make.
"""
import os, shutil, sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DEFAULT_DEST = os.path.join(os.path.expanduser("~"), "Documents", "Teardown", "mods", "Mors Longa Revival (Release)")
MARKER = ".made_by_make_release"
ORIGINAL_ITEM = "2906369984"  # the original Mors Longa's Workshop item (Overdrive Studios): never upload to it

EXCLUDE_DIRS = {".git", ".github", ".vscode", "tools", "docs", "unused", "Teardown-Totally-Documented-main",
                "_WORKSHOP", "__pycache__"}
EXCLUDE_FILES = {".git-blame-ignore-revs", ".gitattributes", ".gitignore", ".luarc.json", ".mcp.json", "CLAUDE.md",
                 "README.md", "id.txt", "info.txt", MARKER}
EXCLUDE_EXT = {".py", ".pyc", ".psd", ".md", ".sqlite", ".sh", ".yml"}


def wanted(rel_dir, name, is_dir):
    if is_dir:
        return not (rel_dir == "" and name in EXCLUDE_DIRS) and name not in (".git", "__pycache__")
    if rel_dir == "" and name in EXCLUDE_FILES:
        return False
    return os.path.splitext(name)[1].lower() not in EXCLUDE_EXT


def main():
    dry = "--dry-run" in sys.argv
    dest = sys.argv[sys.argv.index("--dest") + 1] if "--dest" in sys.argv else DEFAULT_DEST
    info = open(os.path.join(REPO, "info.txt"), encoding="utf-8").read()
    if "AUTHOR_NAME" in info:
        sys.exit("info.txt still says AUTHOR_NAME: put the author name in first")
    info = info.replace("Mors Longa Revival (dev)", "Mors Longa Revival", 1)

    keep_id = None
    if os.path.isdir(dest):
        if not os.path.exists(os.path.join(dest, MARKER)):
            sys.exit("%s exists but was not made by this script (no %s): not touching it" % (dest, MARKER))
        idp = os.path.join(dest, "id.txt")
        if os.path.exists(idp):
            keep_id = open(idp, encoding="utf-8").read()
            if keep_id.strip().splitlines() and keep_id.strip().splitlines()[0].strip() == ORIGINAL_ITEM:
                sys.exit("the release id.txt names the original mod's item %s: fix it first" % ORIGINAL_ITEM)

    files, total = [], 0
    for d, ds, fs in os.walk(REPO):
        rel = os.path.relpath(d, REPO)
        rel = "" if rel == "." else rel
        ds[:] = sorted(x for x in ds if wanted(rel, x, True))
        for f in sorted(fs):
            if wanted(rel, f, False):
                src = os.path.join(d, f)
                files.append((src, os.path.join(rel, f)))
                total += os.path.getsize(src)
    print("%d files, %.0f MB -> %s" % (len(files), total / 1e6, dest))
    if dry:
        return

    if os.path.isdir(dest):
        for name in os.listdir(dest):
            if name == "id.txt":
                continue
            p = os.path.join(dest, name)
            shutil.rmtree(p) if os.path.isdir(p) and not os.path.islink(p) else os.remove(p)
    os.makedirs(dest, exist_ok=True)
    for src, rel in files:
        out = os.path.join(dest, rel)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        shutil.copy2(src, out)
    open(os.path.join(dest, "info.txt"), "w", encoding="utf-8", newline="\n").write(info)
    if keep_id is None:
        shutil.copy2(os.path.join(REPO, "id.txt"), os.path.join(dest, "id.txt"))
    open(os.path.join(dest, MARKER), "w").write("made by tools/porting/make_release.py; rebuilt (emptied) on each run\n")
    first = open(os.path.join(dest, "id.txt"), encoding="utf-8").read().strip().split("\n")[0].strip()
    print("done; id.txt: %s" % ("Workshop item " + first if first.isdigit() else "no item id (the upload creates a new item)"))


if __name__ == "__main__":
    main()
