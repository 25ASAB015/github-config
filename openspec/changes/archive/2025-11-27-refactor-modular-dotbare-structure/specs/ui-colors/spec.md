# Capability: UI Colors (Delta)

## MODIFIED Requirements

### Requirement: Semantic Color Palette Definition

The system SHALL define a semantic color palette using an associative array, **now located in a dedicated module file**.

#### Scenario: Module location
- **GIVEN** the refactored codebase
- **WHEN** accessing color functionality
- **THEN** the `COLORS` associative array SHALL be defined in `scripts/core/colors.sh`
- **AND** the file SHALL follow dotbare-style documentation headers

#### Scenario: Module sourcing
- **GIVEN** any module that uses colors
- **WHEN** the main entry point initializes
- **THEN** `scripts/core/colors.sh` SHALL be sourced before any color-using modules
- **AND** `${mydir}` SHALL be used for the source path

---

### Requirement: Color Access Helper Functions

The system SHALL provide helper functions for safe color access, **now located in a dedicated module file**.

#### Scenario: Helper function location
- **GIVEN** the refactored codebase
- **WHEN** calling `c()` or `cr()` functions
- **THEN** they SHALL be defined in `scripts/core/colors.sh`
- **AND** both functions SHALL be documented with dotbare-style function headers

---

## Notes

- All existing behavior preserved exactly
- Only file location changes, not functionality
- Cross-references updated for new module structure
