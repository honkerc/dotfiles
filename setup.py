#!/usr/bin/env python3
"""
系统服务配置器 - 严格遵循日志模块格式
"""

import os
import sys
import subprocess

# 导入日志模块
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from log import info, success, warning, error, section_header, package_start, package_update


class ServiceConfigurator:
    """系统服务配置器类 - 严格遵循日志模块格式"""
    
    def __init__(self, config_file="lib/actions.conf"):
        self.config_file = config_file
        self.sections = {}
        self.home_dir = os.path.expanduser("~")
        self.current_dir = os.getcwd()
    
    def parse_config(self):
        """解析配置文件 - 只识别 [] 作为节标题"""
        if not os.path.exists(self.config_file):
            error(f"配置文件 {self.config_file} 不存在")
            return False
        
        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            current_section = None
            
            for line in lines:
                stripped_line = line.strip()
                
                # 跳过空行
                if not stripped_line:
                    continue
                
                # 只识别 [节标题] 作为节分隔
                if stripped_line.startswith('[') and stripped_line.endswith(']'):
                    current_section = stripped_line[1:-1].strip()
                    self.sections[current_section] = []
                    continue
                
                # 如果当前不在任何节中，跳过
                if current_section is None:
                    continue
                
                # 处理命令和备注
                if '#' in line:
                    # 分离命令和备注
                    parts = line.split('#', 1)
                    command = parts[0].strip()
                    description = parts[1].strip()
                else:
                    # 没有备注，使用命令本身作为描述
                    command = ""
                    description = command
                
                # 跳过空命令
                if command:
                    self.sections[current_section].append((command, description))
            
            return True
            
        except Exception as e:
            error(f"解析配置文件失败: {str(e)}")
            return False
    
    def run_command(self, index, total, command, description):
        """运行单个命令 - 使用 package_update 显示状态"""
        # 开始执行命令
        package_start(index, total, command, description)
        
        # 替换路径变量
        command = command.replace('$HOME', self.home_dir)
        command = command.replace('~', self.home_dir)
        
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True,
                cwd=self.current_dir
            )
            
            if result.returncode == 0:
                package_update("DONE")
                return True
            else:
                error_msg = result.stderr.strip() if result.stderr else "命令执行失败"
                package_update("FAIL", error_msg)
                return False
                
        except Exception as e:
            package_update("FAIL", str(e))
            return False
    
    def execute_section(self, section_name):
        """执行特定节的命令"""
        if section_name not in self.sections:
            error(f"配置节 '{section_name}' 不存在")
            return False
        
        section_header(section_name)
        
        commands = self.sections[section_name]
        success_count = 0
        
        for index, (command, description) in enumerate(commands, 1):
            if self.run_command(index, len(commands), command, description):
                success_count += 1
        
        return success_count == len(commands)
    
    def execute_all(self):
        """执行所有配置节的命令"""
        if not self.sections:
            error("没有可执行的配置节")
            return False
        
        total_success = 0
        total_commands = 0
        
        for section_name in self.sections:
            commands_count = len(self.sections[section_name])
            total_commands += commands_count
            
            if self.execute_section(section_name):
                total_success += commands_count
        
        info(f"总体完成: {total_success}/{total_commands}")
        
        if total_success == total_commands:
            success("所有服务配置完成!")
            return True
        else:
            warning("部分服务配置失败")
            return False


def main():
    """主函数"""
    configurator = ServiceConfigurator("lib/actions.conf")
    
    if not configurator.parse_config():
        sys.exit(1)
    
    if configurator.execute_all():
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()