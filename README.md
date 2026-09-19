# RXSEND Breach 国服适配版

> SCP 基金会 RP 游戏模式 · Garry's Mod 服务端源码
> 基于 RXSEND Breach（GitHub 上游 fork）的 **安全清理 + 全量简体中文化 + 国服内容适配** 版本
> 主地图 `cn_rxsend_site19_demo` · 面向 32 人专用服务器

本仓库包含**自制源码部分**（约 6.5MB）：游戏模式本体、自定义 Lua 补丁、适配工具链与文档。
游戏内容包（约 24GB）与二进制模块**不随仓库分发**，获取方式见 [依赖与获取](#依赖与获取)。

## 特性

- **安全清理** —— 移除远程日志外传、CW20 / LeyHitreg RCE 与后门、4 处硬编码远程数据库凭据（改为本地 SQLite，数据只落在服务端 `sv.db`）
- **全量简体中文化** —— 语言表约 800 个翻译键全部中文：HUD、聊天、计分板、角色菜单、成就、商店等
- **国服内容适配** —— 模型 / 声音 / 材质三层路径映射，让游戏代码引用的资源对上国服工坊包中的实际文件；主地图 mapconfig 已就位
- **持续缺陷修复** —— 撤离直升机、GOC 核弹、物品刷新、回合重启广播等，完整列表见 [CHANGELOG.md](CHANGELOG.md)

## 目录结构

```
rxsend-breach-cn/
├── gamemodes/rxsend_breach/   游戏模式本体
│   ├── gamemode/              核心逻辑（modules/ 回合·撤离·核弹·角色·玩家数据…）
│   ├── entities/              实体与武器（heli 撤离直升机、entity_goc_nuke 核弹、SCP 效果…）
│   └── rxsend_breach.txt      游戏模式元数据与 ConVar 默认值
├── lua/vgui/dmodelpanel.lua   自定义模型预览面板补丁
├── addons/                    预留目录（内容不随仓库分发，见 addons/README.md）
├── docs/
│   ├── 部署指南.md             完整部署步骤
│   ├── 依赖清单.md             需要哪些内容、从哪里获取
│   └── 更新说明.txt            历史交付说明
└── tools/
    ├── migration/             国服适配期脚本与映射表（模型 / 声音 / 材质路径映射）
    ├── sync_from_source.py    从开发镜像同步源码进本仓库（含脱敏）
    └── make_release.py        生成源码发布包（zip + SHA256）
```

## 快速部署

前提：已安装 [Garry's Mod 专用服务器](https://developer.valvesoftware.com/wiki/SteamCMD)（SteamCMD app `4020`，64 位），并已获取内容依赖（见下节）。

1. **合并源码**：把本仓库的 `gamemodes/`、`lua/` 覆盖进服务器 `garrysmod/` 对应目录
2. **放置内容**：把 24GB 内容包解包后放进 `garrysmod/addons/`，二进制模块放进 `garrysmod/lua/bin/`
3. **启动服务器**：

```
srcds.exe -game garrysmod -console -port 27015 +maxplayers 32 +gamemode rxsend_breach +map cn_rxsend_site19_demo +host_workshop_collection 3796043743 -authkey <你的Steam Web API Key>
```

4. **添加管理员**（服务器控制台）：`ulx adduser <你的SteamID> superadmin`

完整步骤、换图方法与实测验证记录见 [docs/部署指南.md](docs/部署指南.md)。

> ⚠️ **文件总数上限**：GMod 服务端文件总数超过约 66,000 时会在启动阶段崩溃（steam.dll 访问冲突）。
> 完整内容包已精简至约 62,000 文件，继续加内容时请留意，不要超过 65,000。

## 依赖与获取

| 依赖 | 体积 | 获取方式 |
|---|---|---|
| 36 个国服工坊内容包 | ~24GB | 创意工坊合集 **3796043743**，解包后放入 `addons/`（含主地图 BSP） |
| 21 个服务端插件 | — | 随上游 RXSEND Breach 仓库分发（ULX/ULib、CW2.0 等） |
| 适配层 `_adapter_*` | ~1.2GB | 由 `tools/migration/` 脚本生成，映射表随仓库提供 |
| 二进制模块 `lua/bin/` | ~104MB | 见 [依赖清单](docs/依赖清单.md#二二进制模块luabin)，按官方仓库下载对应平台版本 |
| `data/` 运行状态 | — | 服务器首次启动自动生成；可选内容（SCP-263 题库等）从完整服务端包获取 |

完整说明（含 36 个工坊 ID、21 个插件清单、各二进制模块官方链接）见 **[docs/依赖清单.md](docs/依赖清单.md)**。

## 工具链

| 脚本 | 用途 |
|---|---|
| `python tools/sync_from_source.py` | 从 `rxsend_server_content` 开发镜像同步源码进仓库，自动脱敏；`--check` 只对比不写入 |
| `python tools/make_release.py 1.0.0` | 生成 `dist/rxsend-breach-cn-v1.0.0.zip` 与 `.sha256` 校验文件 |
| `tools/migration/` | 国服适配期使用的路径映射脚本与映射表（模型 618 处 / 声音 86 条 / 材质 28 条） |

## 已知问题

以下音效是原国服服务器本地的自定义文件，未打进工坊，完整内容包中也没有原版，目前用包内替代曲目顶上（不报错、不影响运行）：

- 撤离音乐 `cheli*` / `arknigts1` / `mhy1` / `uma1.mp3`（已用包内 evacuation 曲目替代）
- 阵营登场曲 `army_intro` / `ymca` / `gocmusic2` / `goc_intro3`
- 播报 `rxsend_music/cassie_no_scps2` / `xinghong` / `friendly_goc_in`

如需原版，把文件放到 `garrysmod/sound/` 对应路径即可，无需改代码。

## 来源与致谢

- 游戏模式源自 **RXSEND Breach**（GitHub 上游项目，作者未署名），本仓库是其 fork 的国服适配分支
- 上游代码中保留的作者水印与彩蛋名单（成就署名、特殊头部模型名单等）未作改动，版权归原作者
- 国服内容包版权归各工坊作者所有，本仓库不包含、不再分发这些资源

## 声明

- 本项目**非官方**项目，与 Northwood Studios / Facepunch 无关
- 本仓库**未附带 LICENSE**（上游许可证不明），默认保留所有权利；如需转载或二次开发，请先联系仓库维护者
- 游戏内容包中的第三方资源请遵循各自工坊页面的授权说明
