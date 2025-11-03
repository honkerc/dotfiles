#!/bin/bash

# 获取脚本名称和进程ID文件路径
SCRIPT_NAME=$(basename "$0")
SERVICE_DIR=$HOME/www/
PID_FILE="/tmp/${SCRIPT_NAME}.pids"

# 函数：发送桌面通知
notify() {
    local title=$1
    local message=$2
    if command -v notify-send &> /dev/null; then
        notify-send "$title" "$message"
    else
        echo "$title: $message"
    fi
}

# 函数：杀死之前运行的进程
kill_previous_processes() {
    if [[ -f "$PID_FILE" ]]; then
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid"
                echo "已终止进程: $pid"
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
        notify "服务管理" "已停止之前的服务进程"
    fi
}

# 函数：启动服务
start_services() {
    # 杀死之前的进程
    kill_previous_processes

    # 启动后端服务并保存PID
    alacritty -e bash -c "cd $SERVICE_DIR/back && $HOME/.venv/bin/python main.py; exec bash" &
    BACK_PID=$!
    echo $BACK_PID >> "$PID_FILE"

    # 启动前端服务并保存PID
    alacritty -e bash -c "cd $SERVICE_DIR/front && yarn serve; exec bash" &
    FRONT_PID=$!
    echo $FRONT_PID >> "$PID_FILE"

    # 等待一会儿确保服务启动
    sleep 2

    # 检查进程是否仍在运行
    if kill -0 $BACK_PID 2>/dev/null && kill -0 $FRONT_PID 2>/dev/null; then
        notify "服务管理" "服务已成功启动"
        echo "后端服务PID: $BACK_PID"
        echo "前端服务PID: $FRONT_PID"
        echo "PID已保存到: $PID_FILE"
    else
        notify "服务管理" "服务启动可能失败，请检查终端输出"
        echo "警告: 某些服务可能启动失败"
    fi
}

# 函数：显示使用帮助
show_usage() {
    echo "用法: $0 [start|stop|restart|status]"
    echo "  start   - 启动服务"
    echo "  stop    - 停止服务"
    echo "  restart - 重启服务"
    echo "  status  - 查看服务状态"
    echo "  无参数  - 同 restart"
}

# 函数：查看服务状态
check_status() {
    if [[ -f "$PID_FILE" ]]; then
        echo "当前运行的服务进程:"
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                echo "  PID $pid: 运行中"
            else
                echo "  PID $pid: 已停止"
            fi
        done < "$PID_FILE"
    else
        echo "没有找到运行中的服务记录"
    fi
}

# 根据参数执行相应操作
case "${1:-restart}" in
    start)
        start_services
        ;;
    stop)
        kill_previous_processes
        ;;
    restart)
        start_services
        ;;
    status)
        check_status
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
