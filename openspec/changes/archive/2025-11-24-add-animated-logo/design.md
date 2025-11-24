## Context
The `gitconfig.sh` script currently displays a static ASCII art logo at startup via the `logo()` function. The logo is called from `welcome()` and displays immediately with all 16 lines visible at once. Improvement #9 proposes adding a typewriter animation effect where lines appear sequentially with a small delay.

## Goals / Non-Goals

### Goals
- Add smooth line-by-line animation to logo display
- Maintain exact same visual output (ASCII art and text banner)
- Preserve function signature for backward compatibility
- Use existing color system (`CYE` for accent color)
- Hide cursor during animation for cleaner display

### Non-Goals
- Character-by-character animation (only line-by-line)
- Configurable animation speed (fixed 0.05s delay)
- Multiple logo designs or themes
- Animation skipping or fast-forward options

## Decisions

### Decision: Line-by-line animation with fixed delay
**Rationale**: The proposal specifies a typewriter effect with 0.05 second delay per line. This provides smooth animation without being too slow (total ~0.8s for 16 lines). Character-by-character would be too slow and complex.

**Alternatives considered**:
- Character-by-character: Too slow and complex for bash
- Configurable delay: Adds complexity without clear benefit
- No animation: Doesn't meet improvement goal

### Decision: Hide cursor during animation
**Rationale**: Using `tput civis`/`tput cnorm` ensures the blinking cursor doesn't interfere with the animation display. This is standard practice for terminal animations.

**Alternatives considered**:
- Keep cursor visible: Creates visual distraction
- Use escape sequences: Less portable than `tput`

### Decision: Use existing color system
**Rationale**: The proposal mentions using `$(c accent)` which maps to yellow (`CYE`). We'll use the existing color variables (`CYE`, `BLD`, `CRE`, `CNC`) to maintain consistency with the rest of the script.

**Alternatives considered**:
- New color scheme: Breaks visual consistency
- No colors: Reduces visual appeal

### Decision: Preserve function signature
**Rationale**: The `logo()` function currently accepts one parameter (text for banner). Keeping this signature ensures no breaking changes to callers (specifically `welcome()` at line 458).

**Alternatives considered**:
- Add animation flag parameter: Unnecessary complexity
- Separate animated_logo function: Code duplication

## Risks / Trade-offs

### Risk: Animation delay adds perceived latency
**Mitigation**: 0.8 seconds total is acceptable for welcome screen. Users expect some delay on startup.

### Risk: Cursor not restored if script interrupted
**Mitigation**: Use `trap` to ensure cursor restoration, or wrap in function that always restores.

### Risk: Animation looks choppy on slow terminals
**Mitigation**: 0.05s delay is minimal and should work on most terminals. If issues arise, can be adjusted.

### Trade-off: Animation vs. instant display
**Decision**: Animation provides better UX at cost of ~0.8s delay. This is acceptable for welcome screen.

## Migration Plan

1. Modify existing `logo()` function in-place
2. Test with existing `welcome()` call
3. No migration needed - backward compatible

## Open Questions

- Should animation be skippable with a keypress? (Not in scope per proposal)
- Should delay be configurable via environment variable? (Not in scope per proposal)

