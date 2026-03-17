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

# Step 0: Check for fzf dependency
echo -e "\033[1m[0/4]\033[0m Checking dependencies..."
if ! command -v fzf &>/dev/null; then
  echo -e "  \033[1;31m✘\033[0m Error: fzf is not installed!"
  echo "    als requires fzf for its interactive features."
  echo "    Please install fzf first: https://github.com/junegunn/fzf"
  exit 1
fi
echo -e "  \033[1;32m✔\033[0m fzf is installed."
echo ""

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
  echo -e "\033[1m[3/4]\033[0m Creating alias data file..."
  cat > "$ALS_DATA_FILE" <<'EOF'
# als — Alias storage
# Format: name|command|description
EOF
  echo -e "  \033[1;32m✔\033[0m Created ${ALS_DATA_FILE}"
else
  echo -e "\033[1m[3/4]\033[0m Alias data file already exists, keeping it."
  echo -e "  \033[2m${ALS_DATA_FILE}\033[0m"
fi

# Step 4: Configure shell(s)
echo -e "\033[1m[4/4]\033[0m Configuring shell(s)..."

CONFIGURED=()

# ── Bash ──
BASHRC="$HOME/.bashrc"
if [[ -f "$BASHRC" ]]; then
  if grep -qF '.als/als.sh' "$BASHRC"; then
    echo -e "  \033[1;33m⚠\033[0m bash: Already configured in ${BASHRC}"
  else
    echo "" >> "$BASHRC"
    echo "# als — Bash Alias Manager" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
    echo -e "  \033[1;32m✔\033[0m bash: Added source line to ${BASHRC}"
  fi
  CONFIGURED+=("bash")
fi

# ── Zsh ──
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]] || command -v zsh &>/dev/null; then
  touch "$ZSHRC"
  if grep -qF '.als/als.sh' "$ZSHRC"; then
    echo -e "  \033[1;33m⚠\033[0m zsh:  Already configured in ${ZSHRC}"
  else
    echo "" >> "$ZSHRC"
    echo "# als — Bash Alias Manager" >> "$ZSHRC"
    echo "$SOURCE_LINE" >> "$ZSHRC"
    echo -e "  \033[1;32m✔\033[0m zsh:  Added source line to ${ZSHRC}"
  fi
  CONFIGURED+=("zsh")
fi

if [[ ${#CONFIGURED[@]} -eq 0 ]]; then
  echo -e "  \033[1;33m⚠\033[0m No supported shell config found."
  echo -e "  \033[2mManually add this to your shell config:\033[0m"
  echo -e "    $SOURCE_LINE"
fi

# Done
echo ""
echo -e "\033[1;32m════════════════════════════════════════\033[0m"
echo -e "\033[1;32m  ✔ Installation complete!\033[0m"
echo -e "\033[1;32m════════════════════════════════════════\033[0m"
echo ""
echo -e "  Shells configured: \033[1m${CONFIGURED[*]}\033[0m"
echo ""
echo -e "  To activate now, run:"
if [[ " ${CONFIGURED[*]} " == *" bash "* ]]; then
  echo -e "    \033[1msource ~/.bashrc\033[0m"
fi
if [[ " ${CONFIGURED[*]} " == *" zsh "* ]]; then
  echo -e "    \033[1msource ~/.zshrc\033[0m"
fi
echo ""
echo -e "  Or open a new terminal."
echo ""
echo -e "  Quick start:"
echo -e "    \033[1mals --help\033[0m        Show usage"
echo -e "    \033[1mals --list\033[0m        Show all aliases"
echo -e "    \033[1mals\033[0m              Interactive picker"
echo ""
