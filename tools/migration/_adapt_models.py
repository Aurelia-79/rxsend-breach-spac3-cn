#!/usr/bin/env python3
"""Adaptation: for every model path referenced by code (gamemode + addons)
that is missing from the pack, if the pack contains the same basename anywhere,
copy that file (and its siblings .vvd/.vtx/.phy) into the ADAPTER tree at the
CODE-EXPECTED path (the referenced path), so the engine finds it.

Also handles v_/w_ prefix pairs: if a w_ worldmodel is missing but only a v_
viewmodel exists (or vice versa), copy the available one under BOTH names so
the engine never shows error.mdl.

Output: addons/_adapter_models/<referenced path>
"""
import os
import re
import shutil
import collections

ROOT = r"C:\Users\Aurelia\Desktop\News\rxsend_server_content"
ADDONS = os.path.join(ROOT, "addons")
ADAPTER = os.path.join(ADDONS, "_adapter_models")
SCAN_DIRS = [
    os.path.join(ROOT, "gamemodes", "rxsend_breach"),
    ADDONS,
]
MDL_RE = re.compile(r"models/[A-Za-z0-9_\.\-\/]+\.mdl", re.IGNORECASE)

def walk_lua_files(base):
    for dirpath, dirnames, filenames in os.walk(base):
        for fn in filenames:
            if fn.lower().endswith((".lua", ".txt")):
                yield os.path.join(dirpath, fn)

# 1) collect all referenced model paths
refs = set()
for base in SCAN_DIRS:
    for p in walk_lua_files(base):
        try:
            with open(p, encoding="utf-8", errors="replace") as f:
                txt = f.read()
        except Exception:
            continue
        refs.update(MDL_RE.findall(txt))

# 2) index pack models by basename (excluding adapter dir)
pack_by_path = {}
pack_by_base = collections.defaultdict(list)
for dirpath, dirnames, filenames in os.walk(ADDONS):
    rel_base = os.path.relpath(dirpath, ADDONS).replace("\\", "/")
    if rel_base.split("/")[0] == "_adapter_models":
        continue
    for fn in filenames:
        if fn.lower().endswith(".mdl"):
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ADDONS).replace("\\", "/")
            pack_by_path[rel.lower()] = full
            pack_by_base[fn.lower()].append(full)

def copy_with_siblings(src_mdl, dest_mdl):
    os.makedirs(os.path.dirname(dest_mdl), exist_ok=True)
    srcdir = os.path.dirname(src_mdl)
    stem = os.path.splitext(os.path.basename(src_mdl))[0]
    destdir = os.path.dirname(dest_mdl)
    deststem = os.path.splitext(os.path.basename(dest_mdl))[0]
    for sib in os.listdir(srcdir):
        if sib.lower().startswith(stem.lower() + "."):
            ext = os.path.splitext(sib)[1]
            shutil.copy2(os.path.join(srcdir, sib),
                         os.path.join(destdir, deststem + ext))
    shutil.copy2(src_mdl, dest_mdl)

def swap_prefix(name):
    """v_foo -> w_foo, w_foo -> v_foo, else None"""
    b = os.path.basename(name)
    if b.startswith("v_"):
        return os.path.join(os.path.dirname(name), "w_" + b[2:])
    if b.startswith("w_"):
        return os.path.join(os.path.dirname(name), "v_" + b[2:])
    return None

adapted = []      # (ref, src)
prefix_adapted = []
no_base = []
for r in sorted(refs):
    rl = r.lower()
    if rl in pack_by_path:
        continue
    b = os.path.basename(rl)
    cand = None
    if b in pack_by_base:
        cands = pack_by_base[b]
        # prefer candidate sharing prefix char
        for c in cands:
            if os.path.basename(c).lower()[:1] == b[:1]:
                cand = c
                break
        if cand is None:
            cand = cands[0]
    if cand is not None:
        dest = os.path.join(ADAPTER, r.replace("/", os.sep))
        copy_with_siblings(cand, dest)
        adapted.append((r, os.path.relpath(cand, ADDONS)))
        continue
    # try prefix-swapped basename (v_<->w_)
    swapped = swap_prefix(r)
    if swapped is not None:
        sw = os.path.basename(swapped).lower()
        if sw in pack_by_base:
            cand = pack_by_base[sw][0]
            dest = os.path.join(ADAPTER, r.replace("/", os.sep))
            copy_with_siblings(cand, dest)
            prefix_adapted.append((r, os.path.relpath(cand, ADDONS)))
            continue
    no_base.append(r)

print(f"total refs: {len(refs)}")
print(f"adapted exact-basename: {len(adapted)}")
print(f"adapted via prefix swap (v_<->w_): {len(prefix_adapted)}")
print(f"missing (no basename, no prefix swap): {len(no_base)}")
print()
print("=== ADAPTED exact (first 30) ===")
for r, src in adapted[:30]:
    print(f"  {r}  <-  {src}")
print()
print("=== ADAPTED prefix-swap (first 30) ===")
for r, src in prefix_adapted[:30]:
    print(f"  {r}  <-  {src}")
print()
print("=== STILL MISSING (first 100) ===")
for r in no_base[:100]:
    print("  ", r)

with open(os.path.join(ROOT, "_adapt_report.txt"), "w", encoding="utf-8") as f:
    f.write(f"total refs: {len(refs)}\n")
    f.write(f"adapted exact: {len(adapted)}\n")
    f.write(f"adapted prefix-swap: {len(prefix_adapted)}\n")
    f.write(f"missing: {len(no_base)}\n\n")
    f.write("=== ADAPTED EXACT ===\n")
    for r, src in adapted:
        f.write(f"{r}\t<-\t{src}\n")
    f.write("\n=== ADAPTED PREFIX ===\n")
    for r, src in prefix_adapted:
        f.write(f"{r}\t<-\t{src}\n")
    f.write("\n=== MISSING ===\n")
    for r in no_base:
        f.write(r + "\n")
