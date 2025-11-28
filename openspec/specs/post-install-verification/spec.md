# post-install-verification Specification

## Purpose
TBD - created by archiving change add-post-install-verification. Update Purpose after archive.
## Requirements
### Requirement: Post-Installation Verification Suite
The system SHALL provide a comprehensive verification suite that automatically tests all configured components after installation completes.

#### Scenario: Verification suite execution
- **WHEN** the installation workflow completes successfully
- **THEN** the verification suite SHALL be executed automatically
- **AND** it SHALL display a formatted header with title "🧪 VERIFICACIÓN POST-INSTALACIÓN"
- **AND** it SHALL use box-drawing characters for visual separation

#### Scenario: Git configuration verification
- **WHEN** the verification suite runs
- **THEN** it SHALL verify that `git config --global user.name` returns a value
- **AND** it SHALL verify that `git config --global user.email` returns a value
- **AND** if both values exist, it SHALL display "✓" in green
- **AND** if either value is missing, it SHALL display "✗" in red and increment the failure count

#### Scenario: SSH key file verification
- **WHEN** the verification suite runs
- **THEN** it SHALL verify that `$HOME/.ssh/id_ed25519` file exists
- **AND** it SHALL verify that `$HOME/.ssh/id_ed25519.pub` file exists
- **AND** if both files exist, it SHALL display "✓" in green
- **AND** if either file is missing, it SHALL display "✗" in red and increment the failure count

#### Scenario: SSH agent verification
- **WHEN** the verification suite runs
- **THEN** it SHALL verify that `ssh-add -l` executes successfully (indicating agent is running and has keys)
- **AND** if the command succeeds, it SHALL display "✓" in green
- **AND** if the command fails, it SHALL display "⚠" in yellow (warning, not critical failure)

#### Scenario: GPG key verification (conditional)
- **WHEN** the verification suite runs
- **AND** `GPG_KEY_ID` is set (GPG key was generated)
- **THEN** it SHALL verify that `gpg --list-secret-keys "$GPG_KEY_ID"` executes successfully
- **AND** if the key exists, it SHALL display "✓" in green
- **AND** if the key does not exist, it SHALL display "✗" in red and increment the failure count
- **WHEN** `GPG_KEY_ID` is not set (GPG was not generated)
- **THEN** the GPG verification test SHALL be skipped

#### Scenario: GitHub CLI verification
- **WHEN** the verification suite runs
- **THEN** it SHALL verify that `gh` command exists (`command -v gh`)
- **AND** it SHALL verify that `gh auth status` executes successfully (user is authenticated)
- **AND** if both conditions are met, it SHALL display "✓" in green
- **AND** if either condition fails, it SHALL display "⚠" in yellow (warning, not critical failure)

#### Scenario: Git Credential Manager verification
- **WHEN** the verification suite runs
- **THEN** it SHALL verify that `git-credential-manager` command exists (`command -v git-credential-manager`)
- **AND** if the command exists, it SHALL display "✓" in green
- **AND** if the command does not exist, it SHALL display "✗" in red and increment the failure count

#### Scenario: GitHub SSH connectivity test
- **WHEN** the verification suite runs
- **THEN** it SHALL test SSH connectivity to GitHub using `timeout 5 ssh -T git@github.com`
- **AND** it SHALL check if the output contains "successfully authenticated"
- **AND** if authentication succeeds, it SHALL display "✓" in green
- **AND** if authentication fails or times out, it SHALL display "⚠" in yellow (warning, not critical failure)

#### Scenario: Verification summary display
- **WHEN** all verification tests complete
- **THEN** the suite SHALL display a summary section with:
  - Total number of tests executed
  - Number of tests passed (displayed in green with "✓")
  - Number of tests failed (displayed in red with "✗")
- **AND** the summary SHALL use formatted separators for visual clarity

#### Scenario: Verification suite return code
- **WHEN** all critical tests pass (Git config, SSH keys, Git Credential Manager)
- **THEN** the verification suite SHALL return exit code 0
- **WHEN** any critical test fails
- **THEN** the verification suite SHALL return exit code 1
- **AND** it SHALL display a warning message: "Algunas verificaciones fallaron. Revisa la configuración."
- **WHEN** all tests pass (including warnings)
- **THEN** it SHALL display: "¡Todas las verificaciones pasaron correctamente!"

#### Scenario: Test result formatting
- **WHEN** displaying individual test results
- **THEN** each test SHALL display a left-aligned description (60 characters wide)
- **AND** the result indicator (✓, ✗, or ⚠) SHALL be displayed on the same line, right-aligned
- **AND** colors SHALL be used: green for success, red for failure, yellow for warning

#### Scenario: Integration with finalization workflow
- **GIVEN** the refactored codebase
- **WHEN** the main workflow completes finalization
- **THEN** `run_verification_suite()` SHALL be called from `scripts/finalize.sh`
- **AND** the function SHALL be documented with dotbare-style headers
- **AND** it SHALL be called after `show_final_instructions()` in the main workflow

