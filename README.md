# als — Bash/Zsh Alias Manager

[![Release Build](https://github.com/khuongdv/bash-alias-manager/actions/workflows/release.yml/badge.svg)](https://github.com/khuongdv/bash-alias-manager/actions/workflows/release.yml)

A modular, lightweight Alias manager for Bash and Zsh with CRUD operations, keyword search, descriptions, file import/export, and interactive fzf picker.

_Read this in other languages: [English](#english), [Tiếng Việt](#tiếng-việt)_

---

## English

### ✨ Features

- **Multi-shell Support**: Works seamlessly on both `bash` and `zsh`.
- **Interactive Forms & Picker**:
  - `als --add` opens an interactive form to input alias details.
  - `als --delete` opens an fzf fuzzy finder to select aliases to delete.
  - `als` opens the main fzf fuzzy finder to search and execute aliases.
- **Full CRUD**: `--add`, `--delete`, `--update`, and `--reset` aliases with optional descriptions.
- **Search**: Keyword search across names, commands, and descriptions.
- **Import/Export**: Bulk load aliases from file or export to share with others.
- **Tab completion**: Auto-complete all sub-commands and alias names.
- **CI/CD Automation**: Configured with GitHub Actions to auto-build a clean, single-file release `als_release.sh` when `als.json` version changes.
- **Safety First**: Auto-backups before any destructive operations (`delete`, `update`, `reset`).

### 🚀 Quick Install

```bash
git clone <repo-url> bash-alias-manager
cd bash-alias-manager
bash install.sh
```

_The installer will automatically detect and configure `~/.bashrc` and/or `~/.zshrc`._

### 📖 Usage

```bash
als                              # Interactive fzf picker to run aliases
als <name>                       # Run alias directly (e.g., als gs)

# --- Add ---
als --add                        # Interactive form to add new alias
als --add gs "git status"        # Add alias inline
als --add gs "git status" --desc "Show git status"

# --- Delete & Reset ---
als --delete                     # Interactive fzf picker to delete
als --delete gs                  # Delete specific alias
als --reset                      # Delete ALL aliases (prompts for confirmation)

# --- Edit ---
als --update gs --cmd "git status -sb" --desc "Short status"

# --- Search & View ---
als --search git                 # Search aliases by keyword
als --list                       # Show all aliases in a formatted table

# --- Import / Export ---
als --import aliases.txt         # Bulk import from file
als --export backup.txt          # Export aliases to file
```

### 📁 Alias Storage Format

Aliases are stored in `~/.als_aliases` in a simple pipe-delimited format:

```text
gs|git status|Show git working tree status
gp|git pull|Pull latest changes
```

---

## Tiếng Việt

### ✨ Tính Năng

- **Hỗ trợ Đa Shell**: Hoạt động hoàn hảo trên cả `bash` và `zsh`.
- **Nhập liệu & Chọn tương tác**:
  - Chạy `als --add` sẽ mở form nhập liệu tương tác (không cần nhớ cú pháp dài).
  - Chạy `als --delete` sẽ mở giao diện chọn fzf để tìm và xóa alias an toàn.
  - Chạy `als` sẽ mở giao diện fzf chính để tìm và chạy alias.
- **Quản lý đầy đủ (CRUD)**: `--add` (thêm), `--delete` (xóa), `--update` (sửa), và `--reset` (xóa toàn bộ) kèm tính năng mô tả (description).
- **Tìm kiếm**: Tìm từ khóa trên cả tên, lệnh và mô tả.
- **Nhập/Xuất file**: Import hàng loạt alias từ file text hoặc export ra file để chia sẻ.
- **Gợi ý phím Tab (Tab completion)**: Tự động điền phần tử phụ (sub-commands) và tên alias.
- **Tự động hóa CI/CD**: Tích hợp GitHub Actions để tự động build ra file duy nhất `als_release.sh` mỗi khi thay đổi version trong `als.json`.
- **An Toàn Tiên Quyết**: Tự động sao lưu (backup) database trước mọi thao tác nguy hiểm (`delete`, `update`, `reset`).

### 🚀 Cài Đặt Nhanh

```bash
git clone <repo-url> bash-alias-manager
cd bash-alias-manager
bash install.sh
```

_Trình cài đặt sẽ tự động nhận diện và cấu hình cho `~/.bashrc` và/hoặc `~/.zshrc` của bạn._

### 📖 Cách Sử Dụng

```bash
als                              # Mở giao diện fzf chọn và chạy lệnh alias
als <name>                       # Chạy alias trực tiếp (VD: als gs)

# --- Thêm (Add) ---
als --add                        # Mở form nhập liệu tương tác để thêm alias
als --add gs "git status"        # Thêm alias bằng dòng lệnh trực tiếp
als --add gs "git status" --desc "Show git status"

# --- Xóa (Delete & Reset) ---
als --delete                     # Mở giao diện fzf để chọn alias muốn xóa
als --delete gs                  # Xóa chi tiết một alias tên là 'gs'
als --reset                      # Xóa TOÀN BỘ alias (có cơ chế hỏi xác nhận)

# --- Sửa (Update) ---
als --update gs --cmd "git status -sb" --desc "Short status"

# --- Tìm kiếm & Xem biểu đồ ---
als --search git                 # Tìm kiếm alias bằng từ khóa
als --list                       # Hiển thị tất cả alias trong bảng

# --- Nhập / Xuất (Import / Export) ---
als --import aliases.txt         # Import hàng loạt từ file
als --export backup.txt          # Xuất toàn bộ alias ra file
```

### 📁 Định Dạng Lưu Trữ

Các alias được lưu trong file `~/.als_aliases` theo chuẩn ngăn cách bằng dấu gạch đứng `|`:

```text
gs|git status|Hiển thị trạng thái git
gp|git pull|Kéo code mới nhất về
```

---

## 🏗️ Project Structure / Cấu Trúc Dự Án

```
bash-alias-manager/
├── .github/workflows/
│   └── release.yml    # Auto-builds release on version bump
├── src/
│   ├── core.sh        # Constants, data management, validation
│   ├── crud.sh        # --add, --delete, --update, --reset
│   ├── search.sh      # Keyword search across all fields
│   ├── import.sh      # Import/export from/to files
│   ├── display.sh     # Formatted list, fzf picker
│   └── als.sh         # Main entry, arg parsing, completion
├── install.sh         # Automated installer (bash + zsh)
├── build.sh           # Packages src/ → single release file
├── test.sh            # Test suite (25 tests)
├── als.json           # Version and metadata config
└── README.md
```

## License

MIT
