#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# XrayR v0.9.4 installer; embeds the official Chinese menu with documented changes.
# Upstream: XrayR-project/XrayR-release@3611f177d77dc86410bdea4bec436889b4d18420
set -Eeuo pipefail
umask 022

readonly XRAYR_VERSION='v0.9.4'
readonly INSTALL_DIR='/usr/local/XrayR'
readonly CONFIG_DIR='/etc/XrayR'
readonly CACHE_DIR='/usr/local/share/XrayR'
work_dir=''
replacing=0
had_install=0
had_service=0
was_running=0
was_enabled=0

die() { printf '错误：%s\n' "$*" >&2; exit 1; }

render_menu() {
    cat <<'XRAYR_OFFICIAL_MENU_EOF'
#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Official menu adapted for the fixed v0.9.4 distribution.
# SPDX-License-Identifier: MPL-2.0

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

# The installer already verifies the Linux distribution and architecture.
[[ $(uname -s) == Linux && -d /run/systemd/system ]] || {
    echo '此管理菜单仅支持使用 systemd 的 Linux。' >&2
    exit 1
}

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "是否重启XrayR" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo
    read -r -p '按回车返回主菜单: ' temp || return 0
    show_menu
}

install() {
    bash /usr/local/share/XrayR/install.sh v0.9.4 || return $?
    if [[ $# == 0 ]]; then before_show_menu; fi
}

update() {
    if [[ -n "${2:-}" && "${2#v}" != 0.9.4 ]]; then
        echo '此脚本固定为 v0.9.4，不能更新到其他版本。' >&2
        return 1
    fi
    echo '正在重装官方 v0.9.4，保留已有配置。'
    bash /usr/local/share/XrayR/install.sh v0.9.4 || return $?
    if [[ $# == 0 ]]; then before_show_menu; fi
}

config() {
    echo "运行中的 XrayR 会尝试重载配置；首次配置后请执行 XrayR start"
    vi /etc/XrayR/config.yml || return $?
    sleep 2
    check_status
    case $? in
        0)
            echo -e "XrayR状态: ${green}已运行${plain}"
            ;;
        1)
            echo -e "检测到您未启动XrayR或XrayR自动重启失败，是否查看日志？[Y/n]" && echo
            read -e -p "(默认: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "XrayR状态: ${red}未安装${plain}"
    esac
}

uninstall() {
    confirm "确定要卸载 XrayR 吗?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop XrayR || return $?
    systemctl disable XrayR || return $?
    rm /etc/systemd/system/XrayR.service -f || return $?
    systemctl daemon-reload || return $?
    systemctl reset-failed XrayR.service 2>/dev/null || true
    rm /etc/XrayR/ -rf || return $?
    rm /usr/local/XrayR/ -rf || return $?

    echo ""
    echo -e "卸载成功，如果你想删除此脚本，则退出脚本后运行 ${green}rm /usr/bin/XrayR -f${plain} 进行删除"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}XrayR已运行，无需再次启动，如需重启请选择重启${plain}"
    else
        systemctl start XrayR || return $?
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}XrayR 启动成功，请使用 XrayR log 查看运行日志${plain}"
        else
            echo -e "${red}XrayR可能启动失败，请稍后使用 XrayR log 查看日志信息${plain}"
            return 1
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    systemctl stop XrayR || return $?
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}XrayR 停止成功${plain}"
    else
        echo -e "${red}XrayR停止失败，可能是因为停止时间超过了两秒，请稍后查看日志信息${plain}"
        return 1
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart XrayR || return $?
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}XrayR 重启成功，请使用 XrayR log 查看运行日志${plain}"
    else
        echo -e "${red}XrayR可能启动失败，请稍后使用 XrayR log 查看日志信息${plain}"
            return 1
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status XrayR --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable XrayR
    if [[ $? == 0 ]]; then
        echo -e "${green}XrayR 设置开机自启成功${plain}"
    else
        echo -e "${red}XrayR 设置开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable XrayR
    if [[ $? == 0 ]]; then
        echo -e "${green}XrayR 取消开机自启成功${plain}"
    else
        echo -e "${red}XrayR 取消开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u XrayR.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

update_shell() {
    bash /usr/local/share/XrayR/install.sh --restore-menu || return $?
    exit 0
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/XrayR.service ]]; then
        return 2
    fi
    if systemctl is-active --quiet XrayR.service; then return 0; else return 1; fi
}

check_enabled() {
    systemctl is-enabled --quiet XrayR.service
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}XrayR已安装，请不要重复安装${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}请先安装XrayR${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "XrayR状态: ${green}已运行${plain}"
            show_enable_status
            ;;
        1)
            echo -e "XrayR状态: ${yellow}未运行${plain}"
            show_enable_status
            ;;
        2)
            echo -e "XrayR状态: ${red}未安装${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "是否开机自启: ${green}是${plain}"
    else
        echo -e "是否开机自启: ${red}否${plain}"
    fi
}

show_XrayR_version() {
    echo -n "XrayR 版本："
    /usr/local/XrayR/XrayR version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
    echo "XrayR 管理脚本使用方法: "
    echo "------------------------------------------"
    echo "XrayR              - 显示管理菜单 (功能更多)"
    echo "XrayR start        - 启动 XrayR"
    echo "XrayR stop         - 停止 XrayR"
    echo "XrayR restart      - 重启 XrayR"
    echo "XrayR status       - 查看 XrayR 状态"
    echo "XrayR enable       - 设置 XrayR 开机自启"
    echo "XrayR disable      - 取消 XrayR 开机自启"
    echo "XrayR log          - 查看 XrayR 日志"
    echo "XrayR update       - 重装固定的 v0.9.4（保留配置）"
    echo "XrayR config       - 编辑 XrayR 配置"
    echo "XrayR install      - 安装 XrayR"
    echo "XrayR uninstall    - 卸载 XrayR"
    echo "XrayR version      - 查看 XrayR 版本"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}XrayR v0.9.4 后端管理脚本，${plain}${red}不适用于docker${plain}
--- https://github.com/XrayR-project/XrayR ---
  ${green}0.${plain} 修改配置
————————————————
  ${green}1.${plain} 安装 XrayR
  ${green}2.${plain} 重装 XrayR v0.9.4（保留配置）
  ${green}3.${plain} 卸载 XrayR
————————————————
  ${green}4.${plain} 启动 XrayR
  ${green}5.${plain} 停止 XrayR
  ${green}6.${plain} 重启 XrayR
  ${green}7.${plain} 查看 XrayR 状态
  ${green}8.${plain} 查看 XrayR 日志
————————————————
  ${green}9.${plain} 设置 XrayR 开机自启
 ${green}10.${plain} 取消 XrayR 开机自启
————————————————
 ${green}11.${plain} 退出脚本
 ${green}12.${plain} 查看 XrayR 版本 
 ${green}13.${plain} 恢复维护脚本（固定版）
 "
 #后续更新可加入上方字符串中
    show_status
    echo
    read -r -p "请输入选择 [0-13]: " num || return 0

    case "${num}" in
        0) config
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && start
        ;;
        5) check_install && stop
        ;;
        6) check_install && restart
        ;;
        7) check_install && status
        ;;
        8) check_install && show_log
        ;;
        9) check_install && enable
        ;;
        10) check_install && disable
        ;;
        11) exit 0
        ;;
        12) check_install && show_XrayR_version
        ;;
        13) update_shell
        ;;
        *) echo -e "${red}请输入正确的数字 [0-13]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 "${2:-}"
        ;;
        "config") config "$@"
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_XrayR_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi
XRAYR_OFFICIAL_MENU_EOF
}

render_service() {
    cat <<'XRAYR_OFFICIAL_SERVICE_EOF'
[Unit]
Description=XrayR Service
After=network.target nss-lookup.target
Wants=network.target

[Service]
User=root
Group=root
Type=simple
LimitAS=infinity
LimitRSS=infinity
LimitCORE=infinity
LimitNOFILE=999999
WorkingDirectory=/usr/local/XrayR/
ExecStart=/usr/local/XrayR/XrayR --config /etc/XrayR/config.yml
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
XRAYR_OFFICIAL_SERVICE_EOF
}

cleanup() {
    local result=$?
    local rollback_ok=1
    trap - EXIT ERR
    set +e
    if (( result != 0 && replacing == 1 )); then
        printf '安装未完成，正在恢复原程序及服务文件。\n' >&2
        systemctl stop XrayR.service >/dev/null 2>&1 || true
        if (( had_install == 1 )); then
            rm -rf -- "$INSTALL_DIR" || rollback_ok=0
            mv -T -- "$work_dir/old-install" "$INSTALL_DIR" || rollback_ok=0
        else
            rm -rf -- "$INSTALL_DIR" || rollback_ok=0
        fi
        if (( had_service == 1 )); then
            cp -p -- "$work_dir/old-service" /etc/systemd/system/XrayR.service || rollback_ok=0
        else
            systemctl disable XrayR.service >/dev/null 2>&1 || true
            rm -f -- /etc/systemd/system/XrayR.service || rollback_ok=0
        fi
        systemctl daemon-reload || rollback_ok=0
        if (( had_service == 1 )); then
            if (( was_enabled == 1 )); then
                systemctl enable XrayR.service || rollback_ok=0
            else
                systemctl disable XrayR.service || rollback_ok=0
            fi
        fi
        if (( was_running == 1 )); then
            systemctl start XrayR.service || rollback_ok=0
        fi
    fi
    if (( rollback_ok == 0 )); then
        printf '恢复未全部成功；已保留备份目录：%s\n' "$work_dir" >&2
    elif [[ -n "$work_dir" && -d "$work_dir" ]]; then
        rm -rf -- "$work_dir"
    fi
    exit "$result"
}

install_menu() {
    install -m 0755 "$work_dir/XrayR.sh" /usr/bin/.XrayR.new
    mv -f -- /usr/bin/.XrayR.new /usr/bin/XrayR
    ln -sfn /usr/bin/XrayR /usr/bin/xrayr
}

install_dependencies() {
    local editor=''
    if ! command -v vi >/dev/null 2>&1; then editor=1; fi
    if command -v curl >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1 &&
       command -v flock >/dev/null 2>&1 && [[ -z "$editor" ]] &&
       { [[ -s /etc/ssl/certs/ca-certificates.crt ]] || [[ -s /etc/pki/tls/certs/ca-bundle.crt ]]; }; then
        return
    fi
    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends ca-certificates curl unzip util-linux ${editor:+vim-tiny}
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y ca-certificates curl unzip util-linux ${editor:+vim-minimal}
    elif command -v yum >/dev/null 2>&1; then
        yum install -y ca-certificates curl unzip util-linux ${editor:+vim-minimal}
    else
        die '需要 apt-get、dnf 或 yum 来安装必要依赖。'
    fi
}

main() {
    local mode=install arch expected archive_url installer_source binary_version file
    local existing_config=0
    case "${1:-}" in
        ''|0.9.4|v0.9.4) ;;
        --restore-menu) mode=restore ;;
        -h|--help)
            printf '%s\n' '用法：bash install.sh [v0.9.4 | --restore-menu]' \
                '仅安装官方 v0.9.4；无交互；保留已有配置。' \
                '请先将 install.sh 下载成文件，再运行。'
            return ;;
        *) die '此安装器仅支持 v0.9.4，不能安装其他版本。' ;;
    esac
    (( $# <= 1 )) || die '参数过多。'
    [[ $(uname -s) == Linux ]] || die '仅支持使用 systemd 的 Linux，不支持 FreeBSD、Windows 或 macOS。'
    [[ $EUID -eq 0 ]] || die '请使用 root 用户运行；也可使用 sudo bash install.sh。'
    [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null 2>&1 ||
        die '需要运行中的 systemd；不支持普通 Docker 容器、Alpine/OpenRC。'
    [[ -f "${BASH_SOURCE[0]}" ]] || die '请先下载 install.sh 到本地，再用 bash 执行；不支持管道或进程替换。'
    installer_source=$(readlink -f -- "${BASH_SOURCE[0]}")
    [[ ! -L "$INSTALL_DIR" && ! -L "$CACHE_DIR" ]] || die '安装目录不可为符号链接。'
    if [[ -e /usr/bin/xrayr || -L /usr/bin/xrayr ]]; then
        [[ -L /usr/bin/xrayr && $(readlink /usr/bin/xrayr) == /usr/bin/XrayR ]] ||
            die '/usr/bin/xrayr 已被其他文件占用，请先检查。'
    fi
    case "$(uname -m)" in
        x86_64|amd64)
            arch=64
            expected=ad06efe7ca3c19ea20817fb2aa163185f012433d97f8d4cc30eff30ca02bc5b4 ;;
        aarch64|arm64)
            arch=arm64-v8a
            expected=2c2fa9dbc282f30caecaa026319927f6f0a4492f576239fa59c490abd2076558 ;;
        s390x)
            arch=s390x
            expected=16e06ff2451962169355ef6a97d1dd05a058b500e858063db2a4107b922a679c ;;
        *) die "不支持的处理器架构：$(uname -m)。支持 x86_64、ARM64、s390x。" ;;
    esac
    [[ $(getconf LONG_BIT) == 64 ]] || die '需要 64 位 Linux 用户空间。'
    if [[ $mode == install ]]; then
        install_dependencies
    fi
    command -v flock >/dev/null 2>&1 || die '缺少 flock，请重新运行完整安装命令。'
    # The lock remains open for the entire installation and releases automatically.
    exec 9>/run/lock/XrayR-install.lock
    flock -n 9 || die '另一个 XrayR 安装进程正在运行，请稍后重试。'
    work_dir=$(mktemp -d /usr/local/.XrayR-install.XXXXXXXX)
    trap cleanup EXIT
    trap 'printf "安装失败（第 %s 行），请查看上面的错误。\n" "$LINENO" >&2' ERR
    trap 'exit 130' INT
    trap 'exit 143' TERM
    cp -- "$installer_source" "$work_dir/install.sh"
    bash -n "$work_dir/install.sh"
    render_menu > "$work_dir/XrayR.sh"
    bash -n "$work_dir/XrayR.sh"
    render_service > "$work_dir/XrayR.service"
    if [[ $mode == restore ]]; then
        install_menu
        printf '固定版管理菜单已恢复，请运行 XrayR。\n'
        return
    fi

    archive_url="https://github.com/XrayR-project/XrayR/releases/download/${XRAYR_VERSION}/XrayR-linux-${arch}.zip"
    printf '下载官方 XrayR %s（%s）……\n' "$XRAYR_VERSION" "$arch"
    curl --fail --location --show-error --retry 3 --connect-timeout 20 --max-time 900 \
        --proto '=https' --proto-redir '=https' "$archive_url" -o "$work_dir/XrayR.zip"
    printf '%s  %s\n' "$expected" "$work_dir/XrayR.zip" | sha256sum --check --status ||
        die '官方安装包 SHA256 校验失败，未替换已有程序。'
    mkdir "$work_dir/new-install"
    unzip -q "$work_dir/XrayR.zip" -d "$work_dir/new-install"
    for file in XrayR config.yml geoip.dat geosite.dat dns.json route.json custom_inbound.json custom_outbound.json rulelist LICENSE; do
        [[ -f "$work_dir/new-install/$file" ]] || die "安装包缺少 $file。"
    done
    chmod 0755 "$work_dir/new-install/XrayR"
    binary_version=$("$work_dir/new-install/XrayR" version)
    [[ "$binary_version" =~ (^|[^0-9])0\.9\.4([^0-9.]|$) ]] || die "程序版本异常：$binary_version"
    printf '校验通过：%s\n' "$binary_version"

    # All downloads and validation finish before touching the existing service.
    if [[ -f "$CONFIG_DIR/config.yml" ]] && ! cmp -s "$CONFIG_DIR/config.yml" "$work_dir/new-install/config.yml"; then
        existing_config=1
    fi
    if [[ -d "$INSTALL_DIR" ]]; then
        cp -a -- "$INSTALL_DIR" "$work_dir/old-install"
        had_install=1
    fi
    if [[ -f /etc/systemd/system/XrayR.service ]]; then
        cp -p -- /etc/systemd/system/XrayR.service "$work_dir/old-service"
        had_service=1
    fi
    if systemctl is-active --quiet XrayR.service; then was_running=1; fi
    if systemctl is-enabled --quiet XrayR.service; then was_enabled=1; fi
    replacing=1
    if (( had_service == 1 || was_running == 1 )); then systemctl stop XrayR.service; fi
    rm -rf -- "$INSTALL_DIR"
    mv -T -- "$work_dir/new-install" "$INSTALL_DIR"
    install -d -m 0755 "$CONFIG_DIR" "$CACHE_DIR"
    for file in config.yml dns.json route.json custom_inbound.json custom_outbound.json rulelist geoip.dat geosite.dat; do
        if [[ ! -e "$CONFIG_DIR/$file" ]]; then
            if [[ $file == config.yml ]]; then
                install -m 0600 "$INSTALL_DIR/$file" "$CONFIG_DIR/$file"
            else
                install -m 0644 "$INSTALL_DIR/$file" "$CONFIG_DIR/$file"
            fi
        fi
    done
    install -m 0644 "$work_dir/XrayR.service" /etc/systemd/system/XrayR.service
    install -m 0755 "$work_dir/install.sh" "$CACHE_DIR/.install.sh.new"
    mv -f -- "$CACHE_DIR/.install.sh.new" "$CACHE_DIR/install.sh"
    install_menu
    systemctl daemon-reload
    systemctl enable XrayR.service
    replacing=0
    printf '\nXrayR v0.9.4 与管理菜单安装完成，已设置开机自启。\n'
    if (( existing_config == 1 )); then
        if systemctl restart XrayR.service; then
            sleep 2
            if systemctl is-active --quiet XrayR.service; then
                printf '服务已启动；节点是否成功连接面板请查看 XrayR log。\n'
            else
                printf '程序安装完成，但服务未能保持运行。请用 XrayR log 查看原因。\n' >&2
                return 1
            fi
        else
            printf '程序安装完成，但服务启动失败。请用 XrayR log 查看原因。\n' >&2
            return 1
        fi
    else
        printf '当前保留官方示例配置，服务暂未启动。\n'
        printf '若要运行节点，请填入 /etc/XrayR/config.yml 的真实面板配置，再执行 XrayR start。\n'
    fi
    printf '输入 XrayR 或 xrayr 打开官方风格中文管理菜单。\n'
}

main "$@"
