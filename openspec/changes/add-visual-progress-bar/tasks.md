# Implementation Tasks

## 1. Core Progress Bar Function
- [ ] 1.1 Implement `show_progress_bar()` function with parameters: current, total, step_name
- [ ] 1.2 Calculate percentage and visual bar dimensions (width=50)
- [ ] 1.3 Render filled blocks (█) and empty blocks (░) with appropriate colors
- [ ] 1.4 Add carriage return logic for in-place updates
- [ ] 1.5 Handle final step (print newline when current == total)

## 2. Workflow Stage Definition
- [ ] 2.1 Define `WORKFLOW_STEPS` associative array with 9 named stages
- [ ] 2.2 Map stage IDs (1-9) to descriptive names
- [ ] 2.3 Ensure step names are concise (fit within terminal width)

## 3. Integration with Main Workflow
- [ ] 3.1 Add `TOTAL_STEPS=9` and `CURRENT_STEP=0` variables in main()
- [ ] 3.2 Insert `((CURRENT_STEP++)); show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"` before each major function call
- [ ] 3.3 Test progress bar updates at each step
- [ ] 3.4 Verify visual alignment and color consistency

## 4. Backward Compatibility
- [ ] 4.1 Preserve existing `show_spinner()` for sub-tasks within stages
- [ ] 4.2 Ensure progress bar doesn't conflict with spinner output
- [ ] 4.3 Test that error messages display correctly during progress updates

## 5. Validation & Testing
- [ ] 5.1 Test on various terminal widths (80, 120, 160 columns)
- [ ] 5.2 Verify progress bar in non-interactive mode (if implemented)
- [ ] 5.3 Confirm color codes render correctly in different terminal emulators
- [ ] 5.4 Test error handling (e.g., division by zero if total=0)

