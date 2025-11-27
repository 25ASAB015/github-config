#!/usr/bin/env bash
#==============================================================================
#                              DEPENDENCIES
#==============================================================================
# @file dependencies.sh
# @brief Dependency checking and installation
# @description
#   Provides functions for checking and installing required dependencies
#   like git, ssh, gpg, and git-credential-manager.
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
[[ -n "${_DEPENDENCIES_SOURCED:-}" ]] && return 0
declare -r _DEPENDENCIES_SOURCED=1

#==============================================================================
# DEPENDENCY CHECKING
#==============================================================================

# @description Check if all required dependencies are installed
# @return 0 if all dependencies met, 1 otherwise
# @example
#   if ! check_dependencies; then
#       exit 1
#   fi
check_dependencies() {
    local missing_deps=()
    local required_deps=("git" "ssh" "ssh-keygen")
    
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Faltan las siguientes dependencias: ${missing_deps[*]}"
        
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            if ask_yes_no "¿Deseas intentar instalar las dependencias automáticamente?"; then
                local os_type
                os_type=$(detect_os)
                
                for dep in "${missing_deps[@]}"; do
                    if ! auto_install_dependencies "$os_type" "$dep"; then
                        error "No se pudo instalar: $dep"
                        return 1
                    fi
                done
            else
                return 1
            fi
        else
            return 1
        fi
    fi
    
    success "Todas las dependencias requeridas están instaladas"
    
    # Check optional dependencies
    check_optional_dependencies
    
    echo ""
    return 0
}

# @description Check optional dependencies and inform user
# @return 0 always
# @example
#   check_optional_dependencies
check_optional_dependencies() {
    local optional_deps=("gpg" "gh" "git-credential-manager")
    
    for dep in "${optional_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            printf "  $(c bold)$(c success)✓$(cr) $(c bold)%s$(cr)\n" "$dep"
        else
            printf "  $(c muted)○$(cr) $(c bold)%s$(cr) $(c muted)(no instalado)$(cr)\n" "$dep"
        fi
    done
}

#==============================================================================
# AUTOMATIC INSTALLATION
#==============================================================================

# @description Attempt to install a dependency automatically
# @param $1 os_type - Operating system type
# @param $2 package - Package name to install
# @return 0 on success, 1 on failure
# @example
#   auto_install_dependencies "arch" "git"
auto_install_dependencies() {
    local os_type="$1"
    local package="$2"
    
    info "Intentando instalar $package..."
    
    case "$os_type" in
        arch|manjaro|endeavouros|garuda)
            if command -v pacman &> /dev/null; then
                if sudo pacman -S --noconfirm "$package" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi
            ;;
        ubuntu|debian|linuxmint|pop)
            if command -v apt &> /dev/null; then
                if sudo apt update -qq && sudo apt install -y "$package" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi
            ;;
        fedora|rhel|centos|rocky|alma)
            if command -v dnf &> /dev/null; then
                if sudo dnf install -y "$package" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            elif command -v yum &> /dev/null; then
                if sudo yum install -y "$package" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi
            ;;
        darwin)
            if command -v brew &> /dev/null; then
                if brew install "$package" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi
            ;;
    esac
    
    error "No se pudo instalar $package automáticamente"
    return 1
}

#==============================================================================
# MANUAL INSTALLATION INSTRUCTIONS
#==============================================================================

# @description Show manual installation instructions for GitHub CLI
# @param $1 os_type - Operating system type
# @example
#   show_manual_gh_install_instructions "arch"
show_manual_gh_install_instructions() {
    local os_type="$1"
    echo ""
    printf "%b\n" "$(c bold)$(c accent)📦 INSTRUCCIONES DE INSTALACIÓN MANUAL:$(cr)"
    echo ""
    
    case "$os_type" in
        arch|manjaro|endeavouros|garuda)
            printf "%b\n" "$(c warning)Arch Linux / Manjaro:$(cr)"
            echo "  $(c primary)sudo pacman -S github-cli$(cr)"
            echo "  $(c muted)o desde AUR:$(cr) $(c primary)yay -S github-cli$(cr)"
            ;;
        ubuntu|debian|linuxmint|pop)
            printf "%b\n" "$(c warning)Ubuntu / Debian:$(cr)"
            echo "  $(c primary)sudo apt update && sudo apt install gh$(cr)"
            ;;
        fedora|rhel|centos|rocky|alma)
            printf "%b\n" "$(c warning)Fedora / RHEL / CentOS:$(cr)"
            echo "  $(c primary)sudo dnf install gh$(cr)"
            ;;
        darwin)
            printf "%b\n" "$(c warning)macOS:$(cr)"
            echo "  $(c primary)brew install gh$(cr)"
            ;;
        *)
            printf "%b\n" "$(c warning)Instalación genérica:$(cr)"
            echo "  Visita: $(c primary)https://cli.github.com$(cr)"
            ;;
    esac
    
    echo ""
    info "Después de instalar, vuelve a ejecutar este script con $(c primary)--auto-upload$(cr)"
    echo ""
}
