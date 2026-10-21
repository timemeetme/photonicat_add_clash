#!/bin/bash
OWRT=/root/photonicat_openwrt
echo '===== 1. v1.18 references ====='
grep -n 'v1\.18' $OWRT/package/boot/uboot-rockchip/Makefile $OWRT/package/boot/rockchip-rkbin/Makefile 2>/dev/null
echo
echo '===== 2. uboot-rockchip Makefile 440-520 ====='
sed -n '440,520p' $OWRT/package/boot/uboot-rockchip/Makefile
echo
echo '===== 3. Download sections in uboot Makefile ====='
grep -n -A6 'define Download/' $OWRT/package/boot/uboot-rockchip/Makefile | head -80
echo
echo '===== 4. rkbin tarball listing ====='
tar -I zstd -tf "$OWRT/dl/rkbin-2026.06.26~3e288fe8.tar.zst" 2>&1 | grep -iE 'ddr|bl31' | head -40
echo
echo '===== 5. dl dir rk/blob files ====='
ls $OWRT/dl/ | grep -iE 'rkbin|rk35|ddr|bl31'
echo
echo '===== 6. staging image dir ====='
ls $OWRT/staging_dir/target-aarch64_generic_musl/image/ 2>/dev/null
