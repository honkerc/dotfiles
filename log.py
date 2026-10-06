#!/usr/bin/env python3
"""
Logging module
Provides unified log output with four levels: info, success, warning, error
"""

import sys
import time
from datetime import datetime


# Color codes
class Colors:
    RED = '\033[0;31m'
    BOLD_RED = '\033[1;31m'  # Bold red
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color
    BOLD = '\033[1m'  # Bold


class Logger:
    def __init__(self, use_timestamp=False):
        self.use_timestamp = use_timestamp
        self.current_package_line = None  # Info about the current package install line

    def _get_timestamp(self):
        if self.use_timestamp:
            return " " + datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        return ""

    def _clear_current_line(self):
        """Clear the current line"""
        print('\r\033[K', end='', flush=True)

    def _print_package_line(self, index, total, status, pkg_name, comment=""):
        """Print a package install line (supports in-place update)"""
        # Status color mapping
        status_colors = {
            "EXEC": Colors.YELLOW,
            "SKIP": Colors.GREEN,
            "DONE": Colors.GREEN,
            "FAIL": Colors.RED
        }

        status_color = status_colors.get(status, Colors.YELLOW)

        # Format output
        status_display = f"{status_color}{status}{Colors.NC}"
        index_display = f"[{index}/{total}]"
        comment_display = f"{Colors.GREEN}# {comment}{Colors.NC}" if comment else ""
        pkg_display = f"{pkg_name:<70}"

        line_content = f"{index_display} [{status_display}] {pkg_display} {comment_display}"

        # Clear current line and print new content
        self._clear_current_line()
        print(line_content, end='', flush=True)

        # Save current package info for later updates
        self.current_package_line = {
            'index': index,
            'total': total,
            'pkg_name': pkg_name,
            'comment': comment
        }

    def info(self, message):
        timestamp = self._get_timestamp()
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
            print(f"\r{Colors.GREEN}[+]{Colors.NC} {message or 'Done'}       ")
        else:
            print(f"\r{Colors.RED}[!] {message or 'Failed'}{Colors.NC}       ")

    def section_header(self, section_name, manager=""):
        if self.current_package_line:
            print()
            self.current_package_line = None
        manager_display = f" (using {Colors.YELLOW}{manager}{Colors.CYAN})" if manager else ""
        print(f"\n{Colors.CYAN}[*] Executing '{section_name}'{manager_display}{Colors.NC}")

    def package_start(self, index, total, pkg_name, comment=""):
        """Start package installation (show EXEC status)"""
        if self.current_package_line:
            print()  # Newline if a previous package line is still active

        self._print_package_line(index, total, "EXEC", pkg_name, comment)

    def package_update(self, status, message=""):
        """Update the current package status"""
        if not self.current_package_line:
            return

        # Update status
        index = self.current_package_line['index']
        total = self.current_package_line['total']
        pkg_name = self.current_package_line['pkg_name']
        comment = self.current_package_line['comment']

        self._print_package_line(index, total, status, pkg_name, comment)

        # If additional message, print on a new line
        if message:
            print()  # Newline
            if status == "FAIL":
                self.error(message)
            else:
                self.info(message)
            # Clear current package info since it's finished
            self.current_package_line = None

    # Convenience methods
    def package_skip(self, index, total, pkg_name, comment=""):
        """Skip package installation"""
        self.package_start(index, total, pkg_name, comment)
        self.package_update("SKIP")

    def package_done(self, index, total, pkg_name, comment=""):
        """Package installation done"""
        self.package_start(index, total, pkg_name, comment)
        self.package_update("DONE")

    def package_fail(self, index, total, pkg_name, comment="", error_msg=""):
        """Package installation failed"""
        self.package_start(index, total, pkg_name, comment)
        self.package_update("FAIL", error_msg)


# Create global logger instance
log = Logger()

# Export functions directly
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
    # Test all logging features
    print("=== Testing basic log functions ===")
    info("This is an info message")
    success("This is a success message")
    warning("This is a warning message")
    error("This is an error message")

    print("\n=== Testing step functions ===")
    info("Installing system packages...")
    success("Package installed successfully")

    warning("Network interface not configured")
    error("Network configuration failed")

    print("\n=== Testing dynamic package install status ===")
    section_header("Base packages", "paru")

    # Test dynamic update effect
    package_start(1, 5, "git", "Version control")
    time.sleep(1)  # Simulate install process
    package_update("DONE")

    package_start(2, 5, "neovim", "Editor")
    time.sleep(0.5)
    package_update("SKIP")

    package_start(3, 5, "hyprland", "Desktop environment")
    time.sleep(1)
    package_update("FAIL", "Dependency resolution failed")

    package_start(4, 5, "networkmanager", "Network manager")
    time.sleep(1.5)
    package_update("DONE")

    package_start(5, 5, "firefox", "Browser")
    time.sleep(3)
    package_update("DONE")

