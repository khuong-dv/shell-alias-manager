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
    # Interactive mode: prompt for each field
    _als_header "➕ Add new alias"

    if [[ ${#positional[@]} -ge 1 ]]; then
      name="${positional[0]}"
      echo -e "  ${_ALS_C_CYAN}Name:${_ALS_C_RESET}        ${name}"
    else
      echo -n -e "  ${_ALS_C_CYAN}Name:${_ALS_C_RESET}        "
      read -r name
      if [[ -z "$name" ]]; then
        _als_error "Name cannot be empty. Aborted."
        return 1
      fi
    fi

    echo -n -e "  ${_ALS_C_CYAN}Command:${_ALS_C_RESET}     "
    read -r cmd
    if [[ -z "$cmd" ]]; then
      _als_error "Command cannot be empty. Aborted."
      return 1
    fi

    echo -n -e "  ${_ALS_C_CYAN}Description:${_ALS_C_RESET} ${_ALS_C_DIM}(optional, press Enter to skip)${_ALS_C_RESET} "
    read -r desc
    echo
  else
    name="${positional[0]}"
    # Join remaining positional args as the command
    cmd="${positional[*]:1}"
  fi

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
# Usage: als --delete [name] [-y]
_als_cmd_delete() {
  local name="$1"
  local force=false

  if [[ "$1" == "-y" || "$1" == "--yes" ]]; then
    force=true
    name=""
  elif [[ "$2" == "-y" || "$2" == "--yes" ]]; then
    force=true
  fi

  # No name → interactive fzf picker
  if [[ -z "$name" ]]; then
    _als_read_aliases

    if [[ ${#_ALS_NAMES[@]} -eq 0 ]]; then
      _als_warn "No aliases to delete."
      return 0
    fi

    # Find max name width
    local max_name=0 i
    for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
      local len=${#_ALS_NAMES[$i]}
      (( len > max_name )) && max_name=$len
    done

    if command -v fzf &>/dev/null; then
      local chosen
      chosen=$(
        for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
          local desc="${_ALS_DESCS[$i]}"
          [[ -z "$desc" ]] && desc="—"
          printf "%-${max_name}s  │  %-40s  │  %s\n" \
            "${_ALS_NAMES[$i]}" "${_ALS_CMDS[$i]}" "$desc"
        done | fzf \
          --prompt="delete❯ " \
          --header="Select alias to DELETE │ ENTER to confirm │ ESC to cancel" \
          --height=40% \
          --reverse \
          --border=rounded \
          --color="header:italic:yellow,prompt:red,pointer:red"
      )

      if [[ -z "$chosen" ]]; then
        _als_info "Cancelled."
        return 0
      fi

      name=$(echo "$chosen" | awk '{print $1}')
    else
      # Fallback: numbered list
      _als_header "🗑  Select alias to delete"
      for (( i=0; i<${#_ALS_NAMES[@]}; i++ )); do
        printf "  ${_ALS_C_YELLOW}%2d${_ALS_C_RESET}) ${_ALS_C_GREEN}%-${max_name}s${_ALS_C_RESET}  %s\n" \
          $((i+1)) "${_ALS_NAMES[$i]}" "${_ALS_CMDS[$i]}"
      done
      echo
      echo -n -e "  ${_ALS_C_CYAN}Enter number (0 to cancel):${_ALS_C_RESET} "
      local choice
      read -r choice

      if [[ -z "$choice" || "$choice" == "0" ]]; then
        _als_info "Cancelled."
        return 0
      fi

      if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#_ALS_NAMES[@]} )); then
        _als_error "Invalid selection."
        return 1
      fi

      name="${_ALS_NAMES[$((choice-1))]}"
    fi
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
