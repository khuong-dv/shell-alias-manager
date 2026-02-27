#!/usr/bin/env bash
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
