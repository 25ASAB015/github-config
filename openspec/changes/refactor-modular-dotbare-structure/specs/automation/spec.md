# Capability: Automation (Delta)

## MODIFIED Requirements

### Requirement: Command Line Argument Parsing

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

### Requirement: Non-Interactive Mode Variables

The system SHALL support non-interactive execution via environment variables, **now centralized in configuration**.

#### Scenario: Mode variable location
- **GIVEN** the refactored codebase
- **WHEN** checking interactive mode
- **THEN** `INTERACTIVE_MODE` SHALL be defined in `config/defaults.sh`
- **AND** `AUTO_UPLOAD_KEYS` SHALL be defined in `config/defaults.sh`

---

## Notes

- All existing behavior preserved exactly
- Only file locations change, not functionality
- Argument parsing remains in main entry point
- Mode variables centralized in configuration
