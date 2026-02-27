#!/usr/bin/env bash
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
