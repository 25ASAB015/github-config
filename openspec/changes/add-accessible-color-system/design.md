## Context
The `gitconfig.sh` script currently defines 10 global color constants (CRE, CYE, CGR, etc.) at lines 22-32, initialized via `tput` commands. These constants are used directly in approximately 50-70 locations throughout the 1618-line script. There is no centralized color management, no accessibility documentation, and no fallback strategy when `tput` is unavailable or the terminal lacks color support. Improvement #6 (mejoras.md) proposes a semantic palette system based on WCAG 2.1 accessibility principles.

**Current architecture:**
- Global constants initialized once at script startup
- Direct references scattered across UI functions
- No abstraction layer for color access
- No terminal capability detection

**Constraints:**
- Must preserve existing visual output exactly (pixel-perfect compatibility)
- Cannot introduce external dependencies (bash built-ins only)
- Must degrade gracefully on minimal terminals (dumb, xterm-mono)
- Migration must be atomic (no intermediate broken states)

## Goals / Non-Goals

**Goals:**
- Centralize all color definitions into a single semantic palette (COLORS associative array)
- Enforce consistent naming conventions (success, error, warning, info vs. ad-hoc abbreviations)
- Provide safe accessor functions that handle missing tokens and color-incapable terminals
- Document accessibility rationale (WCAG 2.1 contrast guidelines) in code
- Enable future theming or customization (users could override COLORS array)

**Non-Goals:**
- Dynamic theme switching at runtime (out of scope)
- Support for 256-color or true-color palettes (8-color ANSI sufficient)
- Color customization via config files (can be added later if needed)
- Performance optimization (color access is not a bottleneck)

## Decisions

### Decision 1: Associative Array vs. Functions
**Chosen:** Associative array (`declare -A COLORS`) with helper functions.

**Rationale:**
- Arrays allow batch initialization and runtime inspection (`${!COLORS[@]}`)
- Helper functions (`c()`, `cr()`) provide validation and fallback logic
- Easier to document inline (one block of comments above array definition)
- Follows pattern from mejoras.md lines 257-276

**Alternatives considered:**
- Individual functions per color (e.g., `color_success()`) → verbose, no centralized definition
- Global variables with prefix (e.g., `COLOR_SUCCESS`) → no validation, harder to iterate

### Decision 2: Semantic Token Naming
**Chosen:** Semantic names (success, error, primary, text) instead of color names (green, red, cyan).

**Rationale:**
- Intent-based naming improves maintainability (easier to understand "success" than "green")
- Allows future theme changes without renaming tokens (success could become blue in a different theme)
- Aligns with WCAG 2.1 principle of meaning over presentation
- Matches industry patterns (Bootstrap, Tailwind use semantic naming)

**Alternatives considered:**
- Keep color names (green, red, etc.) → ties UI to specific colors, less flexible
- Use original abbreviations (CRE, CYE) → cryptic, no semantic meaning

### Decision 3: Fallback Strategy
**Chosen:** Three-tier fallback: `tput` → empty string → script continues.

**Rationale:**
- Simplest implementation: `"$(tput setaf 2 2>/dev/null || echo -n "")"`
- Fails gracefully: missing colors don't break script execution
- Testable: `TERM=dumb` simulates color-incapable terminal
- No external dependencies (no need for `terminfo` checks)

**Alternatives considered:**
- Fail fast if `tput` unavailable → breaks on minimal terminals, bad UX
- Use hardcoded ANSI escape sequences as fallback → fragile, terminal-specific
- Detect terminal capabilities first (`tput colors`) → added complexity, edge cases

### Decision 4: Migration Path
**Chosen:** All-at-once migration with visual regression tests.

**Steps:**
1. Add COLORS array and helpers below existing constants (keep old constants temporarily)
2. Migrate all functions to use new helpers
3. Verify visual output matches pre-migration screenshots
4. Remove old constants only after all migrations pass tests

**Rationale:**
- Atomic migration reduces risk (either all works or roll back)
- Coexistence period allows gradual testing of each component
- Visual regression tests ensure pixel-perfect compatibility
- Single-commit change simplifies code review

**Alternatives considered:**
- Gradual migration (component by component) → long-lived mixed state, harder to track
- Aliasing old constants to new tokens → technical debt, confusing for future contributors

## Risks / Trade-offs

**Risk 1: Breaking visual output**
- **Mitigation:** Require before/after screenshots for all UI surfaces in tasks.md (4.6)
- **Mitigation:** Use exact same `tput` commands as original constants
- **Trade-off:** More validation work upfront vs. broken UI for users

**Risk 2: Performance overhead from function calls**
- **Assessment:** Negligible (color access is <1% of script runtime, dominated by GPG/SSH key generation)
- **Trade-off:** Cleaner architecture vs. microseconds of overhead (acceptable)

**Risk 3: Bash version compatibility**
- **Assessment:** Associative arrays require Bash 4.0+ (released 2009, widely available)
- **Mitigation:** Document Bash version requirement in script header
- **Trade-off:** Drop support for ancient Bash 3.x vs. modern array syntax

**Risk 4: Unknown tokens during migration**
- **Mitigation:** `c()` helper logs warnings in DEBUG mode, returns empty string to prevent crashes
- **Mitigation:** grep validation in tasks.md (4.5) ensures no legacy constants remain

## Migration Plan

### Phase 1: Setup (Tasks 1.1-1.4)
1. Add COLORS array below existing constants (coexistence)
2. Add c() and cr() helpers
3. Add inline documentation for WCAG rationale

### Phase 2: Gradual Migration (Tasks 3.1-3.7)
1. Migrate one function at a time, starting with low-risk components (logo, separators)
2. Test each function in isolation before moving to next
3. Use grep to find remaining references to old constants

### Phase 3: Validation (Tasks 4.1-4.6)
1. Run shellcheck and dry-run tests
2. Capture screenshots in color and colorless terminals
3. Compare against pre-migration baseline
4. Remove old constants only after 100% test pass rate

### Rollback Strategy
- If visual regression detected: revert to commit before COLORS array introduction
- If performance issue detected: keep COLORS but inline color codes in hot paths
- If compatibility issue detected: add Bash version check and graceful exit with error message

## Open Questions
- **Q1:** Should we support NO_COLOR environment variable (https://no-color.org/)?
  - **Decision:** Out of scope for initial implementation, can be added in follow-up change
- **Q2:** Should we allow users to customize colors via config file?
  - **Decision:** Not in MVP, but architecture supports it (users could source custom COLORS array)
- **Q3:** Should we add color contrast validation tests (automated WCAG checks)?
  - **Decision:** Manual documentation sufficient for terminal colors (WCAG primarily targets GUI)

