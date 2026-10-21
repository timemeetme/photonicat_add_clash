#!/bin/bash
set -e
GW=$(ip route show default | awk '{print $3}')
cat > /root/build_env.sh <<EOF
GW=\$(ip route show default | awk '{print \$3}')
export http_proxy=http://\$GW:7891
export https_proxy=http://\$GW:7891
export no_proxy=localhost,127.0.0.1,::1,mirrors.tuna.tsinghua.edu.cn,.cn
EOF
git config --global http.proxy http://$GW:7891
git config --global https.proxy http://$GW:7891
echo "GIT_PROXY_SET -> $GW:7891"
cd /root/photonicat_openwrt
make defconfig 2>&1 | tail -2
echo "=== proxy packages in .config ==="
grep -E "openclash|passwall|homeproxy|nikki" .config | grep -v "^#" | head -25 || true
