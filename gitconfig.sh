#!/usr/bin/env bash
#==============================================================================
#                              GITCONFIG
#==============================================================================
# @file gitconfig.sh
# @brief Professional Git & GitHub configuration script
# @description
#   Main entry point for the Crixus Git configuration tool. This script
#   orchestrates the setup of SSH keys, GPG keys, Git configuration, and
#   GitHub integration.
#
# @usage
#   ./gitconfig.sh [options]
#
# @options
#   --non-interactive    Run without user prompts
#   --auto-upload        Automatically upload keys to GitHub
#   --help, -h           Show help information
#
# Globals:
#   Defined in config/defaults.sh
#
# Arguments:
#   Various command-line options
#
# Returns:
#   0 - Success
#   1 - Failure
#   130 - Interrupted by user
#==============================================================================

set -euo pipefail

#==============================================================================
# SCRIPT LOCATION
#==============================================================================

# Determine script directory (resolves symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#==============================================================================
# SOURCE MODULES
#==============================================================================

# Source configuration defaults
source "${SCRIPT_DIR}/config/defaults.sh"

# Source core modules
source "${SCRIPT_DIR}/scripts/core/colors.sh"
source "${SCRIPT_DIR}/scripts/core/logger.sh"
source "${SCRIPT_DIR}/scripts/core/validation.sh"
source "${SCRIPT_DIR}/scripts/core/ui.sh"
source "${SCRIPT_DIR}/scripts/core/common.sh"

# Source feature modules
source "${SCRIPT_DIR}/scripts/dependencies.sh"
source "${SCRIPT_DIR}/scripts/ssh.sh"
source "${SCRIPT_DIR}/scripts/gpg.sh"
source "${SCRIPT_DIR}/scripts/git-config.sh"
source "${SCRIPT_DIR}/scripts/github.sh"
source "${SCRIPT_DIR}/scripts/finalize.sh"

#==============================================================================
# ARGUMENT PARSING
#==============================================================================

# @description Parse command-line arguments
# @param $@ All command-line arguments
# @example
#   parse_arguments "$@"
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --non-interactive)
                INTERACTIVE_MODE=false
                shift
                ;;
            --auto-upload)
                AUTO_UPLOAD_KEYS=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Opción desconocida: $1"
                echo "Usa --help para ver opciones disponibles"
                exit 1
                ;;
        esac
    done
}

#==============================================================================
# MAIN FUNCTION
#==============================================================================

# @description Main entry point for the script
# @param $@ All command-line arguments
main() {
    # Parse command-line arguments
    parse_arguments "$@"
    
    # Perform initial checks
    echo "[DEBUG] main() - Antes de initial_checks"
    initial_checks
    echo "[DEBUG] main() - Después de initial_checks"
    
    echo "[DEBUG] main() - Antes de welcome()"
    welcome
    echo "[DEBUG] main() - Después de welcome()"
    
    # Early GitHub CLI check if --auto-upload is active
    echo "[DEBUG] main() - Antes de check GitHub CLI"
    if [[ "$AUTO_UPLOAD_KEYS" == "true" ]]; then
        echo "[DEBUG] main() - AUTO_UPLOAD_KEYS es true, verificando GitHub CLI"
        if ! ensure_github_cli_ready "early"; then
            echo "[DEBUG] main() - GitHub CLI no está listo, saliendo"
            exit 1
        fi
        echo "[DEBUG] main() - GitHub CLI está listo"
    else
        echo "[DEBUG] main() - AUTO_UPLOAD_KEYS es false, saltando check GitHub CLI"
    fi
    
    # Create log file
    echo "[DEBUG] main() - Antes de crear archivo de log"
    mkdir -p "$(dirname "$LOG_FILE")"
    log "=== INICIO DE CONFIGURACIÓN DE GIT ==="
    echo "[DEBUG] main() - Después de crear archivo de log"
    
    # Initialize progress variables
    echo "[DEBUG] main() - Inicializando variables de progreso"
    TOTAL_STEPS=9
    CURRENT_STEP=0
    echo "[DEBUG] main() - TOTAL_STEPS=$TOTAL_STEPS, CURRENT_STEP=$CURRENT_STEP"
    
    # Step 1: Check dependencies
    echo "[DEBUG] main() - Antes de Step 1: Check dependencies"
    echo "[DEBUG] main() - CURRENT_STEP antes de incrementar: $CURRENT_STEP"
    set +e  # Temporarily disable exit on error for arithmetic
    ((CURRENT_STEP++))
    local step_increment_result=$?
    set -e  # Re-enable exit on error
    echo "[DEBUG] main() - Resultado de incremento: $step_increment_result"
    echo "[DEBUG] main() - CURRENT_STEP después de incrementar: $CURRENT_STEP"
    echo "[DEBUG] main() - Antes de show_progress_bar con CURRENT_STEP=$CURRENT_STEP, TOTAL_STEPS=$TOTAL_STEPS"
    echo "[DEBUG] main() - WORKFLOW_STEPS[$CURRENT_STEP]='${WORKFLOW_STEPS[$CURRENT_STEP]}'"
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    echo "[DEBUG] main() - Después de show_progress_bar"
    echo "[DEBUG] main() - Antes de llamar check_dependencies()"
    if ! check_dependencies; then
        echo "[DEBUG] main() - check_dependencies falló, saliendo"
        exit 1
    fi
    echo "[DEBUG] main() - check_dependencies completado exitosamente"
    
    # Step 2: Setup directories
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! setup_directories; then
        exit 1
    fi
    
    # Step 3: Backup existing keys
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    backup_existing_keys
    
    # Step 4: Collect user information
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! collect_user_info; then
        exit 1
    fi
    
    # Ask about GPG before preview to include in summary
    GENERATE_GPG="false"
    
    # Check for existing GPG key
    local existing_gpg_key_id=""
    if command -v gpg &> /dev/null; then
        existing_gpg_key_id=$(gpg --list-secret-keys --keyid-format=long "$USER_EMAIL" 2>/dev/null | grep 'sec' | head -n1 | sed 's/.*\/\([A-Z0-9]*\).*/\1/' || echo "")
    fi
    
    if [[ -n "$existing_gpg_key_id" ]]; then
        # Use existing GPG key
        GENERATE_GPG="true"
        GPG_KEY_ID="$existing_gpg_key_id"
        log "Llave GPG existente detectada: $GPG_KEY_ID"
    elif [[ "$INTERACTIVE_MODE" == "true" ]] && [[ "${AUTO_YES:-false}" != "true" ]]; then
        # Interactive mode: ask user
        if ask_yes_no "¿Deseas generar también una llave GPG para firmar commits?" "n"; then
            GENERATE_GPG="true"
        fi
    elif [[ "$INTERACTIVE_MODE" == "false" ]] || [[ "${AUTO_YES:-false}" == "true" ]]; then
        # Non-interactive or auto-yes: generate GPG by default
        GENERATE_GPG="true"
    fi
    
    # Show changes summary before applying
    if ! show_changes_summary; then
        exit 0
    fi
    
    # Step 5: Generate SSH key
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! generate_ssh_key; then
        exit 1
    fi
    
    # Step 6: Generate or use GPG key
    if [[ "$GENERATE_GPG" == "true" ]]; then
        ((CURRENT_STEP++))
        show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
        
        if [[ -n "$GPG_KEY_ID" ]]; then
            info "Usando llave GPG existente: $GPG_KEY_ID"
            success "Llave GPG configurada correctamente"
        else
            generate_gpg_key
        fi
    fi
    
    # Step 7: Configure Git
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! configure_git; then
        exit 1
    fi
    
    # Step 8: Create ssh-agent configuration
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    create_ssh_agent_script
    
    # Display and upload keys
    display_keys
    maybe_upload_keys
    
    # Save keys to files if requested
    if ask_yes_no "¿Deseas guardar las llaves en archivos para referencia futura?"; then
        save_keys_to_files
    fi
    
    # Test connectivity
    echo "[DEBUG] main() - Antes de test_github_connection()"
    test_github_connection
    echo "[DEBUG] main() - Después de test_github_connection()"
    
    # Step 9: Show final instructions
    echo "[DEBUG] main() - Antes de Step 9: Show final instructions"
    ((CURRENT_STEP++))
    echo "[DEBUG] main() - CURRENT_STEP incrementado a $CURRENT_STEP"
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    echo "[DEBUG] main() - Antes de show_final_instructions()"
    show_final_instructions
    echo "[DEBUG] main() - Después de show_final_instructions()"
    
    log "=== FIN DE SESIÓN EXITOSA ==="
    
    echo ""
    success "¡Script completado exitosamente!"
    info "Log guardado en: $LOG_FILE"
}

#==============================================================================
# SIGNAL HANDLING
#==============================================================================

# @description Clean up on script interruption
cleanup() {
    echo ""
    warning "Script interrumpido por el usuario"
    log "Script interrumpido por señal"
    exit 130
}

# Configure signal handlers
trap cleanup SIGINT SIGTERM

#==============================================================================
# ENTRY POINT
#==============================================================================

main "$@"
