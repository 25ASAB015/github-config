# progress-tracking Specification

## Purpose
TBD - created by archiving change add-visual-progress-bar. Update Purpose after archive.
## Requirements
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

### Requirement: Progress Bar Visual Format
The system SHALL render the progress bar with a fixed width of 50 characters, using Unicode block characters for filled/empty portions, and color-coded elements.

#### Scenario: Visual format components
- **WHEN** rendering a progress bar at 44% completion (step 4 of 9)
- **THEN** the format includes: percentage in yellow/bold `[44%]`, filled blocks in green `██████████████████████`, empty blocks in dim `░░░░░░░░░░░░░░░░░░░░░░░░░░`, and step name in blue

#### Scenario: Terminal width compatibility
- **WHEN** the script runs in an 80-column terminal
- **THEN** the full progress bar (percentage + bar + step name) fits within one line without wrapping

### Requirement: Progress State Management

The system SHALL maintain progress state through global variables, **now centralized in configuration**.

#### Scenario: State variable location
- **GIVEN** the refactored codebase
- **WHEN** tracking progress
- **THEN** `TOTAL_STEPS` and `CURRENT_STEP` SHALL be defined in `config/defaults.sh`
- **AND** both variables SHALL be documented

---

### Requirement: Backward Compatibility with Spinners
The system SHALL preserve existing spinner functionality for individual task progress within workflow stages.

#### Scenario: Combined progress display
- **WHEN** a long-running task (e.g., GPG key generation) executes within a workflow stage
- **THEN** the progress bar shows the stage (e.g., step 6) AND the spinner shows sub-task activity

#### Scenario: No visual conflicts
- **WHEN** both progress bar and spinner are active
- **THEN** spinner output does not corrupt progress bar display and error messages display correctly

