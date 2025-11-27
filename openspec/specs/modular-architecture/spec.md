# modular-architecture Specification

## Purpose
TBD - created by archiving change refactor-modular-dotbare-structure. Update Purpose after archive.
## Requirements
### Requirement: Directory Structure Convention

The system SHALL organize source code into a hierarchical module structure with clear separation of concerns.

#### Scenario: Root level organization
- **GIVEN** the project root directory
- **WHEN** listing directory contents
- **THEN** there SHALL be a `scripts/` directory for executable modules
- **AND** there SHALL be a `config/` directory for configuration and templates
- **AND** the main entry point SHALL be `gitconfig.sh` at root level

#### Scenario: Core utilities separation
- **GIVEN** the `scripts/` directory
- **WHEN** organizing core utility functions
- **THEN** there SHALL be a `scripts/core/` subdirectory
- **AND** it SHALL contain `colors.sh`, `ui.sh`, `logger.sh`, `validation.sh`, `common.sh`
- **AND** each file SHALL have a single focused responsibility

#### Scenario: Feature modules organization
- **GIVEN** the `scripts/` directory
- **WHEN** organizing feature-specific functions
- **THEN** there SHALL be separate files: `dependencies.sh`, `ssh.sh`, `gpg.sh`, `git-config.sh`, `github.sh`, `finalize.sh`
- **AND** each file SHALL contain related functions grouped by domain

#### Scenario: Configuration separation
- **GIVEN** the `config/` directory
- **WHEN** organizing configuration files
- **THEN** there SHALL be a `defaults.sh` for global variables
- **AND** there SHALL be a `templates/` subdirectory for file templates

---

### Requirement: dotbare-Style Documentation Headers

Every script file SHALL include a standardized documentation header following the dotbare format.

#### Scenario: File header structure
- **GIVEN** any `.sh` file in the project
- **WHEN** examining the file header
- **THEN** it SHALL start with `#!/usr/bin/env bash`
- **AND** it SHALL include a brief one-line description
- **AND** it SHALL include a `@params` section

#### Scenario: Globals documentation
- **GIVEN** a script file header
- **WHEN** the script uses or modifies global variables
- **THEN** the header SHALL list each global variable under `# Globals`
- **AND** each variable SHALL have a brief description

#### Scenario: Arguments documentation
- **GIVEN** a script file header
- **WHEN** the script accepts command-line arguments or flags
- **THEN** the header SHALL list each argument under `# Arguments`
- **AND** each argument SHALL specify its format (e.g., `-h|--help`)

#### Scenario: Returns documentation
- **GIVEN** a script file header
- **WHEN** the script has defined exit codes
- **THEN** the header SHALL list exit codes under `# Returns`
- **AND** `0` SHALL indicate success
- **AND** non-zero values SHALL indicate specific error conditions

---

### Requirement: Function Documentation Standard

Every function SHALL include inline documentation above its definition.

#### Scenario: Function header block format
- **GIVEN** a function definition
- **WHEN** documenting the function
- **THEN** it SHALL have a `#######################################` delimiter
- **AND** it SHALL include a brief description
- **AND** it SHALL list `Globals:`, `Arguments:`, `Outputs:`, and `Returns:` as applicable

#### Scenario: Arguments documentation
- **GIVEN** a function that accepts parameters
- **WHEN** documenting arguments
- **THEN** each positional parameter SHALL be documented as `$1`, `$2`, etc.
- **AND** each SHALL have a description of its purpose

---

### Requirement: Module Loading Order

The main entry point SHALL source modules in a specific order to ensure dependencies are satisfied.

#### Scenario: Configuration first
- **GIVEN** the main entry point script
- **WHEN** initializing the script
- **THEN** `config/defaults.sh` SHALL be sourced first
- **AND** all global variables SHALL be available before any functions are loaded

#### Scenario: Core utilities before features
- **GIVEN** the main entry point script
- **WHEN** sourcing utility modules
- **THEN** `scripts/core/` modules SHALL be sourced before `scripts/` feature modules
- **AND** `colors.sh` SHALL be sourced before modules that use colors

#### Scenario: Core internal order
- **GIVEN** the `scripts/core/` modules
- **WHEN** determining load order
- **THEN** the order SHALL be: `colors.sh`, `logger.sh`, `validation.sh`, `ui.sh`, `common.sh`

---

### Requirement: Global Variable Management

All global variables SHALL be centralized in a single configuration file.

#### Scenario: Single source of truth
- **GIVEN** the project codebase
- **WHEN** a global variable is needed
- **THEN** it SHALL be declared in `config/defaults.sh`
- **AND** feature modules SHALL NOT declare new global variables

#### Scenario: Variable documentation
- **GIVEN** `config/defaults.sh`
- **WHEN** declaring a global variable
- **THEN** it SHALL have an inline comment describing its purpose
- **AND** variables SHALL be organized by category (directories, behavior, state, user data)

#### Scenario: Local variable scoping
- **GIVEN** any function in any module
- **WHEN** declaring a variable inside the function
- **THEN** the `local` keyword SHALL be used
- **AND** only existing globals from `defaults.sh` may be modified without `local`

---

### Requirement: Template File System

Externalized templates SHALL replace inline heredocs for generated configuration files.

#### Scenario: Template file location
- **GIVEN** the need to generate `.gitconfig`
- **WHEN** the script processes the template
- **THEN** it SHALL read from `config/templates/gitconfig.template`
- **AND** the template file SHALL contain placeholder syntax

#### Scenario: Placeholder format
- **GIVEN** a template file
- **WHEN** defining substitution points
- **THEN** placeholders SHALL use `{{VARIABLE_NAME}}` format
- **AND** placeholder names SHALL match global variable names

#### Scenario: Template processing
- **GIVEN** a template with placeholders
- **WHEN** generating the output file
- **THEN** all `{{PLACEHOLDER}}` occurrences SHALL be replaced with actual values
- **AND** the output SHALL be written to the target location

---

### Requirement: Path Handling Convention

All module sourcing SHALL use relative paths from a detected base directory.

#### Scenario: Base directory detection
- **GIVEN** the main entry point script
- **WHEN** determining the script location
- **THEN** it SHALL set `mydir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- **AND** all sourcing SHALL use `${mydir}` as the base path

#### Scenario: Module sourcing syntax
- **GIVEN** any `source` statement
- **WHEN** loading a module
- **THEN** the path SHALL be `source "${mydir}/path/to/module.sh"`
- **AND** absolute paths SHALL NOT be hardcoded

---

### Requirement: Shebang Standardization

All Bash scripts SHALL use the portable shebang.

#### Scenario: Shebang format
- **GIVEN** any `.sh` file in the project
- **WHEN** examining the first line
- **THEN** it SHALL be `#!/usr/bin/env bash`
- **AND** `#!/bin/bash` SHALL NOT be used

---

