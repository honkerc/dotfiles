#!/bin/bash

# 使用ps命令获取进程ID、总CPU占用率、父进程ID及应用名称，并按照总CPU占用率降序排序，只显示前十个结果
ps -eo pid,pcpu,ppid,comm --sort=-pcpu | head -n 11 |
  awk '{ printf "%-10s%-10s%-10s%s\n", $1, $2, $3, $4; }'
