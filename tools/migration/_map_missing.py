#!/usr/bin/env python3
"""Semantic mapping pass 2: for missing models, find pack candidates by keyword similarity.
Only outputs HIGH-CONFIDENCE mappings (keyword match + prefix match)."""
import os
import re
from difflib import SequenceMatcher

ROOT = r"C:\Users\Aurelia\Desktop\News\rxsend_server_content"
ADDONS = os.path.join(ROOT, "addons")

# load pack model basenames
pack = []
for dirpath, dirnames, filenames in os.walk(ADDONS):
    rel0 = os.path.relpath(dirpath, ADDONS).replace("\\", "/")
    if rel0.split("/")[0] == "_adapter_models":
        continue
    for fn in filenames:
        if fn.lower().endswith(".mdl"):
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ADDONS).replace("\\", "/")
            pack.append(rel)

missing = [l.strip() for l in open(os.path.join(ROOT, "_missing_custom2.txt"), encoding="utf-8") if l.strip()]

def toks(name):
    b = os.path.basename(name)
    b = re.sub(r"\.mdl$", "", b)
    b = re.sub(r"^(v_|w_|c_|a_|sv_)", "", b)
    return set(re.findall(r"[a-z0-9]+", b.lower()))

def pref(name):
    b = os.path.basename(name)
    m = re.match(r"^(v|w|c|a)_", b)
    return m.group(1) if m else ""

results = []
for m in missing:
    mb = os.path.basename(m).lower()
    mt = toks(m)
    mt.discard("mdl")
    if not mt:
        results.append((m, ""))
        continue
    best = None
    best_score = 0
    for p in pack:
        pb = os.path.basename(p)
        if pb.lower() == mb:  # exact basename would have been caught earlier
            continue
        pt = toks(p)
        if not pt:
            continue
        inter = mt & pt
        if not inter:
            continue
        # score: keyword overlap + prefix match + length similarity
        jac = len(inter) / max(len(mt), len(pt))
        seq = SequenceMatcher(None, "".join(sorted(mt)), "".join(sorted(pt))).ratio()
        score = 0.55 * jac + 0.25 * seq
        if pref(m) and pref(p) and pref(m) == pref(p):
            score += 0.2
        elif pref(m) and pref(p):
            score -= 0.1
        # prefer weapons paths
        if "/weapons/" in p:
            score += 0.05
        if score > best_score:
            best_score = score
            best = p
    if best and best_score >= 0.55:
        results.append((m, best))
    else:
        results.append((m, ""))

print(f"mapped with confidence: {sum(1 for _, t in results if t)} / {len(results)}")
print()
for m, t in results:
    if t:
        print(f"{m}\t{t}")
