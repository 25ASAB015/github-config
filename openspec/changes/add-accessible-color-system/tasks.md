## 1. Setup and Palette Definition
- [ ] 1.1 Remove or comment out existing global color constants (CRE, CYE, CGR, CBL, CMA, CCY, CWH, BLD, DIM, CNC) at lines 22-32 in gitconfig.sh
- [ ] 1.2 Define `COLORS` associative array with semantic tokens:
  - States: `success` (green/setaf 2), `error` (red/setaf 1), `warning` (yellow/setaf 3), `info` (blue/setaf 4)
  - UI elements: `primary` (cyan/setaf 6), `secondary` (magenta/setaf 5), `accent` (yellow/setaf 3), `text` (white/setaf 7)
  - Modifiers: `muted` (dim), `bold` (bold), `reset` (sgr0)
- [ ] 1.3 Wrap each `tput` call in fallback logic (e.g., `|| echo -n ""`) to handle missing tput or color-incapable terminals gracefully
- [ ] 1.4 Document WCAG 2.1 contrast rationale in inline comments above COLORS array

## 2. Helper Functions
- [ ] 2.1 Implement `c()` function that retrieves palette entry by token name, logs debug warning for unknown tokens when DEBUG=true, and returns empty string on failure
- [ ] 2.2 Implement `cr()` function that returns the reset token from COLORS array
- [ ] 2.3 Add fallback detection: check `$TERM` variable and disable colors if `TERM=dumb` or `tput colors` returns 0

## 3. Migration of UI Components
- [ ] 3.1 Update `logo()` function (line ~114) to use `$(c accent)` and `$(c error)` instead of CYE, CRE
- [ ] 3.2 Update `show_spinner()` (line ~168) to use palette tokens for status messages
- [ ] 3.3 Update `show_progress_bar()` (line ~200) to use `$(c warning)`, `$(c success)`, `$(c muted)`, `$(c primary)` for percentage, filled blocks, empty blocks, labels
- [ ] 3.4 Update `show_changes_summary()` to use palette tokens for section headers, status badges ([CREAR], [MODIFICAR]), and explanatory text
- [ ] 3.5 Update logging functions (`success()`, `error()`, `warning()`, `info()`) to use state tokens instead of hard-coded colors
- [ ] 3.6 Update visual separator/banner functions to use palette tokens
- [ ] 3.7 Search for all remaining references to old constants (CRE, CYE, etc.) using `grep -n "C[RYG][ER]\\|CBL\\|CMA\\|CCY\\|CWH\\|BLD\\|DIM\\|CNC" gitconfig.sh` and migrate to palette

## 4. Testing and Validation
- [ ] 4.1 Run `shellcheck gitconfig.sh` to catch any syntax errors from migration
- [ ] 4.2 Execute script in dry-run mode (`DRY_RUN=true ./gitconfig.sh`) and verify no color-related errors
- [ ] 4.3 Test in color terminal: confirm visual output matches pre-migration screenshots for key surfaces (welcome, progress bar, preview, summary)
- [ ] 4.4 Test in colorless terminal (`TERM=dumb ./gitconfig.sh` or `TERM=xterm-mono`) and verify script runs without errors, output is readable
- [ ] 4.5 Verify `grep -c "C[RYG][ER]\\|CBL\\|CMA\\|CCY\\|CWH" gitconfig.sh` returns 0 (all legacy constants removed from active code)
- [ ] 4.6 Capture before/after screenshots of: welcome banner, progress bar at 50%, change preview, final summary, and document in validation report
