#!/bin/bash

# 使用ps命令获取进程ID、总内存占用率、父进程ID及应用名称，并按照总内存占用率降序排序，只显示前十个结果
ps -eo pid,pmem,ppid,comm --sort=-pmem | head -n 11 |
  awk '{ printf "%-10s%-10s%-10s%s\n", $1, $2, $3, $4; }'
