GW=$(ip route show default | awk '{print $3}')
export http_proxy=http://$GW:7891
export https_proxy=http://$GW:7891
export no_proxy=localhost,127.0.0.1,::1,mirrors.tuna.tsinghua.edu.cn,.cn
export FORCE_UNSAFE_CONFIGURE=1
