#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从开发镜像 rxsend_server_content 同步源码进本仓库。

用法:
    python tools/sync_from_source.py           # 同步（写入）
    python tools/sync_from_source.py --check   # 只对比，不写入

同步内容:
    rxsend_server_content/gamemodes/rxsend_breach/  ->  gamemodes/rxsend_breach/
    rxsend_server_content/lua/vgui/dmodelpanel.lua  ->  lua/vgui/dmodelpanel.lua
    rxsend_server_content/_*.*                      ->  tools/migration/
    rxsend_server_content/部署指南.md、更新说明.txt   ->  docs/（执行脱敏）

发布副本会自动执行脱敏（见 REDACTIONS），防止敏感信息进入公开仓库。
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]           # rxsend-breach-cn/
SRC = REPO.parent / "rxsend_server_content"           # 开发镜像

# 脱敏规则: (正则, 替换, 限定的文件名子串; None 表示所有文件)
# 只按模式匹配，规则表中不保存任何真实密钥
REDACTIONS = [
    # Steam Web API authkey（启动命令中 -authkey 后的 32 位十六进制串）
    (re.compile(rb"(-authkey\s+)[0-9A-Fa-f]{32}"),
     b"\\g<1>" + "<你的Steam Web API Key>".encode("utf-8"), None),
    # 玩家 SteamID64（仅更新说明中的提及）
    (re.compile(rb"7656119\d{10}"),
     "<玩家SteamID64>".encode("utf-8"), "更新说明.txt"),
]


def redact(data: bytes, name: str) -> bytes:
    for pattern, repl, only in REDACTIONS:
        if only and only not in name:
            continue
        data = pattern.sub(repl, data)
    return data


def plan() -> list[tuple[Path, Path]]:
    """返回 (源文件, 目标文件) 同步清单。"""
    jobs: list[tuple[Path, Path]] = []

    gm = SRC / "gamemodes" / "rxsend_breach"
    for f in sorted(gm.rglob("*")):
        if f.is_file():
            jobs.append((f, REPO / "gamemodes" / "rxsend_breach" / f.relative_to(gm)))

    jobs.append((SRC / "lua" / "vgui" / "dmodelpanel.lua",
                 REPO / "lua" / "vgui" / "dmodelpanel.lua"))

    for f in sorted(SRC.glob("_*")):
        if f.is_file():
            jobs.append((f, REPO / "tools" / "migration" / f.name))

    for name in ("部署指南.md", "更新说明.txt"):
        jobs.append((SRC / name, REPO / "docs" / name))

    return jobs


def main() -> int:
    check = "--check" in sys.argv
    if not SRC.is_dir():
        print(f"[错误] 找不到开发镜像: {SRC}")
        return 2

    copied = same = 0
    for src, dst in plan():
        data = redact(src.read_bytes(), src.name)
        old = dst.read_bytes() if dst.exists() else None
        if old == data:
            same += 1
            continue
        copied += 1
        state = "新增" if old is None else "更新"
        if check:
            print(f"  [差异] {state}: {dst.relative_to(REPO)}")
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(data)
            print(f"  {state}: {dst.relative_to(REPO)}")

    # 源中已删除、仓库仍保留的文件只提示，不自动删除
    tracked = {dst for _, dst in plan()}
    for f in sorted((REPO / "tools" / "migration").glob("_*")):
        if f not in tracked:
            print(f"  [提示] 源中已不存在，仓库仍保留: {f.relative_to(REPO)}")

    print(f"\n{'待同步' if check else '已同步'}: {copied} 个文件，{same} 个无变化。")
    if check and copied:
        print("运行 python tools/sync_from_source.py 执行同步。")
    return 1 if (check and copied) else 0


if __name__ == "__main__":
    raise SystemExit(main())
