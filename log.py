#!/usr/bin/env python3
"""
日志模块
提供统一的日志输出功能，包含四个等级：info、success、warning、error
"""

import sys
import time
from datetime import datetime

# 颜色代码
class Colors:
    RED = '\033[0;31m'
    BOLD_RED = '\033[1;31m'  # 加粗红色
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color
    BOLD = '\033[1m'  # 加粗

class Logger:
    def __init__(self, use_timestamp=False):
        self.use_timestamp = use_timestamp
        self.current_package_line = None  # 当前包安装行的信息

    def _get_timestamp(self):
        if self.use_timestamp:
            return " " + datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        return ""

    def _clear_current_line(self):
        """清除当前行"""
        print('\r\033[K', end='', flush=True)

    def _print_package_line(self, index, total, status, pkg_name, comment=""):
        """打印包安装行（支持在同一行更新）"""
        # 状态颜色映射
        status_colors = {
            "EXEC": Colors.YELLOW,
            "SKIP": Colors.GREEN,
            "DONE": Colors.GREEN,
            "FAIL": Colors.RED
        }

        status_color = status_colors.get(status, Colors.YELLOW)

        # 格式化输出
        status_display = f"{status_color}{status}{Colors.NC}"
        index_display = f"[{index}/{total}]"
        comment_display = f"{Colors.GREEN}# {comment}{Colors.NC}" if comment else ""
        pkg_display = f"{pkg_name:<70}"

        line_content = f"{index_display} [{status_display}] {pkg_display} {comment_display}"

        # 清除当前行并打印新内容
        self._clear_current_line()
        print(line_content, end='', flush=True)

        # 保存当前包信息用于后续更新
        self.current_package_line = {
            'index': index,
            'total': total,
            'pkg_name': pkg_name,
            'comment': comment
        }

    def info(self, message):
        timestamp = self._get_timestamp()
        # 如果有正在显示的包行，先换行
        if self.current_package_line:
            print()
            self.current_package_line = None
        print(f"{Colors.BLUE}[-]{timestamp}{Colors.NC} {message}")

    def success(self, message):
        timestamp = self._get_timestamp()
        if self.current_package_line:
            print()
            self.current_package_line = None
        print(f"{Colors.GREEN}[+]{timestamp}{Colors.NC} {message}")

    def warning(self, message):
        timestamp = self._get_timestamp()
        if self.current_package_line:
            print()
            self.current_package_line = None
        print(f"{Colors.YELLOW}[?]{timestamp}{Colors.NC} {message}")

    def error(self, message):
        timestamp = self._get_timestamp()
        if self.current_package_line:
            print()
            self.current_package_line = None
        print(f"{Colors.RED}[!]{timestamp} {message}{Colors.NC}")

    def progress_start(self, message):
        if self.current_package_line:
            print()
            self.current_package_line = None
        print(f"{Colors.BLUE}[-]{Colors.NC} {message}...", end='', flush=True)

    def progress_end(self, success=True, message=None):
        if success:
            print(f"\r{Colors.GREEN}[+]{Colors.NC} {message or '完成'}       ")
        else:
            print(f"\r{Colors.RED}[!] {message or '失败'}{Colors.NC}       ")

    def section_header(self, section_name, manager=""):
        if self.current_package_line:
            print()
            self.current_package_line = None
        manager_display = f" (使用 {Colors.YELLOW}{manager}{Colors.CYAN})" if manager else ""
        print(f"\n{Colors.CYAN}[*] 执行 '{section_name}' 命令{manager_display}{Colors.NC}")

    def package_start(self, index, total, pkg_name, comment=""):
        """开始包安装（显示EXEC状态）"""
        if self.current_package_line:
            print()  # 如果有上一个包，先换行

        self._print_package_line(index, total, "EXEC", pkg_name, comment)

    def package_update(self, status, message=""):
        """更新当前包的状态"""
        if not self.current_package_line:
            return

        # 更新状态
        index = self.current_package_line['index']
        total = self.current_package_line['total']
        pkg_name = self.current_package_line['pkg_name']
        comment = self.current_package_line['comment']

        self._print_package_line(index, total, status, pkg_name, comment)

        # 如果有附加消息，换行显示
        if message:
            print()  # 换行
            if status == "FAIL":
                self.error(message)
            else:
                self.info(message)
            # 清除当前包信息，因为已经完成了
            self.current_package_line = None

    # 便捷方法
    def package_skip(self, index, total, pkg_name, comment=""):
        """包跳过安装"""
        self.package_start(index, total, pkg_name, comment)
        # 可以立即更新状态，或者等待一段时间后更新
        # 这里立即更新
        self.package_update("SKIP")

    def package_done(self, index, total, pkg_name, comment=""):
        """包安装完成"""
        self.package_start(index, total, pkg_name, comment)
        self.package_update("DONE")

    def package_fail(self, index, total, pkg_name, comment="", error_msg=""):
        """包安装失败"""
        self.package_start(index, total, pkg_name, comment)
        self.package_update("FAIL", error_msg)

# 创建全局日志实例
log = Logger()

# 直接导出函数
info = log.info
success = log.success
warning = log.warning
error = log.error
section_header = log.section_header
package_start = log.package_start
package_update = log.package_update
package_skip = log.package_skip
package_done = log.package_done
package_fail = log.package_fail

if __name__ == "__main__":
    # 测试所有日志功能
    print("=== 测试基本日志功能 ===")
    info("这是一条信息消息")
    success("这是一条成功消息")
    warning("这是一条警告消息")
    error("这是一条错误消息")

    print("\n=== 测试步骤功能 ===")
    info("安装系统包...")
    success("包安装成功")

    warning("网络接口未配置")
    error("网络配置失败")

    print("\n=== 测试动态包安装状态 ===")
    section_header("基础包", "paru")

    # 测试动态更新效果
    package_start(1, 5, "git", "版本控制")
    time.sleep(1)  # 模拟安装过程
    package_update("DONE")  # 更新为完成状态

    package_start(2, 5, "neovim", "编辑器")
    time.sleep(0.5)  # 模拟短暂安装过程
    package_update("SKIP")  # 更新为跳过状态

    package_start(3, 5, "hyprland", "桌面环境")
    time.sleep(1)  # 模拟安装过程
    package_update("FAIL", "依赖解析失败")  # 更新为失败状态并显示错误

    package_start(4, 5, "networkmanager", "网络管理")
    time.sleep(1.5)  # 模拟安装过程
    package_update("DONE")  # 更新为完成状态

    package_start(5, 5, "firefox", "浏览器")
    time.sleep(3)  # 模拟安装过程
    package_update("DONE")  # 更新为完成状态
