# -*- coding: utf-8 -*-
"""Apply _sound_map*.txt: copy pack sounds into addons/_adapter_sounds at code-expected paths."""
import os, shutil, glob

ROOT = r'C:\Users\Aurelia\Desktop\News\rxsend_server_content'
ADDONS = os.path.join(ROOT, 'addons')
ADAPTER = os.path.join(ADDONS, '_adapter_sounds')

lines = []
for mapfile in sorted(glob.glob(os.path.join(ROOT, '_sound_map*.txt'))):
    with open(mapfile, encoding='utf-8') as f:
        for l in f:
            l = l.rstrip('\n')
            if l.strip() and '\t' in l:
                lines.append((os.path.basename(mapfile), l))
applied, skipped, missing = [], [], []
for srcmap, line in lines:
    key, src = line.split('\t', 1)
    key = key.strip().replace('\\', '/')
    src = src.strip().replace('\\', '/')
    if key.startswith('sound/'):
        key = key[len('sound/'):]
    srcpath = os.path.join(ADDONS, src)
    dst = os.path.join(ADAPTER, 'sound', key)
    if not os.path.exists(srcpath):
        missing.append((key, src))
        continue
    if os.path.exists(dst):
        skipped.append((key, src))
        continue
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(srcpath, dst)
    applied.append((key, src, dst))

print('APPLIED', len(applied))
for k, s, d in applied:
    print('  %-45s <= %s' % (k, s))
print('SKIPPED(dup)', len(skipped))
for k, s in skipped:
    print('  %-45s <= %s' % (k, s))
print('MISSING TARGET', len(missing))
for k, s in missing:
    print('  %-45s (target %s NOT FOUND)' % (k, s))
