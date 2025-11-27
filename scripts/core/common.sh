#!/usr/bin/env bash
#==============================================================================
#                              COMMON
#==============================================================================
# @file common.sh
# @brief Common utility functions
# @description
#   Provides general utility functions used across the application including
#   OS detection, clipboard operations, and initial checks.
#
# Globals:
#   Various from defaults.sh
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_COMMON_SOURCED:-}" ]] && return 0
declare -r _COMMON_SOURCED=1

#==============================================================================
# OS DETECTION
#==============================================================================

# @description Detect the current operating system and distribution
# @return OS identifier string (e.g., arch, ubuntu, darwin)
# @example
#   os=$(detect_os)
#   case "$os" in
#       arch) pacman -S package ;;
#       ubuntu) apt install package ;;
#   esac
detect_os() {
    local os_type
    os_type=$(uname -s)
    
    case "$os_type" in
        "Darwin")
            echo "darwin"
            ;;
        "Linux")
            # Check for common distributions
            if [[ -f /etc/os-release ]]; then
                # shellcheck source=/dev/null
                source /etc/os-release
                case "$ID" in
                    arch|manjaro|endeavouros|garuda)
                        echo "$ID"
                        ;;
                    ubuntu|debian|linuxmint|pop)
                        echo "$ID"
                        ;;
                    fedora|rhel|centos|rocky|alma)
                        echo "$ID"
                        ;;
                    *)
                        echo "linux"
                        ;;
                esac
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

#==============================================================================
# CLIPBOARD OPERATIONS
#==============================================================================

# @description Copy file contents to clipboard
# @param $1 file_path - Path to file to copy
# @return 0 on success, 1 on failure
# @example
#   copy_to_clipboard "$HOME/.ssh/id_ed25519.pub"
copy_to_clipboard() {
    local file_path="$1"
    local os_type
    os_type=$(detect_os)
    
    if [[ ! -f "$file_path" ]]; then
        error "Archivo no encontrado: $file_path"
        return 1
    fi
    
    case "$os_type" in
        darwin)
            if command -v pbcopy &> /dev/null; then
                cat "$file_path" | pbcopy
                success "Llave copiada al portapapeles"
                return 0
            fi
            ;;
        *)
            # Linux - try various clipboard tools
            if command -v xclip &> /dev/null; then
                cat "$file_path" | xclip -selection clipboard
                success "Llave copiada al portapapeles (xclip)"
                return 0
            elif command -v xsel &> /dev/null; then
                cat "$file_path" | xsel --clipboard --input
                success "Llave copiada al portapapeles (xsel)"
                return 0
            elif command -v wl-copy &> /dev/null; then
                cat "$file_path" | wl-copy
                success "Llave copiada al portapapeles (wl-copy)"
                return 0
            fi
            ;;
    esac
    
    warning "No se encontró herramienta de portapapeles"
    info "Instala xclip, xsel o wl-copy para copiar automáticamente"
    return 1
}

#==============================================================================
# INITIAL CHECKS
#==============================================================================

# @description Perform initial environment checks
# @return 0 on success, 1 on failure
# @example
#   if ! initial_checks; then
#       exit 1
#   fi
initial_checks() {
    # Check if running as root (not recommended)
    if [[ $EUID -eq 0 ]]; then
        warning "No se recomienda ejecutar este script como root"
        if ! ask_yes_no "¿Deseas continuar de todos modos?" "n"; then
            exit 1
        fi
    fi
    
    # Check for required directories
    if [[ ! -d "$HOME" ]]; then
        error "No se encontró el directorio HOME"
        return 1
    fi
    
    # Note: We no longer auto-detect terminal interactivity
    # Interactive mode is controlled explicitly via:
    # 1. --non-interactive flag (sets INTERACTIVE_MODE=false)
    # 2. INTERACTIVE_MODE environment variable
    # 3. Default is true (interactive)
    # This prevents false positives when running in terminals
    
    return 0
}

#==============================================================================
# DIRECTORY OPERATIONS
#==============================================================================

# @description Setup required directories for SSH and GPG
# @return 0 on success, 1 on failure
# @example
#   setup_directories
setup_directories() {
    local ssh_dir="$HOME/.ssh"
    local gnupg_dir="$HOME/.gnupg"
    
    # Create SSH directory
    if [[ ! -d "$ssh_dir" ]]; then
        info "Creando directorio SSH..."
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        success "Directorio SSH creado: $ssh_dir"
    fi
    
    # Create GPG directory
    if [[ ! -d "$gnupg_dir" ]]; then
        info "Creando directorio GPG..."
        mkdir -p "$gnupg_dir"
        chmod 700 "$gnupg_dir"
        success "Directorio GPG creado: $gnupg_dir"
    fi
    
    return 0
}

#==============================================================================
# BACKUP OPERATIONS
#==============================================================================

# @description Backup existing SSH keys
# @return 0 always
# @example
#   backup_existing_keys
backup_existing_keys() {
    local ssh_dir="$HOME/.ssh"
    local backup_dir="$ssh_dir/backup-$(date +%Y%m%d_%H%M%S)"
    local has_keys=false
    
    # Check for existing keys
    for key_file in "$ssh_dir"/id_*; do
        if [[ -f "$key_file" ]]; then
            has_keys=true
            break
        fi
    done
    
    if [[ "$has_keys" == "true" ]]; then
        info "Se encontraron llaves SSH existentes"
        
        if ask_yes_no "¿Deseas hacer backup de las llaves existentes?"; then
            mkdir -p "$backup_dir"
            
            for key_file in "$ssh_dir"/id_*; do
                if [[ -f "$key_file" ]]; then
                    cp "$key_file" "$backup_dir/"
                    log "Backed up: $key_file"
                fi
            done
            
            success "Backup creado en: $backup_dir"
        fi
    fi
    
    return 0
}
