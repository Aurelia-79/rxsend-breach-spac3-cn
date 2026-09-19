# -*- coding: utf-8 -*-
p = r'C:\Users\Aurelia\Desktop\News\rxsend_server_content\addons\[admin]_awarn2\lua\autorun\sh_localization.lua'
lines = open(p, encoding='utf-8', errors='replace').read().split('\n')
print('--- odd-quote lines 1..90 ---')
for i in range(1, 91):
    ln = lines[i-1]
    if ln.count('"') % 2 == 1:
        print(i, repr(ln[:90]))
print('--- odd-quote lines 290..360 ---')
for i in range(290, 361):
    ln = lines[i-1]
    if ln.count('"') % 2 == 1:
        print(i, repr(ln[:90]))
