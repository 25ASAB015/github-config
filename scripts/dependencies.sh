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
    
    # Show required dependencies list
    info "Dependencias requeridas:"
    for dep in "${required_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            printf "  $(c bold)$(c success)✓$(cr) $(c bold)%s$(cr)\n" "$dep"
        else
            printf "  $(c error)✗$(cr) $(c bold)%s$(cr) $(c error)(no encontrado)$(cr)\n" "$dep"
        fi
    done
    
    # Check optional dependencies (without header since it's part of required check)
    check_optional_dependencies "true"
    
    echo ""
    return 0
}

# @description Check optional dependencies and inform user
# @param $1 no_header - If "true", don't show header (default: false, shows header)
# @return 0 always
# @example
#   check_optional_dependencies          # Shows header
#   check_optional_dependencies "true"    # No header
check_optional_dependencies() {
    local no_header="${1:-false}"
    local optional_deps=("gpg" "gh" "git-credential-manager")
    local missing_optional=()
    local has_clipboard=false
    local clipboard_status="✓"
    
    if [[ "$no_header" != "true" ]]; then
        info "Dependencias opcionales:"
    fi
    
    for dep in "${optional_deps[@]}"; do
        local found=false
        if [[ "$dep" == "git-credential-manager" ]]; then
            # Algunos paquetes instalan el binario como git-credential-manager-core
            if command -v git-credential-manager &> /dev/null || command -v git-credential-manager-core &> /dev/null; then
                found=true
            fi
        else
            if command -v "$dep" &> /dev/null; then
                found=true
            fi
        fi

        if [[ "$found" == true ]]; then
            printf "  $(c bold)$(c success)✓$(cr) $(c bold)%s$(cr)\n" "$dep"
        else
            printf "  $(c muted)○$(cr) $(c bold)%s$(cr) $(c muted)(no instalado)$(cr)\n" "$dep"
            missing_optional+=("$dep")
        fi
    done

    # Detectar herramienta de portapapeles (cualquiera de xclip/xsel/wl-copy)
    if command -v wl-copy &> /dev/null || command -v xclip &> /dev/null || command -v xsel &> /dev/null; then
        has_clipboard=true
    else
        clipboard_status="○ (no instalado)"
    fi

    # Mostrar estado de portapapeles
    printf "  $(c bold)%s$(cr) $(c bold)Clipboard (xclip/xsel/wl-copy)$(cr)\n" "${has_clipboard:+$(c success)✓$(cr):-$(c muted)○$(cr)}"

    # Ofrecer instalación interactiva de opcionales cuando falten
    if [[ "$INTERACTIVE_MODE" == "true" ]] && [[ ${#missing_optional[@]} -gt 0 ]]; then
        local os_type
        os_type=$(detect_os)

        for dep in "${missing_optional[@]}"; do
            # git-credential-manager y gh son críticos para la experiencia GitHub
            local default_answer="y"
            if ask_yes_no "No se encontró '$dep'. ¿Deseas instalarlo automáticamente?" "$default_answer"; then
                if auto_install_dependencies "$os_type" "$dep"; then
                    success "$dep instalado correctamente"
                else
                    warning "No se pudo instalar '$dep' automáticamente"
                fi
            fi
        done
    fi

    # Ofrecer instalar herramientas de portapapeles si no hay ninguna
    if [[ "$INTERACTIVE_MODE" == "true" ]] && [[ "$has_clipboard" != true ]]; then
        local os_type
        os_type=$(detect_os)
        local clipboard_pkgs=()

        case "$os_type" in
            arch|manjaro|endeavouros|garuda)
                clipboard_pkgs=("wl-clipboard" "xclip")
                ;;
            ubuntu|debian|linuxmint|pop)
                clipboard_pkgs=("wl-clipboard" "xclip")
                ;;
            fedora|rhel|centos|rocky|alma)
                clipboard_pkgs=("wl-clipboard" "xclip")
                ;;
            darwin)
                # pbcopy ya viene instalado
                clipboard_pkgs=()
                ;;
            *)
                clipboard_pkgs=("xclip")
                ;;
        esac

        if [[ ${#clipboard_pkgs[@]} -gt 0 ]] && ask_yes_no "No se encontró herramienta de portapapeles. ¿Deseas instalar ${clipboard_pkgs[*]} ahora?" "y"; then
            for pkg in "${clipboard_pkgs[@]}"; do
                if ! auto_install_dependencies "$os_type" "$pkg"; then
                    warning "No se pudo instalar '$pkg' automáticamente"
                fi
            done
        fi
    fi
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
    local pkg_to_install="$package"
    
    # Map package names per OS when repos use different identifiers
    case "$os_type" in
        arch|manjaro|endeavouros|garuda)
            case "$package" in
                git-credential-manager)
                    pkg_to_install="git-credential-manager-bin"
                    ;;
                gh)
                    pkg_to_install="github-cli"
                    ;;
            esac
            ;;
    esac
    
    info "Intentando instalar $package..."
    
    case "$os_type" in
        arch|manjaro|endeavouros|garuda)
            if command -v pacman &> /dev/null; then
                if sudo pacman -S --noconfirm "$pkg_to_install" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi

            # Fallback a AUR con yay para paquetes no disponibles en pacman
            if command -v yay &> /dev/null; then
                # Lista de candidatos en AUR según el paquete lógico solicitado
                local aur_candidates=("$pkg_to_install")
                if [[ "$package" == "git-credential-manager" ]]; then
                    # Orden de preferencia: paquete AUR directo, luego variantes core/bin
                    aur_candidates=("git-credential-manager-bin")
                fi

                for aur_pkg in "${aur_candidates[@]}"; do
                    if yay -S --noconfirm "$aur_pkg" 2>/dev/null; then
                        success "$package instalado correctamente (AUR: $aur_pkg)"
                        return 0
                    fi
                done
            fi
            ;;
        ubuntu|debian|linuxmint|pop)
            if command -v apt &> /dev/null; then
                if sudo apt update -qq && sudo apt install -y "$pkg_to_install" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi
            ;;
        fedora|rhel|centos|rocky|alma)
            if command -v dnf &> /dev/null; then
                if sudo dnf install -y "$pkg_to_install" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            elif command -v yum &> /dev/null; then
                if sudo yum install -y "$pkg_to_install" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi
            ;;
        darwin)
            if command -v brew &> /dev/null; then
                if brew install "$pkg_to_install" 2>/dev/null; then
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
