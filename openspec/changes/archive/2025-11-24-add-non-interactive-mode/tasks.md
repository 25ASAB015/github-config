# Implementation Tasks

## 1. Environment Variables and Defaults
- [x] 1.1 Add `INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}"` global variable
- [x] 1.2 Add `AUTO_UPLOAD_KEYS=false` global variable (internal, set by `--auto-upload` flag)
- [x] 1.3 Add `GH_INSTALL_ATTEMPTED=false` to prevent duplicate GitHub CLI installation attempts
- [x] 1.4 Place variables near top of script after color definitions

## 2. Command-Line Argument Parsing
- [x] 2.1 Create `parse_arguments()` function before `main()`
- [x] 2.2 Parse `--non-interactive` flag (sets `INTERACTIVE_MODE=false`)
- [x] 2.3 Parse `--auto-upload` flag (sets `AUTO_UPLOAD_KEYS=true`)
- [x] 2.4 Parse `--help` flag (show usage and exit)
- [x] 2.5 Call `parse_arguments "$@"` at start of `main()`

## 3. Modify ask_yes_no() Function
- [x] 3.1 Add non-interactive check at start of function
- [x] 3.2 When `INTERACTIVE_MODE=false`, return default value
- [x] 3.3 Log auto-answered prompts: `log "AUTO-ANSWER: $prompt -> $answer"`
- [x] 3.4 Preserve existing interactive behavior when `INTERACTIVE_MODE=true`

## 4. Non-Interactive Mode Enhancements
- [x] 4.1 Modify `collect_user_info()` to use `USER_EMAIL` and `USER_NAME` environment variables in non-interactive mode
- [x] 4.2 Modify `generate_ssh_key()` to remove existing keys before generation in non-interactive mode
- [x] 4.3 Update `welcome()` to show non-interactive mode status and required variables
- [x] 4.4 Add validation and error messages for missing `USER_EMAIL`/`USER_NAME` in non-interactive mode

## 5. GitHub CLI Auto-Upload Feature
- [x] 5.1 Create `ensure_github_cli_ready()` function with early verification mode support
- [x] 5.2 Add early GitHub CLI verification in `main()` when `--auto-upload` is active
- [x] 5.3 Create `upload_ssh_key_to_github()` function using `gh ssh-key add`
- [x] 5.4 Create `upload_gpg_key_to_github()` function with duplicate key detection
- [x] 5.5 Create `maybe_upload_keys()` function to handle upload logic
- [x] 5.6 Add `show_manual_gh_install_instructions()` for better error messages
- [x] 5.7 Prevent duplicate `gh` installation attempts using `GH_INSTALL_ATTEMPTED` flag
- [x] 5.8 Handle early verification exit behavior (interactive vs non-interactive)

## 6. User Experience Improvements
- [x] 6.1 Modify `display_keys()` to skip showing keys when `--auto-upload` is active
- [x] 6.2 Update `show_final_instructions()` to show conditional steps based on upload status
- [x] 6.3 Add dynamic step numbering in final instructions
- [x] 6.4 Improve error messages to explain why `gh` is required for `--auto-upload`

## 7. Help Documentation
- [x] 7.1 Create `show_help()` function with usage information
- [x] 7.2 Document environment variables: `INTERACTIVE_MODE`, `USER_EMAIL`, `USER_NAME`
- [x] 7.3 Document command-line flags: `--non-interactive`, `--auto-upload`, `--help`
- [x] 7.4 Include usage examples in help text (only showing valid combinations)
- [x] 7.5 Remove references to obsolete `AUTO_YES` variable

## 8. Testing and Validation
- [x] 8.1 Test interactive mode (default behavior unchanged)
- [x] 8.2 Test non-interactive mode with `--non-interactive` and required environment variables
- [x] 8.3 Test auto-upload mode with `--auto-upload` flag
- [x] 8.4 Test environment variable override: `INTERACTIVE_MODE=false ./gitconfig.sh`
- [x] 8.5 Verify all prompts are auto-answered correctly in non-interactive mode
- [x] 8.6 Verify logs contain auto-answer entries
- [x] 8.7 Test GitHub CLI installation flow when `gh` is missing
- [x] 8.8 Test GitHub CLI authentication flow when not authenticated
- [x] 8.9 Test SSH key upload to GitHub
- [x] 8.10 Test GPG key upload to GitHub (including duplicate detection)
- [x] 8.11 Verify early verification exits correctly in non-interactive mode
- [x] 8.12 Verify instructions are conditional based on upload status

