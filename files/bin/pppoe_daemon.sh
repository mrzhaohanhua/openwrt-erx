#!/bin/sh
#PPPoE守护进程

network_config="/etc/config/network"
ping_dest="223.5.5.5"
ping_count=4
fail_count=0

#获取pppoe连接名称
pppoe_name=$(grep -B 1 "proto 'pppoe'" ${network_config} | grep interface | sed 's/config interface '"'"'//;s/'"'"'//')
if [[ -n "${pppoe_name}" ]]
then
    echo "pppoe interface name: ${pppoe_name}"
else
    echo "pppoe interface not found."
    echo "script exit."
    exit 1
fi

#开启循环
while true
do
    # 检查 pppoe 连接的状态
    if (ifstatus ${pppoe_name} | grep "\"up\": true" &> /dev/null)
    then
        # pppoe 状态为 up
        echo "${pppoe_name} is up."
        if (ping -q -c $ping_count $ping_dest &> /dev/null)
        then
            #ping通以后计数器清零
            fail_count=0
        else
            #ping失败后计数器+1
            fail_count=$(($fail_count + 1))
            echo "ping ${ping_dest} fail ${fail_count} times."
        fi
        if [ $fail_count -gt 2 ]
        then
            #ping失败3次以上重置pppoe连接
            echo "Internet down, restart ${pppoe_name}"
            fail_count=0
            ifdown $pppoe_name
            sleep 5
            ifup $pppoe_name
            sleep 20
        fi
    else
        echo "${pppoe_name} is not up."
    fi
    sleep 10
done
