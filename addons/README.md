# addons/ — 本仓库不包含此目录内容

在完整服务端中，本目录存放全部游戏内容与插件，**合计约 24GB，不随本仓库分发**。

需要哪些内容、如何获取，详见 [../docs/依赖清单.md](../docs/依赖清单.md)。简要说明：

| 类别 | 说明 |
|---|---|
| **36 个国服 Workshop 内容包** | `addons/` 下的数字编号目录（如 `3168732387/`），已解包为普通文件夹，直接放进服务器即可，无需再订阅工坊。来源：Steam 创意工坊合集 **3796043743** |
| **21 个服务端插件** | `addons/[admin]_ulx_ulib/`、`addons/[weapons]_cw_20/` 等，随上游 RXSEND Breach 仓库一同分发，本仓库不复刻 |
| **3 个适配层** | `_adapter_models`（约 5600 文件）/ `_adapter_sounds` / `_adapter_materials`，由 `tools/migration/` 中的脚本在本机生成，把游戏代码引用的资源路径映射到国服包中的实际文件 |

部署时把获取到的内容放回本目录即可 —— 目录结构与服务器的 `garrysmod/addons/` 完全一致。

> ⚠️ `_adapter_*` 三个目录的生成依赖完整国服内容包，脚本位于 `tools/migration/`，映射表（`_mat_map.txt` / `_sound_map*.txt` 等）随仓库提供，可据此重建。
