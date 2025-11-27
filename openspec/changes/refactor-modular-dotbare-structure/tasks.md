# Tasks: Refactor gitconfig.sh to modular dotbare-style structure

## Phase 1: Setup and Configuration

### 1.1 Create Directory Structure
- [ ] Create `scripts/` directory
- [ ] Create `scripts/core/` subdirectory
- [ ] Create `config/` directory
- [ ] Create `config/templates/` subdirectory
- [ ] Verify structure with `tree` command

**Validation:** `ls -la scripts/core/ config/templates/` shows all directories

### 1.2 Extract Global Configuration
- [ ] Create `config/defaults.sh` with dotbare-style header
- [ ] Extract `SCRIPT_DIR`, `BACKUP_DIR`, `LOG_FILE` variables
- [ ] Extract `DEBUG`, `INTERACTIVE_MODE`, `AUTO_UPLOAD_KEYS` variables
- [ ] Extract `SSH_KEY_UPLOADED`, `GPG_KEY_UPLOADED`, `GH_INSTALL_ATTEMPTED` variables
- [ ] Extract `USER_EMAIL`, `USER_NAME`, `GPG_KEY_ID`, `GENERATE_GPG` variables
- [ ] Extract `TOTAL_STEPS`, `CURRENT_STEP`, `WORKFLOW_STEPS` array
- [ ] Add inline documentation for each variable category

**Validation:** `shellcheck config/defaults.sh` passes without errors

### 1.3 Extract Templates
- [ ] Create `config/templates/gitconfig.template` from heredoc in `generate_gitconfig()`
- [ ] Replace literal values with `{{PLACEHOLDER}}` syntax
- [ ] Create `config/templates/gitmessage.template` from heredoc in `create_commit_template()`
- [ ] Add explanatory comments to template files

**Validation:** Templates contain valid placeholder syntax

---

## Phase 2: Core Modules

### 2.1 Create scripts/core/colors.sh
- [ ] Create file with dotbare-style header
- [ ] Document all globals: `${COLORS}`, `${DEBUG}`
- [ ] Extract `COLORS` associative array declaration (lines 28-48)
- [ ] Extract `c()` function (lines 50-59) with function header
- [ ] Extract `cr()` function (lines 61-68) with function header
- [ ] Add usage example in file header

**Validation:** `shellcheck scripts/core/colors.sh` passes; sourcing works

### 2.2 Create scripts/core/logger.sh
- [ ] Create file with dotbare-style header
- [ ] Document all globals: `${LOG_FILE}`
- [ ] Extract `log()` function (lines 96-100) with function header
- [ ] Add directory creation logic documentation

**Validation:** `shellcheck scripts/core/logger.sh` passes

### 2.3 Create scripts/core/validation.sh
- [ ] Create file with dotbare-style header
- [ ] Document globals and returns
- [ ] Extract `validate_email()` function (lines 126-135) with function header
- [ ] Extract `initial_checks()` function (lines 178-186) with function header

**Validation:** `shellcheck scripts/core/validation.sh` passes

### 2.4 Create scripts/core/ui.sh
- [ ] Create file with dotbare-style header listing all exported functions
- [ ] Document all globals used
- [ ] Extract `show_separator()` (lines 102-104)
- [ ] Extract `success()`, `error()`, `warning()`, `info()` (lines 106-124)
- [ ] Extract `show_spinner()` (lines 203-230)
- [ ] Extract `check_unicode_support()` (lines 233-245)
- [ ] Extract `show_progress_bar()` (lines 247-278)
- [ ] Extract `logo()` (lines 140-177)
- [ ] Extract `welcome()` (lines 396-424)
- [ ] Extract `ask_yes_no()` (lines 497-525)
- [ ] Extract `show_help()` (lines 427-495)
- [ ] Add function headers for each function

**Validation:** `shellcheck scripts/core/ui.sh` passes

### 2.5 Create scripts/core/common.sh
- [ ] Create file with dotbare-style header
- [ ] Document dependencies (xsel, xclip, wl-copy, etc.)
- [ ] Extract `detect_os()` (lines 280-293)
- [ ] Extract `copy_to_clipboard()` (lines 627-697)
- [ ] Add function headers with dependency documentation

**Validation:** `shellcheck scripts/core/common.sh` passes

---

## Phase 3: Feature Modules

### 3.1 Create scripts/dependencies.sh
- [ ] Create file with dotbare-style header
- [ ] List supported distros in header
- [ ] Extract `auto_install_dependencies()` (lines 295-394)
- [ ] Extract `check_dependencies()` (lines 700-820)
- [ ] Document required dependencies array

**Validation:** `shellcheck scripts/dependencies.sh` passes

### 3.2 Create scripts/ssh.sh
- [ ] Create file with dotbare-style header
- [ ] Document which files each function modifies
- [ ] Extract `backup_existing_keys()` (lines 848-897)
- [ ] Extract `generate_ssh_key()` (lines 1098-1136)
- [ ] Extract `create_ssh_agent_script()` (lines 1600-1720)
- [ ] Add function headers

**Validation:** `shellcheck scripts/ssh.sh` passes

### 3.3 Create scripts/gpg.sh
- [ ] Create file with dotbare-style header
- [ ] Document GPG dependencies and possible errors
- [ ] Extract `generate_gpg_key()` (lines 1140-1260)
- [ ] Extract `generate_gpg_key_alternative()` (lines 1262-1295)
- [ ] Extract `cleanup_gpg_processes()` (lines 1300-1340)
- [ ] Extract `setup_gpg_environment()` (lines 1345-1425)
- [ ] Add function headers

**Validation:** `shellcheck scripts/gpg.sh` passes

### 3.4 Create scripts/git-config.sh
- [ ] Create file with dotbare-style header
- [ ] Document templates used and files generated
- [ ] Extract `collect_user_info()` (lines 905-980)
- [ ] Extract `configure_git()` (lines 1428-1460)
- [ ] Modify `generate_gitconfig()` to use template file (lines 1465-1590)
- [ ] Modify `create_commit_template()` to use template file (lines 1595-1645)
- [ ] Add function headers

**Validation:** `shellcheck scripts/git-config.sh` passes; templates processed correctly

### 3.5 Create scripts/github.sh
- [ ] Create file with dotbare-style header
- [ ] Document gh CLI dependency
- [ ] Extract `ensure_github_cli_ready()` (lines 1890-2040)
- [ ] Extract `show_manual_gh_install_instructions()` (lines 2040-2070)
- [ ] Extract `upload_ssh_key_to_github()` (lines 2075-2095)
- [ ] Extract `upload_gpg_key_to_github()` (lines 2200-2300)
- [ ] Extract `maybe_upload_keys()` (lines 2305-2380)
- [ ] Add function headers

**Validation:** `shellcheck scripts/github.sh` passes

### 3.6 Create scripts/finalize.sh
- [ ] Create file with dotbare-style header
- [ ] Document finalization flow
- [ ] Extract `show_changes_summary()` (lines 1010-1095)
- [ ] Extract `display_keys()` (lines 1725-1810)
- [ ] Extract `save_keys_to_files()` (lines 1815-1885)
- [ ] Extract `test_github_connection()` (lines 2385-2420)
- [ ] Extract `show_final_instructions()` (lines 2425-2530)
- [ ] Add function headers

**Validation:** `shellcheck scripts/finalize.sh` passes

---

## Phase 4: Main Entry Point

### 4.1 Refactor gitconfig.sh
- [ ] Update shebang to `#!/usr/bin/env bash`
- [ ] Add dotbare-style header with full documentation
- [ ] Implement `mydir` detection: `mydir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- [ ] Add module sourcing in correct order:
  - [ ] `config/defaults.sh`
  - [ ] `scripts/core/colors.sh`
  - [ ] `scripts/core/logger.sh`
  - [ ] `scripts/core/validation.sh`
  - [ ] `scripts/core/ui.sh`
  - [ ] `scripts/core/common.sh`
  - [ ] `scripts/dependencies.sh`
  - [ ] `scripts/ssh.sh`
  - [ ] `scripts/gpg.sh`
  - [ ] `scripts/git-config.sh`
  - [ ] `scripts/github.sh`
  - [ ] `scripts/finalize.sh`
- [ ] Keep `parse_arguments()` in main file
- [ ] Keep `main()` in main file
- [ ] Keep `cleanup()` trap handler in main file
- [ ] Remove all extracted functions from main file
- [ ] Remove extracted global variables from main file

**Validation:** `shellcheck gitconfig.sh` passes

---

## Phase 5: Testing and Validation

### 5.1 Static Analysis
- [ ] Run `shellcheck` on all `.sh` files
- [ ] Fix any shellcheck warnings/errors
- [ ] Verify all files use `#!/usr/bin/env bash`

**Validation:** `shellcheck scripts/**/*.sh config/*.sh gitconfig.sh` passes

### 5.2 Functional Testing - Interactive Mode
- [ ] Test `./gitconfig.sh --help` displays help correctly
- [ ] Test `./gitconfig.sh` runs through welcome screen
- [ ] Test user prompts work correctly
- [ ] Test progress bar displays properly
- [ ] Complete full interactive run

**Validation:** Script completes without errors in interactive mode

### 5.3 Functional Testing - Non-Interactive Mode
- [ ] Test `USER_EMAIL="test@test.com" USER_NAME="Test" ./gitconfig.sh --non-interactive`
- [ ] Verify environment variables are respected
- [ ] Verify automatic defaults are used

**Validation:** Script completes without errors in non-interactive mode

### 5.4 Functional Testing - Auto Upload Mode
- [ ] Test `./gitconfig.sh --auto-upload` with gh authenticated
- [ ] Verify keys are uploaded to GitHub
- [ ] Test `./gitconfig.sh --non-interactive --auto-upload`

**Validation:** Keys successfully uploaded when gh is authenticated

### 5.5 Output Verification
- [ ] Verify `~/.gitconfig` is generated correctly
- [ ] Verify `~/.gitmessage` is generated correctly
- [ ] Verify SSH keys are created in `~/.ssh/`
- [ ] Verify GPG key is generated (when requested)
- [ ] Compare output files with original script output

**Validation:** Generated files match original script output

---

## Phase 6: Documentation

### 6.1 Create README.md for New Structure
- [ ] Document the new modular structure
- [ ] Explain relationship to dotbare pattern
- [ ] Describe each module's purpose
- [ ] Include usage examples

### 6.2 Verify All Headers
- [ ] Review each file for complete dotbare-style headers
- [ ] Verify all globals are documented
- [ ] Verify all functions have inline documentation
- [ ] Verify all arguments are documented

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
