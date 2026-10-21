#!/bin/bash
echo "=== /proc/locks (flock entries) ==="
awk '/^ *[0-9]+ -> flock/ {print}' /proc/locks | head
echo "=== processes holding ubox-related fds ==="
for d in /proc/[0-9]*; do
  p=${d#/proc/}
  for f in $d/fd/*; do
    t=$(readlink $f 2>/dev/null)
    case "$t" in *ubox*) echo "pid=$p $(cat $d/comm 2>/dev/null) fd=$f -> $t";; esac
  done
done 2>/dev/null | head -20
echo "=== the stalled chain pids ==="
ps -eo pid,ppid,stat,etime,comm | grep -E "perl|flock|make|bash" | grep -v grep | head -15
