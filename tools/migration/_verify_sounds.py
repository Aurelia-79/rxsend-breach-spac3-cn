# -*- coding: utf-8 -*-
"""Scan gamemode lua for sound references and report which are missing from pack+adapter."""
import os, re, glob

ROOT = r'C:\Users\Aurelia\Desktop\News\rxsend_server_content'
ADDONS = os.path.join(ROOT, 'addons')
GAMEMODE = os.path.join(ROOT, 'gamemodes', 'rxsend_breach')

# Build set of all sound files in pack + adapter, keyed by rel path under sound/
pack_sounds = {}
for adir in os.listdir(ADDONS):
    sdir = os.path.join(ADDONS, adir, 'sound')
    if not os.path.isdir(sdir):
        continue
    for dirpath, dirnames, filenames in os.walk(sdir):
        for fn in filenames:
            if fn.lower().endswith(('.wav', '.mp3', '.ogg')):
                rel = os.path.relpath(os.path.join(dirpath, fn), sdir).replace('\\', '/')
                pack_sounds.setdefault(rel.lower(), []).append(os.path.join(adir, 'sound', rel))

# Scan lua refs
pat = re.compile(r'"((?:sound/)?[A-Za-z0-9_\.\-/]+\.(?:wav|mp3|ogg|MP3))"', re.IGNORECASE)
refs = {}
for dirpath, dirnames, filenames in os.walk(GAMEMODE):
    for fn in filenames:
        if not fn.endswith('.lua'):
            continue
        p = os.path.join(dirpath, fn)
        try:
            txt = open(p, encoding='utf-8', errors='replace').read()
        except Exception:
            continue
        for m in pat.finditer(txt):
            ref = m.group(1).replace('\\', '/')
            refs.setdefault(ref, set()).add(os.path.relpath(p, ROOT))

norm = lambda r: r[6:] if r.lower().startswith('sound/') else r
missing = {}
for ref, locs in sorted(refs.items()):
    if norm(ref).lower() not in pack_sounds:
        missing[ref] = locs

print('TOTAL unique refs:', len(refs))
print('MISSING:', len(missing))
print('--- (prefix=rxsend_music) means sound/rxsend_music/<ref> exists in pack (music.lua getpath resolves it at runtime) ---')
for ref, locs in sorted(missing.items()):
    prefix = 'rxsend_music' if ('rxsend_music/' + norm(ref)).lower() in pack_sounds else ''
    print('%-60s %-14s <- %s' % (ref, prefix, ', '.join(sorted(locs)[:3])))

# Save full missing list
with open(os.path.join(ROOT, '_missing_sounds.txt'), 'w', encoding='utf-8') as f:
    for ref, locs in sorted(missing.items()):
        f.write('%s\t%s\n' % (ref, ', '.join(sorted(locs)[:3])))
print('saved _missing_sounds.txt')
