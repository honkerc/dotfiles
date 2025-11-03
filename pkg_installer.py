#!/usr/bin/env python3
"""
包安装管理器 - 单类模块化版本
"""

import os
import sys
import subprocess
import signal
import tempfile
import time
from pathlib import Path

# 导入日志模块
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from log import info, success, warning, error, section_header, package_start, package_update

class PackageInstaller:
    """包安装管理器"""

    def __init__(self):
        self.interrupted = False
        self.default_timeout = 200
        self.manager = "paru"
        self.run_as_root = False

        # 注册信号处理器
        signal.signal(signal.SIGINT, self.handle_interrupt)

    # ==================== 信号处理模块 ====================
    def handle_interrupt(self, signum, frame):
        """处理中断信号"""
        error("检测到中断信号 (Ctrl+C)，正在退出...")
        self.interrupted = True
        sys.exit(1)

    def check_interrupted(self):
        """检查是否被中断"""
        if self.interrupted:
            warning("操作被用户中断")
            return True
        return False

    # ==================== 系统检查模块 ====================
    def check_root_privileges(self):
        """检查root权限"""
        return os.geteuid() == 0

    def check_package_installed(self, pkg_name):
        """检查包是否已安装"""
        try:
            result = subprocess.run(
                ["pacman", "-Q", pkg_name],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except Exception:
            return False

    def validate_package_manager(self):
        """验证包管理器是否可用"""
        if self.run_as_root and self.manager != "pacman":
            error(f"不能以root用户使用 {self.manager}")
            warning("请以普通用户运行脚本或使用 pacman")
            return False
        return True

    # ==================== 命令执行模块 ====================
    def run_with_timeout(self, cmd, timeout=None):
        """带超时的命令执行"""
        if timeout is None:
            timeout = self.default_timeout

        try:
            result = subprocess.run(
                cmd,
                shell=True,
                timeout=timeout,
                capture_output=True,
                text=True
            )
            return result.returncode == 0, result.stderr
        except subprocess.TimeoutExpired:
            return False, f"命令执行超时 ({timeout} 秒)"
        except Exception as e:
            return False, str(e)

    # ==================== 包命令构建模块 ====================
    def build_install_command(self, pkg_name):
        """构建安装命令"""
        # 特殊处理 archlinuxcn-keyring
        if pkg_name == "archlinuxcn-keyring":
            if self.run_as_root:
                return "pacman -Sy --noconfirm archlinuxcn-keyring"
            else:
                return "sudo pacman -Sy --noconfirm archlinuxcn-keyring"

        if self.manager == "pacman":
            if self.run_as_root:
                return f"pacman -S --noconfirm {pkg_name}"
            else:
                return f"sudo pacman -S --noconfirm {pkg_name}"
        elif self.manager == "yay":
            return f"yay -S --noconfirm {pkg_name}"
        else:  # 默认使用 paru
            return f"paru -S --noconfirm --skipreview {pkg_name}"

    # ==================== 配置解析模块 ====================
    def parse_config_file(self, config_file):
        """解析配置文件"""
        sections = {}
        current_section = None

        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                for line in f:
                    if self.check_interrupted():
                        return sections

                    line = line.strip()

                    # 跳过空行和纯注释行
                    if not line or line.startswith('#'):
                        continue

                    # 检测部分头
                    if line.startswith('[') and line.endswith(']'):
                        current_section = line[1:-1].strip()
                        sections[current_section] = []
                    elif current_section is not None:
                        # 跳过被注释的命令
                        if not line.startswith('#'):
                            sections[current_section].append(line)

        except FileNotFoundError:
            error(f"配置文件不存在: {config_file}")
            sys.exit(1)
        except Exception as e:
            error(f"读取配置文件时出错: {e}")
            sys.exit(1)

        return sections

    def parse_package_line(self, cmd_line):
        """解析包命令行"""
        if '#' in cmd_line:
            pkg_name, comment = cmd_line.split('#', 1)
            pkg_name = pkg_name.strip()
            comment = comment.strip()
        else:
            pkg_name = cmd_line.strip()
            comment = ""

        return pkg_name, comment

    # ==================== 包安装处理模块 ====================
    def install_single_package(self, index, total, pkg_name, comment=""):
        """安装单个包"""
        # 显示开始安装状态
        package_start(index, total, pkg_name, comment)

        # 检查包是否已安装
        if self.check_package_installed(pkg_name):
            package_update("SKIP")
            return True

        # 构建并执行安装命令
        install_cmd = self.build_install_command(pkg_name)
        success, error_msg = self.run_with_timeout(install_cmd)

        if success:
            package_update("DONE")
            return True
        else:
            if self.check_interrupted():
                error(f"命令被中断: {pkg_name}")
                return False

            package_update("FAIL", error_msg)
            return False

    def process_section(self, section_name, commands):
        """处理单个配置部分"""
        total_commands = len(commands)

        # 显示部分标题
        section_header(section_name, self.manager)

        for index, cmd_line in enumerate(commands, 1):
            # 检查是否中断
            if self.check_interrupted():
                return

            # 解析包信息
            pkg_name, comment = self.parse_package_line(cmd_line)

            # 跳过空行
            if not pkg_name:
                continue

            # 安装包
            self.install_single_package(index, total_commands, pkg_name, comment)

    # ==================== 主安装模块 ====================
    def pkginstall(self, config_file):
        """主安装函数"""
        if not config_file:
            error("用法: 需要指定配置文件路径")
            sys.exit(1)

        # 检查文件是否存在
        if not os.path.exists(config_file):
            error(f"配置文件不存在: {config_file}")
            sys.exit(1)

        # 解析配置文件
        sections = self.parse_config_file(config_file)

        if not sections:
            warning("配置文件中没有找到有效的部分")
            return

        # 处理每个部分
        for section_name, commands in sections.items():
            if self.check_interrupted():
                break

            if commands:  # 只处理有命令的部分
                self.process_section(section_name, commands)

    # ==================== 初始化设置模块 ====================
    def setup_environment(self):
        """设置环境"""
        # 设置包管理器
        self.manager = "paru"

        # 检查运行身份
        self.run_as_root = self.check_root_privileges()

        if self.run_as_root:
            warning("以root用户运行脚本")

        # 验证包管理器
        if not self.validate_package_manager():
            sys.exit(1)

        # 显示当前状态
        info("=" * 50)
        success(f"使用包管理器: {self.manager}")
        if self.run_as_root:
            success(f"运行身份: root")
        else:
            success(f"运行身份: {os.getenv('USER', 'unknown')}")
        info("=" * 50)

    def install_archlinuxcn_keyring(self):
        """安装 archlinuxcn-keyring"""
        if not self.check_package_installed("archlinuxcn-keyring"):
            warning("安装 archlinuxcn-keyring...")
            cmd = "pacman -Sy --noconfirm archlinuxcn-keyring"
            if not self.run_as_root:
                cmd = "sudo " + cmd

            success, error_msg = self.run_with_timeout(cmd)
            if success:
                success("archlinuxcn-keyring 安装成功")
            else:
                error(f"archlinuxcn-keyring 安装失败: {error_msg}")
                return False
        return True

    # ==================== 主入口模块 ====================
    def setup(self):
        """主设置函数"""
        try:
            # 环境设置
            self.setup_environment()

            # 安装 archlinuxcn-keyring
            if not self.install_archlinuxcn_keyring():
                error("archlinuxcn-keyring 安装失败，无法继续")
                return

            # 执行包安装
            config_path = os.path.join("lib", "pkgs.conf")
            self.pkginstall(config_path)

            # 可以在这里添加其他设置脚本
            # self.run_additional_scripts()

            success("包安装完成！")

        except Exception as e:
            error(f"安装过程中出现错误: {e}")
            sys.exit(1)

    def run_additional_scripts(self):
        """运行附加脚本"""
        scripts = ["zsh_setup.sh", "grub_setup.sh", "actions.sh"]

        for script in scripts:
            if os.path.exists(script):
                info(f"执行脚本: {script}")
                try:
                    subprocess.run(["sh", script], check=True)
                    success(f"{script} 执行成功")
                except subprocess.CalledProcessError as e:
                    error(f"{script} 执行失败: {e}")

def main():
    """主函数"""
    installer = PackageInstaller()
    installer.setup()

if __name__ == "__main__":
    main()
