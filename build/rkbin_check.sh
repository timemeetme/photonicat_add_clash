#!/bin/bash
OWRT=/root/photonicat_openwrt
echo "=== rkbin tarball contents (ddr/bl31 related) ==="
tar --use-compress-program=unzstd -tf $OWRT/dl/rkbin-2026.06.26~3e288fe8.tar.zst 2>/dev/null | grep -iE 'ddr|bl31' | head -20
echo "=== rockchip-rkbin Makefile DDR handling ==="
grep -n 'DDR\|ddr' $OWRT/package/boot/rockchip-rkbin/Makefile | head -20
echo "=== uboot photonicat variant def ==="
grep -n -A8 'U-Boot/photonicat-rk3568' $OWRT/package/boot/uboot-rockchip/Makefile
echo "=== staging image dir ==="
ls $OWRT/staging_dir/target-aarch64_generic_musl/image/ 2>/dev/null | head -20
