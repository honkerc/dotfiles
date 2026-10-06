#!/bin/bash

# 检查vmware-networks.service的状态
networks_status=$(systemctl is-active vmware-networks.service)

# 检查vmware-usbarbitrator.service的状态
usbarbitrator_status=$(systemctl is-active vmware-usbarbitrator.service)

if pgrep -x "vmware" >/dev/null; then
    # 已经启动
    notify-send -u normal "已启动"  "vmware和服务"
else
    # 检查两个服务是否有一个正在运行，如果没在运行就启动服务
    if [[ "$networks_status" = "inactive" ]] || [[ "$usbarbitrator_status" = "inactive" ]]; then
        # 启动服务，并将notify-send命令的标准输出和错误输出都重定向到/dev/null
        pkexec systemctl start vmware-networks.service vmware-usbarbitrator.service
        notify-send -u normal "成功启动服务"  "1.vmware-networks\n2.vmware-usbartitrator服务" > /dev/null 2>&1
    fi
    vmware
fi


