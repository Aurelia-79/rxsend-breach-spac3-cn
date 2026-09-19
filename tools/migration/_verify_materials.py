# -*- coding: utf-8 -*-
"""Check gamemode Material()/surface refs against pack materials tree."""
import os, re, glob

ROOT = r'C:\Users\Aurelia\Desktop\News\rxsend_server_content'
ADDONS = os.path.join(ROOT, 'addons')
GAMEMODE = os.path.join(ROOT, 'gamemodes', 'rxsend_breach')

# Build set of all material files relative to materials/ (basename -> relpaths)
mat_files = set()
for adir in os.listdir(ADDONS):
    mdir = os.path.join(ADDONS, adir, 'materials')
    if not os.path.isdir(mdir):
        continue
    for dirpath, dirnames, filenames in os.walk(mdir):
        for fn in filenames:
            rel = os.path.relpath(os.path.join(dirpath, fn), mdir).replace('\\', '/')
            mat_files.add(rel.lower())

EXT = ('.vmt', '.vtf', '.png', '.jpg', '.jpeg', '.dds', '.tga', '.gif', '.bmp')

def resolve(ref):
    ref = ref.strip().replace('\\', '/').lower()
    if ref.startswith('/'):
        ref = ref.lstrip('/')
    cands = []
    if os.path.splitext(ref)[1] in EXT:
        cands.append(ref)
    else:
        for e in EXT:
            cands.append(ref + e)
    for c in cands:
        if c in mat_files:
            return c
    return None

# Scan lua: Material("...") and surface.GetTextureID/set material by string, and CreateMaterial? plus entity material set
pat1 = re.compile(r'Material\s*\(\s*"([^"]+)"')
pat2 = re.compile(r'surface\.SetMaterial\s*\(\s*([^,]+)\)\s*[,)]')  # may be variable; skip
refs = {}
for dirpath, dirnames, filenames in os.walk(GAMEMODE):
    for fn in filenames:
        if not fn.endswith('.lua'):
            continue
        p = os.path.join(dirpath, fn)
        txt = open(p, encoding='utf-8', errors='replace').read()
        for m in pat1.finditer(txt):
            ref = m.group(1)
            refs.setdefault(ref, set()).add(os.path.relpath(p, ROOT))

missing = []
for ref, locs in sorted(refs.items()):
    if ref.startswith('l:'):
        continue
    if resolve(ref):
        continue
    missing.append((ref, locs))

print('TOTAL Material() refs:', len(refs))
print('MISSING:', len(missing))
for ref, locs in missing:
    print('%-60s <- %s' % (ref, ', '.join(sorted(locs)[:3])))

with open(os.path.join(ROOT, '_missing_materials.txt'), 'w', encoding='utf-8') as f:
    for ref, locs in missing:
        f.write('%s\t%s\n' % (ref, ', '.join(sorted(locs)[:3])))
print('saved _missing_materials.txt')
