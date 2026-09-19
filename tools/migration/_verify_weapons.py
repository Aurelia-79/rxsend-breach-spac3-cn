#!/usr/bin/env python3
"""Verify every model referenced by every lua file exists (by exact path OR basename anywhere) in the CN pack.
Report gaps per weapon/addon."""
import os
import re
import sys

ROOT = r"C:\Users\Aurelia\Desktop\News\rxsend_server_content"
ADDONS = os.path.join(ROOT, "addons")
GAMEMODE = os.path.join(ROOT, "gamemodes", "rxsend_breach")

MDL_RE = re.compile(r"models/[A-Za-z0-9_\.\-\/]+\.mdl", re.IGNORECASE)

# build pack model index: exact path + basename
# the _adapter_models addon mirrors code-expected paths, so its files are
# content too — index them as their adapter-relative path (models/...).
pack_paths = set()
pack_basenames = {}
for dirpath, dirnames, filenames in os.walk(ADDONS):
    base_rel = os.path.relpath(dirpath, ADDONS).replace("\\", "/")
    first = base_rel.split("/")[0] if base_rel != "." else ""
    for fn in filenames:
        if fn.lower().endswith(".mdl"):
            full = os.path.join(dirpath, fn)
            if first == "_adapter_models":
                # adapter file: its in-addon path IS the code path (models/...)
                rel = os.path.relpath(full, os.path.join(ADDONS, "_adapter_models")).replace("\\", "/").lower()
            else:
                rel = os.path.relpath(full, ADDONS).replace("\\", "/").lower()
            pack_paths.add(rel)
            pack_basenames.setdefault(fn.lower(), []).append(rel)

def check_refs(refs, scope):
    exact_ok = 0
    base_ok = 0
    missing = []
    for r in refs:
        rl = r.lower()
        if rl in pack_paths:
            exact_ok += 1
        else:
            b = os.path.basename(rl)
            if b in pack_basenames:
                base_ok += 1
            else:
                missing.append(r)
    return exact_ok, base_ok, missing

# scan gamemode
gm_refs = []
for dirpath, dirnames, filenames in os.walk(GAMEMODE):
    for fn in filenames:
        if fn.lower().endswith((".lua", ".txt")):
            p = os.path.join(dirpath, fn)
            try:
                with open(p, encoding="utf-8", errors="replace") as f:
                    txt = f.read()
            except Exception:
                continue
            gm_refs.extend(MDL_RE.findall(txt))
gm_refs = sorted(set(gm_refs))
e, b, m = check_refs(gm_refs, "gamemode")
print(f"GAMEMODE: {len(gm_refs)} unique refs | exact={e} basename={b} missing={len(m)}")
for r in m:
    print("  MISS", r)

# scan each addon
for a in sorted(os.listdir(ADDONS)):
    ap = os.path.join(ADDONS, a)
    if not os.path.isdir(ap):
        continue
    refs = []
    for dirpath, dirnames, filenames in os.walk(ap):
        for fn in filenames:
            if fn.lower().endswith(".lua"):
                p = os.path.join(dirpath, fn)
                try:
                    with open(p, encoding="utf-8", errors="replace") as f:
                        txt = f.read()
                except Exception:
                    continue
                refs.extend(MDL_RE.findall(txt))
    refs = sorted(set(refs))
    if not refs:
        continue
    e, b, m = check_refs(refs, a)
    print(f"ADDON {a}: {len(refs)} refs | exact={e} basename={b} missing={len(m)}")
    if m:
        print("   ", "; ".join(m[:8]))
