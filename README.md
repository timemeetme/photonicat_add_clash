# photonicat_add_clash

Photonicat 5G CPE（RK3568，2022 版）刷入 OpenWrt 系固件并配置 Clash 代理上网：
自编译流水线、上游补丁、刷机与 OpenClash 离线安装资料。

## 仓库结构

```
build/                          # WSL 无人值守编译流水线（bash + PowerShell）
├── resume_build.sh             # 编译管理器：代理设置、卡死看门狗、6 轮自动重试、产物校验拷出
├── build_env.sh                # 环境变量（代理等，被各脚本 source）
├── wsl_build_prep.sh           # WSL 构建环境准备（依赖安装等）
├── wsl_defconfig2/3.sh         # 写入 .config / defconfig
├── wsl_add_feed.sh             # 添加 passwall-packages feed 并刷新配置
├── wsl_make_all.sh / wsl_make_resume.sh
├── uboot_fix.sh                # uboot-rockchip 修复 + V=s 单编验证
├── uboot_*.sh                  # uboot 问题定位过程脚本（排障参考）
├── auto_resume_build.ps1       # Windows 侧引导拉起
└── status.sh / stop_all.sh / diag_stall.sh / net_test.sh / ...
firmware/
└── photonicat_base_defconfig   # 编译配置（含 OpenClash/Nikki/PassWall/HomeProxy/sing-box/xray）
patches/
└── 001-uboot-rockchip-sync-ddr-blob-v1.24.patch
tools/                          # 串口读取等调试工具
```

脚本默认路径：源码树 `/root/photonicat_openwrt`（WSL 内），产物目录 `/mnt/d/Projects/photonicat/firmware`。换环境请改脚本头部变量。

## 已修复的上游问题

photonicat_openwrt fork 合并笔误：`package/boot/uboot-rockchip/Makefile` 的 `Download/rk3588-ddr` 段已升级为下载
`rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.24.bin`，但 `Build/Prepare` 中的 `$(CP)` 仍硬编码 v1.18 文件名，
导致全量编译在 uboot-rockchip 阶段确定性失败（cp: cannot stat ... v1.18.bin）。
修复见 `patches/001-uboot-rockchip-sync-ddr-blob-v1.24.patch`（一行改动）。

## 复现自编译固件（WSL）

```bash
# 1. 取官方源码（fork）并打补丁
git clone --depth 1 https://github.com/photonicat/photonicat_openwrt ~/photonicat_openwrt
cd ~/photonicat_openwrt
git apply /path/to/patches/001-uboot-rockchip-sync-ddr-blob-v1.24.patch

# 2. 添加 passwall-packages feed
echo 'src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages;main' >> feeds.conf

# 3. 配置
cp /path/to/firmware/photonicat_base_defconfig .config
./scripts/feeds update -a && ./scripts/feeds install -a
make defconfig

# 4. 无人值守编译（后台，自动重试）
setsid nohup bash /path/to/build/resume_build.sh > /root/build_manager.log 2>&1 < /dev/null &
```

产物：`bin/targets/rockchip/armv8/*-sysupgrade*.img.gz`，管理器自动拷至 `firmware/selfbuilt/` 并写 `BUILD_RESULT.txt`。

## 刷机：ImmortalWrt 官方固件（推荐现成方案）

- 固件：ImmortalWrt 25.12.2 · rockchip-armv8 · `ariaboard_photonicat` · squashfs sysupgrade
  - 官方目录：<https://downloads.immortalwrt.org/releases/25.12.2/targets/rockchip/armv8/>
  - SHA256：`4238b2bc699b46a007e81da902a7fa6b40d2fb52b9f8c0e0391a19b714f9bc79`
  - 本地：`firmware/immortalwrt-25.12.2-photonicat-squashfs-sysupgrade.img.gz`（刷机前解压出 `.img`）
- 工具：DriverAssistant v5.1.1 + RKDevTool v2.86（瑞芯微官方）

步骤：

1. PC 安装 DriverAssistant 驱动。
2. 解压并运行 RKDevTool。
3. 设备断电 → 按住 reset → USB 连 PC 上电，进入 Loader/Maskrom 模式（RKDevTool 提示"发现一个 LOADER/MASKROM 设备"）。
4. 「升级固件」页 → 固件 → 选择解压后的 `.img` → 升级，等待完成重启。

注意：

- Photonicat 官方 Wiki 明示：**不同固件之间更新必须走 USB 线刷**，不要在旧系统里 sysupgrade 直刷。
- ImmortalWrt 上没有 Photonicat 官方的 5G modem 管理 / MCU 电源管理定制件，相关功能可能受限。
- 刷入后管理地址变为 `192.168.1.1`（原 photonicatwrt 为 172.16.0.1）。

## 刷机后安装 OpenClash（离线包）

离线包位于 `firmware/openclash/`（不入库，随 GitHub Release 分发）：

- `luci-app-openclash_0.47.156_all.ipk`（当前稳定版）
- `clash_meta`（MetaCubeX mihomo v1.19.13 linux-arm64，OpenClash 内核）

```bash
scp firmware/openclash/luci-app-openclash_0.47.156_all.ipk root@192.168.1.1:/tmp/
scp firmware/openclash/clash_meta root@192.168.1.1:/tmp/
ssh root@192.168.1.1

# opkg 系统（若固件用 apk 则改为: apk add ...）
opkg update
opkg install bash dnsmasq-full curl ca-bundle ip-full ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base
opkg install /tmp/luci-app-openclash_0.47.156_all.ipk

mkdir -p /etc/openclash/core
mv /tmp/clash_meta /etc/openclash/core/clash_meta
chmod +x /etc/openclash/core/clash_meta
```

LuCI → 服务 → OpenClash，上传订阅/配置即可。

## 产物发布

自编译固件、离线安装包等二进制通过 GitHub Releases 分发，不入 git。
