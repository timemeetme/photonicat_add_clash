#!/bin/bash
cd /root/photonicat_openwrt || exit 1
GW=$(ip route | awk '/default/ {print $3; exit}')
export http_proxy="http://$GW:7891" https_proxy="http://$GW:7891"
{
make package/boot/uboot-rockchip/clean
make package/boot/uboot-rockchip/compile V=s
echo "EXIT_CODE=$?"
} > /root/uboot_vs.log 2>&1
echo done
