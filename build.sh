#!/usr/bin/env bash
# ============================================================
#  build.sh — Package all src/ modules into a single release file
#  Usage: bash build.sh
#  Output: als_release.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/src"
OUTPUT="${SCRIPT_DIR}/als_release.sh"

# Module load order (dependencies first)
MODULES=(
  "core.sh"
  "crud.sh"
  "search.sh"
  "import.sh"
  "display.sh"
  "als.sh"
)

echo "🔨 Building als release..."

{
  # Header
  cat <<'HEADER'
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
HEADER

  echo ""
  echo "# ── Build info ──"
  echo "# Built: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "# Version: $(grep 'ALS_VERSION=' "${SRC_DIR}/core.sh" | head -1 | cut -d'"' -f2)"
  echo ""

  # Concatenate modules
  for module in "${MODULES[@]}"; do
    local_path="${SRC_DIR}/${module}"

    if [[ ! -f "$local_path" ]]; then
      echo "❌ Module not found: ${module}" >&2
      exit 1
    fi

    echo "# ═══════════════════════════════════════════════════════════"
    echo "# Module: ${module}"
    echo "# ═══════════════════════════════════════════════════════════"
    echo ""

    # Read file, strip shebang and source lines (for als.sh)
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Skip shebang
      [[ "$line" == "#!/"* ]] && continue
      # Skip source lines that load other modules
      [[ "$line" == source* && "$line" == *"_ALS_DIR"* ]] && continue
      # Skip _ALS_DIR resolution
      [[ "$line" == '_ALS_DIR='* ]] && continue

      echo "$line"
    done < "$local_path"

    echo ""
  done

} > "$OUTPUT"

chmod +x "$OUTPUT"

# File size
local_size=$(wc -c < "$OUTPUT")
local_lines=$(wc -l < "$OUTPUT")

echo "✔ Built: ${OUTPUT}"
echo "  Lines: ${local_lines}"
echo "  Size:  ${local_size} bytes"
echo ""
echo "Usage:"
echo "  source ${OUTPUT}"
echo "  # or copy to ~/.als/ and add to .bashrc"
