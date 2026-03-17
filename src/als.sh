#!/usr/bin/env bash
# ============================================================
#  als.sh — Main entry point for Alias Manager
#  Usage: source this file (or the built release file)
# ============================================================

# ─── Resolve script directory ─────────────────────────────────
_ALS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Source all modules ───────────────────────────────────────
source "${_ALS_DIR}/core.sh"
source "${_ALS_DIR}/crud.sh"
source "${_ALS_DIR}/search.sh"
source "${_ALS_DIR}/import.sh"
source "${_ALS_DIR}/display.sh"

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

