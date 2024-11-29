#!/bin/bash

#定义变量
openwrt_version_code="v23.05.5"
lede_version_code="20230609"
openwrt_repo="https://github.com/openwrt/openwrt"
lede_repo="https://github.com/coolsnowwolf/lede"
my_package_repo="https://github.com/mrzhaohanhua/openwrt-packages"
extra_package_path="./package/extra"

# 定义函数
copy_package(){
  source_dir=$1
  dest_dir=$2
  mkdir -p $dest_dir
  cp -rf ../openwrt-packages/$source_dir/* $dest_dir/
      if [ $? -ne 0 ]; then
        echo "cp -rf ../openwrt-packages/$source_dir $dest_dir"
        echo "执行错误"
        exit 1
    fi
}

### 清理 ###
echo "清理 ./openwrt/"
rm -rf openwrt
echo "清理 ./openwrt-packages/"
rm -rf openwrt-packages

echo "签出 OpenWRT $openwrt_version_code"

if git clone --depth 1 -b $openwrt_version_code $openwrt_repo openwrt; then
	echo "签出 OpenWRT $openwrt_version_code 成功."
else
	echo "签出 OpenWRT $openwrt_version_code 失败."
	exit 1
fi

echo "签出 openwrt-packages"
if git clone --depth 1 $my_package_repo openwrt-packages; then
	echo "签出 openwrt-packages 成功."
else
	echo "签出 openwrt-packages 失败."
	exit 1
fi

cd openwrt

echo "更新 feeds"
if ./scripts/feeds update -a; then
	echo "更新 feeds 成功."
else
	echo "更新 feeds 失败."
	exit 1
fi

./scripts/feeds install -a

# 默认开启 Irqbalance
sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
# 移除 SNAPSHOT 标签
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in

# UPX 可执行软件压缩
sed -i '/patchelf pkgconf/i\tools-y += ucl upx' ./tools/Makefile
sed -i '\/autoconf\/compile :=/i\$(curdir)/upx/compile := $(curdir)/ucl/compile' ./tools/Makefile
copy_package tools/ucl tools/ucl
copy_package tools/upx tools/upx

### 获取额外的 LuCI 应用、主题和依赖 ###
# 更换 frp
rm -rf feeds/package/net/frp
copy_package frp feeds/package/net/frp

# 更换smartdns
rm -rf feeds/packages/net/smartdns
copy_package openwrt-smartdns feeds/packages/net/smartdns

# 替换luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
copy_package luci-app-smartdns feeds/luci/applications/luci-app-smartdns

# 替换golang为v1.23
rm -rf feeds/packages/lang/golang/golang
copy_package golang feeds/packages/lang/golang/golang

# Argon主题
copy_package luci-theme-argon ${extra_package_path}/luci-theme-argon
copy_package luci-app-argon-config ${extra_package_path}/luci-app-argon-config

# ChinaDNS
copy_package chinadns-ng ${extra_package_path}/chinadns-ng

# OLED 驱动程序
git clone -b master --depth 1 https://github.com/NateLol/luci-app-oled.git ${extra_package_path}/luci-app-oled

# Passwall
copy_package luci-app-passwall ${extra_package_path}/luci-app-passwall

# 修改luci-app-passwall中的Makefile以支持最新的iptables
# sed -i 's,iptables-legacy,iptables-nft,g' ${extra_package_path}/luci-app-passwall/Makefile

# 替换 Xray-core
rm -rf feeds/packages/net/xray-core
copy_package xray-core feeds/packages/net/xray-core

# 替换 v2ray-core
rm -rf feeds/packages/net/v2ray-core
copy_package v2ray-core feeds/packages/net/v2ray-core
rm -rf feeds/packages/net/v2ray-geodata
copy_package v2ray-geodata feeds/packages/net/v2ray-geodata

# Passwall的依赖包
copy_package ipt2socks ${extra_package_path}/ipt2socks
copy_package microsocks ${extra_package_path}/microsocks
copy_package dns2socks ${extra_package_path}/dns2socks
copy_package dns2tcp ${extra_package_path}/dns2tcp
copy_package naiveproxy ${extra_package_path}/naiveproxy
copy_package gn ${extra_package_path}/gn
copy_package pdnsd-alt ${extra_package_path}/pdnsd-alt
copy_package shadowsocks-rust ${extra_package_path}/shadowsocks-rust
copy_package shadowsocksr-libev ${extra_package_path}/shadowsocksr-libev
copy_package simple-obfs ${extra_package_path}/simple-obfs
copy_package tcping ${extra_package_path}/tcping
copy_package trojan-go ${extra_package_path}/trojan-go
copy_package brook ${extra_package_path}/brook
copy_package trojan-plus ${extra_package_path}/trojan-plus
copy_package ssocks ${extra_package_path}/ssocks
copy_package v2ray-plugin ${extra_package_path}/v2ray-plugin
copy_package xray-plugin ${extra_package_path}/xray-plugin
copy_package hysteria ${extra_package_path}/hysteria
copy_package tuic-client ${extra_package_path}/tuic-client

# KMS 激活助手
copy_package luci-app-vlmcsd ${extra_package_path}/luci-app-vlmcsd
copy_package vlmcsd ${extra_package_path}/vlmcsd

### 后续修改 ###

# 最大连接数（来自QiuSimons/YAOF）
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf

#convert_translation（来自QiuSimons/YAOF）
po_file="$({ find | grep -E "[a-z0-9]+\.zh\-cn.+po"; } 2>"/dev/null")"
for a in ${po_file}; do
  [ -n "$(grep "Language: zh_CN" "$a")" ] && sed -i "s/Language: zh_CN/Language: zh_Hans/g" "$a"
  po_new_file="$(echo -e "$a" | sed "s/zh-cn/zh_Hans/g")"
  mv "$a" "${po_new_file}" 2>"/dev/null"
done

po_file2="$({ find | grep "/zh-cn/" | grep "\.po"; } 2>"/dev/null")"
for b in ${po_file2}; do
  [ -n "$(grep "Language: zh_CN" "$b")" ] && sed -i "s/Language: zh_CN/Language: zh_Hans/g" "$b"
  po_new_file2="$(echo -e "$b" | sed "s/zh-cn/zh_Hans/g")"
  mv "$b" "${po_new_file2}" 2>"/dev/null"
done

lmo_file="$({ find | grep -E "[a-z0-9]+\.zh_Hans.+lmo"; } 2>"/dev/null")"
for c in ${lmo_file}; do
  lmo_new_file="$(echo -e "$c" | sed "s/zh_Hans/zh-cn/g")"
  mv "$c" "${lmo_new_file}" 2>"/dev/null"
done

lmo_file2="$({ find | grep "/zh_Hans/" | grep "\.lmo"; } 2>"/dev/null")"
for d in ${lmo_file2}; do
  lmo_new_file2="$(echo -e "$d" | sed "s/zh_Hans/zh-cn/g")"
  mv "$d" "${lmo_new_file2}" 2>"/dev/null"
done

po_dir="$({ find | grep "/zh-cn" | sed "/\.po/d" | sed "/\.lmo/d"; } 2>"/dev/null")"
for e in ${po_dir}; do
  po_new_dir="$(echo -e "$e" | sed "s/zh-cn/zh_Hans/g")"
  mv "$e" "${po_new_dir}" 2>"/dev/null"
done

makefile_file="$({ find | grep Makefile | sed "/Makefile./d"; } 2>"/dev/null")"
for f in ${makefile_file}; do
  [ -n "$(grep "zh-cn" "$f")" ] && sed -i "s/zh-cn/zh_Hans/g" "$f"
  [ -n "$(grep "zh_Hans.lmo" "$f")" ] && sed -i "s/zh_Hans.lmo/zh-cn.lmo/g" "$f"
done

makefile_file="$({ find package | grep Makefile | sed "/Makefile./d"; } 2>"/dev/null")"
for g in ${makefile_file}; do
  [ -n "$(grep "golang-package.mk" "$g")" ] && sed -i "s,\../..,\$(TOPDIR)/feeds/packages,g" "$g"
  [ -n "$(grep "luci.mk" "$g")" ] && sed -i "s,\../..,\$(TOPDIR)/feeds/luci,g" "$g"
done

# Remove upx commands

makefile_file="$({ find package|grep Makefile |sed "/Makefile./d"; } 2>"/dev/null")"
for a in ${makefile_file}
do
	[ -n "$(grep "upx" "$a")" ] && sed -i "/upx/d" "$a"
done

# Script for creating ACL file for each LuCI APP
bash ../create_acl_for_luci.sh -a

# Install scripts
mkdir -p package/base-files/files/bin/
cp ../files/bin/pppoe_daemon.sh package/base-files/files/bin/
sed -i "`wc -l < package/base-files/files/etc/rc.local`i\\sh /bin/pppoe_daemon.sh &\\" package/base-files/files/etc/rc.local

# Copy config file
cp ../config_erx .config
make defconfig
echo "ready to make!!!"
