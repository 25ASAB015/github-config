# ui-colors Specification

## Purpose
TBD - created by archiving change add-accessible-color-system. Update Purpose after archive.
## Requirements
### Requirement: Semantic Color Palette Definition

The system SHALL define a semantic color palette using an associative array, **now located in a dedicated module file**.

#### Scenario: Module location
- **GIVEN** the refactored codebase
- **WHEN** accessing color functionality
- **THEN** the `COLORS` associative array SHALL be defined in `scripts/core/colors.sh`
- **AND** the file SHALL follow dotbare-style documentation headers

#### Scenario: Module sourcing
- **GIVEN** any module that uses colors
- **WHEN** the main entry point initializes
- **THEN** `scripts/core/colors.sh` SHALL be sourced before any color-using modules
- **AND** `${mydir}` SHALL be used for the source path

---

### Requirement: Color Access Helper Functions

The system SHALL provide helper functions for safe color access, **now located in a dedicated module file**.

#### Scenario: Helper function location
- **GIVEN** the refactored codebase
- **WHEN** calling `c()` or `cr()` functions
- **THEN** they SHALL be defined in `scripts/core/colors.sh`
- **AND** both functions SHALL be documented with dotbare-style function headers

---

### Requirement: Consistent Palette Usage in UI Components
All UI-rendering components SHALL consume the semantic palette tokens via `c()` and `cr()` helpers instead of hard-coded escape sequences or legacy constants, guaranteeing uniform theming across progress indicators, previews, banners, and logging.

#### Scenario: Progress bar uses palette tokens
- **WHEN** `show_progress_bar()` renders percentage, filled blocks, empty blocks, and step name
- **THEN** it sources colors from the palette: `$(c warning)` for percentage, `$(c success)` for filled blocks (█), `$(c muted)` for empty blocks (░), `$(c primary)` for step labels
- **AND** the function contains zero references to legacy constants (BLD, CCY, CGR, DIM, CBL)
- **AND** visual output is pixel-identical to pre-migration progress bar

#### Scenario: Change preview uses palette tokens
- **WHEN** `show_changes_summary()` displays headers and file statuses
- **THEN** section headers use `$(c accent)`, status badges (`[CREAR]`, `[MODIFICAR]`) use `$(c success)` and `$(c warning)`, configuration labels use `$(c primary)`, and notes use `$(c muted)`
- **AND** the function contains zero references to legacy constants

#### Scenario: Logo uses palette tokens
- **WHEN** `logo()` function displays ASCII art and text banner
- **THEN** logo lines use `$(c accent)` (replacing CYE), bracket elements use `$(c error)` (replacing CRE), text uses `$(c warning)` (replacing CYE)
- **AND** visual output matches pre-migration logo exactly

#### Scenario: Logging functions use state tokens
- **WHEN** `success()`, `error()`, `warning()`, `info()` functions emit messages
- **THEN** each uses the corresponding state token: `$(c success)`, `$(c error)`, `$(c warning)`, `$(c info)`
- **AND** all message formatting is consistent (same prefix symbols, same reset behavior)

#### Scenario: Spinners use palette tokens
- **WHEN** `show_spinner()` displays loading animation and status messages
- **THEN** spinner frames and messages use palette tokens for success/error states
- **AND** no hard-coded color constants remain in the spinner implementation

#### Scenario: Visual separators and banners use palette
- **WHEN** `show_separator()` and banner functions emit decorative borders
- **THEN** they use palette tokens (e.g., `$(c primary)` for borders, `$(c bold)` for emphasis)
- **AND** consistent styling is enforced across all separator styles

