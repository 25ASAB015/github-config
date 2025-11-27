# Capability: Change Preview (Delta)

## MODIFIED Requirements

### Requirement: Change Preview Display

The system SHALL display a summary of all changes before applying them, **now located in a dedicated finalization module**.

#### Scenario: Function location
- **GIVEN** the refactored codebase
- **WHEN** showing the change preview
- **THEN** `show_changes_summary()` SHALL be defined in `scripts/finalize.sh`
- **AND** the function SHALL be documented with dotbare-style headers

### Requirement: User Confirmation Before Changes

The system SHALL prompt for user confirmation after displaying the preview, **using the UI module**.

#### Scenario: Confirmation function usage
- **GIVEN** the refactored codebase
- **WHEN** prompting for confirmation
- **THEN** `ask_yes_no()` from `scripts/core/ui.sh` SHALL be used
- **AND** the finalize module SHALL source the UI module

---

## Notes

- All existing behavior preserved exactly
- Only file locations change, not functionality
- Preview and finalization functions grouped in `scripts/finalize.sh`
- Confirmation prompts remain in `scripts/core/ui.sh`
