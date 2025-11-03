#!/usr/bin/env python3
"""
Arch Linux 基础系统安装脚本
带完整日志记录功能
"""

import os
import sys
import subprocess
import time
import logging
from dataclasses import dataclass
from typing import List
from pathlib import Path

# 导入日志模块
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from log import info, success, warning, error, section_header, package_start, package_update

@dataclass
class InstallConfig:
    """安装配置数据类"""
    # 磁盘配置
    install_disk: str = "/dev/nvme0n1"
    efi_size: str = "+2048M"
    root_size: str = "+100G"
    home_size: str = "+100G"
    swap_size: str = "+100G"
    # 系统配置
    hostname: str = "archlinux"
    username: str = "clay"
    timezone: str = "Asia/Shanghai"
    locale: str = "en_US.UTF-8"
    
    # 基础软件包
    base_packages: List[str] = None
    
    # 日志配置
    log_file: str = "/var/log/arch-install.log"
    
    def __post_init__(self):
        """初始化默认值"""
        if self.base_packages is None:
            self.base_packages = [
                "base", "base-devel", "linux-lts", "linux-lts-headers", "linux-firmware",
                "git", "neovim", "networkmanager", "grub", "efibootmgr", "intel-ucode"
            ]

class ArchInstaller:
    def __init__(self, config: InstallConfig = None):
        self.config = config or InstallConfig()
        self.partition_map = {}
        self.setup_file_logging()
    
    def setup_file_logging(self):
        """设置文件日志记录"""
        section_header("日志系统初始化")
        
        try:
            # 确保日志目录存在
            log_dir = os.path.dirname(self.config.log_file)
            os.makedirs(log_dir, exist_ok=True)
            
            # 设置文件日志处理器
            file_handler = logging.FileHandler(self.config.log_file, encoding='utf-8')
            file_handler.setLevel(logging.INFO)
            formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
            file_handler.setFormatter(formatter)
            
            # 获取根日志记录器并添加文件处理器
            root_logger = logging.getLogger()
            root_logger.setLevel(logging.INFO)
            root_logger.addHandler(file_handler)
            
            info(f"日志文件: {self.config.log_file}")
            success("日志系统初始化完成")
            
        except Exception as e:
            error(f"设置文件日志失败: {e}")
    
    def log_command_output(self, command, output):
        """记录命令执行输出到文件"""
        logging.info(f"执行命令: {command}")
        if output:
            logging.info(f"命令输出: {output}")
    
    def run_command(self, command, shell=False, check=True, capture_output=True):
        """运行命令并处理输出"""
        try:
            # 打印执行的命令
            if isinstance(command, list):
                command_str = ' '.join(command)
            else:
                command_str = command
            info(f"执行命令: {command_str}")
            
            if shell:
                result = subprocess.run(command, shell=True, check=check, 
                                      capture_output=capture_output, text=True)
            else:
                result = subprocess.run(command, check=check, 
                                      capture_output=capture_output, text=True)
            
            # 记录命令和输出到文件
            if capture_output:
                self.log_command_output(command_str, result.stderr)
            
            return result
        except subprocess.CalledProcessError as e:
            error_msg = f"命令执行失败: {e}"
            if capture_output and e.stderr:
                error_msg += f"\n错误输出: {e.stderr}"
            
            error(error_msg)
            logging.error(error_msg)
            
            if check:
                raise
            return None
    
    def get_partition_path(self, partition_number):
        """获取分区路径"""
        if "nvme" in self.config.install_disk:
            return f"{self.config.install_disk}p{partition_number}"
        else:
            return f"{self.config.install_disk}{partition_number}"
    
    def get_user_input(self):
        """获取用户输入"""
        section_header("安装配置")
        logging.info("开始 Arch Linux 安装流程")
        
        # 显示磁盘信息
        info("显示磁盘信息...")
        self.run_command(["lsblk"])
        self.run_command(["fdisk", "-l"])
        
        disk = input(f"输入要安装系统的磁盘 [{self.config.install_disk}]: ").strip()
        if disk:
            self.config.install_disk = disk
        
        hostname = input(f"输入主机名 [{self.config.hostname}]: ").strip()
        if hostname:
            self.config.hostname = hostname
        
        username = input(f"输入用户名 [{self.config.username}]: ").strip()
        if username:
            self.config.username = username
        
        warning(f"这将清除磁盘 {self.config.install_disk} 上的所有数据!")
        confirmation = input("确认继续? (输入 'YES' 继续): ")
        
        if confirmation != "YES":
            error("安装已取消")
            logging.info("安装被用户取消")
            sys.exit(1)
        
        logging.info(f"安装配置 - 磁盘: {self.config.install_disk}, 主机名: {self.config.hostname}, 用户名: {self.config.username}")
        success("安装配置完成")
    
    def setup_network(self):
        """设置网络连接"""
        section_header("网络设置")
        logging.info("开始网络设置")
        
        # 测试网络连接
        info("测试网络连接...")
        result = self.run_command(["ping", "-c", "1", "-W", "3", "archlinux.org"], 
                                capture_output=True)
        
        if result.returncode != 0:
            warning("网络连接失败，请手动配置网络")
            logging.warning("网络连接测试失败")
            info("可用命令:")
            info("  iwctl device list")
            info("  iwctl station wlan0 scan") 
            info("  iwctl station wlan0 connect SSID")
            info("或者使用有线网络")
            input("按回车键继续...")
        
        success("网络设置完成")
        logging.info("网络设置完成")
        return True
    
    def update_system_clock(self):
        """更新系统时钟"""
        section_header("系统时钟设置")
        logging.info("更新系统时钟")
        
        info("设置系统时钟自动同步...")
        self.run_command(["timedatectl", "set-ntp", "true"])
        
        info("显示当前系统时钟状态...")
        self.run_command(["timedatectl", "status"])
        
        success("系统时钟更新完成")
        logging.info("系统时钟更新完成")
        return True
    
    def partition_disk(self):
        """磁盘分区"""
        section_header("磁盘分区")
        logging.info("开始磁盘分区")
        
        partition_commands = f"""
g
n
1

{self.config.efi_size}
n
2

{self.config.root_size}
n
3

{self.config.home_size}
n
4

{self.config.swap_size}
t
4
19
w
"""
        info("开始分区...")
        info(f"分区命令:\n{partition_commands}")
        
        self.run_command(f"echo '{partition_commands}' | fdisk {self.config.install_disk}", shell=True)
        
        # 更新分区映射
        self.partition_map = {
            'efi': self.get_partition_path(1),
            'root': self.get_partition_path(2),
            'home': self.get_partition_path(3),
            'swap': self.get_partition_path(4)
        }
        
        success("分区完成")
        logging.info(f"分区完成: {self.partition_map}")
        
        info("显示分区结果...")
        self.run_command(["fdisk", "-l", self.config.install_disk])
        return True
    
    def format_partitions(self):
        """格式化分区"""
        section_header("分区格式化")
        logging.info("开始格式化分区")
        
        info("格式化EFI分区...")
        self.run_command(["mkfs.fat", "-F", "32", self.partition_map['efi']])
        
        info("格式化根分区...")
        self.run_command(["mkfs.ext4", self.partition_map['root']])
        
        info("格式化home分区...")
        self.run_command(["mkfs.ext4", self.partition_map['home']])
        
        info("设置交换分区...")
        self.run_command(["mkswap", self.partition_map['swap']])
        
        success("分区格式化完成")
        logging.info("分区格式化完成")
        return True
    
    def mount_filesystems(self):
        """挂载文件系统"""
        section_header("文件系统挂载")
        logging.info("开始挂载文件系统")
        
        # 挂载根分区
        info("挂载根分区...")
        self.run_command(["mount", self.partition_map['root'], "/mnt"])
        
        # 创建挂载点并挂载其他分区
        info("创建挂载点...")
        info("创建 /mnt/boot/efi 目录...")
        os.makedirs("/mnt/boot/efi", exist_ok=True)
        self.run_command(["mount", self.partition_map['efi'], "/mnt/boot/efi"])
        
        info("创建 /mnt/home 目录...")
        os.makedirs("/mnt/home", exist_ok=True)
        self.run_command(["mount", self.partition_map['home'], "/mnt/home"])
        
        # 启用交换分区
        info("启用交换分区...")
        self.run_command(["swapon", self.partition_map['swap']])
        
        success("文件系统挂载完成")
        logging.info("文件系统挂载完成")
        return True
    
    def configure_mirrors(self):
        """配置镜像源"""
        section_header("镜像源配置")
        logging.info("配置镜像源")
        
        # 备份原有镜像列表
        info("备份原有镜像列表...")
        self.run_command(["cp", "/etc/pacman.d/mirrorlist", "/etc/pacman.d/mirrorlist.backup"])
        
        # 使用中国镜像源
        mirrorlist_content = """Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch
"""
        info("配置中国镜像源...")
        with open("/etc/pacman.d/mirrorlist", "w") as f:
            f.write(mirrorlist_content)
        
        # 更新包数据库
        info("更新包数据库...")
        self.run_command(["pacman", "-Syy"])
        
        success("镜像源配置完成")
        logging.info("镜像源配置完成")
        return True
    
    def install_base_system(self):
        """安装基本系统"""
        section_header("基本系统安装")
        logging.info("开始安装基本系统")
        
        info(f"安装基础包: {', '.join(self.config.base_packages)}")
        logging.info(f"安装软件包: {self.config.base_packages}")
        
        info("执行 pacstrap 安装命令...")
        self.run_command(["pacstrap", "/mnt"] + self.config.base_packages)
        
        success("基本系统安装完成")
        logging.info("基本系统安装完成")
        return True
    
    def generate_fstab(self):
        """生成fstab"""
        section_header("fstab生成")
        logging.info("生成 fstab 文件")
        
        info("生成 fstab 文件...")
        self.run_command(["genfstab", "-U", "/mnt", ">>", "/mnt/etc/fstab"], shell=True)
        
        info("显示生成的fstab内容:")
        self.run_command(["cat", "/mnt/etc/fstab"])
        
        success("fstab生成完成")
        logging.info("fstab 生成完成")
        return True
    
    def chroot_configure_system(self):
        """chroot环境配置系统"""
        section_header("系统配置")
        logging.info("开始在 chroot 环境中配置系统")
        
        chroot_script = f"""#!/bin/bash
set -e

echo "配置时区..."
ln -sf /usr/share/zoneinfo/{self.config.timezone} /etc/localtime
hwclock --systohc

echo "配置本地化..."
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen
locale-gen

echo "LANG={self.config.locale}" > /etc/locale.conf

echo "配置网络..."
echo "{self.config.hostname}" > /etc/hostname

cat > /etc/hosts << EOH
127.0.0.1   localhost
::1         localhost
127.0.1.1   {self.config.hostname}.localdomain {self.config.hostname}
EOH

echo "设置root密码..."
passwd

echo "创建用户 {self.config.username}..."
useradd -m -G wheel -s /bin/bash {self.config.username}
echo "设置用户 {self.config.username} 密码:"
passwd {self.config.username}

echo "配置sudo..."
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

echo "安装引导程序..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "启用NetworkManager..."
systemctl enable NetworkManager

echo "基础系统配置完成"
"""
        
        script_path = "/mnt/root/chroot_configure.sh"
        info(f"创建 chroot 配置脚本: {script_path}")
        with open(script_path, "w") as f:
            f.write(chroot_script)
        
        info("设置脚本执行权限...")
        self.run_command(["chmod", "+x", script_path])
        
        info("进入chroot环境配置系统...")
        self.run_command(["arch-chroot", "/mnt", "/bin/bash", "/root/chroot_configure.sh"])
        
        success("系统配置完成")
        logging.info("系统配置完成")
        return True
    
    def show_summary(self):
        """显示安装总结"""
        section_header("安装完成")
        success("Arch Linux 基础系统安装完成!")
        logging.info("Arch Linux 安装完成")
        
        print("=" * 50)
        print(f"用户名: {self.config.username}")
        print(f"主机名: {self.config.hostname}") 
        print(f"安装磁盘: {self.config.install_disk}")
        print("引导方式: UEFI + GRUB")
        print("=" * 50)
        info("下一步操作:")
        info("1. 退出chroot环境: exit")
        info("2. 卸载文件系统: umount -R /mnt")
        info("3. 重启系统: reboot")
        info("4. 登录后继续配置桌面环境和其他软件")
        info(f"5. 查看安装日志: {self.config.log_file}")
        print("=" * 50)
    
    def main_installation(self):
        """主安装流程"""
        try:
            # 获取用户输入
            self.get_user_input()
            
            # 执行安装步骤
            installation_steps = [
                self.setup_network,
                self.update_system_clock,
                self.partition_disk,
                self.format_partitions,
                self.mount_filesystems,
                self.configure_mirrors,
                self.install_base_system,
                self.generate_fstab,
                self.chroot_configure_system
            ]
            
            for step in installation_steps:
                step_name = step.__name__
                section_header(f"执行步骤: {step_name}")
                logging.info(f"开始执行步骤: {step_name}")
                
                if not step():
                    error(f"步骤 {step_name} 执行失败")
                    logging.error(f"步骤 {step_name} 执行失败")
                    break
                else:
                    logging.info(f"步骤 {step_name} 完成")
            
            self.show_summary()
            
        except KeyboardInterrupt:
            error("\n安装被用户中断")
            logging.info("安装被用户中断")
            sys.exit(1)
        except Exception as e:
            error(f"安装过程中出现错误: {e}")
            logging.error(f"安装过程中出现错误: {e}")
            import traceback
            logging.error(traceback.format_exc())
            sys.exit(1)

def debug_single_function():
    """调试单个功能"""
    installer = ArchInstaller()
    
    functions = {
        '1': ('网络设置', installer.setup_network),
        '2': ('磁盘分区', installer.partition_disk),
        '3': ('格式化分区', installer.format_partitions),
        '4': ('文件系统挂载', installer.mount_filesystems),
        '5': ('镜像源配置', installer.configure_mirrors),
        '6': ('基本系统安装', installer.install_base_system)
    }
    
    section_header("调试模式")
    print("选择要调试的功能:")
    for key, (name, _) in functions.items():
        print(f"  {key}. {name}")
    
    choice = input("输入选择 (1-6): ").strip()
    if choice in functions:
        name, func = functions[choice]
        section_header(f"调试: {name}")
        try:
            func()
            success(f"{name} 调试完成")
        except Exception as e:
            error(f"{name} 调试失败: {e}")
    else:
        error("无效的选择")

def main():
    """主函数"""
    # 检查是否以root运行
    if os.geteuid() != 0:
        error("此脚本需要root权限运行")
        sys.exit(1)
    
    # 解析命令行参数
    if len(sys.argv) > 1 and sys.argv[1] == "debug":
        debug_single_function()
        return
    
    # 开始安装
    installer = ArchInstaller()
    installer.main_installation()

if __name__ == "__main__":
    main()