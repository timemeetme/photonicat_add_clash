#!/bin/bash
OWRT=/root/photonicat_openwrt
echo "=== uboot tarballs in dl ==="
ls -la $OWRT/dl/ | grep -iE 'u-boot|uboot'
echo "=== u-boot-2025.01 build_dir content ==="
ls $OWRT/build_dir/target-aarch64_generic_musl/u-boot-2025.01/ 2>/dev/null | head -10
echo "=== photonicat uboot stamps ==="
ls $OWRT/build_dir/target-aarch64_generic_musl/u-boot-photonicat-rk3568/.built* 2>/dev/null
echo "=== defconfig uboot selections ==="
grep -iE 'uboot|u-boot' $OWRT/.config | grep '=y' | head -20
