#!/usr/bin/env bash
# ============================================================
#  core.sh — Constants, data paths, utility functions
# ============================================================

# ─── Paths ────────────────────────────────────────────────────
ALS_VERSION="1.0.1"
ALS_DATA_FILE="${ALS_DATA_FILE:-$HOME/.als_aliases}"
ALS_BACKUP_DIR="${ALS_BACKUP_DIR:-$HOME/.als_backups}"

# ─── Colors ───────────────────────────────────────────────────
_ALS_C_RESET="\033[0m"
_ALS_C_BOLD="\033[1m"
_ALS_C_DIM="\033[2m"
_ALS_C_ITALIC="\033[3m"
_ALS_C_RED="\033[1;31m"
_ALS_C_GREEN="\033[1;32m"
_ALS_C_YELLOW="\033[1;33m"
_ALS_C_BLUE="\033[1;34m"
_ALS_C_MAGENTA="\033[1;35m"
_ALS_C_CYAN="\033[1;36m"
_ALS_C_WHITE="\033[1;37m"
_ALS_C_BG_GREEN="\033[42m"
_ALS_C_BG_RED="\033[41m"

# ─── Output helpers ──────────────────────────────────────────
_als_success() { echo -e "${_ALS_C_GREEN}✔${_ALS_C_RESET} $*"; }
_als_error()   { echo -e "${_ALS_C_RED}✘${_ALS_C_RESET} $*" >&2; }
_als_warn()    { echo -e "${_ALS_C_YELLOW}⚠${_ALS_C_RESET} $*"; }
_als_info()    { echo -e "${_ALS_C_CYAN}ℹ${_ALS_C_RESET} $*"; }
_als_header()  { echo -e "\n${_ALS_C_CYAN}${_ALS_C_BOLD}$*${_ALS_C_RESET}\n"; }

# ─── Ensure data file exists ─────────────────────────────────
_als_ensure_data_file() {
  if [[ ! -f "$ALS_DATA_FILE" ]]; then
    touch "$ALS_DATA_FILE"
    _als_info "Created alias storage: ${_ALS_C_DIM}${ALS_DATA_FILE}${_ALS_C_RESET}"
  fi
}

# ─── Backup before destructive operations ─────────────────────
_als_backup() {
  mkdir -p "$ALS_BACKUP_DIR"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  cp "$ALS_DATA_FILE" "${ALS_BACKUP_DIR}/als_aliases_${timestamp}.bak"
}

# ─── Read all aliases into arrays ─────────────────────────────
#  Sets global arrays: _ALS_NAMES, _ALS_CMDS, _ALS_DESCS
_als_read_aliases() {
  _ALS_NAMES=()
  _ALS_CMDS=()
  _ALS_DESCS=()

  _als_ensure_data_file

  local _rname _rcmd _rdesc
  while IFS='|' read -r _rname _rcmd _rdesc || [[ -n "$_rname" ]]; do
    # Skip empty lines and comments
    [[ -z "$_rname" || "$_rname" == \#* ]] && continue
    _ALS_NAMES+=("$_rname")
    _ALS_CMDS+=("$_rcmd")
    _ALS_DESCS+=("${_rdesc:-}")
  done < "$ALS_DATA_FILE"
}

# ─── Write arrays back to file ────────────────────────────────
_als_write_aliases() {
  _als_ensure_data_file
  : > "$ALS_DATA_FILE"  # truncate

  local i
  for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
    echo "${_ALS_NAMES[$i]}|${_ALS_CMDS[$i]}|${_ALS_DESCS[$i]}" >> "$ALS_DATA_FILE"
  done
}

# ─── Find alias index by name (-1 if not found) ──────────────
_als_find_index() {
  local target="$1"
  local i
  for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
    if [[ "${_ALS_NAMES[$i]}" == "$target" ]]; then
      echo "$i"
      return 0
    fi
  done
  echo "-1"
  return 1
}

# ─── Register all aliases as real bash aliases ────────────────
_als_register_aliases() {
  _als_read_aliases
  local i
  for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
    local name="${_ALS_NAMES[$i]}"
    local cmd="${_ALS_CMDS[$i]}"
    # Only register simple aliases (no $1, $2 etc.)
    if [[ "$cmd" != *'$'* ]]; then
      alias "$name"="$cmd" 2>/dev/null
    fi
  done
}

# ─── Validate alias name ─────────────────────────────────────
_als_validate_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    _als_error "Alias name cannot be empty."
    return 1
  fi
  if [[ "$name" == *"|"* ]]; then
    _als_error "Alias name cannot contain '|' character."
    return 1
  fi
  if [[ "$name" == *" "* ]]; then
    _als_error "Alias name cannot contain spaces."
    return 1
  fi
  if [[ "$name" =~ ^- ]]; then
    _als_error "Alias name cannot start with '-'."
    return 1
  fi
  return 0
}

# ─── Count aliases ────────────────────────────────────────────
_als_count() {
  _als_read_aliases
  echo "${#_ALS_NAMES[@]}"
}
