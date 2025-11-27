# change-preview Specification

## Purpose
TBD - created by archiving change add-change-preview. Update Purpose after archive.
## Requirements
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

### Requirement: Non-Interactive Mode Support
The system SHALL handle preview display appropriately in non-interactive mode, either skipping it or auto-confirming.

#### Scenario: Preview in non-interactive mode
- **WHEN** `INTERACTIVE_MODE` is `false`
- **THEN** the preview may be skipped or auto-confirmed based on implementation
- **AND** the script does not wait for user input

#### Scenario: Preview with auto-yes mode
- **WHEN** `AUTO_YES` is `true`
- **THEN** the preview is displayed (if shown)
- **AND** the confirmation prompt automatically returns "yes" without waiting

### Requirement: Preview Visual Format
The system SHALL display the preview with clear visual formatting using colors, borders, and structured sections.

#### Scenario: Preview header format
- **WHEN** the preview is displayed
- **THEN** it shows a formatted header with title "📋 RESUMEN DE CAMBIOS A REALIZAR"
- **AND** uses box-drawing characters for visual separation

#### Scenario: Preview section organization
- **WHEN** the preview is displayed
- **THEN** it organizes information into sections:
  - Files that will be created/modified (with color-coded status indicators)
  - Git configuration values
- **AND** each section is clearly separated

#### Scenario: Preview color coding
- **WHEN** the preview is displayed
- **THEN** it uses color codes:
  - Green (`CGR`) for `[CREAR]` operations
  - Yellow (`CYE`) for `[SOBRESCRIBIR]` or `[MODIFICAR]` operations
  - Cyan (`CCY`) for section headers
  - Blue (`CBL`) for configuration labels
  - Dim (`DIM`) for additional notes

