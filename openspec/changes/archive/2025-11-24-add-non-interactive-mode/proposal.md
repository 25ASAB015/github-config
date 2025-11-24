# Change: Add Non-Interactive Mode Support

## Why
The script currently always requires user interaction for prompts and confirmations, which prevents automation, CI/CD integration, and automated testing. Users cannot run the script in environments where interaction is not possible or desired.

## What Changes
- Add `INTERACTIVE_MODE` and `AUTO_YES` environment variables and command-line flags
- Modify `ask_yes_no()` function to support non-interactive mode
- Add command-line argument parsing (`--non-interactive`, `--auto-yes`, `--help`)
- Support both environment variables and CLI flags for flexibility
- Log auto-answered prompts for auditability
- Maintain backward compatibility (default remains interactive)

## Impact
- **Affected specs**: `automation` (new capability)
- **Affected code**: 
  - `gitconfig.sh:471-501` (ask_yes_no function)
  - `gitconfig.sh:1733+` (main function - add argument parsing)
  - All calls to `ask_yes_no()` throughout the script
- **User benefit**: Enables automation, CI/CD pipelines, testing, and unattended execution
- **Breaking changes**: None (additive enhancement, defaults to interactive)

