#!/bin/bash
clear

#获取openwrt
git clone --depth 1 -b v21.02.0 https://github.com/openwrt/openwrt openwrt
#切换到openwrt目录
cd openwrt 

### 获取额外的 LuCI 应用、主题和依赖 ###

# ChinaDNS
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/chinadns-ng/ package/extra/chinadns-ng

# Passwall
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/luci-app-passwall package/extra/luci-app-passwall
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/ipt2socks package/extra/ipt2socks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/microsocks package/extra/microsocks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/dns2socks package/extra/dns2socks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/naiveproxy package/extra/naiveproxy
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/pdnsd-alt package/extra/pdnsd-alt
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/shadowsocks-rust package/extra/shadowsocks-rust
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/shadowsocksr-libev package/extra/shadowsocksr-libev
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/simple-obfs package/extra/simple-obfs
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/tcping package/extra/tcping
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-go package/extra/trojan-go
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/brook package/extra/brook
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-plus package/extra/trojan-plus
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/ssocks package/extra/ssocks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/xray-core package/extra/xray-core
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray-plugin package/extra/v2ray-plugin
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/xray-plugin package/extra/xray-plugin
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/hysteria package/extra/hysteria
svn co https://github.com/fw876/helloworld/trunk/v2ray-core package/extra/v2ray-core

# KMS 激活助手
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-vlmcsd package/extra/luci-app-vlmcsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/vlmcsd package/extra/vlmcsd

#convert_translation
po_file="$({ find |grep -E "[a-z0-9]+\.zh\-cn.+po"; } 2>"/dev/null")"
for a in ${po_file}
do
	[ -n "$(grep "Language: zh_CN" "$a")" ] && sed -i "s/Language: zh_CN/Language: zh_Hans/g" "$a"
	po_new_file="$(echo -e "$a"|sed "s/zh-cn/zh_Hans/g")"
	mv "$a" "${po_new_file}" 2>"/dev/null"
done

po_file2="$({ find |grep "/zh-cn/" |grep "\.po"; } 2>"/dev/null")"
for b in ${po_file2}
do
	[ -n "$(grep "Language: zh_CN" "$b")" ] && sed -i "s/Language: zh_CN/Language: zh_Hans/g" "$b"
	po_new_file2="$(echo -e "$b"|sed "s/zh-cn/zh_Hans/g")"
	mv "$b" "${po_new_file2}" 2>"/dev/null"
done

lmo_file="$({ find |grep -E "[a-z0-9]+\.zh_Hans.+lmo"; } 2>"/dev/null")"
for c in ${lmo_file}
do
	lmo_new_file="$(echo -e "$c"|sed "s/zh_Hans/zh-cn/g")"
	mv "$c" "${lmo_new_file}" 2>"/dev/null"
done

lmo_file2="$({ find |grep "/zh_Hans/" |grep "\.lmo"; } 2>"/dev/null")"
for d in ${lmo_file2}
do
	lmo_new_file2="$(echo -e "$d"|sed "s/zh_Hans/zh-cn/g")"
	mv "$d" "${lmo_new_file2}" 2>"/dev/null"
done

po_dir="$({ find |grep "/zh-cn" |sed "/\.po/d" |sed "/\.lmo/d"; } 2>"/dev/null")"
for e in ${po_dir}
do
	po_new_dir="$(echo -e "$e"|sed "s/zh-cn/zh_Hans/g")"
	mv "$e" "${po_new_dir}" 2>"/dev/null"
done

makefile_file="$({ find|grep Makefile |sed "/Makefile./d"; } 2>"/dev/null")"
for f in ${makefile_file}
do
	[ -n "$(grep "zh-cn" "$f")" ] && sed -i "s/zh-cn/zh_Hans/g" "$f"
	[ -n "$(grep "zh_Hans.lmo" "$f")" ] && sed -i "s/zh_Hans.lmo/zh-cn.lmo/g" "$f"
done


# Remove upx commands

makefile_file="$({ find package|grep Makefile |sed "/Makefile./d"; } 2>"/dev/null")"
for a in ${makefile_file}
do
	[ -n "$(grep "upx" "$a")" ] && sed -i "/upx/d" "$a"
done

# Script for creating ACL file for each LuCI APP
bash ../create_acl_for_luci.sh -a
