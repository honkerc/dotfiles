#!/bin/bash
# Config backup script - auto-detects dotfiles repo location

set -u
set -o pipefail

# ===== Colors =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===== Auto-detect dotfiles repo root =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILE_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "/data/dotfiles")"

if [ ! -d "$DOTFILE_DIR" ]; then
    echo -e "${RED}Error: dotfiles directory not found: $DOTFILE_DIR${NC}"
    exit 1
fi

CONFIG_DIR="$DOTFILE_DIR/lib/config"
SOURCE_DIR="$HOME/.config"

# ===== Log file (created only on error) =====
LOG_FILE="${HOME}/backup_$(date +%Y%m%d_%H%M%S).log"
LOG_CONTENT=""

# ===== Config files to back up =====
BACKUP_FILES=(
    "alacritty"
    # "cava"
    "dunst"
    "fcitx5"
    "nvim"
    "yazi"
    "niri"
    "waybar"
    "rofi"
    # "self"
    "pip"
    # "kitty"
)

# ===== Task list (currently empty) =====
task_descs=()
task_cmds=()

# ===== Log helper =====
add_log() {
    local command="$1"
    local error="$2"
    LOG_CONTENT+="- [Command]${command}\n  [Info]${error}\n"
}

# ===== Header =====
echo -e "${CYAN}=======================================${NC}"
echo -e "${BLUE}Dotfiles:${NC} $DOTFILE_DIR"
echo -e "${BLUE}Config:${NC}   $CONFIG_DIR"
echo -e "${CYAN}=======================================${NC}"
echo

# ===== Clean old backup =====
rm -rf "$CONFIG_DIR"

mkdir -p "$DOTFILE_DIR" 2>/dev/null || {
    err="Cannot create directory: $DOTFILE_DIR"
    echo -e "${RED}$err${NC}"
    add_log "mkdir -p $DOTFILE_DIR" "$err"
    exit 1
}
mkdir -p "$CONFIG_DIR" 2>/dev/null || {
    err="Cannot create directory: $CONFIG_DIR"
    echo -e "${RED}$err${NC}"
    add_log "mkdir -p $CONFIG_DIR" "$err"
    exit 1
}

# ===== Backup counters =====
success_count=0
fail_count=0
total_backup=${#BACKUP_FILES[@]}

echo -e "${MAGENTA}Backing up configs to: $CONFIG_DIR${NC}"
echo -e "${CYAN}--------------------------------${NC}"

# ===== Backup loop =====
for ((i=0; i<total_backup; i++)); do
    file="${BACKUP_FILES[$i]}"
    source_path="$SOURCE_DIR/$file"
    target_path="$CONFIG_DIR/$file"
    target_dir=$(dirname "$target_path")

    mkdir -p "$target_dir" 2>/dev/null || {
        err="Cannot create directory: $target_dir"
        echo -e "${RED}$err${NC}"
        add_log "mkdir -p $target_dir" "$err"
        fail_count=$((fail_count + 1))
        continue
    }

    echo -ne "[$((i+1))/$total_backup] Backing up: ${BLUE}$file${NC}... "

    if [[ -e "$source_path" ]]; then
        if cp -a "$source_path" "$target_path" 2>/dev/null; then
            echo -e "${GREEN}OK${NC}"
            success_count=$((success_count + 1))
        else
            err_out=$(cp -av "$source_path" "$target_path" 2>&1 | tr '\n' ' ')
            echo -ne "${YELLOW}Failed (trying sudo)... ${NC}"
            if sudo cp -a "$source_path" "$target_path" 2>/dev/null; then
                echo -e "${GREEN}OK (sudo)${NC}"
                success_count=$((success_count + 1))
                sudo chown -R "$USER:$USER" "$target_path" 2>/dev/null
            else
                sudo_err=$(sudo cp -av "$source_path" "$target_path" 2>&1 | tr '\n' ' ')
                echo -e "${RED}FAILED${NC}"
                add_log "cp -a $source_path $target_path" "$err_out"
                add_log "sudo cp -a $source_path $target_path" "$sudo_err"
                fail_count=$((fail_count + 1))
            fi
        fi
    else
        echo -e "${YELLOW}SKIP (not found)${NC}"
        add_log "Check source" "Not found: $source_path"
        fail_count=$((fail_count + 1))
    fi
done

echo
echo -e "${CYAN}Backup done ${GREEN}OK: $success_count${NC}, ${RED}Failed: $fail_count${NC}"

# ===== Extra tasks (skipped if empty) =====
total_tasks=${#task_descs[@]}
if [ "$total_tasks" -gt 0 ]; then
    echo
    echo -e "${MAGENTA}Running extra tasks ($total_tasks)${NC}"
    echo -e "${CYAN}--------------------------------${NC}"
    task_success=0
    task_fail=0

    for ((i=0; i<total_tasks; i++)); do
        desc="${task_descs[$i]}"
        cmd="${task_cmds[$i]}"

        echo -ne "[$((i+1))/$total_tasks] ${BLUE}$desc${NC}... "

        err_out=$(eval "$cmd" 2>&1)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}OK${NC}"
            task_success=$((task_success + 1))
        else
            err_line=$(echo "$err_out" | tr '\n' ' ')
            echo -e "${RED}FAILED${NC}"
            add_log "$cmd" "$err_line"
            task_fail=$((task_fail + 1))
        fi
    done

    echo
    echo -e "${CYAN}Tasks done ${GREEN}OK: $task_success${NC}, ${RED}Failed: $task_fail${NC}"
else
    task_success=0
    task_fail=0
fi

# ===== Desktop notification =====
if command -v notify-send &> /dev/null; then
    msg="Backup: $success_count OK, $fail_count failed"
    if [[ $total_tasks -gt 0 ]]; then
        msg+="\nTasks: $task_success OK, $task_fail failed"
    fi
    if [[ $fail_count -eq 0 && $task_fail -eq 0 ]]; then
        notify-send -i dialog-information "Config backup complete" "$msg"
    else
        notify-send -i dialog-warning "Config backup partially complete" "$msg"
    fi
fi

# ===== Write log only on error =====
if [ -n "$LOG_CONTENT" ]; then
    {
        echo "=== Backup error log ($(date)) ==="
        echo -e "$LOG_CONTENT"
    } > "$LOG_FILE"
    echo -e "\n${RED}Error log: ${LOG_FILE}${NC}"
    notify-send -i dialog-warning "Backup errors" "Some operations failed, see $LOG_FILE" 2>/dev/null || true
else
    echo -e "\n${GREEN}All operations completed successfully${NC}"
fi
