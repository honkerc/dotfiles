#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Reset color

# Global variables
interrupted=0                  # Track if interrupted
DEFAULT_TIMEOUT=200            # Default timeout (seconds)
MANAGER="paru"                 # Default package manager (paru/pacman/yay)
RUN_AS_ROOT=0                  # Whether running as root

# Handle Ctrl+C signal
handle_interrupt() {
    echo -e "\n${RED}[!] Interrupt signal detected (Ctrl+C), exiting...${NC}"
    interrupted=1
    exit 1
}

# Register interrupt handler
trap handle_interrupt SIGINT

# Command execution with timeout
run_with_timeout() {
    local cmd="$1"
    local timeout="$2"
    local error_file="$3"

    # Use timeout command and capture exit status
    if timeout "$timeout" bash -c "$cmd" > /dev/null 2>"$error_file"; then
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            # Timeout exit code
            echo "Command execution timeout (${timeout} seconds)" > "$error_file"
        fi
        return $exit_code
    fi
}

# Check if package is installed
is_package_installed() {
    local pkg_name="$1"
    pacman -Q "$pkg_name" &>/dev/null
    return $?
}

# Build install command
build_install_cmd() {
    local pkg_name="$1"

    # Special handling for archlinuxcn-keyring
    if [ "$pkg_name" == "archlinuxcn-keyring" ]; then
        if [ "$RUN_AS_ROOT" -eq 1 ]; then
            echo "pacman -Sy --noconfirm archlinuxcn-keyring"
        else
            echo "sudo pacman -Sy --noconfirm archlinuxcn-keyring"
        fi
        return
    fi

    if [ "$MANAGER" = "pacman" ]; then
        if [ "$RUN_AS_ROOT" -eq 1 ]; then
            echo "pacman -S --noconfirm $pkg_name"
        else
            echo "sudo pacman -S --noconfirm $pkg_name"
        fi
    elif [ "$MANAGER" = "yay" ]; then
        echo "yay -S --noconfirm $pkg_name"
    else  # Default to paru
        echo "paru -S --noconfirm --skipreview $pkg_name"
    fi
}

# Process single section
process_section() {
    local section_name="$1"
    local -a commands=("${!2}")
    local total_commands="${#commands[@]}"
    local index=1

    # Print section title
    echo -e "\n${CYAN}[*] Executing '${section_name}' commands (using ${YELLOW}$MANAGER${CYAN})${NC}"

    for cmd_line in "${commands[@]}"; do
        # Check if interrupted
        if [ $interrupted -eq 1 ]; then
            echo -e "${YELLOW}[!] Skipping remaining commands (user interrupt)${NC}"
            return
        fi

        # Separate package name and comment
        local pkg_name="${cmd_line%%#*}"  # Remove comment part
        local comment="${cmd_line#*#}"    # Extract comment

        # Clean whitespace
        pkg_name=$(echo "$pkg_name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        comment=$(echo "$comment" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        # Skip empty lines
        if [ -z "$pkg_name" ]; then
            continue
        fi

        # Initial "executing" status display
        printf "[%d/%d] [${YELLOW}EXEC${NC}] %-50s ${GREEN}# %s${NC}" \
            "$index" "$total_commands" "$pkg_name" "$comment"
        # Flush output buffer immediately
        /bin/echo -ne ""

        # Check if package is already installed
        if is_package_installed "$pkg_name"; then
            # Clear current line
            echo -ne "\r\033[K"
            printf "[%d/%d] [${GREEN}SKIP${NC}] %-50s ${GREEN}# %s${NC}\n" \
                "$index" "$total_commands" "$pkg_name" "$comment"
            ((index++))
            continue
        fi

        # Update status to "installing"
        echo -ne "\r\033[K"
        printf "[%d/%d] [${YELLOW}EXEC${NC}] %-50s ${GREEN}# %s${NC}" \
            "$index" "$total_commands" "$pkg_name" "$comment"
        /bin/echo -ne ""

        # Create temp file for error output
        local error_file
        error_file=$(mktemp)

        # Build install command
        local install_cmd
        install_cmd=$(build_install_cmd "$pkg_name")

        # Execute command and capture result
        if run_with_timeout "$install_cmd" "$DEFAULT_TIMEOUT" "$error_file"; then
            status="${GREEN}DONE${NC}"
            # Clear current line
            echo -ne "\r\033[K"
            printf "[%d/%d] [%b] %-50s ${GREEN}# %s${NC}\n" \
                "$index" "$total_commands" "$status" "$pkg_name" "$comment"
            # Remove temp file
            rm -f "$error_file"
        else
            # Check if interrupted
            if [ $interrupted -eq 1 ]; then
                echo -e "\n${RED}[!] Command interrupted: $pkg_name${NC}"
                rm -f "$error_file"
                return
            fi

            status="${RED}FAIL${NC}"
            # Read error message
            local error_msg
            error_msg=$(<"$error_file")
            rm -f "$error_file"

            # Clear current line
            echo -ne "\r\033[K"
            # Show failure result
            printf "[%d/%d] [%b] %-50s ${GREEN}# %s${NC}\n" \
                "$index" "$total_commands" "$status" "$pkg_name" "$comment"
            # Show error reason on next line
            echo -e "${RED}Error: ${error_msg}${NC}"
        fi

        ((index++))
    done
}

# Main function
pkginstall() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <config-file>"
        exit 1
    fi

    local config_file="$1"
    local current_section=""
    local -a section_commands

    # Check if file exists
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Config file $config_file does not exist${NC}"
        exit 1
    fi

    # Main loop to process config file
    while IFS= read -r line || [ -n "$line" ]; do
        # Check if interrupted
        if [ $interrupted -eq 1 ]; then
            echo -e "${YELLOW}[!] Stopping config file processing (user interrupt)${NC}"
            exit 1
        fi

        # Remove leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Skip empty lines and pure comment lines
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi

        # Detect section header
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            # Process collected section
            if [[ -n "$current_section" && ${#section_commands[@]} -gt 0 ]]; then
                process_section "$current_section" section_commands[@]
            fi

            # Check if interrupted
            if [ $interrupted -eq 1 ]; then
                echo -e "${YELLOW}[!] Stopping config file processing (user interrupt)${NC}"
                exit 1
            fi

            # Start new section
            current_section="${BASH_REMATCH[1]}"
            section_commands=()
        elif [[ -n "$current_section" ]]; then
            # Collect commands - skip commented out commands
            if ! [[ "$line" =~ ^\s*# ]]; then
                section_commands+=("$line")
            fi
        fi
    done < "$config_file"

    # Process last section
    if [[ -n "$current_section" && ${#section_commands[@]} -gt 0 ]]; then
        process_section "$current_section" section_commands[@]
    fi
}


setup(){
    # Set package manager (modify variable directly)
    # Available values: pacman, paru, yay
    MANAGER="paru"

    # Check if running as root
    if [ "$(id -u)" -eq 0 ]; then
        RUN_AS_ROOT=1
        echo -e "${YELLOW}[!] Warning: Running script as root user${NC}"

        # Cannot use AUR helpers as root
        if [ "$MANAGER" != "pacman" ]; then
            echo -e "${RED}Error: Cannot use $MANAGER as root user${NC}"
            echo -e "${YELLOW}Please run script as regular user${NC}"
            exit 1
        fi
    else
        RUN_AS_ROOT=0
    fi

    # Show current package manager
    echo -e "${CYAN}[*] ======================================${NC}"
    echo -e "${GREEN}[*] Using package manager: ${YELLOW}$MANAGER${NC}"
    # Show current user status
    if [ "$RUN_AS_ROOT" -eq 1 ]; then
        echo -e "${GREEN}[*] Running as: ${YELLOW}root${NC}"
    else
        echo -e "${GREEN}[*] Running as: ${YELLOW}$(whoami)${NC}"
    fi
    echo -e "${CYAN}[*] ======================================${NC}"

    # Special handling for archlinuxcn-keyring
    if ! is_package_installed "archlinuxcn-keyring"; then
        echo -e "${YELLOW}[*] Installing archlinuxcn-keyring...${NC}"
        sudo pacman -Sy --noconfirm archlinuxcn-keyring
    fi

    pkginstall "lib/pkgs.conf"
    #sh zsh_setup.sh
    #sh grub_setup.sh
    #sh actions.sh
}

setup
