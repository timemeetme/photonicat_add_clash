#!/bin/bash
# Fix stalled ubox download: fetch with proxy, verify, kill dead chain
GW=$(ip route | awk '/default/ {print $3; exit}')
PROXY="http://$GW:7891"
echo "gateway=$GW proxy=$PROXY"

PKG_FILE="ubox-2025.10.30~6f78fa49.tar.zst"
EXPECT="41c28d9152cdf2998a4d867827655548f823de9de522a113a45ed1efef97d3ae"
DL="/root/photonicat_openwrt/dl"
HASH="6f78fa496bf36c55864a41e353df7d13f04b1077"

# candidate URLs (same as download.pl mirror order)
URLS=(
  "https://downloads.openwrt.org/sources/ubox-2025.10.30~6f78fa49.tar.zst"
  "https://git.openwrt.org/?p=project/ubox.git;a=snapshot;h=$HASH;sf=tgz"
)

ok=0
for u in "${URLS[@]}"; do
  echo "trying: $u"
  curl -x "$PROXY" -L --connect-timeout 15 --max-time 300 -o "/tmp/$PKG_FILE" "$u" 2>&1 | tail -2
  if [ -s "/tmp/$PKG_FILE" ]; then
    got=$(sha256sum "/tmp/$PKG_FILE" | awk '{print $1}')
    echo "size=$(stat -c%s /tmp/$PKG_FILE) sha256=$got"
    if [ "$got" = "$EXPECT" ]; then
      mv "/tmp/$PKG_FILE" "$DL/$PKG_FILE"
      ok=1; echo "OK: installed to dl/"
      break
    else
      echo "hash mismatch, next"; rm -f "/tmp/$PKG_FILE"
    fi
  fi
done

if [ $ok -eq 1 ]; then
  # clean stale leftovers
  rm -f "$DL/$PKG_FILE.dl" "$DL/$PKG_FILE.hash"
  # kill the deadlocked chain (flock/sh/perl/zombie-curl/sh)
  kill -9 307750 307751 307752 307755 307756 2>/dev/null
  echo "dead chain killed, make should resume"
else
  echo "FAILED to fetch ubox tarball"
fi
