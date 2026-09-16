# XrayR v0.9.4 一键安装

固定安装 **官方 XrayR v0.9.4**，保留官方中文管理菜单的主要功能。安装全程无需选择版本、架构或手动安装依赖。

适用于使用 **systemd 的 64 位 Linux**：Debian、Ubuntu，以及使用 yum/dnf 的 CentOS、Rocky Linux、AlmaLinux 等。支持 x86_64、ARM64、s390x；不支持 FreeBSD、Windows、Alpine/OpenRC 或普通 Docker 容器。老系统若软件源已失效，需先解决软件源问题。

## 一键安装

文件上传到上述仓库的 `main` 分支后，使用服务器 **root 用户**执行下面的一条命令即可。仓库地址已填好；若分支不是 `main`，需要修改命令中的分支名。

```bash
curl -fL https://raw.githubusercontent.com/Onebanplanet-sketch/XrayR-install/main/install.sh -o XrayR-install.sh && bash XrayR-install.sh
```

如果服务器仅有 wget，可使用：

```bash
wget -O XrayR-install.sh https://raw.githubusercontent.com/Onebanplanet-sketch/XrayR-install/main/install.sh && bash XrayR-install.sh
```

安装器需要先下载为文件再运行，不支持 `curl | bash` 或 `bash <(curl ...)`。这样它能够保存自身，之后菜单中的重装与恢复功能无需依赖仓库地址。

## 安装结果

- 自动下载匹配架构的官方 v0.9.4 程序包，并核对固定 SHA256。
- 安装程序、管理菜单、官方服务文件并设置开机自启。
- 保留已有配置及自定义数据文件，重装不会切换到其他版本。
- 输入 `XrayR` 或 `xrayr` 打开菜单；安装结束不会要求再选择菜单项。
- 不安装 BBR、第三方加速工具或独立证书脚本。

**安装程序和菜单不需要面板信息；运行节点需要真实的面板配置。** 未提供配置时，保留官方示例文件，服务暂不启动；不能把示例地址和密钥当成可用节点。已有非默认配置时自动尝试启动，并报告服务状态。

首次对接节点：编辑 `/etc/XrayR/config.yml`，填写面板地址、密钥、节点 ID、协议及需要的证书配置，然后执行 `XrayR start`。不要把真实面板密钥或证书私钥上传到公开仓库。

## 常用命令

| 命令 | 功能 |
| --- | --- |
| `XrayR` / `xrayr` | 打开中文菜单 |
| `XrayR config` | 编辑配置 |
| `XrayR start` / `stop` / `restart` | 启动 / 停止 / 重启 |
| `XrayR status` / `log` | 查看状态 / 日志 |
| `XrayR enable` / `disable` | 设置 / 取消开机自启 |
| `XrayR version` | 查看程序版本 |
| `XrayR update` | 重装 v0.9.4，保留配置 |
| `XrayR update_shell` | 从本地安装器恢复固定版菜单 |
| `XrayR uninstall` | 确认后卸载程序并删除配置 |

菜单沿用官方编号：0–10 为原有主要功能，11 改为退出，12 查看版本，13 恢复维护脚本。此仓库为基于官方脚本的固定版本改编，并非官方未修改原版。

程序目录：`/usr/local/XrayR`；配置目录：`/etc/XrayR`。卸载后保留菜单和 `/usr/local/share/XrayR/install.sh`，方便从菜单重新安装。恢复菜单不会从网络更新；以后若修改 GitHub 上的安装器，重新执行完整安装命令即可应用。

来源、版本与改动见 [UPSTREAM.md](UPSTREAM.md)，许可证为 [MPL-2.0](LICENSE)。
