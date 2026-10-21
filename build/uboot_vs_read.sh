#!/bin/bash
grep -n 'EXIT_CODE' /root/uboot_vs.log
echo "=== errors ==="
grep -nE 'error:|Error|ERROR|not found|No such|No rule' /root/uboot_vs.log | grep -v 'Werror' | head -25
echo "=== last 30 lines ==="
tail -30 /root/uboot_vs.log
