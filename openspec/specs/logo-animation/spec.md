# logo-animation Specification

## Purpose
TBD - created by archiving change add-animated-logo. Update Purpose after archive.
## Requirements
### Requirement: Animated Logo Display
The system SHALL display the ASCII art logo with a typewriter animation effect, showing each line sequentially with a delay between lines.

#### Scenario: Logo animation sequence
- **WHEN** the `logo()` function is called with a text parameter
- **THEN** the 16 logo lines are displayed one at a time, with each line appearing after a 0.05 second delay from the previous line

#### Scenario: Logo line formatting
- **WHEN** each logo line is displayed
- **THEN** the line is printed with accent color (yellow/`CYE`) using `printf` with color codes, followed by a newline

#### Scenario: Logo animation completion
- **WHEN** all 16 logo lines have been displayed
- **THEN** the text banner appears below the logo with the format `[ ${text} ]` using bold, red brackets, and yellow text

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

