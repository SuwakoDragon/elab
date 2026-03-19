#!/bin/sh

set -u

SCENARIO="${1:-}"
FIELD="${2:-}"
VALUE="${3:-}"
WAN_IFACE="${4:-wan}"

is_ipv4() {
    case "$1" in
        ''|*[!0-9.]*) return 1 ;;
    esac

    OLDIFS="$IFS"
    IFS='.'
    set -- $1
    IFS="$OLDIFS"

    [ "$#" -eq 4 ] || return 1

    for n in "$1" "$2" "$3" "$4"; do
        [ "$n" -ge 0 ] 2>/dev/null || return 1
        [ "$n" -le 255 ] 2>/dev/null || return 1
    done

    return 0
}

fail() {
    echo "$1"
    exit 1
}

[ -n "$SCENARIO" ] || fail "参数错误：缺少场景"
[ -n "$FIELD" ] || fail "参数错误：缺少字段"
[ -n "$WAN_IFACE" ] || fail "参数错误：缺少接口"

uci -q get network."$WAN_IFACE" >/dev/null 2>&1 || fail "接口不存在: $WAN_IFACE"

case "$SCENARIO" in
    dns_fault)
        [ "$FIELD" = "dns" ] || fail "DNS 场景仅支持字段 dns"
        is_ipv4 "$VALUE" || fail "DNS 服务器必须是 IPv4 地址"

        uci set network."$WAN_IFACE".peerdns='0' || fail "设置 peerdns 失败"
        uci -q delete network."$WAN_IFACE".dns || true
        uci add_list network."$WAN_IFACE".dns="$VALUE" || fail "写入 DNS 失败"
        uci commit network || fail "提交 network 配置失败"
        /etc/init.d/network restart || fail "重启 network 失败"
        echo "DNS 修复项已提交"
        ;;

    dhcp_fault)
        [ "$FIELD" = "lan_ignore" ] || fail "DHCP 场景仅支持字段 lan_ignore"
        [ "$VALUE" = "0" ] || [ "$VALUE" = "1" ] || fail "lan_ignore 仅允许 0 或 1"

        uci set dhcp.lan.ignore="$VALUE" || fail "设置 DHCP ignore 失败"
        uci commit dhcp || fail "提交 dhcp 配置失败"
        /etc/init.d/dnsmasq restart || fail "重启 dnsmasq 失败"
        echo "DHCP 修复项已提交"
        ;;

    ip_fault)
        case "$FIELD" in
            proto)
                [ "$VALUE" = "dhcp" ] || [ "$VALUE" = "static" ] || fail "proto 仅允许 dhcp 或 static"
                uci set network."$WAN_IFACE".proto="$VALUE" || fail "设置 proto 失败"
                if [ "$VALUE" = "dhcp" ]; then
                    uci -q delete network."$WAN_IFACE".ipaddr || true
                    uci -q delete network."$WAN_IFACE".netmask || true
                    uci -q delete network."$WAN_IFACE".gateway || true
                fi
                ;;
            ipaddr|netmask|gateway)
                is_ipv4 "$VALUE" || fail "$FIELD 必须是 IPv4 地址"
                uci set network."$WAN_IFACE"."$FIELD"="$VALUE" || fail "写入 $FIELD 失败"
                ;;
            *)
                fail "IP 场景字段不支持: $FIELD"
                ;;
        esac

        uci commit network || fail "提交 network 配置失败"
        /etc/init.d/network restart || fail "重启 network 失败"
        echo "IP 修复项已提交"
        ;;

    gateway_fault)
        [ "$FIELD" = "gateway" ] || fail "网关场景仅支持字段 gateway"
        is_ipv4 "$VALUE" || fail "gateway 必须是 IPv4 地址"

        uci set network."$WAN_IFACE".gateway="$VALUE" || fail "写入 gateway 失败"
        uci commit network || fail "提交 network 配置失败"
        /etc/init.d/network restart || fail "重启 network 失败"
        echo "网关修复项已提交"
        ;;

    *)
        fail "未知场景: $SCENARIO"
        ;;
esac

exit 0
