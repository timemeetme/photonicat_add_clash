#!/bin/bash
OWRT=/root/photonicat_openwrt
echo "=== all uboot/u-boot lines in .config ==="
grep -iE 'uboot|u-boot' $OWRT/.config
echo "=== who depends on uboot-rockchip (image deps) ==="
grep -rn 'u-boot' $OWRT/target/linux/rockchip/image/*.mk 2>/dev/null | head -20
echo "=== photonicat feed image config ==="
ls $OWRT/target/linux/rockchip/files/ 2>/dev/null | head
grep -rn 'DEVICE_VENDOR.*Aria\|photonicat' $OWRT/target/linux/rockkit/image/*.mk $OWRT/target/linux/rockchip/image/*.mk 2>/dev/null | head -10
echo "=== uboot-rockchip built variants ==="
grep -E 'U-Boot/[a-z0-9-]+' $OWRT/package/boot/uboot-rockchip/Makefile | grep -E '^[A-Z]|define U-Boot' | head -40
