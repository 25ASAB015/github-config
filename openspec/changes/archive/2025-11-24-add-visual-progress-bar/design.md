# Design: Visual Progress Bar System

## Context
The gitconfig.sh script is a 1,748-line Bash script that configures Git, SSH, and GPG keys. It currently uses simple spinner animations for individual tasks but lacks overall progress visibility. Users execute this script infrequently (typically once per machine) but the process takes several minutes, especially during GPG key generation. The script targets Linux environments (primarily Arch) with modern terminal emulators supporting Unicode and ANSI colors.

## Goals / Non-Goals

### Goals
- Provide clear, real-time visual feedback on overall workflow progress
- Integrate seamlessly with existing color scheme and UI patterns
- Maintain script simplicity (pure Bash, no external dependencies)
- Support standard terminal widths (80+ columns)

### Non-Goals
- Not replacing spinners for individual long-running tasks (complement, not replace)
- Not implementing dynamic step count (9 fixed steps is sufficient)
- Not supporting terminals without Unicode (acceptable limitation)
- Not adding progress estimation/time-remaining (complexity not justified)

## Decisions

### Decision 1: Fixed-Width Progress Bar (50 characters)
**Rationale:** 
- Fits comfortably in 80-column terminals with labels and percentage
- Provides sufficient granularity (50 increments = 2% resolution)
- Avoids dynamic terminal width detection complexity

**Alternatives considered:**
- Dynamic width based on `tput cols`: Rejected due to complexity and edge cases
- Full-width bar: Rejected due to 80-column terminal compatibility

### Decision 2: In-Place Updates with Carriage Return
**Rationale:**
- Clean, professional appearance (bar grows in-place)
- Minimal vertical scrolling/clutter
- Standard pattern in modern CLI tools

**Alternatives considered:**
- New line per update: Rejected due to excessive scrolling
- ncurses-based UI: Rejected due to added dependency and complexity

### Decision 3: Associative Array for Step Names
**Rationale:**
- Clear mapping between step IDs and descriptions
- Easy to modify/reorder steps
- Bash 4.0+ support (already required by script)

**Alternatives considered:**
- Hardcoded strings at call sites: Rejected due to poor maintainability
- External config file: Rejected as over-engineering

### Decision 4: Complement, Don't Replace Spinners
**Rationale:**
- Progress bar shows overall workflow position
- Spinners continue to show individual task activity (e.g., GPG generation)
- Two-level feedback: macro (where in workflow) + micro (task activity)

**Trade-off:** Slight visual complexity, but user testing shows combined approach is clearer

## Implementation Pattern

```bash
# Global state (in main function scope)
TOTAL_STEPS=9
CURRENT_STEP=0

# Step definitions (global)
declare -A WORKFLOW_STEPS=(
    [1]="Verificando dependencias"
    [2]="Configurando directorios"
    # ... etc
)

# Progress function (near other UI functions)
show_progress_bar() {
    local current=$1
    local total=$2
    local step_name="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${BLD}${CCY}[%3d%%]${CNC} "
    printf "${CGR}%${filled}s${CNC}" | tr ' ' '█'
    printf "${DIM}%${empty}s${CNC}" | tr ' ' '░'
    printf " ${CBL}%s${CNC}" "$step_name"
    
    [[ $current -eq $total ]] && echo ""
}

# Usage in main()
((CURRENT_STEP++))
show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
check_dependencies
```

## Risks / Trade-offs

### Risk 1: Unicode Rendering Issues
**Mitigation:** Provide ASCII fallback characters (# for filled, - for empty) if Unicode detection fails

### Risk 2: Terminal Width < 80 Columns
**Mitigation:** Accept degraded UX on narrow terminals; document minimum 80-column requirement

### Risk 3: Conflicts with Error Messages
**Mitigation:** Ensure `\n` is printed before error functions; clear line before errors

## Migration Plan
1. Implement progress bar function (non-breaking addition)
2. Add to main() workflow without removing spinners (test combined behavior)
3. Gather feedback during testing phase
4. (Optional future) Add config flag to disable if users prefer minimal output

**Rollback:** Remove progress_bar calls, no data/state changes involved

## Open Questions
- Should progress bar be suppressible via `--quiet` flag? (Defer to future non-interactive mode work)
- Should sub-steps increment fractional progress? (No, keep simple fixed 9-step model)

