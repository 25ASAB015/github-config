# Change: Add Visual Progress Bar System

## Why
The current script uses simple spinners that show individual task progress but fail to communicate overall workflow progress. Users cannot answer "Where am I in the process?" or "How much longer until completion?" This creates uncertainty and a poor user experience, especially during long-running operations.

## What Changes
- Add a comprehensive progress bar system that displays:
  - Current step number and total steps
  - Percentage completion
  - Visual progress bar with filled/empty indicators
  - Step name/description
- Define workflow stages (9 total: dependency check, directory setup, backup, info collection, SSH generation, GPG generation, Git config, SSH agent, summary)
- Replace or augment existing `show_spinner()` calls with progress-aware alternatives
- Maintain visual consistency with current color scheme

## Impact
- **Affected specs**: `progress-tracking` (new capability)
- **Affected code**: 
  - `gitconfig.sh:124-145` (show_spinner function)
  - `gitconfig.sh:1666-1720` (main function workflow)
  - Multiple function calls throughout that use spinners
- **User benefit**: Clear visibility into process completion, reduced uncertainty, professional UX
- **Breaking changes**: None (additive enhancement)

