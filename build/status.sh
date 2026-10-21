#!/bin/bash
tail -3 /root/build_manager.log 2>/dev/null
echo '=== build tail ==='
tail -5 /root/rust_build.log 2>/dev/null
echo '=== make alive ==='
pgrep -x make | wc -l
echo '=== mem avail MB ==='
free -m | awk 'NR==2{print $7}'
