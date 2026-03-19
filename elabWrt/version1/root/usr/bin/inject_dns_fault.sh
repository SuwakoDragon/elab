#!/bin/sh

# 备份当前网络配置
# 在真实环境中，最好做一个更可靠的备份
if [ ! -f /etc/config/network.bak ]; then
    cp /etc/config/network /etc/config/network.bak
fi

# 使用 uci 命令修改 wan 接口的 DNS 服务器地址
# 我们将其设置为一个无效的、不存在的 IP 地址 (192.0.2.1 是一个文档和示例中专用的地址)
uci set network.wan.dns='192.0.2.1' 
uci commit network

# 重启网络服务使配置生效
/etc/init.d/network restart

echo "DNS 故障已注入。WAN 口的 DNS 服务器被设置为 192.0.2.1。"
echo "你可以尝试 ping baidu.com 来验证故障。"
