#!/usr/bin/env python3
"""Apply semantic mappings: copy pack model (with siblings) to ADAPTER at code-expected path."""
import os
import shutil

ROOT = r"C:\Users\Aurelia\Desktop\News\rxsend_server_content"
ADDONS = os.path.join(ROOT, "addons")
ADAPTER = os.path.join(ADDONS, "_adapter_models")
MAP_FILE = os.path.join(ROOT, "_semantic_map.txt")

def copy_with_siblings(src, dest):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    srcdir = os.path.dirname(src)
    stem = os.path.splitext(os.path.basename(src))[0]
    destdir = os.path.dirname(dest)
    deststem = os.path.splitext(os.path.basename(dest))[0]
    for sib in os.listdir(srcdir):
        if sib.lower().startswith(stem.lower() + "."):
            ext = os.path.splitext(sib)[1]
            shutil.copy2(os.path.join(srcdir, sib), os.path.join(destdir, deststem + ext))
    shutil.copy2(src, dest)

ok = 0
skip = 0
err = []
for line in open(MAP_FILE, encoding="utf-8"):
    line = line.strip()
    if not line or "\t" not in line:
        continue
    ref, src = line.split("\t", 1)
    src = src.strip()
    if not src:
        continue
    src_path = os.path.join(ADDONS, src.replace("/", os.sep))
    if not os.path.exists(src_path):
        err.append((ref, src))
        continue
    dest = os.path.join(ADAPTER, ref.replace("/", os.sep))
    copy_with_siblings(src_path, dest)
    ok += 1

print(f"applied: {ok}")
if err:
    print(f"errors (source missing): {len(err)}")
    for r, s in err[:20]:
        print(f"  {r}  ->  {s}")
