#!/usr/bin/env bash
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
