#!/bin/bash
# 添加 passwall-packages feed 并刷新配置
source /root/build_env.sh 2>/dev/null
cd /root/photonicat_openwrt || exit 1

echo "=== 1. add feed ==="
grep -q passwall_packages feeds.conf || echo 'src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages;main' >> feeds.conf
cat feeds.conf

echo "=== 2. update feed ==="
./scripts/feeds update passwall_packages || exit 2

echo "=== 3. install all ==="
./scripts/feeds install -a || exit 3

echo "=== 4. defconfig ==="
make defconfig || exit 4

echo "=== 5. verify proxy packages ==="
grep -E 'CONFIG_PACKAGE_(hysteria|naiveproxy|ipt2socks|shadowsocks-rust-sslocal|tuic-client|xray-plugin|v2ray-plugin|sing-box|xray-core|luci-app-passwall|luci-app-openclash|nikki|luci-app-homeproxy)=' .config
