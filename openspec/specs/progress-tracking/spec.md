# progress-tracking Specification

## Purpose
TBD - created by archiving change add-visual-progress-bar. Update Purpose after archive.
## Requirements
### Requirement: Visual Progress Bar Display
The system SHALL provide a visual progress bar that displays current workflow position, completion percentage, and step description during script execution.

#### Scenario: Progress bar at workflow start
- **WHEN** the script begins the first workflow step (dependency check)
- **THEN** the progress bar displays `[11%] ███████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ Verificando dependencias`

#### Scenario: Progress bar at mid-workflow
- **WHEN** the script completes 5 of 9 steps
- **THEN** the progress bar displays `[55%] ███████████████████████████░░░░░░░░░░░░░░░░░░░ Configurando Git` with approximately 55% filled

#### Scenario: Progress bar at completion
- **WHEN** the script completes all 9 workflow steps
- **THEN** the progress bar displays `[100%] ██████████████████████████████████████████████████ Mostrando resumen` followed by a newline

#### Scenario: In-place updates
- **WHEN** the script advances from step N to step N+1
- **THEN** the progress bar updates in-place using carriage return (no new line until final step)

### Requirement: Workflow Stage Definitions
The system SHALL define a fixed set of 9 workflow stages with human-readable names.

#### Scenario: All workflow stages defined
- **WHEN** the script initializes progress tracking
- **THEN** stages are defined as: (1) Verificando dependencias, (2) Configurando directorios, (3) Backup de llaves existentes, (4) Recopilando información, (5) Generando llave SSH, (6) Generando llave GPG, (7) Configurando Git, (8) Configurando SSH agent, (9) Mostrando resumen

#### Scenario: Stage name retrieval
- **WHEN** the progress bar function is called with stage ID 3
- **THEN** it displays "Backup de llaves existentes" as the step description

### Requirement: Progress Bar Visual Format
The system SHALL render the progress bar with a fixed width of 50 characters, using Unicode block characters for filled/empty portions, and color-coded elements.

#### Scenario: Visual format components
- **WHEN** rendering a progress bar at 44% completion (step 4 of 9)
- **THEN** the format includes: percentage in yellow/bold `[44%]`, filled blocks in green `██████████████████████`, empty blocks in dim `░░░░░░░░░░░░░░░░░░░░░░░░░░`, and step name in blue

#### Scenario: Terminal width compatibility
- **WHEN** the script runs in an 80-column terminal
- **THEN** the full progress bar (percentage + bar + step name) fits within one line without wrapping

### Requirement: Progress State Management
The system SHALL track current step and total steps as integer counters, incrementing before each major workflow function.

#### Scenario: Initial state
- **WHEN** the main() function begins
- **THEN** `CURRENT_STEP` is initialized to 0 and `TOTAL_STEPS` is set to 9

#### Scenario: Step increment
- **WHEN** the script advances to the next workflow stage
- **THEN** `CURRENT_STEP` is incremented by 1 using `((CURRENT_STEP++))`

#### Scenario: Progress calculation
- **WHEN** calculating percentage at step 5 of 9
- **THEN** the percentage is computed as `(5 * 100 / 9) = 55` (integer division)

### Requirement: Backward Compatibility with Spinners
The system SHALL preserve existing spinner functionality for individual task progress within workflow stages.

#### Scenario: Combined progress display
- **WHEN** a long-running task (e.g., GPG key generation) executes within a workflow stage
- **THEN** the progress bar shows the stage (e.g., step 6) AND the spinner shows sub-task activity

#### Scenario: No visual conflicts
- **WHEN** both progress bar and spinner are active
- **THEN** spinner output does not corrupt progress bar display and error messages display correctly

