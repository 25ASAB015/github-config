# Capability: Logo Animation (Delta)

## MODIFIED Requirements

### Requirement: Animated Logo Display

The system SHALL display an animated ASCII art logo, **now located in the UI module**.

#### Scenario: Logo function location
- **GIVEN** the refactored codebase
- **WHEN** displaying the logo
- **THEN** `logo()` SHALL be defined in `scripts/core/ui.sh`
- **AND** the function SHALL be documented with dotbare-style headers

#### Scenario: Logo usage
- **GIVEN** the refactored codebase
- **WHEN** the welcome function calls logo
- **THEN** `welcome()` SHALL also be in `scripts/core/ui.sh`
- **AND** both functions SHALL share the same module

---

## Notes

- All existing behavior preserved exactly
- Only file location changes, not functionality
- Logo and welcome grouped in UI module
