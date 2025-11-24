# Change: Add Change Preview Before Applying

## Why
The script currently has a generic `welcome()` function that shows what the script *can* do, but it runs **before** collecting user information. Once the script collects the user's email, name, and checks which files exist, it immediately proceeds to make changes without showing a **specific summary** of what will actually happen with the user's actual data.

The `welcome()` function (line 456) shows generic information like "te ayudará a configurar Git" but doesn't show:
- The specific email/name that will be used
- Which files will be created vs. modified vs. overwritten
- The exact Git configuration values that will be applied
- Whether GPG keys will be generated

This proposal adds a **specific preview** that runs **after** user info is collected, showing exactly what will happen with the user's actual data before any changes are made.

## What Changes
- Add `show_changes_summary()` function that displays a **specific, data-driven preview** of all changes
- Show which files will be created, modified, or overwritten (based on actual file system state)
- Display **actual Git configuration values** that will be applied (using collected `$USER_EMAIL` and `$USER_NAME`)
- Show GPG key generation status if applicable
- Display shell configuration files that will be modified
- Require user confirmation before proceeding with changes
- Integrate preview into main workflow **after** `collect_user_info()` (line 2338) but **before** any file modifications or key generation
- Support non-interactive mode (skip preview or auto-confirm)

**Key Difference from `welcome()`:**
- `welcome()` = Generic introduction at script start (before knowing user data)
- `show_changes_summary()` = Specific preview after collecting user data (shows actual values and file states)

## Impact
- **Affected specs**: `change-preview` (new capability)
- **Affected code**: 
  - `gitconfig.sh` - Add `show_changes_summary()` function
  - `gitconfig.sh:main()` - Call preview after `collect_user_info()` and before key generation
  - Integration with `ask_yes_no()` for confirmation
- **User benefit**: Complete transparency about what the script will do, increasing user confidence and reducing errors
- **Breaking changes**: None (additive enhancement, existing behavior preserved if preview is skipped in non-interactive mode)

