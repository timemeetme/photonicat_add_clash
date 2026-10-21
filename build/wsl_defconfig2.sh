#!/bin/bash
cd /root/photonicat_openwrt
make defconfig 2>&1 | tail -1
echo "=== proxy frontends ==="
grep -E "CONFIG_PACKAGE_(luci-app-openclash|luci-app-passwall|luci-app-passwall2|luci-app-homeproxy|nikki|nikki-luci)" .config | grep -v "=n" | head -20
echo "=== cores ==="
grep -E "CONFIG_PACKAGE_(xray-core|sing-box|mihomo)" .config | grep -v "=n" | head -10
echo "=== target ==="
grep -E "^CONFIG_TARGET_(BOARD|SUBTARGET|PROFILE)|^CONFIG_TARGET_.*=y" .config | head -5
