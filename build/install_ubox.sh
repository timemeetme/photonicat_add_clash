#!/bin/bash
DL=/root/photonicat_openwrt/dl
SRC="/mnt/d/Projects/photonicat/firmware/ubox-2025.10.30~6f78fa49.tar.zst"
cp "$SRC" "$DL/"
got=$(sha256sum "$DL/ubox-2025.10.30~6f78fa49.tar.zst" | awk '{print $1}')
echo "wsl_sha256=$got"
if [ "$got" = "41c28d9152cdf2998a4d867827655548f823de9de522a113a45ed1efef97d3ae" ]; then
  rm -f "$DL/ubox-2025.10.30~6f78fa49.tar.zst.dl" "$DL/ubox-2025.10.30~6f78fa49.tar.zst.hash"
  echo "killing dead chain..."
  kill -9 307750 307751 307752 307755 307756 2>/dev/null
  sleep 3
  echo "=== make tree after kill ==="
  pstree -p 235307 | head -8
  echo "=== log tail ==="
  tail -5 /root/rust_build.log
else
  echo "HASH MISMATCH - not installed"
fi
