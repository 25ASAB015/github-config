# Design: Non-Interactive Mode Support

## Context
The gitconfig.sh script is an interactive Bash script that configures Git, SSH, and GPG keys. Currently, it requires user interaction for every prompt (yes/no questions, email input, etc.). This prevents automation use cases like CI/CD pipelines, automated testing, and unattended system setup. The script targets Linux environments and is typically run once per machine, but automation scenarios require non-interactive execution.

## Goals / Non-Goals

### Goals
- Enable script execution without user interaction
- Support both environment variables and command-line flags
- Maintain full backward compatibility (default remains interactive)
- Log all auto-answered prompts for auditability
- Support partial automation (non-interactive but still prompt for critical decisions)

### Non-Goals
- Not implementing full configuration file support (defer to future improvement)
- Not removing interactive mode (it remains the default)
- Not implementing dry-run mode (separate improvement #5)
- Not adding complex conditional logic (keep simple: interactive vs non-interactive)

## Decisions

### Decision 1: Dual Control Mechanism (Environment Variables + CLI Flags)
**Rationale:**
- Environment variables: Flexible for CI/CD systems and scripts
- CLI flags: Convenient for direct command execution
- Both methods work together (CLI flags override env vars)
- Standard pattern in Unix tools

**Alternatives considered:**
- CLI flags only: Rejected - less flexible for automation
- Environment variables only: Rejected - less convenient for users
- Configuration file: Rejected - over-engineering for this use case

### Decision 2: AUTO_YES as Separate Flag
**Rationale:**
- `--non-interactive` alone uses defaults (may be "no" for some prompts)
- `--auto-yes` explicitly answers "yes" to all prompts
- Allows fine-grained control: non-interactive with defaults vs non-interactive with auto-yes
- Useful for different automation scenarios

**Alternatives considered:**
- Single flag: Rejected - less flexible
- Auto-yes as default in non-interactive: Rejected - too dangerous (might overwrite existing configs)

### Decision 3: Default Value Behavior in Non-Interactive Mode
**Rationale:**
- When `INTERACTIVE_MODE=false` and `AUTO_YES=false`, use the default value from `ask_yes_no()` call
- This is safer than always saying "yes" (prevents accidental overwrites)
- Users can explicitly use `--auto-yes` if they want all "yes" answers

**Trade-off:** Some prompts default to "no", requiring `--auto-yes` for full automation. This is intentional safety.

### Decision 4: Logging Auto-Answers
**Rationale:**
- Critical for debugging automation failures
- Provides audit trail of what was auto-answered
- Helps troubleshoot issues in CI/CD environments
- Uses existing `log()` function

**Implementation:** `log "AUTO-ANSWER: $prompt -> $default"`

## Implementation Pattern

```bash
# Global variables (after color definitions)
INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}"
AUTO_YES="${AUTO_YES:-false}"

# Argument parsing function
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --non-interactive)
                INTERACTIVE_MODE=false
                shift
                ;;
            --auto-yes)
                AUTO_YES=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Modified ask_yes_no
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local exit_on_no="${3:-false}"
    
    # Non-interactive mode
    if [[ "$INTERACTIVE_MODE" == "false" ]] || [[ "$AUTO_YES" == "true" ]]; then
        local answer="$default"
        if [[ "$AUTO_YES" == "true" ]]; then
            answer="y"
        fi
        log "AUTO-ANSWER: $prompt -> $answer"
        [[ "$answer" == "y" ]] && return 0 || return 1
    fi
    
    # Existing interactive code...
}

# In main()
main() {
    parse_arguments "$@"
    # ... rest of main
}
```

## Risks / Trade-offs

### Risk 1: Accidental Non-Interactive Execution
**Mitigation:** Default remains interactive. Non-interactive requires explicit flag or env var.

### Risk 2: Auto-Yes Too Aggressive
**Mitigation:** Separate `--auto-yes` flag. Users must explicitly opt-in to auto-yes behavior.

### Risk 3: Missing Prompts in Non-Interactive Mode
**Mitigation:** All prompts go through `ask_yes_no()`, which handles non-interactive mode. Input prompts (email, name) need separate handling (future improvement).

### Risk 4: Log File Growth
**Mitigation:** Acceptable trade-off. Logs are essential for debugging automation.

## Migration Plan
1. Add environment variables (non-breaking)
2. Add argument parsing (non-breaking, only processes known flags)
3. Modify `ask_yes_no()` (backward compatible, defaults unchanged)
4. Test interactive mode (verify no regressions)
5. Test non-interactive mode (verify automation works)

**Rollback:** Remove argument parsing calls and non-interactive checks. No data changes.

## Open Questions
- Should input prompts (email, name) also support non-interactive mode? (Defer - requires config file or env vars)
- Should we validate that required inputs are provided in non-interactive mode? (Yes, but defer to input handling improvement)
- Should `--auto-yes` imply `--non-interactive`? (No, keep them separate for flexibility)

