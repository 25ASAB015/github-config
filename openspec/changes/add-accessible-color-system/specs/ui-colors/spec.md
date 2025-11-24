## ADDED Requirements
### Requirement: Semantic Color Palette Definition
The system SHALL replace global color constants (CRE, CYE, CGR, CBL, CMA, CCY, CWH, BLD, DIM, CNC) with a centralized `COLORS` associative array that maps semantic tokens to ANSI escape sequences derived from `tput`, ensuring consistent and accessible styling across the script per WCAG 2.1 guidelines.

#### Scenario: Palette includes state tokens
- **WHEN** the script initializes UI helpers at startup
- **THEN** the `COLORS` array defines tokens for states: `success` (green/setaf 2), `error` (red/setaf 1), `warning` (yellow/setaf 3), `info` (blue/setaf 4)
- **AND** each token references a high-contrast foreground color validated against WCAG 2.1 contrast ratios for terminal backgrounds

#### Scenario: Palette includes UI element tokens
- **WHEN** UI components request styling
- **THEN** tokens exist for `primary` (cyan/setaf 6), `secondary` (magenta/setaf 5), `accent` (yellow/setaf 3), `text` (white/setaf 7), `muted` (dim), `bold` (bold), and `reset` (sgr0)
- **AND** each token resolves to a consistent ANSI sequence shared by all consumers

#### Scenario: Graceful fallback when colors unavailable
- **WHEN** `tput` is missing, the terminal does not support colors (`TERM=dumb`), or `tput colors` returns 0
- **THEN** palette initialization assigns empty strings for all tokens without raising errors or warnings
- **AND** UI output remains readable in monochrome terminals (no broken escape sequences)

#### Scenario: Legacy constants removed
- **WHEN** the script executes after migration
- **THEN** global constants CRE, CYE, CGR, CBL, CMA, CCY, CWH, BLD, DIM, CNC are no longer defined or referenced
- **AND** grep search for these constants in active code returns zero matches

### Requirement: Color Access Helper Functions
The system SHALL expose helper functions `c()` and `cr()` that retrieve palette entries, validate token names, enforce reset usage, and guard against invalid tokens without causing script failures.

#### Scenario: Retrieve token code by name
- **WHEN** a UI function calls `c success` (or any defined token name)
- **THEN** the helper returns the ANSI sequence from `${COLORS[success]}` (e.g., `\033[32m` or equivalent tput output)
- **AND** the caller can inline it within `printf` statements: `printf "$(c success)✓ Done$(cr)\n"`

#### Scenario: Handle unknown tokens safely
- **WHEN** the helper receives an undefined token name (e.g., `c invalid_token`)
- **THEN** it logs a debug warning to stderr when `DEBUG=true`: "Warning: unknown color token 'invalid_token'"
- **AND** returns an empty string to prevent broken output or script crashes

#### Scenario: Reset helper restores defaults
- **WHEN** a UI function calls the reset helper `cr` (or `c reset`)
- **THEN** the helper outputs `${COLORS[reset]}` (tput sgr0), ensuring subsequent text uses default terminal colors
- **AND** the helper prevents nested reset calls from breaking output

#### Scenario: Helpers work without colors
- **WHEN** the terminal does not support colors (COLORS array contains empty strings)
- **THEN** `c()` and `cr()` return empty strings gracefully
- **AND** no stderr warnings are emitted (silent degradation)

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
