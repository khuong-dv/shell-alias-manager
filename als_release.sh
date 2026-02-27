#!/usr/bin/env bash
# ============================================================
#  als — Bash Alias Manager (Release Build)
#  Single-file distribution — auto-generated, do not edit
#
#  Usage: Add to your .bashrc or .bash_profile:
#    source /path/to/als_release.sh
#
#  Then use: als --help
# ============================================================

# ── Build info ──
# Built: 2026-02-27 10:56:20
# Version: 1.0.0

# ═══════════════════════════════════════════════════════════
# Module: core.sh
# ═══════════════════════════════════════════════════════════

# ============================================================
#  core.sh — Constants, data paths, utility functions
# ============================================================

# ─── Paths ────────────────────────────────────────────────────
ALS_VERSION="1.0.0"
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

# ═══════════════════════════════════════════════════════════
# Module: crud.sh
# ═══════════════════════════════════════════════════════════

# ============================================================
#  crud.sh — Add, Delete, Update alias operations
# ============================================================

# ─── ADD ──────────────────────────────────────────────────────
# Usage: als --add <name> <command> [--desc "description"]
_als_cmd_add() {
  local name="" cmd="" desc="" file=""
  local positional=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --desc|-d)
        desc="$2"
        shift 2
        ;;
      --file|-f)
        file="$2"
        shift 2
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  # If --file provided, delegate to import
  if [[ -n "$file" ]]; then
    _als_cmd_import "$file"
    return $?
  fi

  # Extract name and command from positional args
  if [[ ${#positional[@]} -lt 2 ]]; then
    _als_error "Usage: als --add <name> <command> [--desc \"description\"]"
    echo -e "  ${_ALS_C_DIM}Example: als --add gs \"git status\" --desc \"Show git status\"${_ALS_C_RESET}"
    return 1
  fi

  name="${positional[0]}"
  # Join remaining positional args as the command
  cmd="${positional[*]:1}"

  # Validate name
  _als_validate_name "$name" || return 1

  # Check command is not empty
  if [[ -z "$cmd" ]]; then
    _als_error "Command cannot be empty."
    return 1
  fi

  # Check for duplicates
  _als_read_aliases
  local idx
  idx=$(_als_find_index "$name")
  if [[ "$idx" -ge 0 ]]; then
    _als_error "Alias '${_ALS_C_BOLD}${name}${_ALS_C_RESET}' already exists."
    echo -e "  ${_ALS_C_DIM}Current: ${_ALS_CMDS[$idx]}${_ALS_C_RESET}"
    echo -e "  ${_ALS_C_DIM}Use 'als --update $name' to modify it.${_ALS_C_RESET}"
    return 1
  fi

  # Append to data file
  _als_ensure_data_file
  echo "${name}|${cmd}|${desc}" >> "$ALS_DATA_FILE"

  # Register immediately
  if [[ "$cmd" != *'$'* ]]; then
    alias "$name"="$cmd" 2>/dev/null
  fi

  _als_success "Added '${_ALS_C_BOLD}${name}${_ALS_C_RESET}' → ${_ALS_C_DIM}${cmd}${_ALS_C_RESET}"
  if [[ -n "$desc" ]]; then
    echo -e "  ${_ALS_C_DIM}📝 ${desc}${_ALS_C_RESET}"
  fi
}

# ─── DELETE ───────────────────────────────────────────────────
# Usage: als --delete <name> [-y]
_als_cmd_delete() {
  local name="$1"
  local force=false

  if [[ "$2" == "-y" || "$2" == "--yes" ]]; then
    force=true
  fi

  if [[ -z "$name" ]]; then
    _als_error "Usage: als --delete <name> [-y]"
    echo -e "  ${_ALS_C_DIM}Example: als --delete gs${_ALS_C_RESET}"
    return 1
  fi

  _als_read_aliases
  local idx
  idx=$(_als_find_index "$name")

  if [[ "$idx" -lt 0 ]]; then
    _als_error "Alias '${_ALS_C_BOLD}${name}${_ALS_C_RESET}' not found."
    return 1
  fi

  # Show what will be deleted
  echo -e "  ${_ALS_C_YELLOW}Name:${_ALS_C_RESET}    ${_ALS_NAMES[$idx]}"
  echo -e "  ${_ALS_C_YELLOW}Command:${_ALS_C_RESET} ${_ALS_CMDS[$idx]}"
  if [[ -n "${_ALS_DESCS[$idx]}" ]]; then
    echo -e "  ${_ALS_C_YELLOW}Desc:${_ALS_C_RESET}    ${_ALS_DESCS[$idx]}"
  fi

  # Confirm deletion
  if [[ "$force" != true ]]; then
    echo -n -e "  ${_ALS_C_RED}Delete this alias? [y/N]:${_ALS_C_RESET} "
    local confirm
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      _als_info "Cancelled."
      return 0
    fi
  fi

  # Backup and remove
  _als_backup

  # Remove from arrays
  local new_names=() new_cmds=() new_descs=()
  local i
  for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
    if [[ $i -ne $idx ]]; then
      new_names+=("${_ALS_NAMES[$i]}")
      new_cmds+=("${_ALS_CMDS[$i]}")
      new_descs+=("${_ALS_DESCS[$i]}")
    fi
  done

  _ALS_NAMES=("${new_names[@]}")
  _ALS_CMDS=("${new_cmds[@]}")
  _ALS_DESCS=("${new_descs[@]}")

  _als_write_aliases

  # Unalias from current session
  unalias "$name" 2>/dev/null

  _als_success "Deleted '${_ALS_C_BOLD}${name}${_ALS_C_RESET}'"
}

# ─── UPDATE ───────────────────────────────────────────────────
# Usage: als --update <name> [--cmd "new command"] [--desc "new desc"]
_als_cmd_update() {
  local name="$1"
  shift

  if [[ -z "$name" ]]; then
    _als_error "Usage: als --update <name> [--cmd \"new command\"] [--desc \"new desc\"]"
    return 1
  fi

  local new_cmd="" new_desc="" has_cmd=false has_desc=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cmd|-c)
        new_cmd="$2"
        has_cmd=true
        shift 2
        ;;
      --desc|-d)
        new_desc="$2"
        has_desc=true
        shift 2
        ;;
      *)
        _als_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  if [[ "$has_cmd" == false && "$has_desc" == false ]]; then
    _als_error "Nothing to update. Use --cmd and/or --desc."
    echo -e "  ${_ALS_C_DIM}Example: als --update gs --cmd \"git status -sb\" --desc \"Short status\"${_ALS_C_RESET}"
    return 1
  fi

  _als_read_aliases
  local idx
  idx=$(_als_find_index "$name")

  if [[ "$idx" -lt 0 ]]; then
    _als_error "Alias '${_ALS_C_BOLD}${name}${_ALS_C_RESET}' not found."
    return 1
  fi

  # Backup
  _als_backup

  # Show old values
  echo -e "  ${_ALS_C_DIM}Old command: ${_ALS_CMDS[$idx]}${_ALS_C_RESET}"
  if [[ -n "${_ALS_DESCS[$idx]}" ]]; then
    echo -e "  ${_ALS_C_DIM}Old desc:    ${_ALS_DESCS[$idx]}${_ALS_C_RESET}"
  fi

  # Apply changes
  if [[ "$has_cmd" == true ]]; then
    _ALS_CMDS[$idx]="$new_cmd"
  fi
  if [[ "$has_desc" == true ]]; then
    _ALS_DESCS[$idx]="$new_desc"
  fi

  _als_write_aliases

  # Re-register alias
  local updated_cmd="${_ALS_CMDS[$idx]}"
  if [[ "$updated_cmd" != *'$'* ]]; then
    alias "$name"="$updated_cmd" 2>/dev/null
  fi

  echo -e "  ${_ALS_C_GREEN}New command:${_ALS_C_RESET} ${_ALS_CMDS[$idx]}"
  if [[ -n "${_ALS_DESCS[$idx]}" ]]; then
    echo -e "  ${_ALS_C_GREEN}New desc:${_ALS_C_RESET}    ${_ALS_DESCS[$idx]}"
  fi
  _als_success "Updated '${_ALS_C_BOLD}${name}${_ALS_C_RESET}'"
}

# ─── RESET ────────────────────────────────────────────────────
# Usage: als --reset [-y]
_als_cmd_reset() {
  local force=false
  [[ "$1" == "-y" || "$1" == "--yes" ]] && force=true

  _als_read_aliases
  local total=${#_ALS_NAMES[@]}

  if [[ $total -eq 0 ]]; then
    _als_info "No aliases to reset. Storage is already empty."
    return 0
  fi

  _als_warn "This will delete ${_ALS_C_BOLD}ALL ${total} aliases${_ALS_C_RESET}${_ALS_C_YELLOW} from storage."

  if [[ "$force" != true ]]; then
    echo -n -e "  ${_ALS_C_RED}Are you sure you want to delete all aliases? [y/N]:${_ALS_C_RESET} "
    local confirm
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      _als_info "Cancelled. No aliases were deleted."
      return 0
    fi
  fi

  # Backup before reset
  _als_backup

  # Unalias all from current session
  local i
  for (( i=0; i<$total; i++ )); do
    unalias "${_ALS_NAMES[$i]}" 2>/dev/null
  done

  # Truncate data file
  : > "$ALS_DATA_FILE"

  # Clear arrays
  _ALS_NAMES=()
  _ALS_CMDS=()
  _ALS_DESCS=()

  _als_success "All ${_ALS_C_BOLD}${total}${_ALS_C_RESET} aliases have been deleted."
  echo -e "  ${_ALS_C_DIM}A backup was saved to ${ALS_BACKUP_DIR}/${_ALS_C_RESET}"
}

# ═══════════════════════════════════════════════════════════
# Module: search.sh
# ═══════════════════════════════════════════════════════════

# ============================================================
#  search.sh — Keyword search across aliases
# ============================================================

# ─── SEARCH ───────────────────────────────────────────────────
# Usage: als --search <keyword> or als -s <keyword>
_als_cmd_search() {
  local keyword="$1"

  if [[ -z "$keyword" ]]; then
    _als_error "Usage: als --search <keyword>"
    echo -e "  ${_ALS_C_DIM}Example: als --search git${_ALS_C_RESET}"
    return 1
  fi

  _als_read_aliases

  if [[ ${#_ALS_NAMES[@]} -eq 0 ]]; then
    _als_warn "No aliases found. Add some with: als --add <name> <command>"
    return 0
  fi

  local matches=0
  local keyword_lower
  keyword_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')

  # Find max name width for alignment
  local max_name=0
  local i
  for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
    local name_lower cmd_lower desc_lower
    name_lower=$(echo "${_ALS_NAMES[$i]}" | tr '[:upper:]' '[:lower:]')
    cmd_lower=$(echo "${_ALS_CMDS[$i]}" | tr '[:upper:]' '[:lower:]')
    desc_lower=$(echo "${_ALS_DESCS[$i]}" | tr '[:upper:]' '[:lower:]')

    if [[ "$name_lower" == *"$keyword_lower"* ]] || \
       [[ "$cmd_lower" == *"$keyword_lower"* ]] || \
       [[ "$desc_lower" == *"$keyword_lower"* ]]; then
      local len=${#_ALS_NAMES[$i]}
      (( len > max_name )) && max_name=$len
      (( matches++ ))
    fi
  done

  if [[ $matches -eq 0 ]]; then
    _als_warn "No aliases matching '${_ALS_C_BOLD}${keyword}${_ALS_C_RESET}${_ALS_C_YELLOW}' found."
    return 0
  fi

  _als_header "🔍 Search results for '${keyword}' (${matches} found)"

  # Print header
  printf "  ${_ALS_C_DIM}%-${max_name}s  %-30s  %s${_ALS_C_RESET}\n" "NAME" "COMMAND" "DESCRIPTION"
  printf "  ${_ALS_C_DIM}%s${_ALS_C_RESET}\n" "$(printf '─%.0s' $(seq 1 $((max_name + 35 + 20))))"

  for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
    local name_lower cmd_lower desc_lower
    name_lower=$(echo "${_ALS_NAMES[$i]}" | tr '[:upper:]' '[:lower:]')
    cmd_lower=$(echo "${_ALS_CMDS[$i]}" | tr '[:upper:]' '[:lower:]')
    desc_lower=$(echo "${_ALS_DESCS[$i]}" | tr '[:upper:]' '[:lower:]')

    if [[ "$name_lower" == *"$keyword_lower"* ]] || \
       [[ "$cmd_lower" == *"$keyword_lower"* ]] || \
       [[ "$desc_lower" == *"$keyword_lower"* ]]; then
      local desc_display="${_ALS_DESCS[$i]}"
      [[ -z "$desc_display" ]] && desc_display="${_ALS_C_DIM}—${_ALS_C_RESET}"
      printf "  ${_ALS_C_GREEN}%-${max_name}s${_ALS_C_RESET}  %-30s  ${_ALS_C_DIM}%s${_ALS_C_RESET}\n" \
        "${_ALS_NAMES[$i]}" "${_ALS_CMDS[$i]}" "$desc_display"
    fi
  done
  echo
}

# ═══════════════════════════════════════════════════════════
# Module: import.sh
# ═══════════════════════════════════════════════════════════

# ============================================================
#  import.sh — Import/Export aliases from/to external files
# ============================================================

# ─── IMPORT ───────────────────────────────────────────────────
# Usage: als --import <file>
# File format: name|command|description (description is optional)
_als_cmd_import() {
  local file="$1"

  if [[ -z "$file" ]]; then
    _als_error "Usage: als --import <file>"
    echo -e "  ${_ALS_C_DIM}File format (one per line): name|command|description${_ALS_C_RESET}"
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    _als_error "File not found: ${_ALS_C_BOLD}${file}${_ALS_C_RESET}"
    return 1
  fi

  if [[ ! -r "$file" ]]; then
    _als_error "Cannot read file: ${_ALS_C_BOLD}${file}${_ALS_C_RESET}"
    return 1
  fi

  _als_read_aliases

  local added=0 skipped=0 errors=0 line_num=0

  _als_header "📥 Importing from: ${file}"

  while IFS= read -r line || [[ -n "$line" ]]; do
    (( line_num++ ))

    # Skip empty lines and comments
    [[ -z "$line" || "$line" == \#* ]] && continue

    # Parse: name|command|description
    local name cmd desc
    IFS='|' read -r name cmd desc <<< "$line"

    # Trim whitespace
    name=$(echo "$name" | xargs)
    cmd=$(echo "$cmd" | xargs)
    desc=$(echo "$desc" | xargs)

    # Validate
    if [[ -z "$name" || -z "$cmd" ]]; then
      echo -e "  ${_ALS_C_RED}Line ${line_num}: Invalid format${_ALS_C_RESET} — ${_ALS_C_DIM}${line}${_ALS_C_RESET}"
      (( errors++ ))
      continue
    fi

    if ! _als_validate_name "$name" 2>/dev/null; then
      echo -e "  ${_ALS_C_RED}Line ${line_num}: Invalid name '${name}'${_ALS_C_RESET}"
      (( errors++ ))
      continue
    fi

    # Check duplicate
    local idx
    idx=$(_als_find_index "$name")
    if [[ "$idx" -ge 0 ]]; then
      echo -e "  ${_ALS_C_YELLOW}⏭  Skipped '${name}'${_ALS_C_RESET} ${_ALS_C_DIM}(already exists)${_ALS_C_RESET}"
      (( skipped++ ))
      continue
    fi

    # Add to arrays and file
    _ALS_NAMES+=("$name")
    _ALS_CMDS+=("$cmd")
    _ALS_DESCS+=("${desc:-}")
    echo "${name}|${cmd}|${desc:-}" >> "$ALS_DATA_FILE"

    # Register alias immediately
    if [[ "$cmd" != *'$'* ]]; then
      alias "$name"="$cmd" 2>/dev/null
    fi

    echo -e "  ${_ALS_C_GREEN}✔  Added '${name}'${_ALS_C_RESET} → ${_ALS_C_DIM}${cmd}${_ALS_C_RESET}"
    (( added++ ))
  done < "$file"

  echo
  echo -e "  ${_ALS_C_BOLD}Summary:${_ALS_C_RESET}"
  echo -e "    ${_ALS_C_GREEN}Added:${_ALS_C_RESET}   ${added}"
  echo -e "    ${_ALS_C_YELLOW}Skipped:${_ALS_C_RESET} ${skipped}"
  if [[ $errors -gt 0 ]]; then
    echo -e "    ${_ALS_C_RED}Errors:${_ALS_C_RESET}  ${errors}"
  fi
  echo
}

# ─── EXPORT ───────────────────────────────────────────────────
# Usage: als --export [file]
_als_cmd_export() {
  local file="${1:-./als_export.txt}"

  _als_read_aliases

  if [[ ${#_ALS_NAMES[@]} -eq 0 ]]; then
    _als_warn "No aliases to export."
    return 0
  fi

  {
    echo "# als alias export — $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Format: name|command|description"
    echo ""
    local i
    for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
      echo "${_ALS_NAMES[$i]}|${_ALS_CMDS[$i]}|${_ALS_DESCS[$i]}"
    done
  } > "$file"

  _als_success "Exported ${#_ALS_NAMES[@]} aliases to '${_ALS_C_BOLD}${file}${_ALS_C_RESET}'"
}

# ═══════════════════════════════════════════════════════════
# Module: display.sh
# ═══════════════════════════════════════════════════════════

# ============================================================
#  display.sh — List, fzf picker, formatted output
# ============================================================

# ─── Formatted list ──────────────────────────────────────────
_als_cmd_list() {
  _als_read_aliases

  local total=${#_ALS_NAMES[@]}

  if [[ $total -eq 0 ]]; then
    _als_warn "No aliases found."
    echo -e "  ${_ALS_C_DIM}Get started: als --add <name> <command> --desc \"description\"${_ALS_C_RESET}"
    echo -e "  ${_ALS_C_DIM}Or import:   als --import <file>${_ALS_C_RESET}"
    return 0
  fi

  # Find max name width
  local max_name=4  # minimum "NAME"
  local max_cmd=7   # minimum "COMMAND"
  local i
  for (( i=0; i<$total; i++ )); do
    local nlen=${#_ALS_NAMES[$i]}
    local clen=${#_ALS_CMDS[$i]}
    (( nlen > max_name )) && max_name=$nlen
    (( clen > max_cmd )) && max_cmd=$clen
  done

  # Cap max_cmd for readability
  (( max_cmd > 50 )) && max_cmd=50

  _als_header "📋 All aliases (${total} total)"

  # Header
  printf "  ${_ALS_C_BOLD}${_ALS_C_CYAN}%-${max_name}s${_ALS_C_RESET}  ${_ALS_C_BOLD}%-${max_cmd}s${_ALS_C_RESET}  ${_ALS_C_BOLD}%s${_ALS_C_RESET}\n" \
    "NAME" "COMMAND" "DESCRIPTION"
  printf "  ${_ALS_C_DIM}"
  printf '─%.0s' $(seq 1 $((max_name + max_cmd + 25)))
  printf "${_ALS_C_RESET}\n"

  # Rows
  for (( i=0; i<$total; i++ )); do
    local desc_display="${_ALS_DESCS[$i]}"
    [[ -z "$desc_display" ]] && desc_display="—"
    printf "  ${_ALS_C_GREEN}%-${max_name}s${_ALS_C_RESET}  %-${max_cmd}s  ${_ALS_C_DIM}%s${_ALS_C_RESET}\n" \
      "${_ALS_NAMES[$i]}" "${_ALS_CMDS[$i]}" "$desc_display"
  done
  echo
}

# ─── FZF interactive picker ──────────────────────────────────
_als_fzf_picker() {
  _als_read_aliases

  if [[ ${#_ALS_NAMES[@]} -eq 0 ]]; then
    _als_warn "No aliases found. Add some first: als --add <name> <command>"
    return 0
  fi

  if ! command -v fzf &>/dev/null; then
    _als_warn "fzf not installed. Showing list instead."
    echo -e "  ${_ALS_C_DIM}Install: sudo apt install fzf${_ALS_C_RESET}\n"
    _als_cmd_list
    return 0
  fi

  # Find max name width
  local max_name=0
  local i
  for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
    local len=${#_ALS_NAMES[$i]}
    (( len > max_name )) && max_name=$len
  done

  local chosen
  chosen=$(
    for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
      local desc="${_ALS_DESCS[$i]}"
      [[ -z "$desc" ]] && desc="—"
      printf "%-${max_name}s  │  %-40s  │  %s\n" \
        "${_ALS_NAMES[$i]}" "${_ALS_CMDS[$i]}" "$desc"
    done | fzf \
      --prompt="als❯ " \
      --header="Type to filter │ ENTER to run │ ESC to cancel" \
      --height=40% \
      --reverse \
      --border=rounded \
      --color="header:italic:yellow,prompt:green,pointer:cyan" \
      --ansi
  )

  if [[ -n "$chosen" ]]; then
    local sel_key
    sel_key=$(echo "$chosen" | awk '{print $1}')

    # Find and run the command
    for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
      if [[ "${_ALS_NAMES[$i]}" == "$sel_key" ]]; then
        echo -e "${_ALS_C_BLUE}▶ ${_ALS_CMDS[$i]}${_ALS_C_RESET}"
        eval "${_ALS_CMDS[$i]}"
        return
      fi
    done
  fi
}

# ═══════════════════════════════════════════════════════════
# Module: als.sh
# ═══════════════════════════════════════════════════════════

# ============================================================
#  als.sh — Main entry point for Alias Manager
#  Usage: source this file (or the built release file)
# ============================================================

# ─── Resolve script directory ─────────────────────────────────

# ─── Source all modules ───────────────────────────────────────

# ─── Initialize: load and register aliases ────────────────────
_als_ensure_data_file
_als_register_aliases

# ─── Main als function ────────────────────────────────────────
als() {
  local cmd="$1"

  # No argument → fzf interactive picker
  if [[ -z "$cmd" ]]; then
    _als_fzf_picker
    return
  fi

  case "$cmd" in
    # ── CRUD operations ──
    --add|-a)
      shift
      _als_cmd_add "$@"
      ;;
    --delete|--del|--remove|-r)
      shift
      _als_cmd_delete "$@"
      ;;
    --update|--edit|-u)
      shift
      _als_cmd_update "$@"
      ;;
    --reset)
      shift
      _als_cmd_reset "$@"
      ;;

    # ── Search ──
    --search|-s)
      shift
      _als_cmd_search "$@"
      ;;

    # ── Import / Export ──
    --import|-i)
      shift
      _als_cmd_import "$@"
      ;;
    --export|-e)
      shift
      _als_cmd_export "$@"
      ;;

    # ── Display ──
    --list|list|-l)
      _als_cmd_list
      ;;

    # ── Reload ──
    --reload)
      _als_register_aliases
      _als_success "Aliases reloaded from ${_ALS_C_DIM}${ALS_DATA_FILE}${_ALS_C_RESET}"
      ;;

    # ── Info ──
    --count)
      local count
      count=$(_als_count)
      _als_info "Total aliases: ${_ALS_C_BOLD}${count}${_ALS_C_RESET}"
      ;;

    --version|-v)
      echo -e "${_ALS_C_CYAN}als${_ALS_C_RESET} version ${_ALS_C_BOLD}${ALS_VERSION}${_ALS_C_RESET}"
      ;;

    # ── Help ──
    --help|-h|help)
      _als_show_help
      ;;

    # ── Direct alias execution ──
    *)
      _als_read_aliases
      local idx
      idx=$(_als_find_index "$cmd")
      if [[ "$idx" -ge 0 ]]; then
        shift
        echo -e "${_ALS_C_BLUE}▶ ${_ALS_CMDS[$idx]}${_ALS_C_RESET}"
        eval "${_ALS_CMDS[$idx]} $*"
      else
        _als_error "Unknown command: '${_ALS_C_BOLD}${cmd}${_ALS_C_RESET}'"
        echo -e "  ${_ALS_C_DIM}Run 'als --help' for usage info.${_ALS_C_RESET}"
        return 1
      fi
      ;;
  esac
}

# ─── Help text ────────────────────────────────────────────────
_als_show_help() {
  echo -e "
${_ALS_C_CYAN}${_ALS_C_BOLD}als${_ALS_C_RESET} — Bash Alias Manager v${ALS_VERSION}

${_ALS_C_BOLD}USAGE${_ALS_C_RESET}
  ${_ALS_C_GREEN}als${_ALS_C_RESET}                              Interactive fzf picker
  ${_ALS_C_GREEN}als${_ALS_C_RESET} <name>                       Run alias directly
  ${_ALS_C_GREEN}als${_ALS_C_RESET} <name> [args...]             Run alias with extra arguments

${_ALS_C_BOLD}MANAGE ALIASES${_ALS_C_RESET}
  ${_ALS_C_GREEN}als --add${_ALS_C_RESET} <name> <cmd> [--desc \"text\"]    Add a new alias
  ${_ALS_C_GREEN}als --add --file${_ALS_C_RESET} <path>                    Add aliases from file
  ${_ALS_C_GREEN}als --delete${_ALS_C_RESET} <name> [-y]                   Delete an alias
  ${_ALS_C_GREEN}als --update${_ALS_C_RESET} <name> [--cmd c] [--desc d]   Update an alias
  ${_ALS_C_GREEN}als --reset${_ALS_C_RESET} [-y]                           Delete ALL aliases

${_ALS_C_BOLD}SEARCH & BROWSE${_ALS_C_RESET}
  ${_ALS_C_GREEN}als --search${_ALS_C_RESET} <keyword>           Search by name/command/description
  ${_ALS_C_GREEN}als --list${_ALS_C_RESET}                       Show all aliases in a table

${_ALS_C_BOLD}IMPORT & EXPORT${_ALS_C_RESET}
  ${_ALS_C_GREEN}als --import${_ALS_C_RESET} <file>              Bulk import aliases from file
  ${_ALS_C_GREEN}als --export${_ALS_C_RESET} [file]              Export aliases to file

${_ALS_C_BOLD}OTHER${_ALS_C_RESET}
  ${_ALS_C_GREEN}als --reload${_ALS_C_RESET}                     Reload aliases from data file
  ${_ALS_C_GREEN}als --count${_ALS_C_RESET}                      Show total number of aliases
  ${_ALS_C_GREEN}als --version${_ALS_C_RESET}                    Show version
  ${_ALS_C_GREEN}als --help${_ALS_C_RESET}                       Show this help

${_ALS_C_BOLD}FILE FORMAT${_ALS_C_RESET} (for import/export)
  ${_ALS_C_DIM}name|command|description${_ALS_C_RESET}
  ${_ALS_C_DIM}# Lines starting with # are comments${_ALS_C_RESET}

${_ALS_C_BOLD}SHORTCUTS${_ALS_C_RESET}
  --add = -a    --delete = -r    --update = -u
  --search = -s --list = -l      --import = -i
  --export = -e --help = -h      --version = -v

${_ALS_C_BOLD}DATA FILE${_ALS_C_RESET}
  ${_ALS_C_DIM}${ALS_DATA_FILE}${_ALS_C_RESET}
"
}

# ─── Tab Completion ───────────────────────────────────────────
_als_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Complete subcommands after 'als'
  if [[ "$prev" == "als" ]]; then
    local subcommands="--add --delete --update --reset --search --list --import --export --reload --count --version --help"

    # Add alias names to completions
    _als_read_aliases
    local alias_names=""
    local i
    for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
      alias_names+=" ${_ALS_NAMES[$i]}"
    done

    COMPREPLY=( $(compgen -W "${subcommands}${alias_names}" -- "$cur") )
    return
  fi

  # Complete file paths for --import, --export, --add --file
  if [[ "$prev" == "--import" || "$prev" == "-i" || "$prev" == "--export" || "$prev" == "-e" || "$prev" == "--file" || "$prev" == "-f" ]]; then
    COMPREPLY=( $(compgen -f -- "$cur") )
    return
  fi

  # Complete alias names for --delete, --update
  if [[ "$prev" == "--delete" || "$prev" == "--del" || "$prev" == "--remove" || "$prev" == "-r" || \
        "$prev" == "--update" || "$prev" == "--edit" || "$prev" == "-u" ]]; then
    _als_read_aliases
    local alias_names=""
    local i
    for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
      alias_names+=" ${_ALS_NAMES[$i]}"
    done
    COMPREPLY=( $(compgen -W "${alias_names}" -- "$cur") )
    return
  fi
}

complete -F _als_completion als

# ─── First-run hints ─────────────────────────────────────────
if [[ $(_als_count) -eq 0 ]]; then
  _als_info "Welcome to ${_ALS_C_BOLD}als${_ALS_C_RESET}! Start by adding aliases:"
  echo -e "  ${_ALS_C_DIM}als --add gs \"git status\" --desc \"Show git status\"${_ALS_C_RESET}"
  echo -e "  ${_ALS_C_DIM}als --import my_aliases.txt${_ALS_C_RESET}"
fi

if ! command -v fzf &>/dev/null; then
  _als_info "Tip: Install ${_ALS_C_BOLD}fzf${_ALS_C_RESET} for interactive picker → ${_ALS_C_DIM}sudo apt install fzf${_ALS_C_RESET}"
fi

