#!/bin/bash
GW=$(ip route | awk '/default/ {print $3; exit}')
echo "GW=$GW"
timeout 12 curl -x "http://$GW:7891" -sI https://www.google.com -o /dev/null -w "proxy_google=%{http_code}\n"
timeout 12 curl -x "http://$GW:7891" -sI "https://downloads.openwrt.org/sources/" -o /dev/null -w "proxy_openwrt=%{http_code}\n"
timeout 12 curl -sI --connect-timeout 8 "https://downloads.openwrt.org/sources/" -o /dev/null -w "direct_openwrt=%{http_code}\n"
echo "--- fix script still alive? ---"
pgrep -af "fix_ubox" || echo "fix script gone"
