# 官方来源与改动

## 程序

- 官方版本：[XrayR v0.9.4](https://github.com/XrayR-project/XrayR/releases/tag/v0.9.4)
- 代码提交：`944e8cd6a8376d6daa86e9e445b8afb8264c0b33`
- 发布时间：2024-07-21
- 程序直接从该官方 release 下载，不修改、重编译或附带第三方二进制。

| 官方安装包 | SHA256 |
| --- | --- |
| XrayR-linux-64.zip | `ad06efe7ca3c19ea20817fb2aa163185f012433d97f8d4cc30eff30ca02bc5b4` |
| XrayR-linux-arm64-v8a.zip | `2c2fa9dbc282f30caecaa026319927f6f0a4492f576239fa59c490abd2076558` |
| XrayR-linux-s390x.zip | `16e06ff2451962169355ef6a97d1dd05a058b500e858063db2a4107b922a679c` |

以上校验值来自官方同名 `.zip.dgst` 文件，并固定在安装器中。

## 菜单与服务文件

来自 [XrayR-project/XrayR-release 的官方历史提交](https://github.com/XrayR-project/XrayR-release/tree/3611f177d77dc86410bdea4bec436889b4d18420)：

`3611f177d77dc86410bdea4bec436889b4d18420`（2024-06-22，v0.9.4 发布前的最新脚本提交）。

- `XrayR.sh`：官方中文管理菜单，嵌入 `install.sh` 的 `render_menu` 函数。
- `XrayR.service`：保留原始服务文件内容，嵌入 `render_service` 函数。
- `LICENSE`：保留官方 MPL-2.0 许可证。

官方脚本仓库的当前分支已移除旧安装文件，因此本仓库不调用原来的 `master/install.sh` 或 `master/XrayR.sh`。

## 本仓库的必要改动

1. 安装和重装仅允许 v0.9.4；不查询或跟随最新版。
2. 安装器自带菜单和服务文件，保存到 `/usr/local/share/XrayR/install.sh` 供本地重装和恢复菜单。
3. 保留菜单主要布局和命令，将第三方 BBR 入口改为退出；维护脚本升级改为本地恢复。
4. 使用 HTTPS 校验、固定 SHA256、下载失败检测和安装包版本检查。
5. 下载校验完成后再替换程序，保留旧程序备份用于安装阶段失败恢复；恢复失败时保留备份路径。此恢复不覆盖用户配置，也不对用户配置正确性作保证。
6. 明确拒绝不支持的系统和架构，使用 systemd 的状态接口检查服务。
7. 全新安装保留官方示例配置并暂不启动服务；已有非默认配置时尝试启动。现有配置、路由、DNS、规则及 geo 数据均保留。
8. 只补齐下载、解压、校验所需环境和配置编辑器，不附带 cron、socat、BBR 或独立 acme.sh 安装。

本仓库分发的是公开可修改的安装脚本源文件；XrayR 本身的对应源代码位于上述官方 v0.9.4 标签。此脚本是改编版，保留官方项目归属，不声称为官方原样发布。

## 制作时验证

安装器和独立菜单通过 Bash 语法检查，22 项隔离流程检查通过，覆盖版本与平台限制、配置保留、下载/校验失败保护、失败恢复及菜单调用。官方 Linux x86_64 压缩包已实际下载，SHA256 与上述值一致；嵌入的服务文件与官方历史文件一致。

制作环境为 Windows。流程检查模拟了 Linux、systemd 和二进制运行，尚未进行真实 Linux 服务器部署；ARM64/s390x 的校验值取自官方摘要文件，未在对应机器上运行。
