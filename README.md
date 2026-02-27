# als — Bash Alias Manager

A modular, lightweight Bash alias manager with CRUD operations, keyword search, descriptions, file import/export, and interactive fzf picker.

## ✨ Features

- **CRUD**: `--add`, `--delete`, `--update` aliases with descriptions
- **Search**: Keyword search across names, commands, and descriptions
- **Import/Export**: Bulk load aliases from file or export to share
- **Interactive picker**: fzf-powered fuzzy finder
- **Tab completion**: Auto-complete all commands and alias names
- **Single-file release**: Dev in modules, build to one portable `.sh` file
- **Backup**: Auto-backup before destructive operations

## 🚀 Quick Install

```bash
git clone <repo-url> bash-alias-manager
cd bash-alias-manager
bash install.sh
source ~/.bashrc
```

## 📖 Usage

```bash
als                              # Interactive fzf picker
als <name>                       # Run alias directly
als --add gs "git status"        # Add alias
als --add gs "git status" --desc "Show git status"  # With description
als --add --file my_aliases.txt  # Add from file
als --delete gs                  # Delete alias
als --update gs --cmd "git status -sb" --desc "Short status"
als --search git                 # Search aliases
als --list                       # Show all aliases
als --import aliases.txt         # Bulk import
als --export backup.txt          # Export aliases
als --help                       # Show help
```

## 📁 Alias File Format

For import/export, use pipe-separated format:

```
# Comments start with #
name|command|description
gs|git status|Show git working tree status
gp|git pull|Pull latest changes
dcu|docker compose up -d|Start docker compose
```

## 🏗️ Project Structure

```
bash-alias-manager/
├── src/
│   ├── core.sh        # Constants, data management, utilities
│   ├── crud.sh        # --add, --delete, --update
│   ├── search.sh      # Keyword search
│   ├── import.sh      # Import/export from files
│   ├── display.sh     # List view, fzf picker
│   └── als.sh         # Main entry, arg parsing, completion
├── build.sh           # Package into single release file
├── install.sh         # Automated installer
├── test.sh            # Test suite
└── README.md
```

## 🔧 Development

**Source in dev mode** (loads modules individually):

```bash
source src/als.sh
```

**Build release** (single file):

```bash
bash build.sh
# → produces als_release.sh
```

**Run tests**:

```bash
bash test.sh
```

## 📂 Data Files

| File              | Purpose                           |
| ----------------- | --------------------------------- |
| `~/.als_aliases`  | Alias storage (pipe-separated)    |
| `~/.als_backups/` | Auto-backups before delete/update |
| `~/.als/als.sh`   | Installed release file            |

## ⌨️ Shortcuts

| Long        | Short | Description      |
| ----------- | ----- | ---------------- |
| `--add`     | `-a`  | Add alias        |
| `--delete`  | `-r`  | Delete alias     |
| `--update`  | `-u`  | Update alias     |
| `--search`  | `-s`  | Search aliases   |
| `--list`    | `-l`  | List all         |
| `--import`  | `-i`  | Import from file |
| `--export`  | `-e`  | Export to file   |
| `--help`    | `-h`  | Show help        |
| `--version` | `-v`  | Show version     |

## License

MIT
