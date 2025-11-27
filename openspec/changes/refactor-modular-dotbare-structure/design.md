# Design: dotbare-Style Modular Architecture

## Overview

This document describes the technical design for refactoring `gitconfig.sh` into a modular structure following the dotbare repository pattern. The design prioritizes:

1. **Exact behavioral parity** with the current implementation
2. **dotbare conventions** for structure, documentation, and patterns
3. **Single-responsibility modules** that are independently testable
4. **Clear dependency ordering** for module loading

---

## Module Architecture

### Layer 1: Configuration (`config/`)

Configuration files loaded first; define all global state.

```
config/
├── defaults.sh              # All global variables with documentation
└── templates/
    ├── gitconfig.template   # .gitconfig content with placeholders
    └── gitmessage.template  # .gitmessage content
```

**`config/defaults.sh`** establishes:
- Script directories (`SCRIPT_DIR`, `BACKUP_DIR`, `LOG_FILE`)
- Behavior flags (`DEBUG`, `INTERACTIVE_MODE`, `AUTO_UPLOAD_KEYS`)
- State variables (`SSH_KEY_UPLOADED`, `GPG_KEY_UPLOADED`, `GH_INSTALL_ATTEMPTED`)
- User data (`USER_EMAIL`, `USER_NAME`, `GPG_KEY_ID`, `GENERATE_GPG`)
- Progress tracking (`TOTAL_STEPS`, `CURRENT_STEP`, `WORKFLOW_STEPS`)

### Layer 2: Core Utilities (`scripts/core/`)

Foundational utilities with no external dependencies (except `defaults.sh`).

```
scripts/core/
├── colors.sh      # COLORS array, c(), cr()
├── logger.sh      # log() function
├── validation.sh  # validate_email(), initial_checks()
├── ui.sh          # show_separator(), success(), error(), warning(), info(),
│                  # show_spinner(), show_progress_bar(), check_unicode_support(),
│                  # logo(), welcome(), ask_yes_no()
└── common.sh      # detect_os(), copy_to_clipboard()
```

**Load order within core:**
1. `colors.sh` (no dependencies)
2. `logger.sh` (uses colors)
3. `validation.sh` (uses colors, logger)
4. `ui.sh` (uses colors, logger)
5. `common.sh` (uses colors, ui)

### Layer 3: Feature Modules (`scripts/`)

Domain-specific functionality, loaded after core.

```
scripts/
├── dependencies.sh   # check_dependencies(), auto_install_dependencies()
├── ssh.sh            # backup_existing_keys(), generate_ssh_key(), 
│                     # create_ssh_agent_script()
├── gpg.sh            # generate_gpg_key(), generate_gpg_key_alternative(),
│                     # setup_gpg_environment(), cleanup_gpg_processes()
├── git-config.sh     # configure_git(), generate_gitconfig(),
│                     # create_commit_template(), collect_user_info()
├── github.sh         # ensure_github_cli_ready(), show_manual_gh_install_instructions(),
│                     # upload_ssh_key_to_github(), upload_gpg_key_to_github(),
│                     # maybe_upload_keys()
└── finalize.sh       # show_changes_summary(), display_keys(), save_keys_to_files(),
                      # test_github_connection(), show_final_instructions()
```

### Layer 4: Entry Point (`gitconfig.sh`)

Thin orchestrator that:
1. Detects its own directory (`mydir`)
2. Sources all modules in correct order
3. Parses arguments
4. Executes `main()` function
5. Handles signals (trap cleanup)

---

## dotbare Documentation Standard

### File Header Format

Every module MUST include this header format (from dotbare):

```bash
#!/usr/bin/env bash
#
# [One-line brief description]
#
# @params
# Globals
#   ${VARIABLE1}: description of global variable it uses/modifies
#   ${VARIABLE2}: description of another global variable
#   ${mydir}: current directory of the script, used for imports
# Arguments
#   -h|--help: show help message (if applicable)
#   --flag: flag description (if applicable)
# Returns
#   0: success
#   1: error (if applicable)
#
# Usage example:
#   source "${mydir}/scripts/core/colors.sh"
```

### Function Documentation Format

Each function MUST include inline documentation:

```bash
#######################################
# Brief description of what the function does
# Globals:
#   ${VARIABLE}: variable used or modified
# Arguments:
#   $1: description of first argument
#   $2: description of second argument
# Outputs:
#   Writes to stdout/stderr as appropriate
# Returns:
#   0: success
#   1: error condition
#######################################
function_name() {
    local arg1="$1"
    # implementation
}
```

---

## Module Sourcing Pattern

### Main Entry Point Pattern

```bash
#!/usr/bin/env bash
#
# Main entry script for gitconfig, used to configure Git and GitHub
#
# @params
# Globals
#   ${mydir}: string, directory of the executing script, used for sourcing helpers
# Arguments
#   --non-interactive: run without user prompts
#   --auto-upload: automatically upload keys to GitHub
#   -h|--help: show help message
# Returns
#   0: success
#   1: error

mydir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
source "${mydir}/config/defaults.sh"

# Load core utilities (order matters)
source "${mydir}/scripts/core/colors.sh"
source "${mydir}/scripts/core/logger.sh"
source "${mydir}/scripts/core/validation.sh"
source "${mydir}/scripts/core/ui.sh"
source "${mydir}/scripts/core/common.sh"

# Load feature modules
source "${mydir}/scripts/dependencies.sh"
source "${mydir}/scripts/ssh.sh"
source "${mydir}/scripts/gpg.sh"
source "${mydir}/scripts/git-config.sh"
source "${mydir}/scripts/github.sh"
source "${mydir}/scripts/finalize.sh"

# Signal handling
trap cleanup SIGINT SIGTERM

# Main execution
main "$@"
```

### Module Self-Sourcing Prevention

Each module should guard against double-sourcing if it has initialization logic:

```bash
# Guard against double-sourcing (optional, for modules with side effects)
[[ -n "${_COLORS_SH_LOADED:-}" ]] && return 0
_COLORS_SH_LOADED=1
```

---

## Template System Design

### Template Placeholders

Templates use `{{PLACEHOLDER}}` format for substitution:

**`gitconfig.template`:**
```
[user]
    name = {{USER_NAME}}
    email = {{USER_EMAIL}}
    signingkey = {{GPG_KEY_ID}}

[commit]
    gpgsign = {{GPG_SIGN_ENABLED}}
    template = ~/.gitmessage

[credential]
    helper = {{CREDENTIAL_HELPER}}
    credentialStore = {{CREDENTIAL_STORE}}
```

**Template Processing:**
```bash
sed -e "s|{{USER_NAME}}|${USER_NAME}|g" \
    -e "s|{{USER_EMAIL}}|${USER_EMAIL}|g" \
    -e "s|{{GPG_KEY_ID}}|${GPG_KEY_ID}|g" \
    "${mydir}/config/templates/gitconfig.template"
```

---

## Variable Scoping Rules

### Global Variables

All global variables MUST be:
1. Declared in `config/defaults.sh`
2. Documented with inline comments
3. Written in `UPPER_SNAKE_CASE`

```bash
# config/defaults.sh

# Script directories
SCRIPT_DIR="$HOME/.github-keys-setup"           # Base directory for script data
BACKUP_DIR="$SCRIPT_DIR/backup-$(date +%Y%m%d_%H%M%S)"  # Timestamped backup dir
LOG_FILE="$SCRIPT_DIR/setup.log"                # Log file location

# Behavior configuration
DEBUG="${DEBUG:-false}"                          # Enable debug logging
INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}"    # Interactive vs non-interactive
AUTO_UPLOAD_KEYS=false                          # Auto-upload keys to GitHub
```

### Local Variables

All variables inside functions MUST use `local`:

```bash
function example() {
    local input="$1"        # ✓ Correct
    local result=""         # ✓ Correct
    GLOBAL_VAR="value"      # ✗ Only if modifying existing global
}
```

---

## Function Extraction Mapping

### scripts/core/colors.sh (Lines 23-68)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `c()` | Lines 50-59 | Color helper function |
| `cr()` | Lines 61-68 | Reset helper function |
| `COLORS` array | Lines 28-48 | Associative array declaration |

### scripts/core/ui.sh (Lines 102-230)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `show_separator()` | Lines 102-104 | Display separator line |
| `success()` | Lines 106-109 | Success message helper |
| `error()` | Lines 111-114 | Error message helper |
| `warning()` | Lines 116-119 | Warning message helper |
| `info()` | Lines 121-124 | Info message helper |
| `show_spinner()` | Lines 203-230 | Progress spinner |
| `show_progress_bar()` | Lines 247-278 | Visual progress bar |
| `check_unicode_support()` | Lines 233-245 | Unicode detection |
| `logo()` | Lines 140-177 | Animated logo display |
| `welcome()` | Lines 396-424 | Welcome message |
| `ask_yes_no()` | Lines 497-525 | Y/N prompt |

### scripts/core/logger.sh (Lines 96-100)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `log()` | Lines 96-100 | Write to log file |

### scripts/core/validation.sh (Lines 126-181)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `validate_email()` | Lines 126-135 | Email regex validation |
| `initial_checks()` | Lines 178-186 | Root user check |

### scripts/core/common.sh (Lines 280-371)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `detect_os()` | Lines 280-293 | OS detection |
| `copy_to_clipboard()` | Lines 627-697 | Clipboard handling |

### scripts/dependencies.sh (Lines 295-394, 700-820)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `auto_install_dependencies()` | Lines 295-394 | Install deps by distro |
| `check_dependencies()` | Lines 700-820 | Check for required commands |

### scripts/ssh.sh (Lines 848-897, 1098-1180, 1600-1720)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `backup_existing_keys()` | Lines 848-897 | SSH key backup |
| `generate_ssh_key()` | Lines 1098-1136 | SSH key generation |
| `create_ssh_agent_script()` | Lines 1600-1720 | SSH agent config |

### scripts/gpg.sh (Lines 1140-1380)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `generate_gpg_key()` | Lines 1140-1260 | GPG key generation |
| `generate_gpg_key_alternative()` | Lines 1262-1295 | Fallback method |
| `cleanup_gpg_processes()` | Lines 1300-1340 | Clean blocked processes |
| `setup_gpg_environment()` | Lines 1345-1425 | GPG environment setup |

### scripts/git-config.sh (Lines 905-1090, 1428-1595)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `collect_user_info()` | Lines 905-980 | User info collection |
| `configure_git()` | Lines 1428-1460 | Git configuration |
| `generate_gitconfig()` | Lines 1465-1590 | .gitconfig generation |
| `create_commit_template()` | Lines 1595-1645 | .gitmessage creation |

### scripts/github.sh (Lines 1890-2130)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `ensure_github_cli_ready()` | Lines 1890-2040 | gh CLI verification |
| `show_manual_gh_install_instructions()` | Lines 2040-2070 | Install instructions |
| `upload_ssh_key_to_github()` | Lines 2075-2095 | SSH key upload |
| `upload_gpg_key_to_github()` | Lines 2200-2300 | GPG key upload |
| `maybe_upload_keys()` | Lines 2305-2380 | Orchestrate key upload |

### scripts/finalize.sh (Lines 1010-1095, 1725-1885, 2385-2530)
| Function | Current Location | Description |
|----------|------------------|-------------|
| `show_changes_summary()` | Lines 1010-1095 | Preview changes |
| `display_keys()` | Lines 1725-1810 | Show generated keys |
| `save_keys_to_files()` | Lines 1815-1885 | Export keys to files |
| `test_github_connection()` | Lines 2385-2420 | SSH connectivity test |
| `show_final_instructions()` | Lines 2425-2530 | Post-setup instructions |

---

## Testing Strategy

### Unit Test Structure

Each module should have a corresponding test file:

```
tests/
├── core/
│   ├── test_colors.sh
│   ├── test_ui.sh
│   ├── test_logger.sh
│   ├── test_validation.sh
│   └── test_common.sh
├── test_dependencies.sh
├── test_ssh.sh
├── test_gpg.sh
├── test_git-config.sh
├── test_github.sh
└── test_finalize.sh
```

### Test Execution

```bash
# Run all tests
./tests/run_tests.sh

# Run specific module tests
./tests/core/test_colors.sh
```

---

## Migration Safety Measures

1. **Backup current script** before any changes
2. **Incremental extraction**: Extract one module at a time, test, commit
3. **Comparison testing**: Run both old and new versions, compare outputs
4. **Feature flags**: Temporarily allow switching between old/new implementations
5. **ShellCheck validation**: All modules must pass ShellCheck

---

## Compatibility Constraints

1. **Bash 4+**: Required for associative arrays
2. **POSIX paths**: All sourcing uses `${mydir}` relative paths
3. **No new dependencies**: Only existing commands used
4. **Same shebang**: `#!/usr/bin/env bash` (not `#!/bin/bash`)
5. **Same permissions**: Executable files maintain 755
