# -*- coding: utf-8 -*-
"""Apply _mat_map.txt: copy pack materials into addons/_adapter_materials at code-expected paths."""
import os, shutil

ROOT = r'C:\Users\Aurelia\Desktop\News\rxsend_server_content'
ADDONS = os.path.join(ROOT, 'addons')
ADAPTER = os.path.join(ADDONS, '_adapter_materials')
MAPFILE = os.path.join(ROOT, '_mat_map.txt')

with open(MAPFILE, encoding='utf-8') as f:
    lines = [l.rstrip('\n') for l in f if l.strip() and '\t' in l]

applied, skipped, missing = [], [], []
for line in lines:
    key, src = line.split('\t', 1)
    key = key.strip().replace('\\', '/')
    src = src.strip().replace('\\', '/')
    srcpath = os.path.join(ADDONS, src)
    dst = os.path.join(ADAPTER, 'materials', key)
    if not os.path.exists(srcpath):
        missing.append((key, src))
        continue
    if os.path.exists(dst):
        skipped.append((key, src))
        continue
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(srcpath, dst)
    applied.append((key, src))

# nextoren/menu.vmt wrapper so Material("nextoren/menu") resolves
menu_vmt = os.path.join(ADAPTER, 'materials', 'nextoren', 'menu.vmt')
if not os.path.exists(menu_vmt):
    os.makedirs(os.path.dirname(menu_vmt), exist_ok=True)
    with open(menu_vmt, 'w', encoding='utf-8') as f:
        f.write('"UnlitGeneric"\n{\n\t"$basetexture" "nextoren/menu"\n\t"$vertexcolor" "1"\n\t"$vertexalpha" "1"\n}\n')
    applied.append(('nextoren/menu.vmt (generated)', '-'))

print('APPLIED', len(applied))
for k, s in applied:
    print('  %-50s <= %s' % (k, s))
print('SKIPPED(dup)', len(skipped))
for k, s in skipped:
    print('  %-50s <= %s' % (k, s))
print('MISSING TARGET', len(missing))
for k, s in missing:
    print('  %-50s (target %s NOT FOUND)' % (k, s))
