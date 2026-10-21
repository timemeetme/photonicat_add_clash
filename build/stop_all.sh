#!/bin/bash
echo "=== killing manager and make tree ==="
pkill -f resume_build.sh 2>/dev/null
sleep 1
pgrep -x make | xargs -r kill -9 2>/dev/null
pkill -9 -f 'package/boot' 2>/dev/null
sleep 2
pgrep -af 'make|resume_build' | grep -v grep | head -5
echo "=== all killed ==="
