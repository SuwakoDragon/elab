#!/bin/sh

SNAPSHOT_DIR="/etc/experiment_snapshot"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[error] 缺少命令: $1"
        exit 1
    fi
}

require_cmd cp

if [ ! -d "$SNAPSHOT_DIR" ] || [ ! -f "$SNAPSHOT_DIR/.ready" ]; then
    echo "[reset] 未找到可用快照，无法回滚。"
    exit 1
fi

if [ -f "$SNAPSHOT_DIR/network.bak" ]; then
    cp "$SNAPSHOT_DIR/network.bak" /etc/config/network
fi

if [ -f "$SNAPSHOT_DIR/dhcp.bak" ]; then
    cp "$SNAPSHOT_DIR/dhcp.bak" /etc/config/dhcp
fi

if [ -f "$SNAPSHOT_DIR/firewall.bak" ]; then
    cp "$SNAPSHOT_DIR/firewall.bak" /etc/config/firewall
fi

/etc/init.d/network restart
/etc/init.d/dnsmasq restart
/etc/init.d/firewall restart

rm -rf "$SNAPSHOT_DIR"

echo "[reset] 已回滚到预设快照，并清理快照目录。"
