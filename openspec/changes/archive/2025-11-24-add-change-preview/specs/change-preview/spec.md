## ADDED Requirements

### Requirement: Change Preview Display
The system SHALL display a formatted summary of all changes that will be made before applying them, showing file operations and configuration values. This preview is **distinct from** the generic `welcome()` function: it shows **specific values** (email, name) and **actual file states** (create vs. modify) after user information has been collected.

#### Scenario: Preview shown after user info collection
- **WHEN** the script completes `collect_user_info()` successfully (after line 2338 in main())
- **THEN** `show_changes_summary()` is called to display the preview
- **AND** the preview is shown before any file modifications or key generation occurs
- **AND** the preview uses the actual collected values (`$USER_EMAIL`, `$USER_NAME`) rather than generic descriptions

#### Scenario: Preview shows SSH key file status
- **WHEN** the preview is displayed
- **THEN** it shows `[CREAR]` for `~/.ssh/id_ed25519` and `~/.ssh/id_ed25519.pub` if they don't exist
- **OR** it shows `[SOBRESCRIBIR]` if the files already exist

#### Scenario: Preview shows Git config file status
- **WHEN** the preview is displayed
- **THEN** it shows `[CREAR]` for `~/.gitconfig` if it doesn't exist
- **OR** it shows `[MODIFICAR]` with backup note if `~/.gitconfig` exists

#### Scenario: Preview shows GPG key generation status
- **WHEN** GPG key generation is planned (`GENERATE_GPG` is true)
- **THEN** the preview displays `[CREAR] Llave GPG (4096-bit RSA)`
- **WHEN** GPG key generation is not planned
- **THEN** the preview does not show GPG key creation

#### Scenario: Preview shows shell config modifications
- **WHEN** the preview is displayed
- **THEN** it shows `[MODIFICAR] ~/.bashrc` with note about SSH agent configuration
- **AND** it shows `[MODIFICAR] ~/.zshrc` if `~/.zshrc` exists

#### Scenario: Preview shows Git configuration values
- **WHEN** the preview is displayed
- **THEN** it shows the Git configuration section with:
  - User name (`$USER_NAME`)
  - User email (`$USER_EMAIL`)
  - Default branch (main)
  - GPG signing status (`$GENERATE_GPG`)
  - Credential helper (manager/secretservice)

### Requirement: User Confirmation Before Changes
The system SHALL require user confirmation after displaying the preview before proceeding with any changes.

#### Scenario: Confirmation prompt after preview
- **WHEN** the preview is displayed
- **THEN** the system prompts: "¿Confirmas que deseas aplicar estos cambios?" with default "y"
- **AND** waits for user response using `ask_yes_no()`

#### Scenario: User confirms changes
- **WHEN** the user answers "yes" to the confirmation prompt
- **THEN** the script proceeds with key generation and file modifications
- **AND** execution continues normally

#### Scenario: User cancels changes
- **WHEN** the user answers "no" to the confirmation prompt
- **THEN** a warning message is displayed: "Operación cancelada por el usuario"
- **AND** the script exits with code 0 (clean exit)

### Requirement: Non-Interactive Mode Support
The system SHALL handle preview display appropriately in non-interactive mode, either skipping it or auto-confirming.

#### Scenario: Preview in non-interactive mode
- **WHEN** `INTERACTIVE_MODE` is `false`
- **THEN** the preview may be skipped or auto-confirmed based on implementation
- **AND** the script does not wait for user input

#### Scenario: Preview with auto-yes mode
- **WHEN** `AUTO_YES` is `true`
- **THEN** the preview is displayed (if shown)
- **AND** the confirmation prompt automatically returns "yes" without waiting

### Requirement: Preview Visual Format
The system SHALL display the preview with clear visual formatting using colors, borders, and structured sections.

#### Scenario: Preview header format
- **WHEN** the preview is displayed
- **THEN** it shows a formatted header with title "📋 RESUMEN DE CAMBIOS A REALIZAR"
- **AND** uses box-drawing characters for visual separation

#### Scenario: Preview section organization
- **WHEN** the preview is displayed
- **THEN** it organizes information into sections:
  - Files that will be created/modified (with color-coded status indicators)
  - Git configuration values
- **AND** each section is clearly separated

#### Scenario: Preview color coding
- **WHEN** the preview is displayed
- **THEN** it uses color codes:
  - Green (`CGR`) for `[CREAR]` operations
  - Yellow (`CYE`) for `[SOBRESCRIBIR]` or `[MODIFICAR]` operations
  - Cyan (`CCY`) for section headers
  - Blue (`CBL`) for configuration labels
  - Dim (`DIM`) for additional notes

