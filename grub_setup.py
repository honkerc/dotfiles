#!/usr/bin/env python3
"""
GRUB 主题安装脚本 - Python 版本
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path

# 导入日志模块
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from log import info, success, warning, error, section_header

class GrubThemeInstaller:
    def __init__(self):
        self.config = {
            'origin_name': 'lib/grub',
            'theme_name': 'simple',
            'theme_dir': '/boot/grub/themes',
            'grub_config': '/etc/default/grub'
        }

    def run_command(self, command, shell=False, check=True):
        """运行命令并处理输出"""
        try:
            if shell:
                result = subprocess.run(command, shell=True, check=check,
                                      capture_output=True, text=True)
            else:
                result = subprocess.run(command, check=check,
                                      capture_output=True, text=True)

            # 记录命令执行
            if isinstance(command, list):
                command_str = ' '.join(command)
            else:
                command_str = command
            info(f"执行命令: {command_str}")

            return result
        except subprocess.CalledProcessError as e:
            error(f"命令执行失败: {e}")
            if check:
                raise
            return None

    def check_root_privileges(self):
        """检查root权限"""
        if os.geteuid() != 0:
            error("请使用 sudo 或以 root 用户运行此脚本")
            return False
        return True

    def check_theme_files(self):
        """检查主题文件是否存在"""
        section_header("检查主题文件")

        if not os.path.exists(self.config['origin_name']):
            error(f"主题文件夹 '{self.config['origin_name']}' 在当前目录中未找到")
            return False

        info(f"找到主题文件夹: {self.config['origin_name']}")
        success("主题文件检查完成")
        return True

    def create_theme_directory(self):
        """创建主题目录"""
        section_header("创建主题目录")

        theme_path = os.path.join(self.config['theme_dir'], self.config['theme_name'])
        info(f"创建主题目录: {theme_path}")

        try:
            os.makedirs(theme_path, exist_ok=True)
            success(f"主题目录创建成功: {theme_path}")
            return True
        except Exception as e:
            error(f"创建主题目录失败: {e}")
            return False

    def copy_theme_files(self):
        """复制主题文件"""
        section_header("复制主题文件")

        source_dir = self.config['origin_name']
        target_dir = os.path.join(self.config['theme_dir'], self.config['theme_name'])

        info(f"从 {source_dir} 复制文件到 {target_dir}")

        try:
            # 检查源目录是否存在
            if not os.path.exists(source_dir):
                error(f"源目录不存在: {source_dir}")
                return False

            # 复制所有文件
            for item in os.listdir(source_dir):
                source_path = os.path.join(source_dir, item)
                target_path = os.path.join(target_dir, item)

                if os.path.isdir(source_path):
                    shutil.copytree(source_path, target_path, dirs_exist_ok=True)
                    info(f"复制目录: {item}")
                else:
                    shutil.copy2(source_path, target_path)
                    info(f"复制文件: {item}")

            success("主题文件复制完成")
            return True

        except Exception as e:
            error(f"复制主题文件失败: {e}")
            return False

    def backup_grub_config(self):
        """备份 GRUB 配置"""
        section_header("备份 GRUB 配置")

        backup_file = f"{self.config['grub_config']}.bak"

        info(f"备份 GRUB 配置: {self.config['grub_config']} -> {backup_file}")

        try:
            if os.path.exists(self.config['grub_config']):
                shutil.copy2(self.config['grub_config'], backup_file)
                success(f"备份创建成功: {backup_file}")
                return True
            else:
                error(f"GRUB 配置文件不存在: {self.config['grub_config']}")
                return False

        except Exception as e:
            error(f"备份 GRUB 配置失败: {e}")
            return False

    def update_grub_config(self):
        """更新 GRUB 配置"""
        section_header("更新 GRUB 配置")

        theme_path = os.path.join(self.config['theme_dir'], self.config['theme_name'], 'theme.txt')
        theme_config = f'GRUB_THEME="{theme_path}"'

        info(f"设置主题: {self.config['theme_name']}")
        info(f"主题路径: {theme_path}")

        try:
            # 读取现有配置
            with open(self.config['grub_config'], 'r', encoding='utf-8') as f:
                lines = f.readlines()

            # 移除现有的 GRUB_THEME 配置
            new_lines = []
            for line in lines:
                if not line.strip().startswith('GRUB_THEME='):
                    new_lines.append(line)

            # 添加新的主题配置
            new_lines.append(f'{theme_config}\n')

            # 写回配置文件
            with open(self.config['grub_config'], 'w', encoding='utf-8') as f:
                f.writelines(new_lines)

            success(f"主题配置已添加到: {self.config['grub_config']}")
            return True

        except Exception as e:
            error(f"更新 GRUB 配置失败: {e}")
            return False

    def update_grub(self):
        """更新 GRUB"""
        section_header("更新 GRUB 配置")

        update_commands = [
            ['update-grub'],
            ['grub-mkconfig', '-o', '/boot/grub/grub.cfg'],
            ['grub2-mkconfig', '-o', '/boot/grub/grub.cfg']
        ]

        success_flag = False

        for cmd in update_commands:
            if shutil.which(cmd[0]):
                info(f"使用命令: {' '.join(cmd)}")
                try:
                    self.run_command(cmd)
                    success("GRUB 配置更新成功")
                    success_flag = True
                    break
                except Exception as e:
                    warning(f"命令 {cmd[0]} 执行失败: {e}")
                    continue

        if not success_flag:
            warning("无法找到可用的 GRUB 更新命令")
            warning("请手动运行以下命令之一:")
            warning("  update-grub")
            warning("  grub-mkconfig -o /boot/grub/grub.cfg")
            warning("  grub2-mkconfig -o /boot/grub/grub.cfg")
            return False

        return True

    def show_summary(self):
        """显示安装总结"""
        section_header("安装完成")
        success("GRUB 主题安装完成!")

        info("安装信息:")
        info(f"  主题名称: {self.config['theme_name']}")
        info(f"  安装路径: {self.config['theme_dir']}/{self.config['theme_name']}")
        info(f"  配置文件: {self.config['grub_config']}")

        warning("请重启系统以查看效果:")
        info("  sudo reboot")

    def main_installation(self):
        """主安装流程"""
        try:
            section_header("GRUB 主题安装")

            # 检查前置条件
            if not self.check_root_privileges():
                return

            if not self.check_theme_files():
                return

            # 执行安装步骤
            installation_steps = [
                self.create_theme_directory,
                self.copy_theme_files,
                self.backup_grub_config,
                self.update_grub_config,
                self.update_grub
            ]

            for step in installation_steps:
                step_name = step.__name__
                if not step():
                    error(f"步骤 {step_name} 执行失败")
                    return

            self.show_summary()

        except KeyboardInterrupt:
            error("\n安装被用户中断")
        except Exception as e:
            error(f"安装过程中出现错误: {e}")
            import traceback
            error(f"详细错误信息: {traceback.format_exc()}")

def debug_single_function():
    """调试单个功能"""
    installer = GrubThemeInstaller()

    functions = {
        '1': ('检查主题文件', installer.check_theme_files),
        '2': ('创建主题目录', installer.create_theme_directory),
        '3': ('复制主题文件', installer.copy_theme_files),
        '4': ('备份GRUB配置', installer.backup_grub_config),
        '5': ('更新GRUB配置', installer.update_grub_config)
    }

    section_header("调试模式")
    print("选择要调试的功能:")
    for key, (name, _) in functions.items():
        print(f"  {key}. {name}")

    choice = input("输入选择 (1-5): ").strip()
    if choice in functions:
        name, func = functions[choice]
        section_header(f"调试: {name}")
        try:
            # 对于某些功能需要先设置环境
            if choice in ['2', '3', '4', '5']:
                if not installer.check_root_privileges():
                    return
                if choice in ['2', '3'] and not installer.check_theme_files():
                    return

            func()
            success(f"{name} 调试完成")
        except Exception as e:
            error(f"{name} 调试失败: {e}")
    else:
        error("无效的选择")

def main():
    """主函数"""
    # 解析命令行参数
    if len(sys.argv) > 1 and sys.argv[1] == "debug":
        debug_single_function()
        return

    # 开始安装
    installer = GrubThemeInstaller()
    installer.main_installation()

if __name__ == "__main__":
    main()
