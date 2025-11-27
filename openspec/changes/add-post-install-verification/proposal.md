# Change: Add Post-Installation Verification Suite

## Why
After completing the Git/GitHub setup process, users currently have no automated way to verify that all components were configured correctly. They must manually test each component (SSH keys, GPG keys, GitHub connectivity, etc.), which is error-prone and time-consuming. A comprehensive verification suite would provide immediate confidence that the setup was successful and help identify any configuration issues.

## What Changes
- Add a post-installation verification suite that automatically tests all configured components
- Verify Git configuration (user.name, user.email)
- Verify SSH key files exist and are properly formatted
- Verify SSH agent is running and has keys loaded
- Verify GPG key exists (if GPG was configured)
- Verify GitHub CLI is installed and authenticated
- Verify Git Credential Manager is installed
- Test SSH connectivity to GitHub
- Display a formatted summary with pass/fail indicators
- Integrate verification suite into the finalization workflow

## Impact
- Affected specs: New capability `post-install-verification`
- Affected code: 
  - `scripts/finalize.sh` - Add `run_verification_suite()` function
  - `gitconfig.sh` - Call verification suite after finalization
  - May use existing UI functions from `scripts/core/ui.sh` for formatting

