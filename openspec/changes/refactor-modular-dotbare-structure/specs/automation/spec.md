# Capability: Automation (Delta)

## MODIFIED Requirements

### Requirement: Command-Line Argument Parsing

The system SHALL parse command-line arguments for automated execution, **now in the main entry point**.

#### Scenario: Argument parsing location
- **GIVEN** the refactored codebase
- **WHEN** parsing command-line arguments
- **THEN** `parse_arguments()` SHALL be defined in `gitconfig.sh` (main entry point)
- **AND** the function SHALL be documented with dotbare-style headers

#### Scenario: Help display location
- **GIVEN** the refactored codebase
- **WHEN** displaying help information
- **THEN** `show_help()` SHALL be defined in `scripts/core/ui.sh`
- **AND** the function SHALL be documented with dotbare-style headers

### Requirement: Non-Interactive Mode

The system SHALL support execution without user interaction, allowing automation and unattended execution.

#### Scenario: Non-interactive mode via command-line flag
- **WHEN** the script is executed with `--non-interactive` flag
- **THEN** all `ask_yes_no()` prompts use their default values without waiting for user input
- **AND** the script completes without requiring any user interaction

#### Scenario: Non-interactive mode via environment variable
- **WHEN** the script is executed with `INTERACTIVE_MODE=false`
- **THEN** all `ask_yes_no()` prompts use their default values without waiting for user input
- **AND** the script completes without requiring any user interaction
- **AND** `INTERACTIVE_MODE` SHALL be defined in `config/defaults.sh` (centralized configuration)

#### Scenario: Interactive mode remains default
- **WHEN** the script is executed without flags or environment variables
- **THEN** the script operates in interactive mode (prompts for user input)
- **AND** existing behavior is unchanged

---

## Notes

- All existing behavior preserved exactly
- Only file locations change, not functionality
- Argument parsing remains in main entry point
- Mode variables centralized in configuration
