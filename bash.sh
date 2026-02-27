#!/usr/bin/env bash
# ============================================================
#  alias.sh — Shortcut command manager
#  Usage: source ~/alias.sh
#  Then:
#    als <TAB>          → show all sub-commands
#    als                → interactive fzf picker (type / to filter)
# ============================================================

# ─── Define your aliases here ────────────────────────────────
_ALS_COMMANDS=(
  "gs:git status"
  "gp:git pull"
  "gpp:git push"
  "gco:git checkout"
  "gcb:git checkout -b"
  "gcm:git commit -m"
  "gl:git log --oneline --graph --decorate -20"
  "gd:git diff"
  "ga:git add ."

  "dc:docker compose"
  "dcu:docker compose up -d"
  "dcd:docker compose down"
  "dcl:docker compose logs -f"
  "dps:docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

  "ll:ls -lah --color=auto"
  "la:ls -A --color=auto"
  "...:cd ../.."
  ".....:cd ../../.."
  "mkcd:mkdir -p \$1 && cd \$1"

  "serve:python3 -m http.server 8080"
  "myip:curl -s https://ifconfig.me && echo"
  "ports:ss -tulpn"
  "topc:top -o %CPU"
  "topm:top -o %MEM"

  "update:sudo apt update && sudo apt upgrade -y"
  "cls:clear"
  "reload:source ~/.bashrc"
  "path:echo \$PATH | tr ':' '\n'"
  "bashrc:${EDITOR:-nano} ~/.bashrc"
  "alsedit:${EDITOR:-nano} ~/alias.sh"
)

# ─── Register real bash aliases ───────────────────────────────
for _entry in "${_ALS_COMMANDS[@]}"; do
  _key="${_entry%%:*}"
  _val="${_entry#*:}"
  # Only register simple (non-arg) aliases
  if [[ "$_val" != *'$'* ]]; then
    alias "$_key"="$_val"
  fi
done

# ─── Helper: list all names + descriptions ────────────────────
_als_list() {
  local max=0
  for _entry in "${_ALS_COMMANDS[@]}"; do
    local k="${_entry%%:*}"
    (( ${#k} > max )) && max=${#k}
  done
  for _entry in "${_ALS_COMMANDS[@]}"; do
    local k="${_entry%%:*}"
    local v="${_entry#*:}"
    printf "  \033[1;32m%-${max}s\033[0m  %s\n" "$k" "$v"
  done
}

# ─── Main `als` function ──────────────────────────────────────
als() {
  local cmd="$1"

  # No argument → fzf interactive picker
  if [[ -z "$cmd" ]]; then
    if command -v fzf &>/dev/null; then
      local chosen
      chosen=$(
        for _entry in "${_ALS_COMMANDS[@]}"; do
          local k="${_entry%%:*}"
          local v="${_entry#*:}"
          printf "%-20s  %s\n" "$k" "$v"
        done | fzf \
          --prompt="als> " \
          --header="Type to filter | ENTER to run | ESC to cancel" \
          --height=40% \
          --reverse \
          --border=rounded \
          --color="header:italic:yellow"
      )
      if [[ -n "$chosen" ]]; then
        local sel_key
        sel_key=$(echo "$chosen" | awk '{print $1}')
        # Find the real command
        for _entry in "${_ALS_COMMANDS[@]}"; do
          local k="${_entry%%:*}"
          local v="${_entry#*:}"
          if [[ "$k" == "$sel_key" ]]; then
            echo -e "\033[1;34m▶ $v\033[0m"
            eval "$v"
            return
          fi
        done
      fi
    else
      echo -e "\033[1;33m[als]\033[0m fzf not installed. Showing list instead."
      echo -e "\033[2m  Install: sudo apt install fzf\033[0m\n"
      _als_list
    fi
    return
  fi

  # `als list` or `als --list`
  if [[ "$cmd" == "list" || "$cmd" == "--list" || "$cmd" == "-l" ]]; then
    echo -e "\n\033[1;36m All als shortcuts:\033[0m\n"
    _als_list
    echo
    return
  fi

  # `als add <key> <command...>`
  if [[ "$cmd" == "add" ]]; then
    local new_key="$2"
    shift 2
    local new_val="$*"
    if [[ -z "$new_key" || -z "$new_val" ]]; then
      echo "Usage: als add <shortcut> <command>"
      return 1
    fi
    echo "  \"${new_key}:${new_val}\"" >> ~/alias.sh
    echo -e "\033[1;32m✔\033[0m Added '\033[1m$new_key\033[0m' → $new_val"
    echo -e "\033[2m  Run 'reload' or 'source ~/alias.sh' to apply.\033[0m"
    return
  fi

  # `als help`
  if [[ "$cmd" == "help" || "$cmd" == "--help" || "$cmd" == "-h" ]]; then
    echo -e "\n\033[1;36mUsage:\033[0m"
    echo "  als              → fzf interactive picker (type / to filter)"
    echo "  als list         → show all shortcuts"
    echo "  als add k cmd    → append new shortcut to alias.sh"
    echo "  als help         → this message"
    echo ""
    echo -e "\033[1;36mTab completion:\033[0m"
    echo "  als <TAB>        → autocomplete sub-commands"
    echo ""
    return
  fi

  # Run a named shortcut directly: als gs
  for _entry in "${_ALS_COMMANDS[@]}"; do
    local k="${_entry%%:*}"
    local v="${_entry#*:}"
    if [[ "$k" == "$cmd" ]]; then
      echo -e "\033[1;34m▶ $v\033[0m"
      eval "$v"
      return
    fi
  done

  echo -e "\033[1;31m[als]\033[0m Unknown shortcut: '$cmd'. Try 'als list'."
}

# ─── Bash Tab Completion ──────────────────────────────────────
_als_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ "$prev" == "als" ]]; then
    # Collect all shortcut keys + built-in subcommands
    local keys=("list" "add" "help")
    for _entry in "${_ALS_COMMANDS[@]}"; do
      keys+=("${_entry%%:*}")
    done
    COMPREPLY=( $(compgen -W "${keys[*]}" -- "$cur") )
  fi
}

complete -F _als_completion als

# ─── Install hint (first run) ─────────────────────────────────
if ! command -v fzf &>/dev/null; then
  echo -e "\033[1;33m[als]\033[0m Tip: install fzf for interactive dropdown → sudo apt install fzf"
fi