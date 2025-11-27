# Change: Refactor gitconfig.sh to modular dotbare-style structure

## Why

The current `gitconfig.sh` is a monolithic 2677-line Bash script that is difficult to maintain, test, and extend. Following the established dotbare repository pattern (https://github.com/kazhala/dotbare) will provide:

1. **Improved maintainability**: Single-responsibility modules are easier to understand and modify
2. **Better testability**: Isolated modules can be unit tested independently
3. **Cleaner organization**: Clear separation of concerns with consistent documentation
4. **Industry standard**: dotbare is a well-established, community-vetted pattern for organizing Bash scripts
5. **Easier onboarding**: Developers familiar with dotbare will immediately understand the codebase

## What Changes

### Directory Structure (NEW)
```
.
├── gitconfig.sh                 # Main entry point (dotbare-style)
├── scripts/
│   ├── core/
│   │   ├── colors.sh            # Color system and helpers (c, cr)
│   │   ├── ui.sh                # Interface functions (spinner, progress, logo)
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

### Code Organization Changes

- **Main entry point** (`gitconfig.sh`): Becomes a thin orchestrator that sources modules and calls `main()`
- **Configuration** (`config/defaults.sh`): All global variables extracted and documented
- **Core utilities** (`scripts/core/*.sh`): Shared helper functions with dotbare-style headers
- **Feature modules** (`scripts/*.sh`): Domain-specific logic grouped by functionality
- **Templates** (`config/templates/`): Externalized from heredoc strings to separate files

### Documentation Standard (dotbare format)

Each file will include a standardized header:
```bash
#!/usr/bin/env bash
#
# [Brief description]
#
# @params
# Globals
#   ${VARIABLE}: description
# Arguments
#   -h|--help: show help message
# Returns
#   0: success
#   1: error
```

### What DOES NOT Change

- **Identical functionality**: All features preserved exactly
- **No logic changes**: Execution flow remains the same
- **Total compatibility**: Same interactive/non-interactive behavior
- **Same dependencies**: No new dependencies added or removed
- **Same messages**: All user-facing text preserved
- **Same file outputs**: Generated files remain identical

## Impact

- **Affected specs**: 
  - `ui-colors` (MODIFIED): Functions move to `scripts/core/colors.sh`
  - `progress-tracking` (MODIFIED): Functions move to `scripts/core/ui.sh`
  - `change-preview` (MODIFIED): Functions move to `scripts/finalize.sh`
  - `automation` (MODIFIED): Argument parsing moves to main entry point
  - `logo-animation` (MODIFIED): Logo function moves to `scripts/core/ui.sh`
  - `modular-architecture` (NEW): New capability defining module structure

- **Affected code**: 
  - `gitconfig.sh`: Complete restructure into 15+ files
  - No behavior changes, only organization changes

- **Breaking changes**: None. The script is invoked the same way.

## Success Criteria

1. Script executes without errors with `./gitconfig.sh`
2. Works identically in interactive and non-interactive modes
3. All flags respected (`--help`, `--non-interactive`, `--auto-upload`)
4. Same user question flow maintained
5. Same output files generated
6. All existing tests pass
7. ShellCheck passes on all modules

## References

- dotbare repository: https://github.com/kazhala/dotbare
- Current script analysis: 2677 lines, 50+ functions to extract
