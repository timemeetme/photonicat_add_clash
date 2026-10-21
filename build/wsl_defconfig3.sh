#!/bin/bash
set -e
cd /root/photonicat_openwrt
cp /mnt/d/Projects/photonicat/firmware/photonicat_base_defconfig .config
make defconfig 2>&1 | tail -1
echo "=== proxy frontends ==="
grep -E "CONFIG_PACKAGE_(luci-app-openclash|luci-app-passwall|luci-app-passwall2|luci-app-homeproxy|nikki|nikki-luci)=" .config | head -10
echo "=== cores ==="
grep -E "CONFIG_PACKAGE_(xray-core|sing-box|mihomo)=" .config | head -5
