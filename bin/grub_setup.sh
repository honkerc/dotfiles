#!/bin/bash

# Simple Grub theme installation script

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Reset color

# Configuration variables
ORIGIN_NAME="grub"
THEME_NAME="simple"
THEME_DIR="/boot/grub/themes"
GRUB_CONFIG="/etc/default/grub"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: Please run this script with sudo or as root user${NC}"
    exit 1
fi

# Check if theme files exist
if [ ! -d "$ORIGIN_NAME" ]; then
    echo -e "${RED}Error: Theme folder '$ORIGIN_NAME' not found in current directory${NC}"
    exit 1
fi

echo -e "${CYAN}[*] Starting Grub theme installation...${NC}"

# Create theme directory
echo -e "${BLUE}[-] Creating theme directory: $THEME_DIR/$THEME_NAME${NC}"
mkdir -p "$THEME_DIR/$THEME_NAME"

# Copy theme files
echo -e "${BLUE}[-] Installing $THEME_NAME theme...${NC}"
cp -r "$ORIGIN_NAME"/* "$THEME_DIR/$THEME_NAME/"

# Backup original configuration
echo -e "${BLUE}[-] Backing up Grub configuration...${NC}"
cp "$GRUB_CONFIG" "${GRUB_CONFIG}.bak"
echo -e "${GREEN}[+] Backup created: ${GRUB_CONFIG}.bak${NC}"

# Update Grub configuration
echo -e "${BLUE}[-] Setting $THEME_NAME as default theme...${NC}"
sed -i '/GRUB_THEME=/d' "$GRUB_CONFIG"
echo "GRUB_THEME=\"$THEME_DIR/$THEME_NAME/theme.txt\"" >> "$GRUB_CONFIG"
echo -e "${GREEN}[+] Theme configuration added to $GRUB_CONFIG${NC}"

# Update Grub
echo -e "${BLUE}[-] Updating Grub configuration...${NC}"
if command -v update-grub >/dev/null; then
    update-grub
    echo -e "${GREEN}[+] Grub configuration updated successfully${NC}"
elif command -v grub-mkconfig >/dev/null; then
    grub-mkconfig -o /boot/grub/grub.cfg
    echo -e "${GREEN}[+] Grub configuration updated successfully${NC}"
elif command -v grub2-mkconfig >/dev/null; then
    grub2-mkconfig -o /boot/grub/grub.cfg
    echo -e "${GREEN}[+] Grub configuration updated successfully${NC}"
else
    echo -e "${YELLOW}[!] Warning: Could not find update-grub or grub-mkconfig command${NC}"
    echo -e "${YELLOW}[!] Please run grub-mkconfig manually to update configuration${NC}"
fi

echo -e "${GREEN}[+] Installation completed! Please reboot to see the effect${NC}"
