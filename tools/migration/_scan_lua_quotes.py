# -*- coding: utf-8 -*-
"""Scan .lua files for lines with an odd number of double quotes (unclosed strings)."""
import os, re, sys

ROOT = r'C:\Users\Aurelia\Desktop\News\rxsend_server_content'

# skip files inside these (compiled/binaries)
SKIP_DIRS = {'lua', 'resource'}

def scan(path):
    bad = []
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()
    for i, line in enumerate(lines, 1):
        # ignore pure comment lines
        stripped = line.strip()
        if stripped.startswith('--') or stripped.startswith('//'):
            continue
        q = line.count('"')
        if q % 2 == 1:
            bad.append((i, line.rstrip('\n')))
    return bad

report = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    rel = os.path.relpath(dirpath, ROOT)
    parts = rel.split(os.sep)
    if parts and parts[0] in SKIP_DIRS:
        dirnames[:] = []
        continue
    for fn in filenames:
        if not fn.endswith('.lua'):
            continue
        p = os.path.join(dirpath, fn)
        bad = scan(p)
        if bad:
            report.append((os.path.relpath(p, ROOT), bad))

print('FILES WITH ODD-QUOTE LINES:', len(report))
for rel, bad in report:
    print('\n== %s (%d lines)' % (rel, len(bad)))
    for ln, txt in bad[:60]:
        print('  %4d: %s' % (ln, txt[:160]))
    if len(bad) > 60:
        print('  ... and %d more' % (len(bad) - 60))
