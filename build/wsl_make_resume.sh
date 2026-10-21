#!/bin/bash
source /root/build_env.sh
cd /root/photonicat_openwrt
JOBS=$(nproc)
if [ "$JOBS" -gt 12 ]; then JOBS=12; fi
make -j$JOBS > /root/build.log 2>&1
echo "BUILD_EXIT=$?" > /root/build_exit.txt
tail -25 /root/build.log >> /root/build_exit.txt
