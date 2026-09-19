# -*- coding: utf-8 -*-
"""Repair truncated .vmt files (missing closing brace / trailing garbage)."""
import os

ROOT = r'C:\Users\Aurelia\Desktop\News\rxsend_server_content\addons'
BAD = [
    r'3158539639\materials\models\weapons\mp443\grip.vmt',
    r'3158539639\materials\models\weapons\rpq\ak_tac.vmt',
    r'3168756944\materials\arty\codmw2022\mp\shadow company\militant\head\shadow_eyeball_l.vmt',
    r'3168756944\materials\arty\codmw2022\mp\shadow company\militant\head\shadow_eyeball_r.vmt',
    r'3171508439\materials\models\weapons\sq300\sight.vmt',
    r'3171508439\materials\models\weapons\svu\svu.vmt',
    r'3171510948\materials\models\weapons\ak_pack\akm\akm_compensator.vmt',
    r'3171510948\materials\models\weapons\ak_pack\akm\akm_grips.vmt',
    r'3352951512\materials\models\halo7725\russian_operator\cover.vmt',
    r'3629952289\materials\arty\codmw2023\mp\kortac\thirst\rasp\head\eyelashes.vmt',
]

for rel in BAD:
    p = os.path.join(ROOT, rel)
    if not os.path.exists(p):
        print('MISSING:', rel)
        continue
    with open(p, 'r', encoding='utf-8', errors='replace') as f:
        t = f.read()
    stripped = t.rstrip()
    idx = stripped.rfind('}')
    if idx == -1:
        new = stripped + '\n}\n'
    else:
        new = stripped[:idx + 1].rstrip() + '\n}\n'
    with open(p, 'w', encoding='utf-8', errors='replace') as f:
        f.write(new)
    print('FIXED:', rel, '(had close brace: %s)' % (idx != -1))
