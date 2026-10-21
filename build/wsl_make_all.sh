#!/bin/bash
source /root/build_env.sh
cd /root/photonicat_openwrt
JOBS=$(nproc)
if [ "$JOBS" -gt 12 ]; then JOBS=12; fi
echo "JOBS=$JOBS proxy=$http_proxy"
make -j$JOBS download > /root/dl.log 2>&1
DL_EXIT=$?
echo "DOWNLOAD_EXIT=$DL_EXIT"
if [ $DL_EXIT -ne 0 ]; then
  echo "--- dl.log tail ---"
  tail -30 /root/dl.log
  exit $DL_EXIT
fi
make -j$JOBS > /root/build.log 2>&1
BUILD_EXIT=$?
echo "BUILD_EXIT=$BUILD_EXIT"
tail -40 /root/build.log
ls -la /root/photonicat_openwrt/bin/targets/rockchip/armv8/ 2>/dev/null | tail -20
