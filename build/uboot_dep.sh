#!/bin/bash
OWRT=/root/photonicat_openwrt
echo "=== uboot-rockchip Makefile head ==="
head -60 $OWRT/package/boot/uboot-rockchip/Makefile 2>/dev/null
echo "=== stamps ==="
ls -la $OWRT/build_dir/target-*/u-boot-* 2>/dev/null | head -5
find $OWRT/build_dir -maxdepth 2 -name 'u-boot*' -type d 2>/dev/null
echo "=== rkbin in dl ==="
ls -la $OWRT/dl/ 2>/dev/null | grep -iE 'rkbin|bl31|tf-a|trusted' 
