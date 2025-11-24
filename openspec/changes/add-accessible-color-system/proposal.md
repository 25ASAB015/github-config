# Change: Accessible Color System

## Why
Current UI outputs inside `gitconfig.sh` rely on scattered hard-coded ANSI codes defined as global variables (lines 22-32: `CRE`, `CYE`, `CGR`, `CBL`, `CMA`, `CCY`, `CWH`, `BLD`, `DIM`, `CNC`). Colors differ between features (progress bar uses different tokens than change preview), and there is no guarantee of accessibility (WCAG 2.1 contrast ratios) or graceful degradation when the terminal lacks `tput` or color support. Improvement #6 (mejoras.md lines 246-285) proposes consolidating colors into a semantic palette so every UI element shares a consistent, high-contrast theme with safe fallbacks.

## What Changes
- **Replace global color constants** (CRE, CYE, etc.) with a semantic `COLORS` associative array that maps tokens (success, error, warning, info, primary, secondary, accent, text, muted, bold, reset) to ANSI codes using `tput`, following WCAG 2.1 accessibility guidelines for terminal contrast.
- **Provide helper functions** `c()` and `cr()` that safely retrieve palette entries by name, handle unknown tokens gracefully, and return empty strings when colors are unavailable (e.g., `$TERM=dumb` or missing `tput`).
- **Migrate all UI components** (progress bar at line ~200, change preview, spinners at line ~168, logging functions, logo at line ~114, welcome/separator/banner functions) to consume palette tokens via helpers instead of hard-coded constants, ensuring uniform theming and accessibility.
- **Document migration path** from old constants to new tokens in code comments to assist future maintenance.

## Impact
- **Affected specs:** `ui-colors` (new capability)
- **Affected code:** 
  - `gitconfig.sh` lines 22-32 (color constant definitions → COLORS array)
  - All functions using color constants: `logo()`, `show_spinner()`, `show_progress_bar()`, `show_changes_summary()`, `success()`, `error()`, `warning()`, `info()`, `show_separator()`, and others
  - Approximately 50-70 color constant references throughout the 1618-line script
- **Breaking changes:** None (visual output remains identical, only internal implementation changes)
- **Backward compatibility:** Full compatibility with existing behavior; visual regression testing required
