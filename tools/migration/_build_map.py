#!/usr/bin/env python3
"""Build mapping report: for each missing model ref, find best candidates in CN pack."""
import os
import re
import csv
from difflib import SequenceMatcher

ROOT = r"C:\Users\Aurelia\Desktop\News\rxsend_server_content"
ADDONS = os.path.join(ROOT, "addons")

def norm(s):
    return s.replace("\\", "/").lower()

def strip_prefix(name):
    # strip v_/w_/c_ prefixes and model path noise for comparison
    b = os.path.basename(name)
    b = re.sub(r"^(v_|w_|c_|a_|sv_|m_)", "", b)
    b = re.sub(r"\.mdl$", "", b)
    return b

def tokenize(b):
    return set(re.findall(r"[a-z0-9]+", b))

# load all pack models
pack = []
for dirpath, dirnames, filenames in os.walk(ADDONS):
    for fn in filenames:
        if fn.lower().endswith(".mdl"):
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ADDONS)
            pack.append(norm(rel))

pack_base = {}
for p in pack:
    b = os.path.basename(p)
    pack_base.setdefault(b, []).append(p)

# load missing custom models
missing = [l.strip() for l in open(os.path.join(ROOT, "_missing_custom.txt"), encoding="utf-8") if l.strip()]

rows = []
for m in missing:
    mb = norm(os.path.basename(m))
    mbt = strip_prefix(mb)
    mtok = tokenize(mbt)
    cands = []
    # exact basename match
    if mb in pack_base:
        for p in pack_base[mb]:
            cands.append((1.0, p))
    else:
        # similarity by tokens
        scored = []
        for b, plist in pack_base.items():
            bt = strip_prefix(b)
            btok = tokenize(bt)
            if not mtok or not btok:
                continue
            inter = mtok & btok
            if not inter:
                continue
            score = len(inter) / max(len(mtok), len(btok)) * 0.6 + SequenceMatcher(None, mbt, bt).ratio() * 0.4
            if score >= 0.5:
                for p in plist:
                    scored.append((score, p))
        scored.sort(reverse=True)
        cands = scored[:3]
    rows.append((m, mb, cands))

with open(os.path.join(ROOT, "_mapping_report.csv"), "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f)
    w.writerow(["missing_ref", "basename", "candidates"])
    for m, mb, cands in rows:
        clist = " | ".join(f"{s:.2f}:{p}" for s, p in cands)
        w.writerow([m, mb, clist])

# stats
exact = sum(1 for _, _, c in rows if c and c[0][0] >= 1.0)
anycand = sum(1 for _, _, c in rows if c)
print(f"missing: {len(rows)}, exact basename matches: {exact}, with any candidate: {anycand}")
