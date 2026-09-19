#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成源码发布包（zip + SHA256 校验文件）。

用法:
    python tools/make_release.py 1.0.0

输出:
    dist/rxsend-breach-cn-v1.0.0.zip
    dist/rxsend-breach-cn-v1.0.0.zip.sha256

优先使用 git archive，只打包 git 跟踪的文件；不在 git 仓库中时退化为遍历打包
（排除 .git / dist / __pycache__ 等目录）。
注意: git archive 只包含已提交内容，打包前请先提交改动。
"""
from __future__ import annotations

import hashlib
import re
import subprocess
import sys
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
EXCLUDE_DIRS = {".git", "dist", "__pycache__", ".claude", ".codegraph"}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    if len(sys.argv) != 2 or not re.fullmatch(r"\d+\.\d+\.\d+", sys.argv[1]):
        print("用法: python tools/make_release.py <版本号，如 1.0.0>")
        return 2
    version = sys.argv[1]

    dist = REPO / "dist"
    dist.mkdir(exist_ok=True)
    name = f"rxsend-breach-cn-v{version}"
    out = dist / f"{name}.zip"

    if (REPO / ".git").exists():
        dirty = subprocess.run(["git", "status", "--porcelain"], cwd=REPO,
                               capture_output=True, text=True).stdout.strip()
        if dirty:
            print("[提示] 工作区有未提交改动，git archive 只包含已提交内容。")
        subprocess.run(
            ["git", "archive", "--format=zip", f"--prefix={name}/", "-o", str(out), "HEAD"],
            cwd=REPO, check=True)
    else:
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
            for f in sorted(REPO.rglob("*")):
                if f.is_file() and not any(p in EXCLUDE_DIRS for p in f.relative_to(REPO).parts):
                    zf.write(f, f"{name}/{f.relative_to(REPO).as_posix()}")

    digest = sha256(out)
    (dist / f"{name}.zip.sha256").write_text(f"{digest}  {name}.zip\n", encoding="utf-8")
    print(f"发布包: {out}")
    print(f"大小:   {out.stat().st_size / 1024 / 1024:.2f} MB")
    print(f"SHA256: {digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
