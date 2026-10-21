#!/bin/bash
# Photonicat OpenWrt unattended build manager
# - ensures ubox tarball present, sets proxy
# - runs taskset-limited make -j1 with stall detection and auto-retry
# - verifies artifacts, copies to Windows, writes BUILD_RESULT.txt
# Runs detached inside WSL. Idempotent.

FWMNT="/mnt/d/Projects/photonicat/firmware"
RESULT="$FWMNT/BUILD_RESULT.txt"
MGR_LOG="/root/build_manager.log"
BUILD_LOG="/root/rust_build.log"
OWRT=/root/photonicat_openwrt
DL=$OWRT/dl
UBOX_FILE="ubox-2025.10.30~6f78fa49.tar.zst"
UBOX_EXPECT="41c28d9152cdf2998a4d867827655548f823de9de522a113a45ed1efef97d3ae"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$MGR_LOG"; }

finish() {
  echo "$1" > "$RESULT"
  log "RESULT: $1"
  exit 0
}

# ---- 1. sanity + ubox tarball ----
[ -d "$OWRT" ] || finish "FAIL: build tree missing"
if [ ! -f "$DL/$UBOX_FILE" ]; then
  cp "$FWMNT/$UBOX_FILE" "$DL/" 2>>"$MGR_LOG" || finish "FAIL: cannot copy ubox tarball"
fi
got=$(sha256sum "$DL/$UBOX_FILE" | awk '{print $1}')
[ "$got" = "$UBOX_EXPECT" ] || finish "FAIL: ubox tarball hash mismatch"
rm -f "$DL/$UBOX_FILE.dl" "$DL/$UBOX_FILE.hash"
log "ubox tarball OK"

# ---- 2. proxy ----
GW=$(ip route | awk '/default/ {print $3; exit}')
export http_proxy="http://$GW:7891" https_proxy="http://$GW:7891" all_proxy="http://$GW:7891"
export no_proxy="localhost,127.0.0.1"
code=$(curl -sI --connect-timeout 10 -o /dev/null -w '%{http_code}' https://downloads.openwrt.org/ 2>/dev/null)
log "proxy=$http_proxy net_test=$code"

# ---- 3. build loop with stall detection ----
cd "$OWRT" || finish "FAIL: cd"
CORES_FILE=/root/core_limit
CORES=$(cat "$CORES_FILE" 2>/dev/null || echo "0-7")
MAX_ROUNDS=6
for round in $(seq 1 $MAX_ROUNDS); do
  log "=== round $round start (cores $CORES) ==="
  setsid taskset -c "$CORES" make -j1 > "$BUILD_LOG" 2>&1 < /dev/null &
  MPID=$!
  log "make pid=$MPID"

  # watchdog while make alive
  last_size=$(stat -c%s "$BUILD_LOG" 2>/dev/null || echo 0)
  stall=0
  while kill -0 "$MPID" 2>/dev/null; do
    sleep 120
    # count all live make processes in this session (make spawns children)
    if ! pgrep -x make >/dev/null 2>&1; then break; fi
    cur_size=$(stat -c%s "$BUILD_LOG" 2>/dev/null || echo 0)
    # idle ratio over 5s sample: 15th field of vmstat = idle %
    idle=$(vmstat 5 2 | tail -1 | awk '{print $15}')
    if [ "$cur_size" = "$last_size" ] && [ "${idle:-100}" -gt 97 ]; then
      stall=$((stall+1))
      log "stall? size unchanged, idle=${idle}% ($stall/3)"
      if [ "$stall" -ge 3 ]; then
        log "STALL CONFIRMED, killing make tree"
        pkill -9 -P "$MPID" 2>/dev/null
        pgrep -x make | xargs -r kill -9 2>/dev/null
        pkill -9 -f 'download.pl' 2>/dev/null
        pkill -9 curl 2>/dev/null
        sleep 3
        break
      fi
    else
      stall=0
      last_size=$cur_size
    fi
  done
  wait "$MPID" 2>/dev/null
  rc=$?
  log "make exited rc=$rc"

  # collect missing download info for diagnosis
  MISS=$(find "$DL" -maxdepth 1 -name '*.dl' -size 0 -printf '%f\n' 2>/dev/null | sed 's/\.dl$//' | tr '\n' ' ')
  [ -n "$MISS" ] && log "possibly-missing downloads: $MISS"

  # success check
  if [ "$rc" -eq 0 ] && ls "$OWRT/bin/targets/rockchip/armv8/"*sysupgrade*.img.gz >/dev/null 2>&1; then
    log "BUILD SUCCESS on round $round"
    break
  fi
  if grep -q "failed to build" "$BUILD_LOG" 2>/dev/null; then
    FAILPKGS=$(grep -oE 'package/[^ ]+ failed to build' "$BUILD_LOG" | sort -u | tr '\n' '; ')
    log "failed packages: $FAILPKGS"
    # OOM guard: if rust failed, drop to 6 cores next round
    if echo "$FAILPKGS" | grep -q rust; then
      log "rust failure detected -> limiting to cores 0-5 next round"
      echo "0-5" > "$CORES_FILE"
    fi
  fi
  [ "$round" -eq "$MAX_ROUNDS" ] && finish "FAIL: build did not succeed after $MAX_ROUNDS rounds. See rust_build.log. Failed: ${FAILPKGS:-unknown}; Missing dl: ${MISS:-none}"
done

# ---- 4. verify artifacts ----
TGT="$OWRT/bin/targets/rockchip/armv8"
IMG=$(ls "$TGT"/*sysupgrade*.img.gz 2>/dev/null | head -1)
[ -n "$IMG" ] || finish "FAIL: no sysupgrade image found"

IMGSIZE=$(stat -c%s "$IMG")
if ! gzip -t "$IMG" 2>>"$MGR_LOG"; then
  finish "FAIL: sysupgrade image corrupt (gzip test failed)"
fi

PKGS=$(ls "$OWRT/bin/packages/aarch64_generic/" 2>/dev/null)
PROXY_PKGS=$(echo "$PKGS" | grep -iE 'openclash|nikki|passwall|homeproxy|sing-box|xray|mihomo' | tr '\n' ' ')

{
  echo "SUCCESS $(date '+%F %T')"
  echo "image: $(basename "$IMG") size: $IMGSIZE bytes"
  echo "gzip integrity: OK"
  echo "proxy packages: ${PROXY_PKGS:-NONE FOUND}"
  echo "kernel pkgs count: $(echo "$PKGS" | wc -l)"
} > "$RESULT"

# ---- 5. copy artifacts to Windows ----
mkdir -p "$FWMNT/selfbuilt"
cp "$TGT"/*sysupgrade*.img.gz "$FWMNT/selfbuilt/" 2>>"$MGR_LOG"
cp "$TGT"/sha256sums "$FWMNT/selfbuilt/" 2>>"$MGR_LOG"
cp "$TGT"/*.manifest "$FWMNT/selfbuilt/" 2>>"$MGR_LOG" 2>/dev/null
mkdir -p "$FWMNT/selfbuilt/packages"
for p in openclash nikki passwall homeproxy sing-box xray mihomo; do
  ls "$OWRT/bin/packages/aarch64_generic/" 2>/dev/null | grep -i "$p" | while read -r f; do
    cp "$OWRT/bin/packages/aarch64_generic/$f" "$FWMNT/selfbuilt/packages/" 2>>"$MGR_LOG"
  done
done
log "artifacts copied to $FWMNT/selfbuilt"
log "RESULT: SUCCESS - done"
exit 0
