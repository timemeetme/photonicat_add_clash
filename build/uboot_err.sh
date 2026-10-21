#!/bin/bash
LOG=/root/rust_build.log
echo "=== manager log ==="
tail -4 /root/build_manager.log
echo "=== uboot error context in build log ==="
grep -n 'ERROR\|failed to build\|error:' $LOG | tail -10
echo "=== around uboot compile ==="
grep -n 'uboot-rockchip\|u-boot-2025.01' $LOG | tail -10
echo "=== last 40 lines ==="
tail -40 $LOG
