#!/usr/bin/env bash
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
