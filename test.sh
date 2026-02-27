#!/usr/bin/env bash
# ============================================================
#  test.sh — Test suite for als (Bash Alias Manager)
#  Usage: bash test.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DATA_FILE="/tmp/als_test_aliases_$$"
TEST_BACKUP_DIR="/tmp/als_test_backups_$$"
PASS=0
FAIL=0

# Colors
G="\033[1;32m"
R="\033[1;31m"
Y="\033[1;33m"
C="\033[1;36m"
N="\033[0m"

# ─── Test helpers ─────────────────────────────────────────────
_test_pass() { echo -e "  ${G}✔ PASS${N}: $1"; (( PASS++ )); }
_test_fail() { echo -e "  ${R}✘ FAIL${N}: $1"; (( FAIL++ )); }

_test_assert() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == *"$expected"* ]]; then
    _test_pass "$desc"
  else
    _test_fail "$desc (expected '$expected', got '$actual')"
  fi
}

# ─── Setup ────────────────────────────────────────────────────
_test_setup() {
  # Override data paths for testing
  export ALS_DATA_FILE="$TEST_DATA_FILE"
  export ALS_BACKUP_DIR="$TEST_BACKUP_DIR"

  # Clean up
  rm -f "$TEST_DATA_FILE"
  rm -rf "$TEST_BACKUP_DIR"

  # Source als
  source "${SCRIPT_DIR}/src/als.sh"
}

# ─── Teardown ─────────────────────────────────────────────────
_test_teardown() {
  rm -f "$TEST_DATA_FILE"
  rm -rf "$TEST_BACKUP_DIR"
}

# ─── Tests ────────────────────────────────────────────────────

echo -e "\n${C}═══════════════════════════════════════${N}"
echo -e "${C}  als — Test Suite${N}"
echo -e "${C}═══════════════════════════════════════${N}\n"

# --- Test 1: Data file creation ---
echo -e "${Y}▸ Test: Data file creation${N}"
_test_setup
_test_assert "Data file exists after init" "" ""
[[ -f "$TEST_DATA_FILE" ]] && _test_pass "Data file created" || _test_fail "Data file not created"

# --- Test 2: Add alias ---
echo -e "\n${Y}▸ Test: Add alias${N}"
_test_setup
output=$(als --add mytest "echo hello world" --desc "Test alias" 2>&1)
_test_assert "Add reports success" "Added" "$output"
content=$(cat "$TEST_DATA_FILE")
_test_assert "Data file contains alias" "mytest|echo hello world|Test alias" "$content"

# --- Test 3: Add duplicate ---
echo -e "\n${Y}▸ Test: Add duplicate${N}"
output=$(als --add mytest "echo again" 2>&1)
_test_assert "Duplicate rejected" "already exists" "$output"

# --- Test 4: List aliases ---
echo -e "\n${Y}▸ Test: List aliases${N}"
output=$(als --list 2>&1)
_test_assert "List shows alias name" "mytest" "$output"
_test_assert "List shows command" "echo hello world" "$output"

# --- Test 5: Search ---
echo -e "\n${Y}▸ Test: Search${N}"
output=$(als --search hello 2>&1)
_test_assert "Search finds by command" "mytest" "$output"
output=$(als --search "Test alias" 2>&1)
_test_assert "Search finds by description" "mytest" "$output"
output=$(als --search nonexistent 2>&1)
_test_assert "Search reports no match" "No aliases matching" "$output"

# --- Test 6: Update alias ---
echo -e "\n${Y}▸ Test: Update alias${N}"
als --update mytest --cmd "echo updated" --desc "Updated desc" >/dev/null 2>&1
content=$(cat "$TEST_DATA_FILE")
_test_assert "Updated command in file" "mytest|echo updated|Updated desc" "$content"

# --- Test 7: Delete alias ---
echo -e "\n${Y}▸ Test: Delete alias${N}"
als --delete mytest -y >/dev/null 2>&1
content=$(cat "$TEST_DATA_FILE")
if [[ "$content" != *"mytest"* ]]; then
  _test_pass "Alias removed from file"
else
  _test_fail "Alias still in file after delete"
fi

# --- Test 8: Backup on delete ---
echo -e "\n${Y}▸ Test: Backup creation${N}"
_test_setup
als --add backuptest "echo backup" >/dev/null 2>&1
als --delete backuptest -y >/dev/null 2>&1
backup_count=$(ls "$TEST_BACKUP_DIR" 2>/dev/null | wc -l)
_test_assert "Backup file created" "1" "$backup_count"

# --- Test 9: Import from file ---
echo -e "\n${Y}▸ Test: Import from file${N}"
_test_setup
import_file="/tmp/als_test_import_$$.txt"
cat > "$import_file" <<EOF
# Test import file
gs|git status|Show status
gp|git pull|Pull changes
invalid_line_no_pipe
EOF
output=$(als --import "$import_file" 2>&1)
_test_assert "Import reports added" "Added" "$output"
content=$(cat "$TEST_DATA_FILE")
_test_assert "Imported gs" "gs|git status|Show status" "$content"
_test_assert "Imported gp" "gp|git pull|Pull changes" "$content"
rm -f "$import_file"

# --- Test 10: Export ---
echo -e "\n${Y}▸ Test: Export${N}"
export_file="/tmp/als_test_export_$$.txt"
als --export "$export_file" >/dev/null 2>&1
_test_assert "Export file created" "" ""
[[ -f "$export_file" ]] && _test_pass "Export file exists" || _test_fail "Export file missing"
if [[ -f "$export_file" ]]; then
  content=$(cat "$export_file")
  _test_assert "Export contains aliases" "gs|git status" "$content"
fi
rm -f "$export_file"

# --- Test 11: Count ---
echo -e "\n${Y}▸ Test: Count${N}"
output=$(als --count 2>&1)
_test_assert "Count shows number" "2" "$output"

# --- Test 12: Help ---
echo -e "\n${Y}▸ Test: Help${N}"
output=$(als --help 2>&1)
_test_assert "Help shows usage" "USAGE" "$output"
_test_assert "Help shows MANAGE" "MANAGE" "$output"

# --- Test 13: Version ---
echo -e "\n${Y}▸ Test: Version${N}"
output=$(als --version 2>&1)
_test_assert "Version shows version" "1.0.0" "$output"

# --- Test 14: Build script ---
echo -e "\n${Y}▸ Test: Build script${N}"
build_output=$(bash "${SCRIPT_DIR}/build.sh" 2>&1)
_test_assert "Build succeeds" "Built" "$build_output"
[[ -f "${SCRIPT_DIR}/als_release.sh" ]] && _test_pass "Release file created" || _test_fail "Release file missing"

# --- Test 15: Release file works ---
if [[ -f "${SCRIPT_DIR}/als_release.sh" ]]; then
  echo -e "\n${Y}▸ Test: Release file loads${N}"
  (
    export ALS_DATA_FILE="$TEST_DATA_FILE"
    export ALS_BACKUP_DIR="$TEST_BACKUP_DIR"
    source "${SCRIPT_DIR}/als_release.sh"
    output=$(als --version 2>&1)
    if [[ "$output" == *"1.0.0"* ]]; then
      echo -e "  ${G}✔ PASS${N}: Release file loads and works"
    else
      echo -e "  ${R}✘ FAIL${N}: Release file failed"
    fi
  )
fi

# ─── Summary ──────────────────────────────────────────────────
_test_teardown

echo -e "\n${C}═══════════════════════════════════════${N}"
echo -e "  ${G}Passed: ${PASS}${N}  |  ${R}Failed: ${FAIL}${N}"
echo -e "${C}═══════════════════════════════════════${N}"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
