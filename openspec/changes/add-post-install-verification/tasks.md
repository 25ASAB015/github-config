## 1. Implementation
- [ ] 1.1 Create `run_verification_suite()` function in `scripts/finalize.sh`
- [ ] 1.2 Implement Git config verification (user.name, user.email)
- [ ] 1.3 Implement SSH key file verification (id_ed25519, id_ed25519.pub)
- [ ] 1.4 Implement SSH agent verification (ssh-add -l)
- [ ] 1.5 Implement GPG key verification (conditional, only if GPG_KEY_ID is set)
- [ ] 1.6 Implement GitHub CLI verification (command exists + auth status)
- [ ] 1.7 Implement Git Credential Manager verification (command exists)
- [ ] 1.8 Implement GitHub SSH connectivity test (timeout 5 ssh -T git@github.com)
- [ ] 1.9 Add formatted header with box-drawing characters
- [ ] 1.10 Add test result display with color-coded pass/fail/warning indicators
- [ ] 1.11 Add summary section showing total tests, passed, and failed counts
- [ ] 1.12 Add return code logic (0 if all critical tests pass, 1 if any fail)
- [ ] 1.13 Integrate verification suite call into main workflow (after `show_final_instructions()`)

## 2. Testing
- [ ] 2.1 Test verification suite with successful installation
- [ ] 2.2 Test verification suite with missing SSH keys
- [ ] 2.3 Test verification suite with missing GPG key (when GPG was not generated)
- [ ] 2.4 Test verification suite with GitHub CLI not authenticated
- [ ] 2.5 Test verification suite with no network connectivity (GitHub test)
- [ ] 2.6 Verify color coding works correctly
- [ ] 2.7 Verify return codes are correct (0 for success, 1 for failure)

## 3. Documentation
- [ ] 3.1 Add function documentation with dotbare-style headers
- [ ] 3.2 Document which tests are critical (fail) vs optional (warning)
- [ ] 3.3 Update README.md if needed to mention verification suite

