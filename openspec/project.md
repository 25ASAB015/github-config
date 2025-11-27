# Project Context

## Purpose

**github-config** is an interactive Bash script (`gitconfig.sh`) that automates the professional configuration of Git and GitHub on Linux systems. It streamlines the developer onboarding process by:

- Generating and registering SSH keys (Ed25519) for GitHub authentication
- Generating GPG keys for commit signing
- Creating a professional `.gitconfig` with sensible defaults and useful aliases
- Installing and authenticating GitHub CLI (`gh`) and GitKraken CLI (`gk`)
- Configuring Git Credential Manager for secure credential storage
- Setting up `ssh-agent` integration with automatic key loading

The goal is to provide a single-command solution for developers to have a fully configured, secure Git environment ready for GitHub workflows.

## Tech Stack

- **Language:** Bash (POSIX-compatible where possible, uses Bash 4+ features like associative arrays)
- **Target OS:** Linux (Debian/Ubuntu, Arch, Fedora, and derivatives)
- **External Tools:**
  - `git` – Version control
  - `ssh-keygen` – SSH key generation (Ed25519)
  - `gpg` – GPG key generation and management
  - `gh` – GitHub CLI for key uploads and authentication
  - `gk` – GitKraken CLI (optional)
  - `git-credential-manager` – Secure credential storage
  - Clipboard tools: `xsel`, `xclip`, or `wl-copy` (Wayland)
- **Package Managers:** `apt`, `pacman`, `dnf` (auto-detected)

## Project Conventions

### Code Style

- **Formatting:** 4-space indentation (or tabs converted to 4 spaces for heredocs)
- **Naming:**
  - Functions: `snake_case` (e.g., `generate_ssh_key`, `show_progress_bar`)
  - Global variables: `UPPER_SNAKE_CASE` (e.g., `INTERACTIVE_MODE`, `GPG_KEY_ID`)
  - Local variables: `lower_snake_case` with `local` keyword
- **Comments:**
  - Section headers use `# ===...===` blocks
  - Functions have brief inline comments explaining purpose
  - Complex logic annotated inline
- **Output:**
  - Use semantic color tokens via `$(c token)` helper (e.g., `$(c success)`, `$(c error)`)
  - Always reset colors with `$(cr)`
  - Use emoji prefixes for message types: ✅ success, ❌ error, ⚠️ warning, ℹ️ info

### Architecture Patterns

- **Single-file script:** All functionality in `gitconfig.sh` for easy distribution
- **Modular functions:** Each task is a discrete function (e.g., `generate_ssh_key`, `configure_git`)
- **Workflow steps:** Defined in `WORKFLOW_STEPS` associative array for progress tracking
- **Graceful degradation:**
  - Color system falls back to empty strings if `tput` unavailable
  - Unicode progress bar falls back to ASCII (`#`/`-`) when needed
  - Missing optional tools don't break the script
- **Dual-mode operation:**
  - Interactive (default): prompts user for input
  - Non-interactive (`--non-interactive`): uses environment variables, suitable for CI/automation
- **Change preview:** Shows summary of all changes before applying them

### Testing Strategy

- **Manual testing:** Run the script in various Linux environments (Ubuntu, Arch, Fedora)
- **Non-interactive mode:** Use `--non-interactive` flag with `USER_EMAIL` and `USER_NAME` for automated testing
- **Debug mode:** Set `DEBUG=true` to enable verbose logging
- **Log file:** All operations logged to `~/.github-keys-setup/setup.log` for troubleshooting
- **Idempotency:** Script can be re-run safely; existing keys backed up, configs regenerated

### Git Workflow

- **Default branch:** `master`
- **Commit conventions:** Conventional Commits encouraged (the script generates a `.gitmessage` template)
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `revert`
- **Branching:** Feature branches merged via pull requests
- **Signing:** GPG commit signing enabled when keys are configured

## Domain Context

Key concepts AI assistants should understand:

- **SSH vs GPG keys:** SSH keys authenticate to GitHub; GPG keys sign commits to verify authorship
- **Ed25519:** Modern elliptic-curve algorithm, preferred over RSA for SSH keys
- **Git Credential Manager (GCM):** Cross-platform credential helper that stores tokens securely
- **ssh-agent:** Background process that caches SSH keys to avoid repeated passphrase entry
- **GitHub CLI (`gh`):** Official CLI for GitHub operations including key uploads
- **`.gitconfig`:** User-level Git configuration file at `~/.gitconfig`
- **Semantic colors:** The script uses a token-based color system (success/error/warning/info/primary/secondary/accent) for consistent, accessible terminal output

## Important Constraints

- **No root execution:** Script must NOT run as root (checks and exits if `id -u` is 0)
- **User-space only:** Only modifies files in user's home directory (`~/.ssh`, `~/.gitconfig`, `~/.gnupg`, `~/.bashrc`, `~/.zshrc`)
- **Accessibility:** WCAG 2.1 compliant color contrast for terminal output; graceful fallback for non-color terminals
- **License:** GPL-3.0
- **Backup policy:** Always create timestamped backups before modifying existing keys or configs
- **No secrets in repo:** Credentials and keys are generated locally, never committed

## External Dependencies

- **GitHub:** Primary target platform for SSH/GPG key registration and authentication
- **Package registries:** `apt`, `pacman`, `dnf` repos for installing dependencies
- **GitHub CLI releases:** `gh` installed from official GitHub releases or package managers
- **Git Credential Manager releases:** Installed from Microsoft's GitHub releases
- **Clipboard:** Relies on system clipboard tools for copying keys (optional but helpful)
