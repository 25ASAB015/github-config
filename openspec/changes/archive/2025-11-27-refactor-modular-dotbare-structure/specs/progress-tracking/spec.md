# Capability: Progress Tracking (Delta)

## MODIFIED Requirements

### Requirement: Visual Progress Bar Display

The system SHALL display a visual progress bar indicating workflow completion, **now located in a dedicated UI module**.

#### Scenario: Function location
- **GIVEN** the refactored codebase
- **WHEN** displaying progress
- **THEN** `show_progress_bar()` SHALL be defined in `scripts/core/ui.sh`
- **AND** the function SHALL be documented with dotbare-style headers

### Requirement: Workflow Stage Definitions

The system SHALL define workflow stages in an associative array, **now located in the configuration module**.

#### Scenario: Stage definition location
- **GIVEN** the refactored codebase
- **WHEN** accessing workflow stage names
- **THEN** `WORKFLOW_STEPS` associative array SHALL be defined in `config/defaults.sh`
- **AND** the array SHALL be documented with inline comments

### Requirement: Progress State Management

The system SHALL maintain progress state through global variables, **now centralized in configuration**.

#### Scenario: State variable location
- **GIVEN** the refactored codebase
- **WHEN** tracking progress
- **THEN** `TOTAL_STEPS` and `CURRENT_STEP` SHALL be defined in `config/defaults.sh`
- **AND** both variables SHALL be documented

---

## Notes

- All existing behavior preserved exactly
- Only file locations change, not functionality
- UI functions grouped in `scripts/core/ui.sh`
- Configuration grouped in `config/defaults.sh`
