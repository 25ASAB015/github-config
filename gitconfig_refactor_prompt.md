# Bash Script Refactoring - dotbare-style Structure

## Context
I have a monolithic 2400-line bash script called `@gitconfig.sh` that professionally configures Git with SSH and GPG on Linux. I need to refactor it following **exactly** the structure and conventions of the dotbare repository (https://github.com/kazhala/dotbare).

## Main Objective
**Replicate dotbare's organization, style, and functionality**: The script must be structured similarly to how dotbare organizes its files, with the same level of modularity, documentation, and clarity. The final result should look and feel like dotbare in terms of:
- Directory structure
- Documentation style for each script
- Separation of concerns
- Main entry point that delegates to specialized modules
- Logical function organization

While maintaining:
- **Identical functionality**: Behavior must be exactly the same
- **No logic changes**: Do not modify execution flow
- **Total compatibility**: Same interactive/non-interactive behavior
- **Same dependencies**: Do not add or remove dependencies

## Desired Structure (dotbare-like)

```
.
├── @gitconfig.sh                 # Main entry point (like dotbare)
├── scripts/
│   ├── core/
│   │   ├── colors.sh            # Color system and helpers (c, cr)
│   │   ├── ui.sh                # Interface functions (spinner, progress bar, separators, logo)
│   │   ├── logger.sh            # Logging system
│   │   ├── validation.sh        # Validations (email, etc.)
│   │   └── common.sh            # Common auxiliary functions
│   ├── dependencies.sh          # Dependency checking and installation
│   ├── ssh.sh                   # SSH key generation and configuration
│   ├── gpg.sh                   # GPG key generation and configuration
│   ├── git-config.sh            # Git configuration and .gitconfig
│   ├── github.sh                # GitHub CLI integration (upload keys)
│   └── finalize.sh              # Final summary, instructions, connectivity test
└── config/
    ├── defaults.sh              # Global variables and default configuration
    └── templates/
        ├── gitconfig.template   # Template for .gitconfig
        └── gitmessage.template  # Template for .gitmessage
```

## Documentation Format (MANDATORY - dotbare style)

**Each file must include a documentation header following this exact format:**

```bash
#!/usr/bin/env bash
#
# [One-line brief description of the script's purpose]
#
# @params
# Globals
#   ${VARIABLE1}: description of global variable it uses/modifies
#   ${VARIABLE2}: description of another global variable
#   ${mydir}: current directory of the script, used for imports
# Arguments
#   -h|--help: show help message
#   --flag: flag description
# Returns
#   0: success
#   1: error
#
# Usage example:
#   source "${mydir}/colors.sh"
```

**Header requirements:**
- Shebang: `#!/usr/bin/env bash` (not `#!/bin/bash`)
- Brief module description (1-2 lines)
- `@params` section with:
  - `Globals`: ALL global variables the script reads or modifies
  - `Arguments`: flags or arguments it accepts (if applicable)
  - `Returns`: exit codes (if applicable)
- Usage example or note on how the module is loaded

**Real example for scripts/core/colors.sh:**
```bash
#!/usr/bin/env bash
#
# Semantic color system for terminal output
# Provides color palette with graceful degradation
#
# @params
# Globals
#   ${COLORS}: associative array with ANSI color codes
#   ${DEBUG}: debug mode for logging unknown tokens
# Functions
#   c(): helper to get color code by token
#   cr(): helper to reset terminal colors
# Returns
#   0: always successful
#
# Usage:
#   source "${mydir}/scripts/core/colors.sh"
#   echo "$(c success)Success message$(cr)"
```

**Real example for scripts/ssh.sh:**
```bash
#!/usr/bin/env bash
#
# SSH key generation and configuration for GitHub
# Handles backup, generation, permissions, and ssh-agent setup
#
# @params
# Globals
#   ${USER_EMAIL}: user email for SSH key
#   ${HOME}: user home directory
#   ${INTERACTIVE_MODE}: interactive or non-interactive mode
#   ${BACKUP_DIR}: directory for existing key backups
# Functions
#   backup_existing_keys(): backs up existing SSH keys
#   generate_ssh_key(): generates new Ed25519 SSH key
#   create_ssh_agent_script(): configures automatic ssh-agent
# Returns
#   0: successful operation
#   1: error in generation or configuration
#
# Usage:
#   source "${mydir}/scripts/ssh.sh"
#   generate_ssh_key
```

## Technical Specifications

### 1. Main File (`@gitconfig.sh`)
- Shebang: `#!/usr/bin/env bash`
- Complete header with dotbare-style documentation
- Must be the only entry point
- Load all necessary modules using relative sourcing
- Parse arguments (`--non-interactive`, `--auto-upload`, `--help`)
- Execute `main()` function orchestrating the complete flow
- Maintain signal handling (trap cleanup)
- Detect its own directory: `mydir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`

### 2. Color System (`scripts/core/colors.sh`)
- Complete dotbare-style header
- `COLORS` associative array with all colors
- Functions `c()` and `cr()` for color helpers
- Graceful degradation when color support unavailable
- Document each color in array (inline comments)

### 3. User Interface (`scripts/core/ui.sh`)
- Complete header listing all exported functions
- Functions: `show_separator()`, `success()`, `error()`, `warning()`, `info()`
- Functions: `show_spinner()`, `show_progress_bar()`, `check_unicode_support()`
- Function `logo()` with ASCII art
- Function `welcome()` for welcome message
- Function `ask_yes_no()` with interactive/non-interactive mode support
- Each function must have inline comment describing its purpose

### 4. Logger (`scripts/core/logger.sh`)
- Complete dotbare-style header
- Function `log()` to write to log file
- Log file initialization
- Document log format and file location

### 5. Validations (`scripts/core/validation.sh`)
- Complete dotbare-style header
- Function `validate_email()` with regex and description
- Function `initial_checks()` (check non-root)
- Document what each function validates and its returns

### 6. Common Functions (`scripts/core/common.sh`)
- Complete dotbare-style header
- Function `detect_os()` - returns OS ID
- Function `copy_to_clipboard()` - handles multiple backends
- Document dependencies of each function (xsel, wl-copy, etc.)

### 7. Configuration (`config/defaults.sh`)
- Complete dotbare-style header
- **Document EACH global variable** with inline comment
- Global variables organized by category:
  ```bash
  # Script directories
  SCRIPT_DIR="$HOME/.github-keys-setup"
  BACKUP_DIR="$SCRIPT_DIR/backup-$(date +%Y%m%d_%H%M%S)"
  LOG_FILE="$SCRIPT_DIR/setup.log"
  
  # Behavior configuration
  DEBUG="${DEBUG:-false}"
  INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}"
  AUTO_UPLOAD_KEYS=false
  
  # Key status
  SSH_KEY_UPLOADED=false
  GPG_KEY_UPLOADED=false
  GH_INSTALL_ATTEMPTED=false
  
  # User information
  USER_EMAIL=""
  USER_NAME=""
  GPG_KEY_ID=""
  GENERATE_GPG="false"
  
  # Workflow and progress
  TOTAL_STEPS=9
  CURRENT_STEP=0
  declare -A WORKFLOW_STEPS=(
      [1]="Checking dependencies"
      [2]="Setting up directories"
      # ... rest of steps
  )
  ```

### 8. Dependencies (`scripts/dependencies.sh`)
- Complete header listing all functions
- Function `check_dependencies()` - verifies available commands
- Function `auto_install_dependencies()` - installs by distro
- Document required dependencies array
- List supported distros in header

### 9. SSH (`scripts/ssh.sh`)
- Complete dotbare-style header
- Function `backup_existing_keys()` - conditional backups
- Function `generate_ssh_key()` - generates Ed25519
- Function `create_ssh_agent_script()` - configures autostart
- Document which files each function modifies

### 10. GPG (`scripts/gpg.sh`)
- Complete dotbare-style header
- Function `generate_gpg_key()` - generates RSA 4096
- Function `generate_gpg_key_alternative()` - fallback method
- Function `setup_gpg_environment()` - configures gpg-agent
- Function `cleanup_gpg_processes()` - cleans blocked processes
- Document GPG dependencies and possible errors

### 11. Git Config (`scripts/git-config.sh`)
- Complete dotbare-style header
- Function `configure_git()` - orchestrates configuration
- Function `generate_gitconfig()` - uses template
- Function `create_commit_template()` - creates .gitmessage
- Function `collect_user_info()` - interactive prompt
- Document templates it uses and files it generates

### 12. GitHub (`scripts/github.sh`)
- Complete dotbare-style header
- Function `ensure_github_cli_ready()` - verifies gh installed and authenticated
- Function `show_manual_gh_install_instructions()` - help by distro
- Function `upload_ssh_key_to_github()` - uploads SSH key via gh
- Function `upload_gpg_key_to_github()` - uploads GPG key via gh
- Function `maybe_upload_keys()` - orchestrates conditional upload
- Document gh CLI dependency

### 13. Finalization (`scripts/finalize.sh`)
- Complete dotbare-style header
- Function `show_changes_summary()` - preview before applying
- Function `display_keys()` - shows generated keys
- Function `save_keys_to_files()` - exports keys
- Function `test_github_connection()` - tests SSH
- Function `show_final_instructions()` - post-setup help
- Document finalization flow

### 14. Templates (`config/templates/`)
- `gitconfig.template`: .gitconfig content with placeholders:
  - `{{USER_NAME}}`, `{{USER_EMAIL}}`, `{{GPG_KEY_ID}}`
  - `{{CREDENTIAL_HELPER}}`, `{{CREDENTIAL_STORE}}`
  - `{{DATE}}`
- `gitmessage.template`: .gitmessage content
- **Both templates must include explanatory comments**

## Critical Rules

### dotbare Style (MANDATORY)
- **All scripts must use `#!/usr/bin/env bash`** not `#!/bin/bash`
- **All scripts must have complete header** with dotbare format
- **All global variables must be documented** in header
- **All public functions must be listed** in header
- **Use inline comments** for complex logic (like dotbare)
- **Keep functions small and focused** (single responsibility)

### Module Loading
- Main file must source modules in correct order:
  ```bash
  mydir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  # Load configuration
  source "${mydir}/config/defaults.sh"
  
  # Load core utilities
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
  ```

### Path Handling
- Use `mydir` as standard variable (like dotbare) for base directory
- All sourcing paths must be relative to `mydir`
- Pass `mydir` to functions that need to load other modules

### Global Variables
- All global variables must be in `config/defaults.sh`
- Modules must NOT declare their own global variables (only local)
- Modules may MODIFY global variables defined in defaults.sh
- Use `local` for all variables inside functions

### main() Function
- Maintain current flow structure:
  1. `parse_arguments "$@"`
  2. `initial_checks`
  3. `welcome`
  4. Early GitHub CLI verification (if --auto-upload)
  5. `check_dependencies` (with progress bar)
  6. `setup_directories`
  7. `backup_existing_keys`
  8. `collect_user_info`
  9. GPG question
  10. `show_changes_summary`
  11. `generate_ssh_key`
  12. `generate_gpg_key` (conditional)
  13. `configure_git`
  14. `create_ssh_agent_script`
  15. `display_keys`
  16. `maybe_upload_keys`
  17. `save_keys_to_files` (conditional)
  18. `test_github_connection`
  19. `show_final_instructions`

### Templates
- Function `generate_gitconfig()` must read `config/templates/gitconfig.template`
- Replace placeholders using `sed` or similar
- Function `create_commit_template()` must read `config/templates/gitmessage.template`

### Compatibility
- **DO NOT change function names** exported to user
- **DO NOT modify logic** of any existing function
- **DO NOT change** interactive/non-interactive behavior
- **Keep all messages** exactly the same
- **Respect execution order** as current

## Testing
After refactoring, the script must:
- Execute without errors with `./gitconfig.sh`
- Work the same in interactive and non-interactive modes
- Respect all flags (`--help`, `--non-interactive`, `--auto-upload`)
- Maintain same user question flow
- Generate same output files

## Specific Tasks

1. **Analyze current script** and identify all functions and their dependencies
2. **Create directory structure** as specified
3. **Extract and organize functions** into corresponding modules
4. **Create dotbare-style headers** for each file with complete documentation
5. **Create main file** that loads modules and executes main()
6. **Extract templates** from multiline strings to separate files
7. **Extract global variables** to config/defaults.sh with documentation
8. **Verify no undeclared global variables** outside defaults.sh
9. **Add inline comments** for complex logic (dotbare style)
10. **Create README.md** explaining new structure and how it relates to dotbare

## Complete Module Example (scripts/core/colors.sh)

```bash
#!/usr/bin/env bash
#
# Semantic color system for terminal output
# Provides color palette with graceful degradation when no support available
#
# @params
# Globals
#   ${COLORS}: associative array with ANSI color codes
#   ${DEBUG}: debug mode for logging unknown color tokens
# Functions
#   c(): returns ANSI color code for given token (success, error, etc.)
#   cr(): returns reset code to restore default colors
# Returns
#   0: always successful
#
# Usage:
#   source "${mydir}/scripts/core/colors.sh"
#   echo "$(c success)Successful operation$(cr)"
#   echo "$(c error)Something failed$(cr)"

# =============================================================================
# Color Palette - WCAG 2.1 Accessibility Compliant
# =============================================================================

declare -A COLORS=(
    # State Colors - Semantic status indicators
    [success]="$(tput setaf 2 2>/dev/null || echo -n "")"     # Green - success messages
    [error]="$(tput setaf 1 2>/dev/null || echo -n "")"       # Red - error messages
    [warning]="$(tput setaf 3 2>/dev/null || echo -n "")"     # Yellow - warnings
    [info]="$(tput setaf 4 2>/dev/null || echo -n "")"        # Blue - informational
    
    # UI Element Colors - Consistent theming
    [primary]="$(tput setaf 6 2>/dev/null || echo -n "")"     # Cyan - primary actions
    [secondary]="$(tput setaf 5 2>/dev/null || echo -n "")"   # Magenta - secondary
    [accent]="$(tput setaf 3 2>/dev/null || echo -n "")"      # Yellow - highlights
    [text]="$(tput setaf 7 2>/dev/null || echo -n "")"        # White - standard text
    
    # Text Modifiers
    [muted]="$(tput dim 2>/dev/null || echo -n "")"           # Dim - less important
    [bold]="$(tput bold 2>/dev/null || echo -n "")"           # Bold - emphasis
    
    # Reset
    [reset]="$(tput sgr0 2>/dev/null || echo -n "")"          # Reset all attributes
)

#######################################
# Get ANSI color code by token
# Arguments:
#   $1: color token (success, error, warning, info, primary, etc.)
# Outputs:
#   Writes ANSI code to stdout, or empty string if unknown token
# Returns:
#   0: always successful
#######################################
c() {
    local token="$1"
    if [[ -n "${COLORS[$token]}" ]]; then
        echo -n "${COLORS[$token]}"
    else
        # Log warning in debug mode for unknown tokens
        [[ "$DEBUG" == "true" ]] && echo "Warning: unknown color token '$token'" >&2
        echo -n ""
    fi
}

#######################################
# Reset terminal colors to default values
# Outputs:
#   Writes ANSI reset code to stdout
# Returns:
#   0: always successful
#######################################
cr() {
    echo -n "${COLORS[reset]}"
}
```

## Important Notes
- Original script is in attached file as `@gitconfig.sh`
- Keep copyright header and GPL-3.0 license in main file
- DO NOT install new dependencies
- DO NOT change observable script behavior
- Prioritize readability and maintainability (like dotbare)
- Each module must be self-contained in its responsibility
- **Study dotbare before starting**: review how it organizes functions, documents, sources modules
- Goal is that someone familiar with dotbare feels comfortable reading this code

## Reference
- dotbare repository: https://github.com/kazhala/dotbare
- Study especially:
  - `dotbare` (main file)
  - Scripts in `scripts/` (modularization)
  - Scripts in `scripts/core/` (utilities)
  - Documentation headers of each script
  - Comment style and organization

Can you perform this refactoring following exactly dotbare's style and organization?
