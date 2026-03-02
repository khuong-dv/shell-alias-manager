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
  - `als --update` opens an fzf picker to select an alias followed by an interactive edit form.
  - `als` opens the main fzf fuzzy finder to search and execute aliases.
- **Clash Warning**: Automatically detects if a new alias name conflicts with an existing system command and warns the user.
- **Full CRUD**: `--add`, `--delete`, `--update`, and `--reset` aliases with optional descriptions.
- **Search**: Keyword search across names, commands, and descriptions.
- **Import/Export**: Bulk load aliases from file or export to share with others.
- **Tab completion**: Auto-complete all sub-commands and alias names.
- **Safety First**: Auto-backups before any destructive operations (`delete`, `update`, `reset`).

### 🚀 Installation Modes

#### 1. Standard Mode (Use Built Version)

Best for general users who just want to use the tool without managing the source code.

1. Download [als_release.sh](https://raw.githubusercontent.com/khuongdv/bash-alias-manager/master/als_release.sh).
2. Save it to `~/.als/als.sh`.
3. Add `source ~/.als/als.sh` to your `~/.bashrc` or `~/.zshrc`.
4. Restart your terminal.

#### 2. Developer Mode (Full Source)

Best for contributors or those who want to customize the tool.

```bash
git clone <repo-url> bash-alias-manager
cd bash-alias-manager
bash install.sh
```

_The installer will automatically build the release and configure your shell files._

### 📖 Usage

```bash
als                              # Interactive fzf picker to run aliases
als <name>                       # Run alias directly (e.g., als gs)

# --- Add ---
als --add                        # Interactive form to add new alias

# --- Delete & Reset ---
als --delete                     # Interactive fzf picker to delete
als --reset                      # Delete ALL aliases (prompts for confirmation)

# --- Edit ---
als --update                     # Interactive fzf picker to select alias + edit form

# --- Search & View ---
als --search git                 # Search aliases by keyword
als --list                       # Show all aliases in a formatted table
```

---

## Tiếng Việt

### ✨ Tính Năng

- **Hỗ trợ Đa Shell**: Hoạt động hoàn hảo trên cả `bash` và `zsh`.
- **Nhập liệu & Chọn tương tác**:
  - `als --add`: Mở form nhập liệu tương tác.
  - `als --delete`: Mở giao diện chọn fzf để tìm và xóa alias.
  - `als --update`: Mở giao diện chọn fzf để tìm và sửa alias với form điền sẵn nội dung cũ.
  - `als`: Mở giao diện fzf chính để tìm và chạy alias.
- **Cảnh báo trùng lệnh**: Tự động phát hiện khi đặt tên alias trùng với lệnh hệ thống.
- **Quản lý đầy đủ (CRUD)**: `--add`, `--delete`, `--update`, `--reset` kèm tính năng mô tả.
- **Tìm kiếm**: Tìm từ khóa trên cả tên, lệnh và mô tả.
- **An Toàn**: Tự động sao lưu (backup) trước khi xóa hoặc sửa.

### 🚀 Các Chế Độ Cài Đặt

#### 1. Chế độ Tiêu chuẩn (Sử dụng File đã Build)

Dành cho người dùng thông thường, chỉ cần script chạy là đủ.

1. Tải file [als_release.sh](https://raw.githubusercontent.com/khuongdv/bash-alias-manager/master/als_release.sh).
2. Lưu vào đường dẫn `~/.als/als.sh`.
3. Thêm dòng `source ~/.als/als.sh` vào file `~/.bashrc` hoặc `~/.zshrc`.
4. Khởi động lại terminal.

#### 2. Chế độ Nhà phát triển (Mã nguồn đầy đủ)

Dành cho người muốn đóng góp hoặc tùy chỉnh sâu dự án.

```bash
git clone <repo-url> bash-alias-manager
cd bash-alias-manager
bash install.sh
```

_Trình cài đặt sẽ tự động build file release và cấu hình shell cho bạn._

### 📖 Cách Sử Dụng

```bash
als                              # Mở giao diện fzf chọn và chạy lệnh alias
als --add                        # Mở form tương tác để thêm alias mới
als --delete                     # Mở giao diện fzf để chọn alias muốn xóa
als --update                     # Mở giao diện fzf chọn alias + form sửa
als --search git                 # Tìm kiếm alias bằng từ khóa
als --list                       # Hiển thị tất cả alias trong bảng
```

---

## 🏗️ Project Structure / Cấu Trúc Dự Án

```
bash-alias-manager/
├── .github/workflows/
│   └── release.yml    # Auto-builds release on version bump
├── src/               # Source code (Development mode)
├── install.sh         # Automated installer
├── build.sh           # Packages src/ → als_release.sh
├── als.json           # Version config
└── als_release.sh     # Standalone release file (Standard mode)
```

## License

MIT
