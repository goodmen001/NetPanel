#!/bin/bash
# NetPanel Linux 服务管理脚本（支持 systemd / OpenWrt procd）
# 需要 root 权限
#
# 用法:
#   sudo ./service-linux.sh install            - 安装并启用服务
#   sudo ./service-linux.sh uninstall          - 停止并卸载服务（保留数据）
#   sudo ./service-linux.sh uninstall --purge  - 完整卸载（含安装目录和数据目录）
#   sudo ./service-linux.sh start              - 启动服务
#   sudo ./service-linux.sh stop               - 停止服务
#   sudo ./service-linux.sh restart            - 重启服务
#   sudo ./service-linux.sh status             - 查看服务状态（含 PID/端口/版本）
#   sudo ./service-linux.sh logs               - 实时跟踪日志
#   sudo ./service-linux.sh update             - 热更新（下载最新版本并重启）

set -euo pipefail

SERVICE_NAME="netpanel"
INSTALL_DIR="/opt/netpanel"
BINARY_NAME="netpanel"
BINARY_PATH="${INSTALL_DIR}/${BINARY_NAME}"
DATA_DIR="${INSTALL_DIR}/data"
PORT=8080
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
OPENWRT_INIT="/etc/init.d/${SERVICE_NAME}"
REPO="${NETPANEL_REPO:-YOUR_ORG/netpanel}"

# ── 颜色输出 ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header()  { echo -e "${BLUE}──── $* ────${NC}"; }

# ── 检查 root 权限 ──────────────────────────────────────────
assert_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "请以 root 权限运行此脚本（sudo ./service-linux.sh $1）"
        exit 1
    fi
}

# ── 检测运行环境 ────────────────────────────────────────────
is_openwrt() {
    [ -f /etc/openwrt_release ]
}

is_systemd() {
    command -v systemctl &>/dev/null && systemctl is-system-running &>/dev/null
}

# ── 安装服务 ────────────────────────────────────────────────
do_install() {
    assert_root install

    if [ ! -f "${BINARY_PATH}" ]; then
        error "未找到可执行文件: ${BINARY_PATH}"
        echo "请先将 netpanel 二进制文件复制到 ${INSTALL_DIR}/"
        echo "或使用一键安装脚本: curl -fsSL https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh | bash"
        exit 1
    fi

    chmod +x "${BINARY_PATH}"
    mkdir -p "${DATA_DIR}"

    if is_openwrt; then
        _install_openwrt
    elif is_systemd; then
        _install_systemd
    else
        error "未检测到 systemd 或 OpenWrt，请手动配置服务。"
        exit 1
    fi
}

_install_systemd() {
    info "写入 systemd 服务文件: ${SERVICE_FILE}"
    cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=NetPanel - Network Management Panel
Documentation=https://github.com/${REPO}
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${BINARY_PATH} --port ${PORT} --data ${DATA_DIR}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=5s
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}
AmbientCapabilities=CAP_NET_BIND_SERVICE CAP_NET_ADMIN CAP_NET_RAW
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_ADMIN CAP_NET_RAW

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}"
    systemctl start  "${SERVICE_NAME}"

    sleep 2
    if systemctl is-active --quiet "${SERVICE_NAME}"; then
        info "✅ 服务安装并启动成功！"
        info "   安装目录: ${INSTALL_DIR}"
        info "   数据目录: ${DATA_DIR}"
        info "   访问地址: http://localhost:${PORT}"
    else
        error "服务启动失败，请查看日志: journalctl -u ${SERVICE_NAME} -n 50"
        exit 1
    fi
}

_install_openwrt() {
    info "写入 OpenWrt procd init.d 脚本: ${OPENWRT_INIT}"
    cat > "${OPENWRT_INIT}" <<EOF
#!/bin/sh /etc/rc.common
# NetPanel init.d 服务脚本
USE_PROCD=1
START=99
STOP=10

BINARY="${BINARY_PATH}"
DATA_DIR="${DATA_DIR}"
PORT="${PORT}"

start_service() {
  procd_open_instance
  procd_set_param command "\${BINARY}" --port "\${PORT}" --data "\${DATA_DIR}"
  procd_set_param respawn \${respawn_threshold:-3600} \${respawn_timeout:-5} \${respawn_retry:-5}
  procd_set_param stdout 1
  procd_set_param stderr 1
  procd_set_param pidfile /var/run/${SERVICE_NAME}.pid
  procd_close_instance
}

stop_service() {
  procd_kill ${SERVICE_NAME}
}

reload_service() {
  stop_service
  start_service
}
EOF
    chmod +x "${OPENWRT_INIT}"
    "${OPENWRT_INIT}" enable
    "${OPENWRT_INIT}" start
    info "✅ OpenWrt 服务安装并启动成功！"
    info "   访问地址: http://localhost:${PORT}"
}

# ── 卸载服务 ────────────────────────────────────────────────
do_uninstall() {
    assert_root uninstall
    local purge=false
    if [ "${2:-}" = "--purge" ]; then
        purge=true
    fi

    if is_openwrt; then
        if [ -f "${OPENWRT_INIT}" ]; then
            "${OPENWRT_INIT}" stop 2>/dev/null || true
            "${OPENWRT_INIT}" disable 2>/dev/null || true
            rm -f "${OPENWRT_INIT}"
            info "✅ OpenWrt 服务已卸载。"
        fi
    elif is_systemd; then
        if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
            info "正在停止服务..."
            systemctl stop "${SERVICE_NAME}"
        fi
        if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
            systemctl disable "${SERVICE_NAME}"
        fi
        if [ -f "${SERVICE_FILE}" ]; then
            rm -f "${SERVICE_FILE}"
            systemctl daemon-reload
        fi
        info "✅ systemd 服务已卸载。"
    fi

    # 删除软链接
    rm -f /usr/local/bin/netpanel 2>/dev/null || true

    if [ "$purge" = true ]; then
        warn "正在执行完整卸载（--purge），将删除安装目录和数据目录..."
        rm -rf "${INSTALL_DIR}"
        rm -rf "${DATA_DIR}"
        rm -rf /var/log/netpanel
        info "✅ 完整卸载完成，所有文件已删除。"
    else
        warn "安装目录 '${INSTALL_DIR}' 和数据目录 '${DATA_DIR}' 未被删除。"
        warn "如需完整清理，请执行: sudo $0 uninstall --purge"
    fi
}

# ── 启动服务 ────────────────────────────────────────────────
do_start() {
    assert_root start
    if is_openwrt; then
        "${OPENWRT_INIT}" start
    else
        systemctl start "${SERVICE_NAME}"
        sleep 1
        if systemctl is-active --quiet "${SERVICE_NAME}"; then
            info "✅ 服务已启动，访问 http://localhost:${PORT}"
        else
            error "启动失败，请查看日志: journalctl -u ${SERVICE_NAME} -n 50"
            exit 1
        fi
    fi
}

# ── 停止服务 ────────────────────────────────────────────────
do_stop() {
    assert_root stop
    if is_openwrt; then
        "${OPENWRT_INIT}" stop
    else
        systemctl stop "${SERVICE_NAME}"
        info "✅ 服务已停止。"
    fi
}

# ── 重启服务 ────────────────────────────────────────────────
do_restart() {
    assert_root restart
    if is_openwrt; then
        "${OPENWRT_INIT}" restart
    else
        systemctl restart "${SERVICE_NAME}"
        sleep 1
        if systemctl is-active --quiet "${SERVICE_NAME}"; then
            info "✅ 服务已重启，访问 http://localhost:${PORT}"
        else
            error "重启失败，请查看日志: journalctl -u ${SERVICE_NAME} -n 50"
            exit 1
        fi
    fi
}

# ── 查看状态（含 PID / 端口 / 版本）──────────────────────────
do_status() {
    header "NetPanel 服务状态"

    # 服务运行状态
    if is_openwrt; then
        if [ -f "${OPENWRT_INIT}" ]; then
            "${OPENWRT_INIT}" status 2>/dev/null || echo "服务未运行"
        else
            echo "服务未安装"
        fi
    else
        systemctl status "${SERVICE_NAME}" --no-pager -l 2>/dev/null || echo "服务未安装或未运行"
    fi

    echo ""
    header "详细信息"

    # 版本信息
    if [ -f "${BINARY_PATH}" ]; then
        local version
        version=$("${BINARY_PATH}" --version 2>/dev/null || echo "未知")
        echo "  版本:     ${version}"
        echo "  二进制:   ${BINARY_PATH}"
        echo "  大小:     $(du -sh "${BINARY_PATH}" 2>/dev/null | cut -f1 || echo '未知')"
    else
        echo "  二进制:   未找到 (${BINARY_PATH})"
    fi

    # PID 信息
    local pid
    pid=$(pgrep -f "${BINARY_NAME}" 2>/dev/null | head -1 || echo "")
    if [ -n "$pid" ]; then
        echo "  PID:      ${pid}"
        echo "  运行时间: $(ps -p "$pid" -o etime= 2>/dev/null | tr -d ' ' || echo '未知')"
    else
        echo "  PID:      未运行"
    fi

    # 端口占用
    echo ""
    header "端口占用"
    if command -v ss &>/dev/null; then
        ss -tlnp 2>/dev/null | grep "${BINARY_NAME}" || echo "  未检测到端口占用"
    elif command -v netstat &>/dev/null; then
        netstat -tlnp 2>/dev/null | grep "${BINARY_NAME}" || echo "  未检测到端口占用"
    else
        echo "  无法检测（缺少 ss/netstat）"
    fi

    # 数据目录
    echo ""
    header "目录信息"
    echo "  安装目录: ${INSTALL_DIR}"
    echo "  数据目录: ${DATA_DIR}"
    if [ -d "${DATA_DIR}" ]; then
        echo "  数据大小: $(du -sh "${DATA_DIR}" 2>/dev/null | cut -f1 || echo '未知')"
    fi
}

# ── 实时日志 ────────────────────────────────────────────────
do_logs() {
    if is_openwrt; then
        if command -v logread &>/dev/null; then
            logread -f -e "${SERVICE_NAME}"
        else
            tail -f /var/log/netpanel/netpanel.log 2>/dev/null || error "未找到日志文件"
        fi
    else
        journalctl -u "${SERVICE_NAME}" -f --no-pager
    fi
}

# ── 热更新 ──────────────────────────────────────────────────
do_update() {
    assert_root update

    info "开始热更新 NetPanel..."

    # 获取最新版本
    local latest_version
    latest_version=$(curl -fsSL --retry 3 \
        "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' | head -1 \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

    if [ -z "$latest_version" ]; then
        error "无法获取最新版本，请检查网络连接或手动指定版本"
        exit 1
    fi

    info "最新版本: ${latest_version}"

    # 检测当前版本
    local current_version
    current_version=$("${BINARY_PATH}" --version 2>/dev/null || echo "未知")
    info "当前版本: ${current_version}"

    # 检测架构
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)   arch="amd64" ;;
        aarch64|arm64)  arch="arm64" ;;
        armv7l|armv7)   arch="armv7" ;;
        mipsle|mipsel)  arch="mipsle" ;;
        mips)           arch="mips" ;;
        *)              error "不支持的架构: $arch"; exit 1 ;;
    esac

    # 下载新版本到临时文件
    local tmp_file
    tmp_file=$(mktemp)
    local download_url="https://github.com/${REPO}/releases/download/${latest_version}/netpanel-linux-${arch}"

    info "下载新版本..."
    if ! curl -fsSL --retry 3 --progress-bar "$download_url" -o "$tmp_file"; then
        rm -f "$tmp_file"
        error "下载失败: $download_url"
        exit 1
    fi
    chmod +x "$tmp_file"

    # 停止服务
    info "停止服务..."
    do_stop 2>/dev/null || true
    sleep 2

    # 备份旧版本
    if [ -f "${BINARY_PATH}" ]; then
        cp "${BINARY_PATH}" "${BINARY_PATH}.bak"
        warn "已备份旧版本到 ${BINARY_PATH}.bak"
    fi

    # 替换二进制
    mv "$tmp_file" "${BINARY_PATH}"
    chmod +x "${BINARY_PATH}"
    info "二进制文件已更新"

    # 重新启动服务
    info "启动服务..."
    do_start

    info "✅ 热更新完成！当前版本: ${latest_version}"
}

# ── 入口 ────────────────────────────────────────────────────
ACTION="${1:-}"
case "${ACTION}" in
    install)   do_install   ;;
    uninstall) do_uninstall "$@" ;;
    start)     do_start     ;;
    stop)      do_stop      ;;
    restart)   do_restart   ;;
    status)    do_status    ;;
    logs)      do_logs      ;;
    update)    do_update    ;;
    *)
        echo "NetPanel 服务管理脚本"
        echo ""
        echo "用法: sudo $0 <命令> [选项]"
        echo ""
        echo "命令:"
        echo "  install            安装并启用服务"
        echo "  uninstall          卸载服务（保留数据目录）"
        echo "  uninstall --purge  完整卸载（删除安装目录和数据目录）"
        echo "  start              启动服务"
        echo "  stop               停止服务"
        echo "  restart            重启服务"
        echo "  status             查看服务状态（含 PID/端口/版本）"
        echo "  logs               实时跟踪日志"
        echo "  update             热更新到最新版本"
        exit 1
        ;;
esac
