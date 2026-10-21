#!/bin/bash
OWRT=/root/photonicat_openwrt
echo "=== logs dir ==="
ls -la $OWRT/logs/package/boot/uboot-rockchip/ 2>/dev/null || echo "no log dir"
echo "=== compile tail ==="
tail -30 $OWRT/logs/package/boot/uboot-rockchip/compile.txt 2>/dev/null | grep -iE 'error|fail|not found|No such' | head -15
echo "=== last 15 lines ==="
tail -15 $OWRT/logs/package/boot/uboot-rockchip/compile.txt 2>/dev/null
