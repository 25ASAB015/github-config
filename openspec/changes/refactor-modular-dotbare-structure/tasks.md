# Tasks: Refactor gitconfig.sh to modular dotbare-style structure

## Phase 1: Setup and Configuration

### 1.1 Create Directory Structure
- [x] Create `scripts/` directory
- [x] Create `scripts/core/` subdirectory
- [x] Create `config/` directory
- [x] Create `config/templates/` subdirectory
- [x] Verify structure with `tree` command

**Validation:** `ls -la scripts/core/ config/templates/` shows all directories ✓

### 1.2 Extract Global Configuration
- [x] Create `config/defaults.sh` with dotbare-style header
- [x] Extract `SCRIPT_DIR`, `BACKUP_DIR`, `LOG_FILE` variables
- [x] Extract `DEBUG`, `INTERACTIVE_MODE`, `AUTO_UPLOAD_KEYS` variables
- [x] Extract `SSH_KEY_UPLOADED`, `GPG_KEY_UPLOADED`, `GH_INSTALL_ATTEMPTED` variables
- [x] Extract `USER_EMAIL`, `USER_NAME`, `GPG_KEY_ID`, `GENERATE_GPG` variables
- [x] Extract `TOTAL_STEPS`, `CURRENT_STEP`, `WORKFLOW_STEPS` array
- [x] Add inline documentation for each variable category

**Validation:** `shellcheck config/defaults.sh` passes without errors ✓

### 1.3 Extract Templates
- [x] Create `config/templates/gitconfig.template` from heredoc in `generate_gitconfig()`
- [x] Replace literal values with `{{PLACEHOLDER}}` syntax
- [x] Create `config/templates/gitmessage.template` from heredoc in `create_commit_template()`
- [x] Add explanatory comments to template files

**Validation:** Templates contain valid placeholder syntax ✓

---

## Phase 2: Core Modules

### 2.1 Create scripts/core/colors.sh
- [x] Create file with dotbare-style header
- [x] Document all globals: `${COLORS}`, `${DEBUG}`
- [x] Extract `COLORS` associative array declaration (lines 28-48)
- [x] Extract `c()` function (lines 50-59) with function header
- [x] Extract `cr()` function (lines 61-68) with function header
- [x] Add usage example in file header

**Validation:** `shellcheck scripts/core/colors.sh` passes; sourcing works ✓

### 2.2 Create scripts/core/logger.sh
- [x] Create file with dotbare-style header
- [x] Document all globals: `${LOG_FILE}`
- [x] Extract `log()` function (lines 96-100) with function header
- [x] Add directory creation logic documentation

**Validation:** `shellcheck scripts/core/logger.sh` passes ✓

### 2.3 Create scripts/core/validation.sh
- [x] Create file with dotbare-style header
- [x] Document globals and returns
- [x] Extract `validate_email()` function (lines 126-135) with function header
- [x] Extract `initial_checks()` function (lines 178-186) with function header

**Validation:** `shellcheck scripts/core/validation.sh` passes ✓

### 2.4 Create scripts/core/ui.sh
- [x] Create file with dotbare-style header listing all exported functions
- [x] Document all globals used
- [x] Extract `show_separator()` (lines 102-104)
- [x] Extract `success()`, `error()`, `warning()`, `info()` (lines 106-124)
- [x] Extract `show_spinner()` (lines 203-230)
- [x] Extract `check_unicode_support()` (lines 233-245)
- [x] Extract `show_progress_bar()` (lines 247-278)
- [x] Extract `logo()` (lines 140-177)
- [x] Extract `welcome()` (lines 396-424)
- [x] Extract `ask_yes_no()` (lines 497-525)
- [x] Extract `show_help()` (lines 427-495)
- [x] Add function headers for each function

**Validation:** `shellcheck scripts/core/ui.sh` passes ✓

### 2.5 Create scripts/core/common.sh
- [x] Create file with dotbare-style header
- [x] Document dependencies (xsel, xclip, wl-copy, etc.)
- [x] Extract `detect_os()` (lines 280-293)
- [x] Extract `copy_to_clipboard()` (lines 627-697)
- [x] Add function headers with dependency documentation

**Validation:** `shellcheck scripts/core/common.sh` passes ✓

---

## Phase 3: Feature Modules

### 3.1 Create scripts/dependencies.sh
- [x] Create file with dotbare-style header
- [x] List supported distros in header
- [x] Extract `auto_install_dependencies()` (lines 295-394)
- [x] Extract `check_dependencies()` (lines 700-820)
- [x] Document required dependencies array

**Validation:** `shellcheck scripts/dependencies.sh` passes ✓

### 3.2 Create scripts/ssh.sh
- [x] Create file with dotbare-style header
- [x] Document which files each function modifies
- [x] Extract `backup_existing_keys()` (lines 848-897)
- [x] Extract `generate_ssh_key()` (lines 1098-1136)
- [x] Extract `create_ssh_agent_script()` (lines 1600-1720)
- [x] Add function headers

**Validation:** `shellcheck scripts/ssh.sh` passes ✓

### 3.3 Create scripts/gpg.sh
- [x] Create file with dotbare-style header
- [x] Document GPG dependencies and possible errors
- [x] Extract `generate_gpg_key()` (lines 1140-1260)
- [x] Extract `generate_gpg_key_alternative()` (lines 1262-1295)
- [x] Extract `cleanup_gpg_processes()` (lines 1300-1340)
- [x] Extract `setup_gpg_environment()` (lines 1345-1425)
- [x] Add function headers

**Validation:** `shellcheck scripts/gpg.sh` passes ✓

### 3.4 Create scripts/git-config.sh
- [x] Create file with dotbare-style header
- [x] Document templates used and files generated
- [x] Extract `collect_user_info()` (lines 905-980)
- [x] Extract `configure_git()` (lines 1428-1460)
- [x] Modify `generate_gitconfig()` to use template file (lines 1465-1590)
- [x] Modify `create_commit_template()` to use template file (lines 1595-1645)
- [x] Add function headers

**Validation:** `shellcheck scripts/git-config.sh` passes; templates processed correctly ✓

### 3.5 Create scripts/github.sh
- [x] Create file with dotbare-style header
- [x] Document gh CLI dependency
- [x] Extract `ensure_github_cli_ready()` (lines 1890-2040)
- [x] Extract `show_manual_gh_install_instructions()` (lines 2040-2070)
- [x] Extract `upload_ssh_key_to_github()` (lines 2075-2095)
- [x] Extract `upload_gpg_key_to_github()` (lines 2200-2300)
- [x] Extract `maybe_upload_keys()` (lines 2305-2380)
- [x] Add function headers

**Validation:** `shellcheck scripts/github.sh` passes ✓

### 3.6 Create scripts/finalize.sh
- [x] Create file with dotbare-style header
- [x] Document finalization flow
- [x] Extract `show_changes_summary()` (lines 1010-1095)
- [x] Extract `display_keys()` (lines 1725-1810)
- [x] Extract `save_keys_to_files()` (lines 1815-1885)
- [x] Extract `test_github_connection()` (lines 2385-2420)
- [x] Extract `show_final_instructions()` (lines 2425-2530)
- [x] Add function headers

**Validation:** `shellcheck scripts/finalize.sh` passes ✓

---

## Phase 4: Main Entry Point

### 4.1 Refactor gitconfig.sh
- [x] Update shebang to `#!/usr/bin/env bash`
- [x] Add dotbare-style header with full documentation
- [x] Implement `mydir` detection: `mydir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- [x] Add module sourcing in correct order:
  - [x] `config/defaults.sh`
  - [x] `scripts/core/colors.sh`
  - [x] `scripts/core/logger.sh`
  - [x] `scripts/core/validation.sh`
  - [x] `scripts/core/ui.sh`
  - [x] `scripts/core/common.sh`
  - [x] `scripts/dependencies.sh`
  - [x] `scripts/ssh.sh`
  - [x] `scripts/gpg.sh`
  - [x] `scripts/git-config.sh`
  - [x] `scripts/github.sh`
  - [x] `scripts/finalize.sh`
- [x] Keep `parse_arguments()` in main file
- [x] Keep `main()` in main file
- [x] Keep `cleanup()` trap handler in main file
- [x] Remove all extracted functions from main file
- [x] Remove extracted global variables from main file

**Validation:** `shellcheck gitconfig.sh` passes ✓

---

## Phase 5: Testing and Validation

### 5.1 Static Analysis
- [x] Run `shellcheck` on all `.sh` files
- [x] Fix any shellcheck warnings/errors
- [x] Verify all files use `#!/usr/bin/env bash`

**Validation:** `shellcheck scripts/**/*.sh config/*.sh gitconfig.sh` passes ✓

### 5.2 Functional Testing - Interactive Mode
- [x] Test `./gitconfig.sh --help` displays help correctly
- [x] Test `./gitconfig.sh` runs through welcome screen
- [x] Test user prompts work correctly
- [x] Test progress bar displays properly
- [x] Complete full interactive run

**Validation:** Script completes without errors in interactive mode (partial)

### 5.3 Functional Testing - Non-Interactive Mode
- [x] Test `USER_EMAIL="test@test.com" USER_NAME="Test" ./gitconfig.sh --non-interactive`
- [x] Verify environment variables are respected
- [x] Verify automatic defaults are used

**Validation:** Script completes without errors in non-interactive mode

### 5.4 Functional Testing - Auto Upload Mode
- [ ] Test `./gitconfig.sh --auto-upload` with gh authenticated
- [ ] Verify keys are uploaded to GitHub
- [ ] Test `./gitconfig.sh --non-interactive --auto-upload`

**Validation:** Keys successfully uploaded when gh is authenticated

### 5.5 Output Verification
- [x] Verify `~/.gitconfig` is generated correctly
- [x] Verify `~/.gitmessage` is generated correctly
- [x] Verify SSH keys are created in `~/.ssh/`
- [x] Verify GPG key is generated (when requested)
- [x] Compare output files with original script output

**Validation:** Generated files match original script output

---

## Phase 6: Documentation

### 6.1 Create README.md for New Structure
- [x] Document the new modular structure
- [x] Explain relationship to dotbare pattern
- [x] Describe each module's purpose
- [x] Include usage examples

### 6.2 Verify All Headers
- [x] Review each file for complete dotbare-style headers
- [x] Verify all globals are documented
- [x] Verify all functions have inline documentation
- [x] Verify all arguments are documented

**Validation:** Manual review confirms documentation completeness

---

## Completion Criteria

1. All tasks marked as complete (`[x]`)
2. `shellcheck` passes on all files
3. Script runs identically in interactive mode
4. Script runs identically in non-interactive mode
5. All flags work as before (`--help`, `--non-interactive`, `--auto-upload`)
6. Generated output files are identical to original
7. All files follow dotbare documentation standard
