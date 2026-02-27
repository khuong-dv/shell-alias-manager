#!/usr/bin/env bash
# ============================================================
#  install.sh — Install als (Bash Alias Manager)
#  Usage: bash install.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.als"
BASHRC="$HOME/.bashrc"
SOURCE_LINE='source "$HOME/.als/als.sh"'

echo -e "\033[1;36m"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║   als — Bash Alias Manager Installer  ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "\033[0m"

# Step 1: Build release
echo -e "\033[1m[1/4]\033[0m Building release..."
bash "${SCRIPT_DIR}/build.sh"
echo ""

# Step 2: Install to ~/.als/
echo -e "\033[1m[2/4]\033[0m Installing to ${INSTALL_DIR}..."
mkdir -p "$INSTALL_DIR"
cp "${SCRIPT_DIR}/als_release.sh" "${INSTALL_DIR}/als.sh"
chmod +x "${INSTALL_DIR}/als.sh"
echo -e "  \033[1;32m✔\033[0m Copied to ${INSTALL_DIR}/als.sh"

# Step 3: Create default aliases if data file doesn't exist
ALS_DATA_FILE="$HOME/.als_aliases"
if [[ ! -f "$ALS_DATA_FILE" ]]; then
  echo -e "\033[1m[3/4]\033[0m Creating default aliases..."
  cat > "$ALS_DATA_FILE" <<'EOF'
# als — Default aliases
# Format: name|command|description
gs|git status|Show git working tree status
gp|git pull|Pull latest changes from remote
gpp|git push|Push commits to remote
gl|git log --oneline --graph --decorate -20|Git log with graph
ga|git add .|Stage all changes
gcm|git commit -m|Commit with message
gco|git checkout|Switch branches
gd|git diff|Show changes
ll|ls -lah --color=auto|Detailed file listing
la|ls -A --color=auto|List all including hidden
cls|clear|Clear terminal
reload|source ~/.bashrc|Reload bash configuration
myip|curl -s https://ifconfig.me && echo|Show public IP
ports|ss -tulpn|Show listening ports
EOF
  echo -e "  \033[1;32m✔\033[0m Created ${ALS_DATA_FILE} with default aliases"
else
  echo -e "\033[1m[3/4]\033[0m Alias data file already exists, keeping it."
  echo -e "  \033[2m${ALS_DATA_FILE}\033[0m"
fi

# Step 4: Add to .bashrc
echo -e "\033[1m[4/4]\033[0m Configuring shell..."
if [[ -f "$BASHRC" ]] && grep -qF '.als/als.sh' "$BASHRC"; then
  echo -e "  \033[1;33m⚠\033[0m Already configured in ${BASHRC}"
else
  echo "" >> "$BASHRC"
  echo "# als — Bash Alias Manager" >> "$BASHRC"
  echo "$SOURCE_LINE" >> "$BASHRC"
  echo -e "  \033[1;32m✔\033[0m Added source line to ${BASHRC}"
fi

# Done
echo ""
echo -e "\033[1;32m════════════════════════════════════════\033[0m"
echo -e "\033[1;32m  ✔ Installation complete!\033[0m"
echo -e "\033[1;32m════════════════════════════════════════\033[0m"
echo ""
echo -e "  To activate now, run:"
echo -e "    \033[1msource ~/.bashrc\033[0m"
echo ""
echo -e "  Or open a new terminal."
echo ""
echo -e "  Quick start:"
echo -e "    \033[1mals --help\033[0m        Show usage"
echo -e "    \033[1mals --list\033[0m        Show all aliases"
echo -e "    \033[1mals\033[0m              Interactive picker (requires fzf)"
echo ""
