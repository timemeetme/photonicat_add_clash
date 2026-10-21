#!/bin/bash
set -e
OWRT=/root/photonicat_openwrt
MK=$OWRT/package/boot/uboot-rockchip/Makefile

# backup then fix stale v1.18 filename -> v1.24 (matches Download/rk3588-ddr)
cp -n $MK ${MK}.bak
sed -i 's/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1\.18\.bin/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.24.bin/' $MK
echo '--- after fix ---'
grep -n 'rk3588_ddr_lp4' $MK

echo '--- verify compile (V=s) ---'
cd $OWRT
GW=$(ip route | awk '/default/ {print $3; exit}')
export http_proxy="http://$GW:7891" https_proxy="http://$GW:7891"
make package/boot/uboot-rockchip/clean > /dev/null 2>&1 || true
make package/boot/uboot-rockchip/compile V=s > /root/uboot_fix_verify.log 2>&1
RC=$?
echo "VERIFY_EXIT=$RC"
tail -3 /root/uboot_fix_verify.log
ls $OWRT/staging_dir/target-aarch64_generic_musl/image/ | grep -i photonicat || echo 'no photonicat uboot artifact yet'
