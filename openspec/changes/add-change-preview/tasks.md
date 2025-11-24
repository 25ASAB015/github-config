## 1. Implementation
- [ ] 1.1 Create `show_changes_summary()` function with formatted output
- [ ] 1.2 Implement file status detection (create/modify/overwrite) for SSH keys
- [ ] 1.3 Implement file status detection for `.gitconfig`
- [ ] 1.4 Implement GPG key generation status display
- [ ] 1.5 Implement shell config files detection (`.bashrc`, `.zshrc`)
- [ ] 1.6 Add Git configuration values display section
- [ ] 1.7 Integrate confirmation prompt using `ask_yes_no()`
- [ ] 1.8 Add non-interactive mode support (skip preview or auto-confirm)

## 2. Integration
- [ ] 2.1 Call `show_changes_summary()` in `main()` after `collect_user_info()` completes
- [ ] 2.2 Ensure preview runs before any file modifications or key generation
- [ ] 2.3 Handle user cancellation gracefully (exit cleanly if user declines)

## 3. Testing
- [ ] 3.1 Test preview display with new installation (no existing files)
- [ ] 3.2 Test preview display with existing `.gitconfig` file
- [ ] 3.3 Test preview display with existing SSH keys
- [ ] 3.4 Test preview display with GPG generation enabled/disabled
- [ ] 3.5 Test preview in non-interactive mode (should skip or auto-confirm)
- [ ] 3.6 Test user cancellation flow
- [ ] 3.7 Verify preview accuracy matches actual changes made

## 4. Validation
- [ ] 4.1 Ensure preview output is readable in 80-column terminals
- [ ] 4.2 Verify color coding is consistent with existing script style
- [ ] 4.3 Confirm all file paths are correctly detected and displayed
- [ ] 4.4 Validate that preview information matches actual execution

