#!/bin/sh

set -u

SCENARIO="${1:-dns_fault}"
WAN_IFACE="${2:-wan}"

SNAPSHOT_DIR="/etc/experiment_snapshot"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[error] 缺少命令: $1"
        exit 1
    fi
}

save_snapshot_once() {
    if [ -d "$SNAPSHOT_DIR" ] && [ -f "$SNAPSHOT_DIR/.ready" ]; then
        echo "[snapshot] 已存在，跳过创建。"
        return 0
    fi

    mkdir -p "$SNAPSHOT_DIR"
    cp /etc/config/network "$SNAPSHOT_DIR/network.bak"
    cp /etc/config/dhcp "$SNAPSHOT_DIR/dhcp.bak"
    cp /etc/config/firewall "$SNAPSHOT_DIR/firewall.bak"
    date > "$SNAPSHOT_DIR/.ready"
    echo "[snapshot] 已创建 network/dhcp/firewall 快照。"
}

apply_dns_fault() {
    uci set network."$WAN_IFACE".peerdns='0'
    uci -q delete network."$WAN_IFACE".dns
    uci add_list network."$WAN_IFACE".dns='192.0.2.1'
    uci commit network
    /etc/init.d/network restart
    echo "[inject] DNS 故障已注入：$WAN_IFACE DNS=192.0.2.1"
}

apply_dhcp_fault() {
    uci set dhcp.lan.ignore='1'
    uci commit dhcp
    /etc/init.d/dnsmasq restart
    echo "[inject] DHCP 故障已注入：LAN DHCP 服务已禁用。"
}

apply_ip_fault() {
    uci set network."$WAN_IFACE".proto='static'
    uci set network."$WAN_IFACE".ipaddr='198.51.100.10'
    uci set network."$WAN_IFACE".netmask='255.255.255.0'
    uci set network."$WAN_IFACE".gateway='198.51.100.1'
    uci set network."$WAN_IFACE".peerdns='0'
    uci -q delete network."$WAN_IFACE".dns
    uci add_list network."$WAN_IFACE".dns='114.114.114.114'
    uci commit network
    /etc/init.d/network restart
    echo "[inject] IP 故障已注入：$WAN_IFACE 被改为错误静态地址。"
}

apply_gateway_fault() {
    uci set network."$WAN_IFACE".gateway='192.0.2.254'
    uci commit network
    /etc/init.d/network restart
    echo "[inject] 网关故障已注入：$WAN_IFACE gateway=192.0.2.254"
}

if ! uci -q get network."$WAN_IFACE" >/dev/null; then
    echo "[error] 接口 '$WAN_IFACE' 不存在，请先检查 network 配置。"
    exit 1
fi

require_cmd uci
require_cmd cp
require_cmd date

save_snapshot_once

case "$SCENARIO" in
    dns_fault)
        apply_dns_fault
        ;;
    dhcp_fault)
        apply_dhcp_fault
        ;;
    ip_fault)
        apply_ip_fault
        ;;
    gateway_fault)
        apply_gateway_fault
        ;;
    *)
        echo "[error] 未知实验场景: $SCENARIO"
        exit 1
        ;;
esac

echo "[done] 场景: $SCENARIO, 接口: $WAN_IFACE"