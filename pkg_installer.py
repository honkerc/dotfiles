#!/usr/bin/env python3
"""
Package Installation Manager - Single-class modular version
"""

import os
import sys
import subprocess
import signal
from pathlib import Path

# Import logging module
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from log import info, success, warning, error, section_header, package_start, package_update


class PackageInstaller:
    """Package installation manager"""

    def __init__(self):
        self.interrupted = False
        self.default_timeout = 200
        self.manager = "paru"
        self.run_as_root = False

        # Register signal handler
        signal.signal(signal.SIGINT, self.handle_interrupt)

    # ==================== Signal handling ====================
    def handle_interrupt(self, signum, frame):
        """Handle interrupt signal"""
        error("Interrupt signal detected (Ctrl+C), exiting...")
        self.interrupted = True
        sys.exit(1)

    def check_interrupted(self):
        """Check if interrupted"""
        if self.interrupted:
            warning("Operation interrupted by user")
            return True
        return False

    # ==================== System checks ====================
    def check_root_privileges(self):
        """Check root privileges"""
        return os.geteuid() == 0

    def check_package_installed(self, pkg_name):
        """Check if a package is already installed"""
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
        """Validate package manager availability"""
        if self.run_as_root and self.manager != "pacman":
            error(f"Cannot use {self.manager} as root")
            warning("Please run the script as a normal user or use pacman")
            return False
        return True

    # ==================== Command execution ====================
    def run_with_timeout(self, cmd, timeout=None):
        """Execute a command with a timeout"""
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
            return False, f"Command timed out ({timeout}s)"
        except Exception as e:
            return False, str(e)

    # ==================== Command construction ====================
    def build_install_command(self, pkg_name):
        """Build the install command"""
        if self.manager == "pacman":
            if self.run_as_root:
                return f"pacman -S --noconfirm {pkg_name}"
            else:
                return f"sudo pacman -S --noconfirm {pkg_name}"
        elif self.manager == "yay":
            return f"yay -S --noconfirm {pkg_name}"
        else:  # default to paru
            return f"paru -S --noconfirm --skipreview {pkg_name}"

    # ==================== Config parsing ====================
    def parse_config_file(self, config_file):
        """Parse the config file"""
        sections = {}
        current_section = None

        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                for line in f:
                    if self.check_interrupted():
                        return sections

                    line = line.strip()

                    # Skip empty lines and pure comment lines
                    if not line or line.startswith('#'):
                        continue

                    # Detect section header
                    if line.startswith('[') and line.endswith(']'):
                        current_section = line[1:-1].strip()
                        sections[current_section] = []
                    elif current_section is not None:
                        # Skip commented commands
                        if not line.startswith('#'):
                            sections[current_section].append(line)

        except FileNotFoundError:
            error(f"Config file not found: {config_file}")
            sys.exit(1)
        except Exception as e:
            error(f"Error reading config file: {e}")
            sys.exit(1)

        return sections

    def parse_package_line(self, cmd_line):
        """Parse a package line"""
        if '#' in cmd_line:
            pkg_name, comment = cmd_line.split('#', 1)
            pkg_name = pkg_name.strip()
            comment = comment.strip()
        else:
            pkg_name = cmd_line.strip()
            comment = ""

        return pkg_name, comment

    # ==================== Package installation ====================
    def install_single_package(self, index, total, pkg_name, comment=""):
        """Install a single package"""
        # Show start status
        package_start(index, total, pkg_name, comment)

        # Check if already installed
        if self.check_package_installed(pkg_name):
            package_update("SKIP")
            return True

        # Build and run install command
        install_cmd = self.build_install_command(pkg_name)
        ok, error_msg = self.run_with_timeout(install_cmd)

        if ok:
            package_update("DONE")
            return True
        else:
            if self.check_interrupted():
                error(f"Command interrupted: {pkg_name}")
                return False

            package_update("FAIL", error_msg)
            return False

    def process_section(self, section_name, commands):
        """Process a single config section"""
        total_commands = len(commands)

        # Show section header
        section_header(section_name, self.manager)

        for index, cmd_line in enumerate(commands, 1):
            if self.check_interrupted():
                return

            pkg_name, comment = self.parse_package_line(cmd_line)

            if not pkg_name:
                continue

            self.install_single_package(index, total_commands, pkg_name, comment)

    # ==================== Main install logic ====================
    def pkginstall(self, config_file):
        """Main installation function"""
        if not config_file:
            error("Usage: a config file path is required")
            sys.exit(1)

        if not os.path.exists(config_file):
            error(f"Config file not found: {config_file}")
            sys.exit(1)

        sections = self.parse_config_file(config_file)

        if not sections:
            warning("No valid sections found in the config file")
            return

        for section_name, commands in sections.items():
            if self.check_interrupted():
                break

            if commands:
                self.process_section(section_name, commands)

    # ==================== Environment setup ====================
    def setup_environment(self):
        """Set up the environment"""
        # Set package manager
        self.manager = "paru"

        # Check running identity
        self.run_as_root = self.check_root_privileges()

        if self.run_as_root:
            warning("Running as root")

        # Validate package manager
        if not self.validate_package_manager():
            sys.exit(1)

        # Show current status
        info("=" * 50)
        success(f"Package manager: {self.manager}")
        if self.run_as_root:
            success("Running as: root")
        else:
            success(f"Running as: {os.getenv('USER', 'unknown')}")
        info("=" * 50)

    # ==================== Main entry ====================
    def setup(self):
        """Main setup function"""
        try:
            # Environment setup
            self.setup_environment()

            # Run package installation
            config_path = os.path.join("lib", "pkgs.conf")
            self.pkginstall(config_path)

            # Additional scripts can be added here
            # self.run_additional_scripts()

            success("Package installation complete!")

        except Exception as e:
            error(f"Error during installation: {e}")
            sys.exit(1)

    def run_additional_scripts(self):
        """Run additional scripts"""
        scripts = ["zsh_setup.sh", "grub_setup.sh", "actions.sh"]

        for script in scripts:
            if os.path.exists(script):
                info(f"Running script: {script}")
                try:
                    subprocess.run(["sh", script], check=True)
                    success(f"{script} executed successfully")
                except subprocess.CalledProcessError as e:
                    error(f"{script} failed: {e}")


def main():
    """Main function"""
    installer = PackageInstaller()
    installer.setup()


if __name__ == "__main__":
    main()
