# Change: Add Animated Logo with Typewriter Effect

## Why
The current logo function displays all lines instantly, which lacks visual polish and doesn't create an engaging first impression. An animated logo with a typewriter effect (line-by-line display with delay) provides a more professional and engaging user experience, especially for first-time users. The animation draws attention to the welcome screen and sets a positive tone for the script execution.

## What Changes
- Replace static `logo()` function with animated version that displays lines sequentially
- Add line-by-line animation with configurable delay (0.05 seconds per line)
- Hide cursor during animation using `tput civis` and restore with `tput cnorm`
- Apply accent color (`CYE`/yellow) to logo lines for visual consistency
- Maintain existing logo ASCII art design (16 lines)
- Preserve text banner format below logo with bold/color formatting
- Ensure animation completes before script continues execution

## Impact
- **Affected specs**: `logo-animation` (new capability)
- **Affected code**: 
  - `gitconfig.sh:110-131` (logo function - MODIFIED)
  - `gitconfig.sh:458` (welcome function call - unchanged signature)
- **User benefit**: More engaging and professional welcome experience
- **Breaking changes**: None (function signature unchanged, only internal behavior)
- **Performance**: Minimal overhead (~0.8 seconds total animation time for 16 lines)

