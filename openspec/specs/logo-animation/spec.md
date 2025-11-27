# logo-animation Specification

## Purpose
TBD - created by archiving change add-animated-logo. Update Purpose after archive.
## Requirements
### Requirement: Animated Logo Display

The system SHALL display an animated ASCII art logo, **now located in the UI module**.

#### Scenario: Logo function location
- **GIVEN** the refactored codebase
- **WHEN** displaying the logo
- **THEN** `logo()` SHALL be defined in `scripts/core/ui.sh`
- **AND** the function SHALL be documented with dotbare-style headers

#### Scenario: Logo usage
- **GIVEN** the refactored codebase
- **WHEN** the welcome function calls logo
- **THEN** `welcome()` SHALL also be in `scripts/core/ui.sh`
- **AND** both functions SHALL share the same module

---

### Requirement: Cursor Management During Animation
The system SHALL hide the terminal cursor at the start of logo animation and restore it after completion.

#### Scenario: Cursor hidden at start
- **WHEN** the `logo()` function begins execution
- **THEN** the cursor is hidden using `tput civis` before any logo lines are displayed

#### Scenario: Cursor restored at end
- **WHEN** all logo lines and the text banner have been displayed
- **THEN** the cursor is restored using `tput cnorm` before the function returns

#### Scenario: Cursor restoration on early exit
- **WHEN** the script is interrupted during logo animation (e.g., Ctrl+C)
- **THEN** the cursor is restored to visible state to prevent terminal corruption

### Requirement: Animation Timing
The system SHALL display each logo line with a fixed delay of 0.05 seconds between consecutive lines.

#### Scenario: Delay between lines
- **WHEN** displaying logo line N
- **THEN** the system waits 0.05 seconds using `sleep 0.05` before displaying line N+1

#### Scenario: Total animation duration
- **WHEN** displaying all 16 logo lines
- **THEN** the total animation time is approximately 0.8 seconds (16 lines × 0.05s delay)

### Requirement: Backward Compatibility
The system SHALL maintain the existing `logo()` function signature and visual output format.

#### Scenario: Function signature unchanged
- **WHEN** code calls `logo "GitHub Configuración – $USER"`
- **THEN** the function accepts a single text parameter and displays the logo with that text in the banner

#### Scenario: Visual output matches static version
- **WHEN** the animated logo completes
- **THEN** the final visual output (all 16 lines + text banner) matches the previous static logo output exactly

#### Scenario: Existing callers work unchanged
- **WHEN** the `welcome()` function calls `logo()` at line 458
- **THEN** no changes are required to the caller code

### Requirement: Logo Art Preservation
The system SHALL display the exact same 16-line ASCII art design as the current static logo.

#### Scenario: Logo lines match existing design
- **WHEN** the logo is displayed
- **THEN** all 16 lines match the existing logo art:
  - Line 1: `               %%%`
  - Line 2: `        %%%%%//%%%%%`
  - Lines 3-16: [remaining lines from existing logo]
  - All lines preserve exact spacing and characters

