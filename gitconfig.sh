#!/bin/bash
# =============================================================================
# Archivo: @gitconfig.sh         (https://github.com/25asab015/github-config)
# Descripción: Script para configurar Git profesionalmente con SSH y GPG en Linux
# Autor: 25asab015 <25asab015@ujmd.edu.sv>
# =============================================================================
#
# Copyright (C) 2021-2025 25asab015
# Licenciado bajo la licencia GPL-3.0
#
# Este script realiza:
#  - Verificación e instalación de dependencias (git, gh, gk, gpg, git-credential-manager)
#  - Generación y subida de llaves SSH y GPG a GitHub
#  - Backup y configuración segura de ~/.gitconfig y archivos de llaves
#  - Integración automática con ssh-agent y portapapeles
#  - Instalación y preconfiguración de Git Credential Manager
#  - Mensajes claros multietapa y soporte interactivo/no-interactivo
#
# Repositorio oficial y documentación:
#   (https://github.com/25asab015/github-config)

# =============================================================================
# Color System - Semantic Palette
# =============================================================================
# WCAG 2.1 Accessibility: Uses high-contrast colors for terminal output
# - State colors (success, error, warning, info) follow standard conventions
# - UI colors (primary, secondary, accent) provide consistent theming
# - Graceful degradation: returns empty strings when colors unavailable
# =============================================================================

declare -A COLORS=(
    # State Colors - Semantic status indicators
    [success]="$(tput setaf 2 2>/dev/null || echo -n "")"     # Green - success messages
    [error]="$(tput setaf 1 2>/dev/null || echo -n "")"       # Red - error messages
    [warning]="$(tput setaf 3 2>/dev/null || echo -n "")"     # Yellow - warnings
    [info]="$(tput setaf 4 2>/dev/null || echo -n "")"        # Blue - informational messages
    
    # UI Element Colors - Consistent theming
    [primary]="$(tput setaf 6 2>/dev/null || echo -n "")"     # Cyan - primary actions/labels
    [secondary]="$(tput setaf 5 2>/dev/null || echo -n "")"   # Magenta - secondary elements
    [accent]="$(tput setaf 3 2>/dev/null || echo -n "")"      # Yellow - highlights/accents
    [text]="$(tput setaf 7 2>/dev/null || echo -n "")"        # White - standard text
    
    # Text Modifiers
    [muted]="$(tput dim 2>/dev/null || echo -n "")"           # Dim - less important text
    [bold]="$(tput bold 2>/dev/null || echo -n "")"           # Bold - emphasis
    
    # Reset
    [reset]="$(tput sgr0 2>/dev/null || echo -n "")"          # Reset all attributes
)

# Color helper function - safely retrieve color codes by token name
# Usage: $(c success) or $(c bold)
c() {
    local token="$1"
    if [[ -n "${COLORS[$token]}" ]]; then
        echo -n "${COLORS[$token]}"
    else
        # Log warning in debug mode for unknown tokens
        [[ "$DEBUG" == "true" ]] && echo "Warning: unknown color token '$token'" >&2
        echo -n ""
    fi
}

# Reset helper - restore default terminal colors
# Usage: $(cr)
cr() {
    echo -n "${COLORS[reset]}"
}

# Configuración global
SCRIPT_DIR="$HOME/.github-keys-setup"
BACKUP_DIR="$SCRIPT_DIR/backup-$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$SCRIPT_DIR/setup.log"
DEBUG="${DEBUG:-false}"  # Variable para modo debug

# Variables de modo interactivo/no-interactivo
INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}"
AUTO_UPLOAD_KEYS=false  # Se establece con el flag --auto-upload
SSH_KEY_UPLOADED=false
GPG_KEY_UPLOADED=false
GH_INSTALL_ATTEMPTED=false  # Flag para evitar instalación duplicada de gh

# Definir etapas del proceso para barra de progreso
declare -A WORKFLOW_STEPS=(
    [1]="Verificando dependencias"
    [2]="Configurando directorios"
    [3]="Backup de llaves existentes"
    [4]="Recopilando información"
    [5]="Generando llave SSH"
    [6]="Generando llave GPG"
    [7]="Configurando Git"
    [8]="Configurando SSH agent"
    [9]="Mostrando resumen"
)

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

# Función para logging
log() {
    # Crear directorio si no existe
    [ ! -d "$(dirname "$LOG_FILE")" ] && mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}


# Función para mostrar separador
show_separator() {
    printf "%b\n" "$(c primary)─────────────────────────────────────────────────────────────────────────────$(cr)"
}

# Función para mostrar mensajes de éxito
success() {
    printf "%b\n" "$(c bold)$(c success)✅ $1$(cr)"
    log "SUCCESS: $1"
}

# Función para mostrar mensajes de error
error() {
    printf "%b\n" "$(c bold)$(c error)❌ ERROR: $1$(cr)"
    log "ERROR: $1"
}

# Función para mostrar advertencias
warning() {
    printf "%b\n" "$(c bold)$(c warning)⚠️  ADVERTENCIA: $1$(cr)"
    log "WARNING: $1"
}

# Función para mostrar información
info() {
    printf "%b\n" "$(c bold)$(c info)ℹ️  $1$(cr)"
    log "INFO: $1"
}

# Función para validar email
validate_email() {
    local email="$1"
    local regex="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"

    if [[ $email =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# Logo
logo() {
    local text="$1"
    # Array of logo lines (16 lines)
    local logo_lines=(
        "               %%%"
        "        %%%%%//%%%%%"
        "      %%************%%%"
        "  (%%//############*****%%"
        " %%%%**###&&&&&&&&&###**//"
        " %%(**##&&&#########&&&##**"
        " %%(**##*****#####*****##**%%%"
        " %%(**##     *****     ##**"
        "   //##   @@**   @@   ##//"
        "     ##     **###     ##"
        "     #######     #####//"
        "       ###**&&&&&**###"
        "       &&&         &&&"
        "       &&&////   &&"
        "          &&//@@@**"
        "            ..***"
    )
    
    # Hide cursor during animation
    tput civis
    
    # Ensure cursor is restored even if function exits early (e.g., Ctrl+C)
    trap 'tput cnorm' EXIT INT TERM
    
    # Display each line with animation effect
    for line in "${logo_lines[@]}"; do
        printf "%b%b%b\n" "$(c accent)" "$line" "$(cr)"
        sleep 0.03
    done
    
    # Display text banner below logo
    printf "\n   %b%b[ %b%s %b]%b\n\n" "$(c bold)" "$(c error)" "$(c warning)" "${text}" "$(c error)" "$(cr)"
    
    # Restore cursor
    tput cnorm
    
    # Clear trap after successful completion
    trap - EXIT INT TERM
}

initial_checks() {
    # Verificar usuario root
    if [ "$(id -u)" = 0 ]; then
        printf "This script MUST NOT be run as root user."
        exit 1
    fi

}

# Función para mostrar spinner de progreso
show_spinner() {
    local pid=$1
    local message="$2"
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    printf "%b" "$(c bold)$(c primary)${message}$(cr) "
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r%b %s " "$(c bold)$(c primary)${message}$(cr)" "$(c accent)${spinstr:0:1}$(cr)"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    
    wait "$pid"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf "\r%b %s\n" "$(c bold)$(c primary)${message}$(cr)" "$(c success)✓$(cr)"
    else
        printf "\r%b %s\n" "$(c bold)$(c primary)${message}$(cr)" "$(c error)✗$(cr)"
    fi
    
    return $exit_code
}

# Función para detectar soporte Unicode
check_unicode_support() {
    # Permitir forzar ASCII con variable de entorno (tiene prioridad)
    if [[ "${PROGRESS_BAR_ASCII}" == "true" ]] || [[ "${PROGRESS_BAR_ASCII}" == "1" ]]; then
        return 1
    fi
    
    # Permitir forzar Unicode con variable de entorno
    if [[ "${PROGRESS_BAR_UNICODE}" == "true" ]] || [[ "${PROGRESS_BAR_UNICODE}" == "1" ]]; then
        return 0
    fi
    
    # Por defecto, usar ASCII para máxima compatibilidad
    # Muchos terminales reportan UTF-8 pero no renderizan correctamente los caracteres Unicode
    return 1
}

# Función para mostrar barra de progreso visual
show_progress_bar() {
    local current=$1
    local total=$2
    local step_name="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    # Detectar soporte Unicode y elegir caracteres apropiados
    local filled_char="█"
    local empty_char="░"
    if ! check_unicode_support; then
        filled_char="#"
        empty_char="-"
    fi
    
    # Construir la barra directamente sin usar tr (que puede fallar con Unicode)
    local filled_bar=""
    local empty_bar=""
    local i
    
    for ((i=0; i<filled; i++)); do
        filled_bar="${filled_bar}${filled_char}"
    done
    
    for ((i=0; i<empty; i++)); do
        empty_bar="${empty_bar}${empty_char}"
    done
    
    printf "\r$(c bold)$(c warning)[%3d%%]$(cr) $(c success)%s$(cr)$(c muted)%s$(cr) $(c primary)%s$(cr)" \
           "$percentage" "$filled_bar" "$empty_bar" "$step_name"
    
    # Siempre imprimir salto de línea para que los mensajes siguientes no se superpongan
    echo ""
}

# Función para detectar el sistema operativo
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "ubuntu"
    else
        echo "unknown"
    fi
}

# Función para instalar dependencias automáticamente

auto_install_dependencies() {
    local os_type="$1"
    shift
    local packages="$@"
    local temp_log=$(mktemp)
    local failed_pkgs=""
    local retry_failed=""
    local missing_file="$HOME/missing_apps.txt"
    
    echo ""
    
    case "$os_type" in
        arch|manjaro|endeavouros|garuda)
            # Verificar si el paquete está en repositorios oficiales o AUR
            local official_pkgs=""
            local aur_pkgs=""
            
            for pkg in $packages; do
                if pacman -Si "$pkg" &>/dev/null; then
                    official_pkgs+=" $pkg"
                else
                    aur_pkgs+=" $pkg"
                fi
            done
            
            # Instalar paquetes oficiales
            if [ -n "$official_pkgs" ]; then
                info "Instalando desde repositorios oficiales..."
                for pkg in $official_pkgs; do
                    if ! sudo pacman -S --noconfirm --needed "$pkg" >> "$temp_log" 2>&1; then
                        failed_pkgs="$failed_pkgs $pkg"
                    fi
                done
                
                if [ -z "$failed_pkgs" ]; then
                    success "Paquetes oficiales instalados correctamente"
                else
                    warning "Algunos paquetes oficiales fallaron, reintentando..."
                    echo ""
                    
                    # Reintentar paquetes fallidos
                    for pkg in $failed_pkgs; do
                        if ! sudo pacman -S --noconfirm --needed "$pkg" >> "$temp_log" 2>&1; then
                            retry_failed="$retry_failed $pkg"
                        fi
                    done
                    
                    if [ -z "$retry_failed" ]; then
                        success "Todos los paquetes se instalaron correctamente en el segundo intento"
                    else
                        error "Los siguientes paquetes no se pudieron instalar:$(c warning)$retry_failed$(cr)"
                    fi
                fi
            fi
            
            # Instalar paquetes de AUR
            if [ -n "$aur_pkgs" ]; then
                if command -v yay &>/dev/null; then
                    info "Instalando desde AUR con yay..."
                    local aur_failed=""
                    
                    for pkg in $aur_pkgs; do
                        if ! yay -S --noconfirm --needed "$pkg" >> "$temp_log" 2>&1; then
                            aur_failed="$aur_failed $pkg"
                        fi
                    done
                    
                    if [ -z "$aur_failed" ]; then
                        success "Paquetes de AUR instalados correctamente"
                    else
                        warning "Los siguientes paquetes de AUR fallaron:$(c warning)$aur_failed$(cr)"
                        retry_failed="$retry_failed$aur_failed"
                    fi
                elif command -v paru &>/dev/null; then
                    info "Instalando desde AUR con paru..."
                    local aur_failed=""
                    
                    for pkg in $aur_pkgs; do
                        if ! paru -S --noconfirm --needed "$pkg" >> "$temp_log" 2>&1; then
                            aur_failed="$aur_failed $pkg"
                        fi
                    done
                    
                    if [ -z "$aur_failed" ]; then
                        success "Paquetes de AUR instalados correctamente"
                    else
                        warning "Los siguientes paquetes de AUR fallaron:$(c warning)$aur_failed$(cr)"
                        retry_failed="$retry_failed$aur_failed"
                    fi
                else
                    warning "No se encontró helper de AUR (yay/paru) para instalar:$aur_pkgs"
                    info "Instala manualmente: yay -S $aur_pkgs"
                    retry_failed="$retry_failed$aur_pkgs"
                fi
            fi
            ;;
            
        ubuntu|debian|linuxmint|pop)
            # Actualizar lista de paquetes
            (sudo apt update > "$temp_log" 2>&1) &
            local update_pid=$!
            
            if show_spinner "$update_pid" "Actualizando lista de paquetes..."; then
                success "Lista de paquetes actualizada"
                echo ""
                
                # Instalar paquetes uno por uno para detectar cuáles fallan
                info "Instalando paquetes..."
                for pkg in $packages; do
                    if ! sudo apt install -y "$pkg" >> "$temp_log" 2>&1; then
                        failed_pkgs="$failed_pkgs $pkg"
                    fi
                done
                
                if [ -z "$failed_pkgs" ]; then
                    success "Todos los paquetes se instalaron correctamente"
                else
                    warning "Algunos paquetes fallaron, reintentando..."
                    echo ""
                    
                    # Reintentar paquetes fallidos
                    for pkg in $failed_pkgs; do
                        if ! sudo apt install -y "$pkg" >> "$temp_log" 2>&1; then
                            retry_failed="$retry_failed $pkg"
                        fi
                    done
                    
                    if [ -z "$retry_failed" ]; then
                        success "Todos los paquetes se instalaron correctamente en el segundo intento"
                    else
                        error "Los siguientes paquetes no se pudieron instalar:$(c warning)$retry_failed$(cr)"
                    fi
                fi
            else
                error "Error al actualizar lista de paquetes"
                echo ""
                warning "Detalles del error:"
                cat "$temp_log"
                rm -f "$temp_log"
                return 1
            fi
            ;;
            
        fedora|rhel|centos|rocky|alma)
            info "Instalando paquetes con dnf..."
            for pkg in $packages; do
                if ! sudo dnf install -y "$pkg" >> "$temp_log" 2>&1; then
                    failed_pkgs="$failed_pkgs $pkg"
                fi
            done
            
            if [ -z "$failed_pkgs" ]; then
                success "Todos los paquetes se instalaron correctamente"
            else
                warning "Algunos paquetes fallaron, reintentando..."
                echo ""
                
                # Reintentar paquetes fallidos
                for pkg in $failed_pkgs; do
                    if ! sudo dnf install -y "$pkg" >> "$temp_log" 2>&1; then
                        retry_failed="$retry_failed $pkg"
                    fi
                done
                
                if [ -z "$retry_failed" ]; then
                    success "Todos los paquetes se instalaron correctamente en el segundo intento"
                else
                    error "Los siguientes paquetes no se pudieron instalar:$(c warning)$retry_failed$(cr)"
                fi
            fi
            ;;
            
        *)
            warning "Sistema operativo no soportado para instalación automática: $os_type"
            info "Por favor, instala las dependencias manualmente"
            rm -f "$temp_log"
            return 1
            ;;
    esac
    
    # Crear archivo con paquetes que fallaron después de reintentar
    if [ -n "$retry_failed" ]; then
        echo ""
        error "No se pudieron instalar los siguientes paquetes después de dos intentos:"
        printf "%b\n" "$(c bold)$(c warning)$retry_failed$(cr)"
        echo ""
        info "Creando archivo $(c primary)$missing_file$(cr) con la lista de paquetes fallidos..."
        
        {
            echo "# Paquetes que no se pudieron instalar"
            echo "# Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "# Sistema: $os_type"
            echo ""
            echo "Los siguientes paquetes fallaron después de dos intentos de instalación:"
            echo ""
            for pkg in $retry_failed; do
                echo "  - $pkg"
            done
            echo ""
            echo "Por favor, instala estos paquetes manualmente."
        } > "$missing_file"
        
        success "Archivo creado: $(c primary)$missing_file$(cr)"
        echo ""
        warning "Revisa el archivo para instalar manualmente los paquetes faltantes"
        sleep 3
    else
        success "Todos los paquetes se instalaron correctamente"
    fi
    
    rm -f "$temp_log"
    
    # Retornar 1 si hubo paquetes que fallaron, 0 si todo se instaló correctamente
    [ -n "$retry_failed" ] && return 1 || return 0
}

welcome() {
    clear
    logo "GitHub Configuración – $USER"

    printf "%b" "$(c bold)$(c success)Este script te ayudará a dejar lista tu configuración de Git y GitHub:$(cr)

  $(c bold)$(c success)[$(c warning)i$(c success)]$(cr) Generar y/o registrar tu clave SSH para GitHub
  $(c bold)$(c success)[$(c warning)i$(c success)]$(cr) Generar una clave GPG para firmar tus commits
  $(c bold)$(c success)[$(c warning)i$(c success)]$(cr) Configurar tu archivo $(c primary).gitconfig$(cr) con nombre, email y preferencias recomendadas
  $(c bold)$(c success)[$(c warning)i$(c success)]$(cr) Instalar y/o autenticar $(c primary)GitHub CLI (gh)$(cr)
  $(c bold)$(c success)[$(c warning)i$(c success)]$(cr) Instalar y configurar $(c primary)GitKraken CLI (gk)$(cr)

$(c bold)$(c success)[$(c error)!$(c success)]$(cr) $(c bold)$(c error)Este script NO realiza cambios peligrosos en tu sistema$(cr)
$(c bold)$(c success)[$(c error)!$(c success)]$(cr) $(c bold)$(c error)Solo edita configuraciones relacionadas a Git y GitHub en tu usuario$(cr)

"

    # Mostrar información sobre modo no-interactivo si está activo
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        echo ""
        printf "%b\n" "$(c bold)$(c accent)ℹ️  MODO NO-INTERACTIVO ACTIVO$(cr)"
        if [[ -n "$USER_EMAIL" ]] && [[ -n "$USER_NAME" ]]; then
            printf "%b\n" "$(c muted)   Usando: $(c primary)USER_EMAIL=${USER_EMAIL}$(c muted), $(c primary)USER_NAME=${USER_NAME}$(cr)"
        else
            printf "%b\n" "$(c warning)   ⚠️  ADVERTENCIA: USER_EMAIL y USER_NAME deben estar definidos$(cr)"
            printf "%b\n" "$(c muted)   Ejemplo: $(c primary)USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive$(cr)"
        fi
        echo ""
    fi

    ask_yes_no "¿Deseas continuar?" "n" "true"
}

# Función para mostrar ayuda
show_help() {
    printf "%b\n" "$(c bold)$(c secondary)╔══════════════════════════════════════════════════════════════════════════════╗$(cr)"
    printf "%b\n" "$(c bold)$(c secondary)║$(cr)  $(c bold)$(c text)                    GITCONFIG.SH - CONFIGURADOR DE GIT                        $(cr)$(c bold)$(c secondary)║$(cr)"
    printf "%b\n" "$(c bold)$(c secondary)╚══════════════════════════════════════════════════════════════════════════════╝$(cr)"
    printf "%b\n" "$(c bold)$(c accent)📋 DESCRIPCIÓN:$(cr) $(c muted)Script interactivo para configurar Git, SSH, GPG y GitHub CLI$(cr)"
    printf "%b\n" "$(c bold)$(c accent)🚀 USO:$(cr) $(c primary)./gitconfig.sh$(cr) $(c muted)[OPCIONES]$(cr)"
    echo ""
    printf "%b\n" "$(c bold)$(c accent)⚙️  OPCIONES:$(cr)"
    printf "%b\n" "   $(c success)-h, --help$(cr)              $(c muted)Mostrar esta ayuda$(cr)"
    printf "%b\n" "   $(c success)--non-interactive$(cr)        $(c muted)Modo no-interactivo (requiere USER_EMAIL y USER_NAME)$(cr)"
    printf "%b\n" "   $(c success)--auto-upload$(cr)            $(c muted)Subir llaves a GitHub usando gh CLI (requiere autenticación previa)$(cr)"
    echo ""
    printf "%b\n" "$(c bold)$(c accent)🔧 VARIABLES DE ENTORNO:$(cr)"
    printf "%b\n" "   $(c primary)INTERACTIVE_MODE$(cr)         $(c muted)true|false$(cr) $(c warning)(default: true)$(cr) - Controla si el script espera entrada del usuario$(cr)"
    printf "%b\n" "   $(c primary)USER_EMAIL$(cr) $(c warning)(requerido en modo no-interactivo)$(cr) - Email de GitHub para configurar Git$(cr)"
    printf "%b\n" "   $(c primary)USER_NAME$(cr) $(c warning)(requerido en modo no-interactivo)$(cr) - Nombre completo para configurar Git$(cr)"
    echo ""
    printf "%b\n" "$(c bold)$(c accent)💡 EJEMPLOS:$(cr)"
    printf "%b\n" "   $(c muted)# Interactivo:$(cr) $(c success)./gitconfig.sh$(cr)"
    printf "%b\n" "   $(c muted)# No-interactivo (requiere variables):$(cr)"
    printf "%b\n" "   $(c success)USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive$(cr)"
    printf "%b\n" "   $(c muted)# No-interactivo + auto-upload:$(cr)"
    printf "%b\n" "   $(c success)USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive --auto-upload$(cr)"
    echo ""
    printf "%b\n" "$(c bold)$(c accent)⚠️  NOTAS IMPORTANTES:$(cr)"
    printf "%b\n" "   $(c warning)•$(cr) $(c muted)En modo no-interactivo, $(c primary)USER_EMAIL$(c muted) y $(c primary)USER_NAME$(c muted) son $(c error)OBLIGATORIOS$(c muted)$(cr)"
    printf "%b\n" "   $(c warning)•$(cr) $(c muted)Las preguntas sí/no usan sus valores por defecto (no existe auto-confirmación de 'sí')$(cr)"
    printf "%b\n" "   $(c warning)•$(cr) $(c muted)Las respuestas automáticas se registran en el archivo de log$(cr)"
    printf "%b\n" "   $(c warning)•$(cr) $(c muted)El modo interactivo es el comportamiento por defecto$(cr)"
    printf "%b\n" "   $(c warning)•$(cr) $(c muted)Archivo de log: $(c primary)~/.github-keys-setup/setup.log$(cr)$(c muted)$(cr)"
    show_separator
    printf "%b\n" "$(c muted)AUTOR:$(cr) $(c primary)25asab015$(cr) $(c muted)<25asab015@ujmd.edu.sv>$(cr)  $(c muted)│$(cr)  $(c muted)LICENCIA:$(cr) $(c primary)GPL-3.0$(cr)"
}

# Función para preguntar sí/no con valor por defecto
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local exit_on_no="${3:-false}"
    local response

    # Modo no-interactivo
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        local answer="$default"
        log "AUTO-ANSWER: $prompt -> $answer"
        [[ "$answer" == "y" ]] && return 0 || return 1
    fi

    while true; do
        if [ "$default" = "y" ]; then
            printf " %b" "$(c bold)$(c success)${prompt}$(cr) [Y/n]: "
        else
            printf " %b" "$(c bold)$(c success)${prompt}$(cr) [y/N]: "
        fi

        read -r response
        response=${response:-$default}

        case "${response}" in
            [Yy]|[Ss]|yes|si)
                return 0 ;;
            [Nn]|no)
                if [ "$exit_on_no" = "true" ]; then
                    printf "\n%b\n" "$(c bold)$(c warning)Operación cancelada$(cr)"
                    exit 0
                else
                    return 1
                fi
                ;;
            *)
                printf "\n%b\n\n" "$(c bold)$(c error)Error:$(cr) Solo escribe '$(c bold)$(c warning)s$(cr)', '$(c bold)$(c warning)n$(cr)', '$(c bold)$(c warning)y$(cr)' o '$(c bold)$(c warning)N$(cr)'" ;;
        esac
    done
}

# Función para copiar al portapapeles
copy_to_clipboard() {
    local file_to_copy="$1"
    
    # Validar que el archivo existe
    if [ ! -f "$file_to_copy" ]; then
        error "El archivo $file_to_copy no existe"
        return 1
    fi
    
    local content
    content=$(cat "$file_to_copy")
    
    # Lista de métodos de portapapeles en orden de prioridad
    local clipboard_cmd=""
    local verify_cmd=""
    local method_name=""
    
    # Detectar método de portapapeles disponible
    if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy &> /dev/null; then
        clipboard_cmd="wl-copy"
        verify_cmd="wl-paste"
        method_name="wl-copy (Wayland)"
    elif [ -n "$DISPLAY" ] && command -v xsel &> /dev/null; then
        clipboard_cmd="xsel --clipboard --input"
        verify_cmd="xsel --clipboard --output"
        method_name="xsel (X11)"
    elif [ -n "$DISPLAY" ] && command -v xclip &> /dev/null; then
        clipboard_cmd="xclip -selection clipboard"
        verify_cmd="xclip -selection clipboard -o"
        method_name="xclip (X11)"
    elif command -v pbcopy &> /dev/null; then
        clipboard_cmd="pbcopy"
        verify_cmd="pbpaste"
        method_name="pbcopy (macOS)"
    else
        error "No se encontró ninguna herramienta de portapapeles instalada"
        info "Instala una de estas: $(c primary)xsel$(cr), $(c primary)xclip$(cr) (X11), $(c primary)wl-clipboard$(cr) (Wayland)"
        return 1
    fi
    
    # Intentar copiar
    if echo -n "$content" | eval "$clipboard_cmd" 2>/dev/null; then
        # Verificar que se copió correctamente
        if command -v $(echo "$verify_cmd" | awk '{print $1}') &> /dev/null; then
            local clipboard_content
            clipboard_content=$(eval "$verify_cmd" 2>/dev/null)
            
            if [ "$clipboard_content" = "$content" ]; then
                success "✓ Copiado al portapapeles usando $method_name"
                return 0
            else
                warning "El contenido del portapapeles no coincide"
                info "Intenta copiar manualmente"
                return 1
            fi
        else
            # No se puede verificar, pero el comando tuvo éxito
            success "✓ Copiado al portapapeles usando $method_name (sin verificar)"
            return 0
        fi
    else
        error "Falló al copiar usando $method_name"
        if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
            info "No se detectó sesión gráfica activa (X11/Wayland)"
        fi
        info "Copia manualmente el contenido mostrado arriba"
        return 1
    fi
}


# --- Main run --- #
# Función para verificar dependencias
check_dependencies() {
    local retry="${1:-false}"
    info "Verificando dependencias del sistema..."

    local missing_deps=()
    local deps=("ssh-keygen" "gpg" "git" "gh" "gk" "git-credential-manager")
    
    # Verificar herramientas de portapapeles (solo necesita una)
    local clipboard_tools=("xsel" "xclip" "wl-copy")
    local has_clipboard=false
    
    for tool in "${clipboard_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            has_clipboard=true
            break
        fi
    done

    for dep in "${deps[@]}"; do
        # Si gh ya se intentó instalar en verificación temprana, omitirlo aquí
        if [[ "$dep" == "gh" ]] && [[ "$GH_INSTALL_ATTEMPTED" == "true" ]]; then
            # Verificar si ahora está instalado (puede que se haya instalado en early check)
            if command -v "$dep" &> /dev/null; then
                continue  # Está instalado, no agregar a missing
            fi
            # Si no está instalado pero ya se intentó, no agregarlo de nuevo
            continue
        fi
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Agregar herramientas de portapapeles a missing_deps si no hay ninguna
    if [ "$has_clipboard" = false ]; then
        missing_deps+=("xsel|xclip|wl-copy")
    fi

    if [ "${#missing_deps[@]}" -gt 0 ]; then
        error "Faltan las siguientes dependencias:"
        for dep in "${missing_deps[@]}"; do
            if [[ "$dep" == *"|"* ]]; then
                printf "%b\n" "  $(c bold)$(c error)• Una herramienta de portapapeles: $(c warning)${dep}$(cr)"
            else
                printf "%b\n" "  $(c bold)$(c error)• $dep$(cr)"
            fi
        done

        echo ""
        
        # Construir lista de dependencias SOLO para los comandos faltantes
        local debian_pkgs=""
        local arch_pkgs=""
        local centos_pkgs=""
        local fedora_pkgs=""
        local brew_pkgs=""

        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                ssh-keygen|openssh-client|openssh-clients|openssh)
                    debian_pkgs+=" openssh-client"
                    arch_pkgs+=" openssh"
                    centos_pkgs+=" openssh-clients"
                    fedora_pkgs+=" openssh-clients"
                    ;;
                gpg|gnupg|gnupg2)
                    debian_pkgs+=" gnupg"
                    arch_pkgs+=" gnupg"
                    centos_pkgs+=" gnupg2"
                    fedora_pkgs+=" gnupg2"
                    brew_pkgs+=" gnupg"
                    ;;
                git)
                    debian_pkgs+=" git"
                    arch_pkgs+=" git"
                    centos_pkgs+=" git"
                    fedora_pkgs+=" git"
                    brew_pkgs+=" git"
                    ;;
                xsel|xclip|wl-copy)
                    # Instalar herramientas de portapapeles (priorizar xsel y wl-clipboard)
                    debian_pkgs+=" xsel wl-clipboard"
                    arch_pkgs+=" xsel wl-clipboard"
                    centos_pkgs+=" xsel wl-clipboard"
                    fedora_pkgs+=" xsel wl-clipboard"
                    brew_pkgs+=" xsel"
                    ;;
                gh)
                    debian_pkgs+=" gh"
                    arch_pkgs+=" github-cli"
                    centos_pkgs+=" gh"
                    fedora_pkgs+=" gh"
                    brew_pkgs+=" gh"
                    ;;
                gk)
                    # "gk" refers to gitkraken-cli, not always in official repos
                    debian_pkgs+=" gitkraken-cli"
                    arch_pkgs+=" gitkraken-cli"
                    centos_pkgs+=" gitkraken-cli"
                    fedora_pkgs+=" gitkraken-cli"
                    brew_pkgs+=" gk"  # Homebrew co-installable
                    ;;
                git-credential-manager)
                    debian_pkgs+=" git-credential-manager"
                    arch_pkgs+=" git-credential-manager-bin"
                    centos_pkgs+=" git-credential-manager"
                    fedora_pkgs+=" git-credential-manager"
                    brew_pkgs+=" git-credential-manager"
                    ;;
            esac
        done
        
        # Detectar sistema operativo e instalar automáticamente (solo si no es reintento)
        if [ "$retry" = "false" ]; then
            local os_type
            os_type=$(detect_os)
            
            case "$os_type" in
                arch|manjaro|endeavouros|garuda)
                    if auto_install_dependencies "$os_type" $arch_pkgs; then
                        echo ""
                        info "Verificando dependencias nuevamente..."
                        sleep 1
                        check_dependencies "true"
                        return $?
                    else
                        error "No se pudieron instalar todas las dependencias"
                        return 1
                    fi
                    ;;
                ubuntu|debian|linuxmint|pop)
                    if auto_install_dependencies "$os_type" $debian_pkgs; then
                        echo ""
                        info "Verificando dependencias nuevamente..."
                        sleep 1
                        check_dependencies "true"
                        return $?
                    else
                        error "No se pudieron instalar todas las dependencias"
                        return 1
                    fi
                    ;;
                *)
                    warning "Sistema operativo no soportado para instalación automática: $os_type"
                    echo ""
                    info "Comandos de instalación manual:"
                    printf "%b\n" "$(c bold)$(c warning)Arch Linux:$(cr)    $(c success)sudo pacman -S --noconfirm${arch_pkgs}$(cr)"
                    if [[ "$arch_pkgs" == *"gitkraken-cli"* ]] || [[ "$arch_pkgs" == *"git-credential-manager-bin"* ]]; then
                        printf "%b\n" "$(c bold)$(c warning)Arch Linux (AUR):$(cr) $(c success)yay -S --noconfirm${arch_pkgs}$(cr)"
                    fi
                    printf "%b\n" "$(c bold)$(c warning)Ubuntu/Debian:$(cr) $(c success)sudo apt update && sudo apt install -y${debian_pkgs}$(cr)"
                    printf "%b\n" "$(c bold)$(c warning)CentOS/RHEL:$(cr)   $(c success)sudo yum install -y${centos_pkgs}$(cr)"
                    printf "%b\n" "$(c bold)$(c warning)Fedora:$(cr)        $(c success)sudo dnf install -y${fedora_pkgs}$(cr)"
                    printf "%b\n" "$(c bold)$(c warning)macOS:$(cr)         $(c success)brew install${brew_pkgs}$(cr)"
                    echo ""
                    return 1
                    ;;
            esac
        else
            # Si es un reintento y aún faltan dependencias, mostrar error
            error "Algunas dependencias no se pudieron instalar correctamente"
            info "Por favor, instálalas manualmente usando los comandos mostrados arriba"
            return 1
        fi
    fi

    success "Todas las dependencias están instaladas"
    return 0
}

# Función para crear directorio de trabajo
setup_directories() {
    info "Configurando directorios de trabajo..."

    if [[ ! -d "$SCRIPT_DIR" ]]; then
        mkdir -p "$SCRIPT_DIR" || {
            error "No se pudo crear el directorio $SCRIPT_DIR"
            return 1
        }
    fi

    mkdir -p "$BACKUP_DIR" || {
        error "No se pudo crear el directorio de backup"
        return 1
    }

    success "Directorios configurados correctamente"
    return 0
}


# Función para hacer backup de llaves existentes
backup_existing_keys() {
    info "Verificando llaves SSH existentes..."

    local ssh_files=("$HOME/.ssh/id_rsa" "$HOME/.ssh/id_rsa.pub" "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub")
    local backup_made=false
    local should_backup=false
    local existing_keys=()

    # Primero verificar si hay llaves existentes
    for file in "${ssh_files[@]}"; do
        if [[ -f "$file" ]]; then
            existing_keys+=("$file")
        fi
    done

    # Si hay llaves, preguntar una vez si hacer backup
    if [ ${#existing_keys[@]} -gt 0 ]; then
        warning "Se encontraron ${#existing_keys[@]} llave(s) SSH existente(s):"
        for file in "${existing_keys[@]}"; do
            echo "  • $(basename "$file")"
        done
        echo ""
        
        if ask_yes_no "¿Deseas hacer un backup de las llaves existentes antes de continuar?"; then
            should_backup=true
            info "Creando backup de llaves existentes..."
            
            # Hacer backup de cada llave encontrada
            for file in "${existing_keys[@]}"; do
                if cp "$file" "$BACKUP_DIR/" 2>/dev/null; then
                    success "✓ Backup creado: $(basename "$file")"
                else
                    error "No se pudo hacer backup de: $(basename "$file")"
                fi
            done
            
            success "Backup completado en: $(c primary)$BACKUP_DIR$(cr)"
        else
            info "Continuando sin hacer backup (las llaves existentes se sobrescribirán)"
        fi
    else
        info "No se encontraron llaves SSH existentes"
    fi

    return 0
}


# Función para recopilar información del usuario
collect_user_info() {
    show_separator
    echo -e "$(c bold)📝 INFORMACIÓN DEL USUARIO$(cr)"
    show_separator

    # Modo no-interactivo: usar variables de entorno
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        if [[ -z "$USER_EMAIL" ]]; then
            error "USER_EMAIL no está definido. Requerido en modo no-interactivo."
            echo ""
            info "Ejemplo de uso:"
            printf "%b\n" "$(c primary)USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive$(cr)"
            return 1
        fi
        
        if ! validate_email "$USER_EMAIL"; then
            error "USER_EMAIL inválido: $USER_EMAIL"
            return 1
        fi
        
        if [[ -z "$USER_NAME" ]]; then
            error "USER_NAME no está definido. Requerido en modo no-interactivo."
            echo ""
            info "Ejemplo de uso:"
            printf "%b\n" "$(c primary)USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive$(cr)"
            return 1
        fi
        
        info "Usando información de variables de entorno:"
        info "  Email: $USER_EMAIL"
        info "  Nombre: $USER_NAME"
        success "Información del usuario recopilada"
        return 0
    fi

    # Modo interactivo: pedir información
    while true; do
        echo -ne "$(c primary)Ingresa tu email de GitHub: $(cr)"
        read -r USER_EMAIL

        if [[ -z "$USER_EMAIL" ]]; then
            error "El email no puede estar vacío"
            continue
        fi

        if validate_email "$USER_EMAIL"; then
            break
        else
            error "Email inválido. Por favor ingresa un email válido"
        fi
    done

    while true; do
        echo -ne "$(c primary)Ingresa tu nombre completo para Git: $(cr)"
        read -r USER_NAME

        if [[ -n "$USER_NAME" ]]; then
            break
        else
            error "El nombre no puede estar vacío"
        fi
    done

    success "Información del usuario recopilada"
    return 0
}

# Función para mostrar resumen de cambios antes de aplicarlos
show_changes_summary() {
    # No usar clear para mantener el contexto del welcome
    # En su lugar, agregar separadores visuales
    echo ""
    echo ""
    show_separator
    printf "%b\n" "$(c bold)$(c secondary)╔══════════════════════════════════════════════════════════════════════════════╗$(cr)"
    printf "%b\n" "$(c bold)$(c secondary)║$(cr)  $(c bold)$(c text)📋  RESUMEN DE CAMBIOS A REALIZAR$(cr)                                        $(c bold)$(c secondary)║$(cr)"
    printf "%b\n" "$(c bold)$(c secondary)╚══════════════════════════════════════════════════════════════════════════════╝$(cr)"
    echo ""
    
    printf "%b\n" "$(c bold)$(c accent)🔧 Archivos que se crearán/modificarán:$(cr)"
    echo ""
    
    # SSH keys
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        printf "  $(c success)[CREAR]$(cr)    ~/.ssh/id_ed25519\n"
        printf "  $(c success)[CREAR]$(cr)    ~/.ssh/id_ed25519.pub\n"
    else
        printf "  $(c warning)[SOBRESCRIBIR]$(cr) ~/.ssh/id_ed25519\n"
        printf "  $(c warning)[SOBRESCRIBIR]$(cr) ~/.ssh/id_ed25519.pub\n"
    fi
    
    # .gitconfig
    if [[ -f "$HOME/.gitconfig" ]]; then
        printf "  $(c warning)[MODIFICAR]$(cr) ~/.gitconfig $(c muted)(backup: ~/.gitconfig.backup-*)$(cr)\n"
    else
        printf "  $(c success)[CREAR]$(cr)    ~/.gitconfig\n"
    fi
    
    # GPG key
    if [[ "$GENERATE_GPG" == "true" ]]; then
        # Verificar si ya existe una llave GPG para este email
        local existing_gpg_key_id=""
        if command -v gpg &> /dev/null; then
            existing_gpg_key_id=$(gpg --list-secret-keys --keyid-format=long "$USER_EMAIL" 2>/dev/null | grep 'sec' | head -n1 | sed 's/.*\/\([A-Z0-9]*\).*/\1/' || echo "")
        fi
        
        if [[ -n "$existing_gpg_key_id" ]]; then
            printf "  $(c warning)[USAR EXISTENTE]$(cr) Llave GPG (ID: ${existing_gpg_key_id})\n"
        else
            printf "  $(c success)[CREAR]$(cr)    Llave GPG (4096-bit RSA)\n"
        fi
    fi
    
    # Shell configs
    printf "  $(c warning)[MODIFICAR]$(cr) ~/.bashrc $(c muted)(agregar configuración SSH agent)$(cr)\n"
    [[ -f "$HOME/.zshrc" ]] && printf "  $(c warning)[MODIFICAR]$(cr) ~/.zshrc $(c muted)(agregar configuración SSH agent)$(cr)\n"
    
    echo ""
    printf "%b\n" "$(c bold)$(c accent)📦 Configuración Git:$(cr)"
    echo ""
    
    # Determinar credential helper (misma lógica que generate_gitconfig)
    local credential_helper="manager"
    local os_type=$(uname -s)
    
    case $os_type in
        "Darwin")
            if ! command -v git-credential-manager &> /dev/null; then
                credential_helper="osxkeychain"
            fi
            ;;
        "Linux")
            if ! command -v git-credential-manager &> /dev/null; then
                credential_helper="store"
            else
                credential_helper="manager (secretservice)"
            fi
            ;;
    esac
    
    printf "  $(c primary)Nombre:$(cr)        $USER_NAME\n"
    printf "  $(c primary)Email:$(cr)         $USER_EMAIL\n"
    printf "  $(c primary)Rama default:$(cr)  master\n"
    if [[ "$GENERATE_GPG" == "true" ]]; then
        if [[ -n "$GPG_KEY_ID" ]]; then
            printf "  $(c primary)GPG signing:$(cr)   $(c success)true$(cr) $(c muted)(usando llave existente: ${GPG_KEY_ID})$(cr)\n"
        else
            printf "  $(c primary)GPG signing:$(cr)   $(c success)true$(cr) $(c muted)(se generará nueva llave)$(cr)\n"
        fi
    else
        printf "  $(c primary)GPG signing:$(cr)   $(c warning)false$(cr)\n"
    fi
    printf "  $(c primary)Credential:$(cr)    $credential_helper\n"
    
    echo ""
    printf "%b\n" "$(c bold)$(c accent)📝 Notas importantes:$(cr)"
    echo ""
    if [[ -f "$HOME/.gitconfig" ]]; then
        printf "  $(c muted)•$(cr) Se creará un backup de tu $(c primary).gitconfig$(cr) actual antes de modificarlo\n"
    fi
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        printf "  $(c muted)•$(cr) Las llaves SSH existentes serán $(c warning)sobrescritas$(cr)\n"
    fi
    if [[ "$GENERATE_GPG" == "true" ]] && [[ -n "$GPG_KEY_ID" ]]; then
        printf "  $(c muted)•$(cr) Se usará tu llave GPG existente $(c primary)($GPG_KEY_ID)$(cr)\n"
    fi
    if [[ "$AUTO_UPLOAD_KEYS" == "true" ]]; then
        printf "  $(c muted)•$(cr) Las llaves se subirán automáticamente a GitHub $(c success)(--auto-upload activo)$(cr)\n"
    fi
    echo ""
    show_separator
    
    # En modo no-interactivo, auto-confirmar
    if [[ "$INTERACTIVE_MODE" == "false" ]] || [[ "${AUTO_YES:-false}" == "true" ]]; then
        log "AUTO-ANSWER: ¿Confirmas que deseas aplicar estos cambios? -> y"
        return 0
    fi
    
    if ! ask_yes_no "¿Confirmas que deseas aplicar estos cambios?" "y"; then
        warning "Operación cancelada por el usuario"
        exit 0
    fi
    
    return 0
}

# Función para generar llave SSH
generate_ssh_key() {
    show_separator
    echo -e "$(c bold)🔑 GENERACIÓN DE LLAVE SSH$(cr)"
    show_separator

    info "Generando llave SSH Ed25519 (recomendada por GitHub)..."

    # Asegurar que existe el directorio .ssh
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Generar llave SSH
    # Si el archivo ya existe, forzar sobrescritura en modo no-interactivo
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        # Forzar sobrescritura sin preguntar
        if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
            rm -f "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub"
        fi
    fi
    
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$HOME/.ssh/id_ed25519" -N "" || {
        error "No se pudo generar la llave SSH"
        return 1
    }

    # Configurar permisos
    chmod 600 "$HOME/.ssh/id_ed25519"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"

    success "Llave SSH generada exitosamente"

    # Iniciar ssh-agent y agregar llave
    info "Configurando ssh-agent..."
    eval "$(ssh-agent -s)" &>/dev/null
    ssh-add "$HOME/.ssh/id_ed25519" &>/dev/null || {
        warning "No se pudo agregar la llave al ssh-agent automáticamente"
    }

    success "Llave SSH configurada en ssh-agent"
    return 0
}

# Función para generar llave GPG
generate_gpg_key() {
    show_separator
    printf "%b\n" "$(c bold)$(c text)🔐 GENERACIÓN DE LLAVE GPG$(cr)"
    show_separator

    info "Verificando configuración de GPG..."

    # Verificar que GPG esté instalado y funcionando
    if ! command -v gpg &> /dev/null; then
        error "GPG no está instalado. Instálalo con: sudo pacman -S gnupg"
        return 1
    fi

    # Verificar versión de GPG
    local gpg_version=$(gpg --version | head -n1 | grep -oE '[0-9]+\.[0-9]+')
    info "Versión de GPG detectada: $gpg_version"
    
    # Configurar entorno GPG
    if ! setup_gpg_environment; then
        error "No se pudo configurar el entorno GPG"
        return 1
    fi

    # Verificar si ya existe una llave para este email
    if gpg --list-secret-keys --keyid-format=long "$USER_EMAIL" &>/dev/null; then
        warning "Ya existe una llave GPG para el email: $USER_EMAIL"
        if ask_yes_no "¿Deseas usar la llave existente?"; then
            GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$USER_EMAIL" 2>/dev/null | grep 'sec' | head -n1 | sed 's/.*\/\([A-Z0-9]*\).*/\1/')
            success "Usando llave GPG existente: $GPG_KEY_ID"
            return 0
        fi
    fi

    info "Generando nueva llave GPG para firmar commits..."

    # Crear archivo de configuración temporal para GPG
    local gpg_config=$(mktemp)
    cat > "$gpg_config" << EOF
%echo Generando llave GPG para GitHub
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $USER_NAME
Name-Email: $USER_EMAIL
Expire-Date: 2y
%no-protection
%commit
%echo Llave GPG generada exitosamente
EOF

    info "Archivo de configuración GPG creado: $gpg_config"
    
    # Mostrar contenido del archivo de configuración para debug
    if [[ "$DEBUG" == "true" ]]; then
        printf "%b\n" "$(c warning)Contenido del archivo de configuración GPG:$(cr)"
        cat "$gpg_config"
        echo ""
    fi

    # Generar llave GPG con mejor manejo de errores
    info "Ejecutando: gpg --batch --generate-key $gpg_config"
    
    local gpg_output
    local gpg_exit_code
    local max_retries=3
    local retry_count=0
    
    # Intentar generar la llave con reintentos
    while [[ $retry_count -lt $max_retries ]]; do
        info "Intento $((retry_count + 1)) de $max_retries..."
        
        # Limpiar procesos antes de cada intento
        if [[ $retry_count -gt 0 ]]; then
            cleanup_gpg_processes
            sleep 3
        fi
        
        # Capturar tanto stdout como stderr
        gpg_output=$(timeout 60 gpg --batch --generate-key "$gpg_config" 2>&1)
        gpg_exit_code=$?
        
        if [[ $gpg_exit_code -eq 0 ]]; then
            success "Llave GPG generada exitosamente"
            log "GPG output: $gpg_output"
            break
        elif [[ $gpg_output == *"waiting for lock"* ]] || [[ $gpg_output == *"Connection timed out"* ]]; then
            warning "Bloqueo detectado, limpiando y reintentando..."
            cleanup_gpg_processes
            sleep 5
            ((retry_count++))
            continue
        else
            error "No se pudo generar la llave GPG (código de salida: $gpg_exit_code)"
            error "Salida de GPG: $gpg_output"
            log "GPG ERROR: $gpg_output"
            break
        fi
    done
    
    # Limpiar archivo temporal
    rm -f "$gpg_config"
    
    # Si todos los intentos fallaron, probar método alternativo
    if [[ $gpg_exit_code -ne 0 ]]; then
        warning "Intentando método alternativo de generación..."
        if generate_gpg_key_alternative; then
            return 0
        else
            return 1
        fi
    fi

    # Obtener ID de la llave GPG
    info "Obteniendo ID de la llave GPG generada..."
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$USER_EMAIL" 2>/dev/null | grep 'sec' | head -n1 | sed 's/.*\/\([A-Z0-9]*\).*/\1/')

    if [[ -z "$GPG_KEY_ID" ]]; then
        error "No se pudo obtener el ID de la llave GPG"
        warning "Intentando método alternativo para obtener el ID..."
        
        # Método alternativo para obtener el ID
        GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep -A1 "$USER_EMAIL" | grep 'sec' | sed 's/.*\/\([A-Z0-9]*\).*/\1/')
        
        if [[ -z "$GPG_KEY_ID" ]]; then
            error "No se pudo obtener el ID de la llave GPG con métodos alternativos"
            return 1
        fi
    fi

    success "ID de llave GPG obtenido: $GPG_KEY_ID"
    return 0
}

# Función alternativa para generar llave GPG
generate_gpg_key_alternative() {
    info "Intentando generación alternativa de llave GPG..."
    
    # Método alternativo usando gpg --full-generate-key
    local temp_script=$(mktemp)
    cat > "$temp_script" << EOF
#!/bin/bash
echo "1"  # RSA and RSA
echo "4096"  # Key size
echo "2y"  # Expiration
echo "y"  # Confirm expiration
echo "$USER_NAME"  # Real name
echo "$USER_EMAIL"  # Email
echo ""  # Comment (empty)
echo "O"  # Okay
echo ""  # Passphrase (empty)
echo ""  # Confirm passphrase (empty)
EOF

    chmod +x "$temp_script"
    
    if gpg --batch --full-generate-key < "$temp_script" &>/dev/null; then
        success "Llave GPG generada con método alternativo"
        rm -f "$temp_script"
        return 0
    else
        error "Método alternativo también falló"
        rm -f "$temp_script"
        return 1
    fi
}

# Función para limpiar procesos GPG bloqueados
cleanup_gpg_processes() {
    info "Limpiando procesos GPG bloqueados..."
    
    # Matar todos los procesos GPG relacionados
    local gpg_processes=("gpg-agent" "keyboxd" "gpg")
    
    for process in "${gpg_processes[@]}"; do
        if pgrep "$process" > /dev/null; then
            info "Terminando proceso: $process"
            pkill -f "$process" 2>/dev/null || true
            sleep 1
        fi
    done
    
    # Usar gpgconf para limpiar completamente
    if command -v gpgconf &> /dev/null; then
        info "Limpiando configuración GPG con gpgconf..."
        gpgconf --kill all 2>/dev/null || true
        sleep 2
    fi
    
    # Limpiar archivos de bloqueo
    local gpg_home="$HOME/.gnupg"
    if [[ -d "$gpg_home" ]]; then
        find "$gpg_home" -name "*.lock" -delete 2>/dev/null || true
        find "$gpg_home" -name "lock" -delete 2>/dev/null || true
        info "Archivos de bloqueo eliminados"
    fi
    
    # Esperar un momento para que los procesos terminen completamente
    sleep 2
    
    success "Limpieza de procesos GPG completada"
    return 0
}

# Función para configurar GPG correctamente
setup_gpg_environment() {
    info "Configurando entorno GPG..."
    
    # Limpiar procesos bloqueados primero
    cleanup_gpg_processes
    
    # Crear directorio GPG si no existe
    local gpg_home="$HOME/.gnupg"
    if [[ ! -d "$gpg_home" ]]; then
        mkdir -p "$gpg_home"
        chmod 700 "$gpg_home"
        success "Directorio GPG creado: $gpg_home"
    fi
    
    # Configurar GPG para modo batch
    local gpg_config="$gpg_home/gpg.conf"
    if [[ ! -f "$gpg_config" ]]; then
        cat > "$gpg_config" << EOF
# Configuración GPG para GitHub
batch
no-tty
use-agent
pinentry-mode loopback
EOF
        chmod 600 "$gpg_config"
        success "Archivo de configuración GPG creado"
    fi
    
    # Configurar gpg-agent
    local gpg_agent_config="$gpg_home/gpg-agent.conf"
    if [[ ! -f "$gpg_agent_config" ]]; then
        cat > "$gpg_agent_config" << EOF
# Configuración gpg-agent
default-cache-ttl 600
max-cache-ttl 7200
pinentry-program /usr/bin/pinentry-curses
allow-loopback-pinentry
EOF
        chmod 600 "$gpg_agent_config"
        success "Archivo de configuración gpg-agent creado"
    fi
    
    # Iniciar gpg-agent limpio
    info "Iniciando gpg-agent..."
    if command -v gpgconf &> /dev/null; then
        gpgconf --launch gpg-agent 2>/dev/null || true
        sleep 1
    fi
    
    # Verificar que no hay procesos bloqueados
    local retry_count=0
    while [[ $retry_count -lt 3 ]]; do
        if ! pgrep -f "gpg.*batch.*generate-key" > /dev/null; then
            break
        fi
        warning "Proceso GPG aún bloqueado, esperando..."
        sleep 2
        ((retry_count++))
    done
    
    success "Entorno GPG configurado correctamente"
    return 0
}

# Función para configurar Git
configure_git() {
    show_separator
    echo -e "$(c bold)⚙️  CONFIGURACIÓN DE GIT$(cr)"
    show_separator

    # Generar archivo .gitconfig completo (PRIORIDAD)
    generate_gitconfig || {
        error "No se pudo generar el archivo .gitconfig"
        return 1
    }

    # Configurar Git Credential Manager si está disponible
    if command -v git-credential-manager &> /dev/null; then
        info "Configurando Git Credential Manager..."
        
        # Intentar configuración automática (esto puede agregar configuraciones adicionales)
        if git-credential-manager configure &>/dev/null; then
            success "Git Credential Manager configurado automáticamente"
        fi
        
        # Nota: La configuración principal ya está en .gitconfig generado
        success "Git Credential Manager listo para usar"
    fi

    success "Configuración Git completada exitosamente"
    echo ""
    info "Puedes ver tu configuración con: $(c primary)git config --global --list$(cr)"
    
    return 0
}


# Función para generar archivo .gitconfig completo
generate_gitconfig() {
    info "Generando archivo .gitconfig profesional..."

    local gitconfig_path="$HOME/.gitconfig"
    local backup_suffix=".backup-$(date +%Y%m%d_%H%M%S)"

    # Hacer backup del .gitconfig existente
    if [[ -f "$gitconfig_path" ]]; then
        warning "Se encontró un archivo .gitconfig existente"
        if ask_yes_no "¿Deseas hacer backup del .gitconfig actual antes de reemplazarlo?"; then
            cp "$gitconfig_path" "${gitconfig_path}${backup_suffix}"
            success "Backup creado: ${gitconfig_path}${backup_suffix}"
        fi
    fi

    # Determinar credential helper
    local credential_helper="manager"
    local os_type=$(uname -s)

    case $os_type in
        "Darwin")
            if ! command -v git-credential-manager &> /dev/null; then
                credential_helper="osxkeychain"
            fi
            ;;
        "Linux")
            if ! command -v git-credential-manager &> /dev/null; then
                credential_helper="store"
            fi
            ;;
    esac

    # Generar .gitconfig completo
    cat > "$gitconfig_path" << EOF
# ============================================================================
# Configuración Git Profesional
# Generado automáticamente el $(date)
# Usuario: $USER_NAME <$USER_EMAIL>
# ============================================================================

[user]
	name = $USER_NAME
	email = $USER_EMAIL$(if [[ -n "$GPG_KEY_ID" ]]; then echo "
	signingkey = $GPG_KEY_ID"; fi)

[commit]$(if [[ -n "$GPG_KEY_ID" ]]; then echo "
	gpgsign = true"; fi)
	template = ~/.gitmessage

[credential]
	helper = $credential_helper$(if [[ "$os_type" == "Linux" ]] && [[ "$credential_helper" == "manager" ]]; then echo "
	credentialStore = secretservice"; fi)

[init]
	defaultBranch = master

[core]
	editor = nano
	autocrlf = false
	filemode = true
	ignorecase = false
	precomposeUnicode = true
	quotepath = false

[push]
	default = simple
	followTags = true
	autoSetupRemote = true

[pull]
	rebase = false
	ff = only

[fetch]
	prune = true
	pruneTags = true

[merge]
	tool = vimdiff
	conflictstyle = diff3

[diff]
	tool = vimdiff
	algorithm = histogram
	colorMoved = default

[status]
	showUntrackedFiles = all

[branch]
	autoSetupMerge = always
	autoSetupRebase = never

[rerere]
	enabled = true

[help]
	autoCorrect = 1

[color]
	ui = auto
	branch = auto
	diff = auto
	status = auto
	showBranch = auto

[color "branch"]
	current = yellow reverse
	local = yellow
	remote = green

[color "diff"]
	meta = yellow bold
	frag = magenta bold
	old = red bold
	new = green bold

[color "status"]
	added = yellow
	changed = green
	untracked = cyan

[alias]
	# Aliases básicos
	st = status -s
	co = checkout
	br = branch
	ci = commit
	df = diff
	dc = diff --cached
	lg = log --oneline --decorate --graph --all
	ls = log --pretty=format:"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]" --decorate
	ll = log --pretty=format:"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]" --decorate --numstat

	# Aliases avanzados
	unstage = reset HEAD --
	last = log -1 HEAD
	visual = !gitk
	type = cat-file -t
	dump = cat-file -p

	# Aliases para trabajo con ramas
	branches = branch -a
	remotes = remote -v
	tags = tag -l

	# Aliases para estadísticas
	stats = shortlog -sn
	contributors = shortlog -s -n

	# Aliases para GitHub
	hub = !gh
	pr = !gh pr
	issue = !gh issue

[url "git@github.com:"]
	insteadOf = https://github.com/

[github]
	user = $(echo "$USER_EMAIL" | cut -d'@' -f1)

# Configuración específica para diferentes repositorios
# Descomenta y modifica según necesites:
# [includeIf "gitdir:~/work/"]
#     path = ~/.gitconfig-work
# [includeIf "gitdir:~/personal/"]
#     path = ~/.gitconfig-personal
EOF

    success "Archivo .gitconfig generado exitosamente"

    # Crear plantilla de mensaje de commit
    create_commit_template

    return 0
}

# Función para crear plantilla de mensaje de commit
create_commit_template() {
    local template_path="$HOME/.gitmessage"
    
    info "Creando plantilla de mensaje de commit..."
    
    # Crear plantilla de commit profesional
    cat > "$template_path" << 'EOF'
# <tipo>(<ámbito>): <asunto>
#
# <cuerpo del mensaje>
#
# <pie del mensaje>
#
# Tipos permitidos:
#   feat:     Nueva característica
#   fix:      Corrección de bug
#   docs:     Cambios en documentación
#   style:    Formato, espacios, etc (sin cambios de código)
#   refactor: Refactorización (sin cambios funcionales)
#   perf:     Mejoras de rendimiento
#   test:     Agregar o modificar tests
#   chore:    Cambios en build, dependencias, etc
#   ci:       Cambios en configuración CI/CD
#   revert:   Revertir un commit anterior
#
# Ámbito (opcional): Componente o módulo afectado
#
# Asunto: Descripción breve (máx 50 caracteres)
#   - Usa imperativo: "agrega" no "agregando" ni "agregó"
#   - Sin punto al final
#   - Primera letra en minúscula
#
# Cuerpo (opcional): Explicación detallada del cambio
#   - Wrap a 72 caracteres
#   - Explica QUÉ y POR QUÉ, no CÓMO
#
# Pie (opcional): Issues relacionados, breaking changes
#   - Refs: #123
#   - Closes: #456
#   - BREAKING CHANGE: descripción
#
# Ejemplo:
# feat(auth): agrega autenticación con OAuth2
#
# Implementa flujo OAuth2 para login con Google y GitHub.
# Mejora seguridad y experiencia de usuario.
#
# Refs: #123
# Closes: #456
EOF

    chmod 644 "$template_path"
    success "Plantilla de commit creada: $(c primary)$template_path$(cr)"
    
    return 0
}

# Función para crear script de configuración del ssh-agent
create_ssh_agent_script() {
    local ssh_config="$HOME/.ssh/config"
    local bashrc_addition="$SCRIPT_DIR/bashrc_addition.txt"

    info "Creando configuración permanente para ssh-agent..."

    # Crear configuración SSH si no existe
    if [[ ! -f "$ssh_config" ]]; then
        cat > "$ssh_config" << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
        chmod 600 "$ssh_config"
        success "Archivo de configuración SSH creado"
    fi

    # Crear adición para archivos de configuración de shell
    cat > "$bashrc_addition" << 'EOF'
# GitHub SSH Agent Configuration (generado automáticamente)
if [ -f ~/.ssh/id_ed25519 ]; then
    eval "$(ssh-agent -s)" &>/dev/null
    ssh-add ~/.ssh/id_ed25519 &>/dev/null
fi
EOF

    # Detectar archivos de configuración de shell disponibles
    local shell_configs=()
    local shell_names=()
    
    if [[ -f "$HOME/.bashrc" ]]; then
        shell_configs+=("$HOME/.bashrc")
        shell_names+=("bashrc")
    fi
    
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_configs+=("$HOME/.zshrc")
        shell_names+=("zshrc")
    fi
    
    # Mostrar configuración a agregar
    echo ""
    info "Configuración para ssh-agent automático:"
    show_separator
    cat "$bashrc_addition"
    show_separator
    echo ""
    
    # Si hay archivos de configuración disponibles
    if [ ${#shell_configs[@]} -gt 0 ]; then
        # Mostrar qué archivos se encontraron
        info "Archivos de configuración de shell detectados:"
        for name in "${shell_names[@]}"; do
            echo "  • ~/.${name}"
        done
        echo ""
        
        # Preguntar si agregar a todos
        local prompt_msg="¿Deseas agregar esta configuración a"
        if [ ${#shell_configs[@]} -eq 1 ]; then
            prompt_msg+=" ~/.${shell_names[0]}?"
        else
            prompt_msg+=" todos estos archivos?"
        fi
        
        if ask_yes_no "$prompt_msg"; then
            local added_count=0
            
            for i in "${!shell_configs[@]}"; do
                local config_file="${shell_configs[$i]}"
                local config_name="${shell_names[$i]}"
                
                # Verificar si ya existe la configuración
                if grep -q "GitHub SSH Agent Configuration" "$config_file" 2>/dev/null; then
                    warning "La configuración ya existe en ~/.${config_name}, omitiendo..."
                else
                    # Agregar configuración
                    echo "" >> "$config_file"
                    cat "$bashrc_addition" >> "$config_file"
                    success "✓ Configuración agregada a ~/.${config_name}"
                    ((added_count++))
                fi
            done
            
            if [ $added_count -gt 0 ]; then
                echo ""
                success "Configuración agregada a ${added_count} archivo(s)"
                info "Reinicia tu terminal o ejecuta: $(c primary)source ~/.bashrc$(cr) / $(c primary)source ~/.zshrc$(cr)"
            fi
        else
            info "Configuración no agregada. Puedes agregarla manualmente usando el código mostrado arriba"
        fi
    else
        warning "No se encontraron archivos ~/.bashrc ni ~/.zshrc"
        info "Crea uno de estos archivos y agrega manualmente la configuración mostrada arriba"
    fi
    
    # Limpiar archivo temporal
    rm -f "$bashrc_addition"
}

# Función para mostrar las llaves generadas
display_keys() {
    # Si --auto-upload está activo, las llaves ya se subieron, no es necesario mostrarlas
    if [[ "$AUTO_UPLOAD_KEYS" == "true" ]]; then
        return 0
    fi

    show_separator
    echo -e "$(c bold)📋 RESUMEN DE LLAVES GENERADAS$(cr)"
    show_separator
    echo ""

    # ========== LLAVE SSH ==========
    info "1. LLAVE SSH PÚBLICA (para agregar a GitHub):"
    echo ""
    
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        show_separator
        printf "%b\n" "$(c bold)$(c success)$(cat "$HOME/.ssh/id_ed25519.pub")$(cr)"
        show_separator
        echo ""
        
        # Ofrecer copiar SSH al portapapeles
        if ask_yes_no "¿Deseas copiar la llave SSH al portapapeles?"; then
            copy_to_clipboard "$HOME/.ssh/id_ed25519.pub"
        fi
    else
        error "No se encontró la llave SSH pública en $HOME/.ssh/id_ed25519.pub"
    fi

    echo ""
    
    # ========== LLAVE GPG ==========
    if [[ -n "$GPG_KEY_ID" ]]; then
        info "2. LLAVE GPG PÚBLICA (para agregar a GitHub):"
        echo ""
        info "ID de la llave GPG: $(c primary)$GPG_KEY_ID$(cr)"
        echo ""
        
        # Exportar llave GPG a archivo temporal
        local gpg_temp=$(mktemp)
        if gpg --armor --export "$GPG_KEY_ID" > "$gpg_temp" 2>/dev/null; then
            show_separator
            cat "$gpg_temp"
            show_separator
            echo ""
            
            # Ofrecer copiar GPG al portapapeles
            if ask_yes_no "¿Deseas copiar la llave GPG al portapapeles?"; then
                copy_to_clipboard "$gpg_temp"
            fi
        else
            error "No se pudo exportar la llave GPG"
        fi
        
        # Limpiar archivo temporal
        rm -f "$gpg_temp"
    else
        info "2. LLAVE GPG: No se generó (opcional)"
    fi
    
    echo ""
    show_separator
    info "Próximos pasos:"
    echo ""
    echo "  $(c bold)$(c warning)Para la llave SSH:$(cr)"
    echo "    1. Ve a: $(c primary)https://github.com/settings/ssh/new$(cr)"
    echo "    2. Pega la llave SSH mostrada arriba"
    echo "    3. Dale un título descriptivo"
    echo ""
    
    if [[ -n "$GPG_KEY_ID" ]]; then
        echo "  $(c bold)$(c warning)Para la llave GPG:$(cr)"
        echo "    1. Ve a: $(c primary)https://github.com/settings/gpg/new$(cr)"
        echo "    2. Pega la llave GPG mostrada arriba"
        echo "    3. Tus commits aparecerán como 'Verified' ✓"
        echo ""
    fi
    
    show_separator
}

# Función para guardar llaves en archivos
save_keys_to_files() {
    show_separator
    printf "%b\n" "$(c bold)$(c text)💾 GUARDANDO LLAVES EN ARCHIVOS$(cr)"
    show_separator

    local output_dir="$SCRIPT_DIR/keys-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"

    # Guardar llave SSH
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        cp "$HOME/.ssh/id_ed25519.pub" "$output_dir/ssh_public_key.txt"
        success "Llave SSH guardada en: $output_dir/ssh_public_key.txt"
    fi

    # Guardar llave GPG
    if [[ -n "$GPG_KEY_ID" ]]; then
        gpg --armor --export "$GPG_KEY_ID" > "$output_dir/gpg_public_key.txt"
        success "Llave GPG guardada en: $output_dir/gpg_public_key.txt"
    fi

    # Crear archivo de información
    cat > "$output_dir/key_info.txt" << EOF
INFORMACIÓN DE LLAVES GENERADAS
===============================

Fecha de generación: $(date)
Usuario: $USER_NAME
Email: $USER_EMAIL
GPG Key ID: $GPG_KEY_ID

INSTRUCCIONES:
1. Agrega la llave SSH a tu cuenta de GitHub en: https://github.com/settings/ssh/new
2. Agrega la llave GPG a tu cuenta de GitHub en: https://github.com/settings/gpg/new
3. Las llaves están guardadas en este directorio para referencia futura

NOTA: Mantén estos archivos seguros y no los compartas públicamente.
EOF

    success "Información guardada en: $output_dir/key_info.txt"
    info "Directorio de salida: $output_dir"
}


# Funciones para subida automática a GitHub
ensure_github_cli_ready() {
    local early_mode="${1:-false}"
    
    # Verificar si gh está instalado
    if ! command -v gh &> /dev/null; then
        show_separator
        printf "%b\n" "$(c bold)$(c warning)⚠️  GITHUB CLI NO ESTÁ INSTALADO$(cr)"
        show_separator
        echo ""
        
        if [[ "$early_mode" == "early" ]]; then
            error "El flag --auto-upload requiere que GitHub CLI (gh) esté instalado y configurado."
            echo ""
            info "GitHub CLI es necesario para subir automáticamente las llaves SSH y GPG a tu cuenta de GitHub."
            echo ""
        else
            info "Para subir llaves automáticamente a GitHub, necesitas instalar GitHub CLI (gh)."
            echo ""
        fi
        
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            if ask_yes_no "¿Deseas que el script intente instalar GitHub CLI automáticamente?" "y"; then
                local os_type
                os_type=$(detect_os)
                
                case "$os_type" in
                    arch|manjaro|endeavouros|garuda)
                        GH_INSTALL_ATTEMPTED=true
                        if auto_install_dependencies "$os_type" github-cli; then
                            success "GitHub CLI instalado correctamente"
                            echo ""
                        else
                            error "No se pudo instalar GitHub CLI automáticamente"
                            show_manual_gh_install_instructions "$os_type"
                            if [[ "$early_mode" == "early" ]]; then
                                echo ""
                                error "No se puede continuar sin GitHub CLI instalado."
                                echo ""
                                info "Instala GitHub CLI manualmente y vuelve a ejecutar el script con $(c primary)--auto-upload$(cr)"
                                exit 1
                            fi
                            return 1
                        fi
                        ;;
                    ubuntu|debian|linuxmint|pop)
                        GH_INSTALL_ATTEMPTED=true
                        if auto_install_dependencies "$os_type" gh; then
                            success "GitHub CLI instalado correctamente"
                            echo ""
                        else
                            error "No se pudo instalar GitHub CLI automáticamente"
                            show_manual_gh_install_instructions "$os_type"
                            if [[ "$early_mode" == "early" ]]; then
                                echo ""
                                error "No se puede continuar sin GitHub CLI instalado."
                                echo ""
                                info "Instala GitHub CLI manualmente y vuelve a ejecutar el script con $(c primary)--auto-upload$(cr)"
                                exit 1
                            fi
                            return 1
                        fi
                        ;;
                    *)
                        show_manual_gh_install_instructions "$os_type"
                        if [[ "$early_mode" == "early" ]]; then
                            echo ""
                            error "No se puede continuar sin GitHub CLI instalado."
                            echo ""
                            info "Instala GitHub CLI manualmente y vuelve a ejecutar el script con $(c primary)--auto-upload$(cr)"
                            exit 1
                        fi
                        return 1
                        ;;
                esac
            else
                show_manual_gh_install_instructions "$(detect_os)"
                if [[ "$early_mode" == "early" ]]; then
                    echo ""
                    error "El flag --auto-upload requiere GitHub CLI instalado y configurado."
                    echo ""
                    info "El script no puede continuar sin GitHub CLI. Instálalo y vuelve a ejecutar con $(c primary)--auto-upload$(cr)"
                    exit 1
                fi
                return 1
            fi
        else
            # Modo no-interactivo: mostrar instrucciones claras
            show_manual_gh_install_instructions "$(detect_os)"
            if [[ "$early_mode" == "early" ]]; then
                echo ""
                error "El flag --auto-upload requiere que GitHub CLI (gh) esté instalado y autenticado."
                echo ""
                info "En modo no-interactivo, debes instalar y autenticar GitHub CLI antes de ejecutar este script:"
                echo ""
                echo "  1. Instala GitHub CLI:"
                echo "     $(c primary)sudo pacman -S github-cli$(cr)  # Arch Linux"
                echo "     $(c primary)sudo apt install gh$(cr)        # Ubuntu/Debian"
                echo ""
                echo "  2. Autentica GitHub CLI:"
                echo "     $(c primary)gh auth login$(cr)"
                echo ""
                echo "  3. Vuelve a ejecutar este script con $(c primary)--auto-upload$(cr)"
                echo ""
                exit 1
            fi
            return 1
        fi
    fi

    # Verificar autenticación
    local auth_status
    auth_status=$(gh auth status 2>&1)
    local auth_exit_code=$?

    if [[ $auth_exit_code -eq 0 ]]; then
        return 0
    fi

    # No está autenticado
    show_separator
    printf "%b\n" "$(c bold)$(c warning)⚠️  GITHUB CLI NO ESTÁ AUTENTICADO$(cr)"
    show_separator
    echo ""
    
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        if [[ "$early_mode" == "early" ]]; then
            error "El flag --auto-upload requiere que GitHub CLI (gh) esté autenticado."
            echo ""
            info "GitHub CLI está instalado pero necesita autenticación para subir automáticamente las llaves SSH y GPG a tu cuenta de GitHub."
            echo ""
        else
            info "GitHub CLI está instalado pero requiere autenticación para subir llaves."
            echo ""
        fi
        info "Opciones de autenticación:"
        echo "  1. $(c primary)gh auth login$(cr) - Autenticación interactiva (recomendada)"
        echo "  2. $(c primary)gh auth login --with-token$(cr) - Autenticación con token"
        echo ""
        
        if ask_yes_no "¿Deseas ejecutar 'gh auth login' ahora?" "y"; then
            echo ""
            info "Ejecutando autenticación de GitHub CLI..."
            echo "$(c muted)Nota: Sigue las instrucciones en pantalla para completar la autenticación.$(cr)"
            echo ""
            
            if gh auth login; then
                echo ""
                success "✓ Autenticación de GitHub CLI completada exitosamente"
                return 0
            else
                echo ""
                error "La autenticación de GitHub CLI falló"
                echo ""
                if [[ "$early_mode" == "early" ]]; then
                    error "No se puede continuar sin GitHub CLI autenticado."
                    echo ""
                    info "Autentica GitHub CLI manualmente con $(c primary)gh auth login$(cr) y vuelve a ejecutar el script con $(c primary)--auto-upload$(cr)"
                    exit 1
                fi
                info "Puedes autenticarte manualmente más tarde con: $(c primary)gh auth login$(cr)"
                return 1
            fi
        else
            echo ""
            if [[ "$early_mode" == "early" ]]; then
                error "El flag --auto-upload requiere GitHub CLI autenticado."
                echo ""
                info "El script no puede continuar sin autenticación. Autentica GitHub CLI con $(c primary)gh auth login$(cr) y vuelve a ejecutar con $(c primary)--auto-upload$(cr)"
                exit 1
            fi
            warning "Autenticación omitida. Las llaves no se subirán automáticamente."
            echo ""
            info "Para autenticarte más tarde, ejecuta: $(c primary)gh auth login$(cr)"
            return 1
        fi
    else
        # Modo no-interactivo: instrucciones claras
        if [[ "$early_mode" == "early" ]]; then
            error "El flag --auto-upload requiere que GitHub CLI (gh) esté autenticado."
            echo ""
            info "GitHub CLI está instalado pero necesita autenticación para subir automáticamente las llaves SSH y GPG a tu cuenta de GitHub."
            echo ""
            info "En modo no-interactivo, debes autenticar GitHub CLI antes de ejecutar este script:"
            echo ""
            echo "  1. Autentica GitHub CLI manualmente:"
            echo "     $(c primary)gh auth login$(cr)"
            echo ""
            echo "  2. O usa un token de GitHub:"
            echo "     $(c primary)echo 'tu_token_github' | gh auth login --with-token$(cr)"
            echo ""
            echo "  3. Vuelve a ejecutar este script con $(c primary)--auto-upload$(cr)"
            echo ""
            exit 1
        else
            info "GitHub CLI está instalado pero requiere autenticación para subir llaves."
            echo ""
            printf "%b\n" "$(c warning)Para habilitar la subida automática en modo no-interactivo:$(cr)"
            echo ""
            echo "  1. Autentica GitHub CLI manualmente:"
            echo "     $(c primary)gh auth login$(cr)"
            echo ""
            echo "  2. O usa un token de GitHub:"
            echo "     $(c primary)echo 'tu_token_github' | gh auth login --with-token$(cr)"
            echo ""
            echo "  3. Luego vuelve a ejecutar este script con $(c primary)--auto-upload$(cr)"
            echo ""
            warning "Omitiendo subida automática. Las llaves se guardarán localmente."
            return 1
        fi
    fi
}

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
        *)
            printf "%b\n" "$(c warning)Instalación genérica:$(cr)"
            echo "  Visita: $(c primary)https://cli.github.com$(cr)"
            ;;
    esac
    
    echo ""
    info "Después de instalar, vuelve a ejecutar este script con $(c primary)--auto-upload$(cr)"
    echo ""
}

upload_ssh_key_to_github() {
    local ssh_key_file="$HOME/.ssh/id_ed25519.pub"
    if [[ ! -f "$ssh_key_file" ]]; then
        warning "No se encontró la llave SSH pública para subirla a GitHub."
        return 1
    fi

    local title="${SSH_KEY_TITLE:-$(hostname)-$(date +%Y%m%d_%H%M)}"
    if gh ssh-key add "$ssh_key_file" --title "$title" &>/dev/null; then
        success "Llave SSH subida a GitHub automáticamente (${title})"
        SSH_KEY_UPLOADED=true
        return 0
    else
        warning "No se pudo subir la llave SSH automáticamente."
        return 1
    fi
}

upload_gpg_key_to_github() {
    if [[ -z "$GPG_KEY_ID" ]]; then
        info "No hay llave GPG nueva para subir."
        return 1
    fi

    # Verificar y solicitar permisos OAuth necesarios para GPG
    local scope_check_output
    scope_check_output=$(gh gpg-key list 2>&1 || true)
    
    if echo "$scope_check_output" | grep -qi "insufficient OAuth scopes\|write:gpg_key"; then
        show_separator
        warning "GitHub CLI necesita permisos adicionales para gestionar llaves GPG"
        show_separator
        echo ""
        info "Se requiere el scope $(c primary)write:gpg_key$(cr) para subir llaves GPG a GitHub."
        echo ""
        
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            if ask_yes_no "¿Deseas actualizar los permisos de GitHub CLI ahora?" "y"; then
                echo ""
                info "Actualizando permisos de GitHub CLI..."
                echo "$(c muted)Nota: Es posible que se abra tu navegador para autorizar los permisos adicionales.$(cr)"
                echo ""
                
                if gh auth refresh -s write:gpg_key; then
                    echo ""
                    success "✓ Permisos actualizados exitosamente"
                    echo ""
                else
                    echo ""
                    error "No se pudieron actualizar los permisos"
                    echo ""
                    info "Puedes actualizar los permisos manualmente ejecutando:"
                    echo "  $(c primary)gh auth refresh -s write:gpg_key$(cr)"
                    return 1
                fi
            else
                echo ""
                warning "Permisos no actualizados. No se podrá subir la llave GPG automáticamente."
                echo ""
                info "Para subir la llave GPG más tarde, ejecuta:"
                echo "  $(c primary)gh auth refresh -s write:gpg_key$(cr)"
                echo "  $(c primary)gh gpg-key add <archivo-llave-gpg>$(cr)"
                return 1
            fi
        else
            # Modo no-interactivo
            echo ""
            warning "GitHub CLI requiere permisos adicionales para gestionar llaves GPG."
            echo ""
            info "En modo no-interactivo, actualiza los permisos manualmente:"
            echo "  $(c primary)gh auth refresh -s write:gpg_key$(cr)"
            echo ""
            info "Luego vuelve a ejecutar este script."
            return 1
        fi
    fi

    # Verificar si la llave GPG ya existe en GitHub
    local existing_keys
    existing_keys=$(gh gpg-key list 2>/dev/null | grep -i "$GPG_KEY_ID" || true)
    if [[ -n "$existing_keys" ]]; then
        info "La llave GPG $(c primary)$GPG_KEY_ID$(cr) ya existe en tu cuenta de GitHub."
        GPG_KEY_UPLOADED=true
        return 0
    fi

    local gpg_temp
    gpg_temp=$(mktemp)
    if ! gpg --armor --export "$GPG_KEY_ID" > "$gpg_temp" 2>/dev/null; then
        warning "No se pudo exportar la llave GPG para subirla a GitHub."
        rm -f "$gpg_temp"
        return 1
    fi

    # Intentar subir la llave GPG y capturar el error real
    local gh_output
    local gh_exit_code
    gh_output=$(gh gpg-key add "$gpg_temp" 2>&1)
    gh_exit_code=$?

    if [[ $gh_exit_code -eq 0 ]]; then
        success "Llave GPG subida a GitHub automáticamente"
        GPG_KEY_UPLOADED=true
        rm -f "$gpg_temp"
        return 0
    else
        # Verificar si el error es porque la llave ya existe (puede haber cambiado entre la verificación y la subida)
        if echo "$gh_output" | grep -qi "already exists\|duplicate\|already registered"; then
            info "La llave GPG $(c primary)$GPG_KEY_ID$(cr) ya existe en tu cuenta de GitHub."
            GPG_KEY_UPLOADED=true
            rm -f "$gpg_temp"
            return 0
        else
            warning "No se pudo subir la llave GPG automáticamente."
            if [[ -n "$gh_output" ]]; then
                printf "%b\n" "$(c muted)Error: ${gh_output}$(cr)"
            fi
            rm -f "$gpg_temp"
            return 1
        fi
    fi
}

maybe_upload_keys() {
    local should_upload=false

    # Determinar si debemos intentar subir
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        if [[ "$AUTO_UPLOAD_KEYS" == "true" ]]; then
            should_upload=true
        else
            if ask_yes_no "¿Deseas subir automáticamente las llaves a GitHub usando GitHub CLI?" "y"; then
                should_upload=true
            fi
        fi
    else
        # En modo no-interactivo, solo subir si el flag --auto-upload está activo
        if [[ "$AUTO_UPLOAD_KEYS" == "true" ]]; then
            should_upload=true
        else
            info "El flag --auto-upload no está activo. Omitiendo subida automática."
            return
        fi
    fi

    if [[ "$should_upload" != "true" ]]; then
        return
    fi

    # Verificación de seguridad (la verificación principal ya se hizo al inicio)
    # Solo verificamos que gh siga autenticado, pero no salimos si falla (ya es tarde)
    if ! ensure_github_cli_ready; then
        echo ""
        warning "GitHub CLI no está disponible. No se pudieron subir las llaves automáticamente."
        info "Las llaves se guardarán localmente para que puedas subirlas manualmente."
        echo ""
        return
    fi

    # Intentar subir llaves
    echo ""
    show_separator
    printf "%b\n" "$(c bold)$(c success)🚀 SUBIENDO LLAVES A GITHUB$(cr)"
    show_separator
    echo ""

    local ssh_uploaded=false
    local gpg_uploaded=false

    if upload_ssh_key_to_github; then
        ssh_uploaded=true
    fi

    if [[ -n "$GPG_KEY_ID" ]]; then
        if upload_gpg_key_to_github; then
            gpg_uploaded=true
        fi
    fi

    echo ""
    show_separator
    
    if [[ "$ssh_uploaded" == "true" ]] || [[ "$gpg_uploaded" == "true" ]]; then
        success "✓ Subida de llaves completada"
        echo ""
        if [[ "$ssh_uploaded" == "true" ]]; then
            info "  • Llave SSH: $(c success)Subida exitosamente$(cr)"
        fi
        if [[ "$gpg_uploaded" == "true" ]]; then
            info "  • Llave GPG: $(c success)Subida exitosamente$(cr)"
        fi
    else
        warning "No se pudieron subir las llaves automáticamente"
        echo ""
        info "Puedes subirlas manualmente desde:"
        echo "  $(c primary)https://github.com/settings/ssh/new$(cr) (SSH)"
        echo "  $(c primary)https://github.com/settings/gpg/new$(cr) (GPG)"
    fi
    
    show_separator
    echo ""
}

# Función para test de conectividad
test_github_connection() {
    show_separator
    printf "%b\n" "$(c bold)$(c text)🧪 PRUEBA DE CONECTIVIDAD$(cr)"
    show_separator

    if ask_yes_no "¿Deseas probar la conexión SSH con GitHub ahora?"; then
        info "Probando conexión SSH con GitHub..."

        # Test SSH connection
        ssh_output=$(ssh -T git@github.com 2>&1)
        ssh_exit_code=$?

        if [[ $ssh_exit_code -eq 1 ]] && [[ $ssh_output == *"successfully authenticated"* ]]; then
            success "¡Conexión SSH con GitHub exitosa!"
            printf "%b\n" "$(c success)$ssh_output$(cr)"
        else
            warning "La conexión SSH falló o está pendiente de configuración"
            printf "%b\n" "$(c warning)Salida: $ssh_output$(cr)"
            printf "%b\n" "$(c primary)Asegúrate de haber agregado la llave SSH a tu cuenta de GitHub$(cr)"
        fi
    fi
}


# Función para mostrar instrucciones finales
show_final_instructions() {
    echo ""
    show_separator
    printf "%b\n" "$(c bold)$(c secondary)╔══════════════════════════════════════════════════════════════════════════════╗$(cr)"
    printf "%b\n" "$(c bold)$(c secondary)║$(cr)  $(c bold)$(c text)📚  INSTRUCCIONES FINALES PARA GITHUB$(cr)                                    $(c bold)$(c secondary)║$(cr)"
    printf "%b\n" "$(c bold)$(c secondary)╚══════════════════════════════════════════════════════════════════════════════╝$(cr)"
    echo ""

    if [[ "$SSH_KEY_UPLOADED" == true ]] || [[ "$GPG_KEY_UPLOADED" == true ]]; then
        info "Subida automática: $(c success)SSH $( [[ "$SSH_KEY_UPLOADED" == true ]] && echo '✓' || echo '✗' )$(cr)  |  $(c success)GPG $( [[ "$GPG_KEY_UPLOADED" == true ]] && echo '✓' || echo '✗' )$(cr)"
        echo ""
    fi

    # Solo mostrar pasos de agregar llaves si no se subieron automáticamente
    if [[ "$SSH_KEY_UPLOADED" != true ]]; then
        printf "%b\n" "$(c bold)$(c accent)🔐 PASO 1: AGREGAR LLAVE SSH$(cr)"
        printf "%b\n" "$(c muted)$(cr)   ├─ $(c primary)URL:$(cr) $(c bold)https://github.com/settings/ssh/new$(cr)"
        printf "%b\n" "$(c muted)$(cr)   ├─ $(c primary)Título sugerido:$(cr) $(hostname)-$(date +%Y%m%d)"
        printf "%b\n" "$(c muted)$(cr)   └─ $(c warning)Pega la llave SSH pública que se mostró arriba$(cr)"
        echo ""
    else
        printf "%b\n" "$(c bold)$(c accent)🔐 PASO 1: LLAVE SSH$(cr)"
        printf "%b\n" "$(c muted)$(cr)   └─ $(c success)✓ Ya agregada automáticamente a tu cuenta de GitHub$(cr)"
        echo ""
    fi
    
    if [[ "$GPG_KEY_UPLOADED" != true ]]; then
        if [[ -n "$GPG_KEY_ID" ]]; then
            printf "%b\n" "$(c bold)$(c accent)🔑 PASO 2: AGREGAR LLAVE GPG (Opcional)$(cr)"
            printf "%b\n" "$(c muted)$(cr)   ├─ $(c primary)URL:$(cr) $(c bold)https://github.com/settings/gpg/new$(cr)"
            printf "%b\n" "$(c muted)$(cr)   ├─ $(c warning)Pega la llave GPG pública que se mostró arriba$(cr)"
            printf "%b\n" "$(c muted)$(cr)   └─ $(c muted)Esto permitirá que tus commits aparezcan como 'Verified'$(cr)"
            echo ""
        fi
    else
        printf "%b\n" "$(c bold)$(c accent)🔑 PASO 2: LLAVE GPG$(cr)"
        printf "%b\n" "$(c muted)$(cr)   └─ $(c success)✓ Ya agregada automáticamente a tu cuenta de GitHub$(cr)"
        echo ""
    fi
    
    # Ajustar número de paso según si se mostraron los pasos anteriores
    local paso_num=3
    if [[ "$SSH_KEY_UPLOADED" == true ]] && [[ "$GPG_KEY_UPLOADED" == true ]]; then
        paso_num=1
    elif [[ "$SSH_KEY_UPLOADED" == true ]] || [[ "$GPG_KEY_UPLOADED" == true ]]; then
        paso_num=2
    fi
    
    printf "%b\n" "$(c bold)$(c accent)✅ PASO ${paso_num}: VERIFICAR CONFIGURACIÓN$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c primary)Probar SSH:$(cr) $(c bold)$(c success)ssh -T git@github.com$(cr)"
    printf "%b\n" "$(c muted)$(cr)   │  $(c muted)→ Deberías ver: 'Hi username! You've successfully authenticated...'$(cr)"
    printf "%b\n" "$(c muted)$(cr)   └─ $(c primary)Probar GPG:$(cr) $(c muted)Haz un commit y verifica el badge 'Verified' en GitHub$(cr)"
    echo ""
    
    ((paso_num++))
    printf "%b\n" "$(c bold)$(c accent)📁 PASO ${paso_num}: ARCHIVOS GENERADOS$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)~/.gitconfig$(cr)     $(c muted)→ Configuración profesional de Git$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)~/.gitmessage$(cr)    $(c muted)→ Plantilla para mensajes de commit$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)~/.ssh/config$(cr)    $(c muted)→ Configuración SSH optimizada$(cr)"
    printf "%b\n" "$(c muted)$(cr)   └─ $(c bold)$(c primary)~/.ssh/id_ed25519$(cr) $(c muted)→ Tu llave SSH privada (¡nunca la compartas!)$(cr)"
    echo ""
    
    ((paso_num++))
    printf "%b\n" "$(c bold)$(c accent)🔐 PASO ${paso_num}: CREDENTIAL MANAGER$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c success)✓$(cr) Git Credential Manager configurado"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c muted)No se solicitará contraseña en cada operación$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c warning)En el primer push, se abrirá el navegador para autenticar$(cr)"
    printf "%b\n" "$(c muted)$(cr)   └─ $(c primary)Pre-autenticar (opcional):$(cr) $(c bold)$(c success)git-credential-manager github login$(cr)"
    echo ""
    
    printf "%b\n" "$(c bold)$(c accent)💡 COMANDOS ÚTILES:$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c primary)Ver configuración Git:$(cr)    $(c bold)git config --list --show-origin$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c primary)Ver llaves SSH:$(cr)          $(c bold)ls -la ~/.ssh/$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c primary)Ver llaves GPG:$(cr)          $(c bold)gpg --list-secret-keys --keyid-format=long$(cr)"
    printf "%b\n" "$(c muted)$(cr)   └─ $(c primary)Ver logs del script:$(cr)     $(c bold)cat $LOG_FILE$(cr)"
    echo ""
    
    show_separator
    printf "%b\n" "$(c bold)$(c success)✨ ¡CONFIGURACIÓN COMPLETADA EXITOSAMENTE! ✨$(cr)"
    printf "%b\n" "$(c accent)Tu entorno de desarrollo Git está configurado de forma profesional.$(cr)"
    printf "%b\n" "$(c muted)Ahora puedes trabajar con GitHub con autenticación SSH y commits firmados.$(cr)"
    show_separator
    echo ""
}


# =============================================================================
# FUNCION PRINCIPAL
# =============================================================================

# Función para parsear argumentos de línea de comandos
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

main() {
    # Parsear argumentos de línea de comandos
    parse_arguments "$@"
    
    initial_checks
    welcome
    
    # Verificación temprana de GitHub CLI si --auto-upload está activo
    if [[ "$AUTO_UPLOAD_KEYS" == "true" ]]; then
        if ! ensure_github_cli_ready "early"; then
            exit 1
        fi
    fi
    
    # Crear archivo de log
    mkdir -p "$(dirname "$LOG_FILE")"
    log "=== INICIO DE CONFIGURACIÓN DE GIT ==="

    # Inicializar variables de progreso
    TOTAL_STEPS=9
    CURRENT_STEP=0

    # Verificar dependencias
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! check_dependencies; then
        exit 1
    fi

    # Configurar directorios
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! setup_directories; then
        exit 1
    fi

    # Hacer backup de llaves existentes
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    backup_existing_keys

    # Recopilar información del usuario
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! collect_user_info; then
        exit 1
    fi

    # Preguntar sobre GPG antes del preview para incluirlo en el resumen
    GENERATE_GPG="false"
    
    # Verificar si ya existe una llave GPG para este email
    local existing_gpg_key_id=""
    if command -v gpg &> /dev/null; then
        existing_gpg_key_id=$(gpg --list-secret-keys --keyid-format=long "$USER_EMAIL" 2>/dev/null | grep 'sec' | head -n1 | sed 's/.*\/\([A-Z0-9]*\).*/\1/' || echo "")
    fi
    
    if [[ -n "$existing_gpg_key_id" ]]; then
        # Si ya existe una llave GPG, usarla automáticamente
        GENERATE_GPG="true"
        GPG_KEY_ID="$existing_gpg_key_id"
        log "Llave GPG existente detectada: $GPG_KEY_ID"
    elif [[ "$INTERACTIVE_MODE" == "true" ]] && [[ "${AUTO_YES:-false}" != "true" ]]; then
        # Modo interactivo: preguntar al usuario
        if ask_yes_no "¿Deseas generar también una llave GPG para firmar commits?" "n"; then
            GENERATE_GPG="true"
        fi
    elif [[ "$INTERACTIVE_MODE" == "false" ]] || [[ "${AUTO_YES:-false}" == "true" ]]; then
        # En modo no-interactivo o auto-yes, generar GPG por defecto si no existe
        GENERATE_GPG="true"
    fi

    # Mostrar resumen de cambios antes de aplicar
    if ! show_changes_summary; then
        exit 0
    fi

    # Generar llave SSH
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! generate_ssh_key; then
        exit 1
    fi

    # Generar o usar llave GPG (ya se preguntó antes del preview)
    if [[ "$GENERATE_GPG" == "true" ]]; then
        ((CURRENT_STEP++))
        show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
        
        # Si ya tenemos el ID de una llave existente, no generar nueva
        if [[ -n "$GPG_KEY_ID" ]]; then
            info "Usando llave GPG existente: $GPG_KEY_ID"
            success "Llave GPG configurada correctamente"
        else
            generate_gpg_key
        fi
    fi

    # Configurar Git
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! configure_git; then
        exit 1
    fi

    # Crear configuración ssh-agent
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    create_ssh_agent_script

    # Mostrar llaves generadas
    display_keys
    maybe_upload_keys

    # Guardar llaves en archivos
    if ask_yes_no "¿Deseas guardar las llaves en archivos para referencia futura?"; then
        save_keys_to_files
    fi

    # Probar conectividad
    test_github_connection

    # Mostrar instrucciones finales
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    show_final_instructions

    log "=== FIN DE SESIÓN EXITOSA ==="

    echo ""
    success "¡Script completado exitosamente!"
    info "Log guardado en: $LOG_FILE"


}

# Función para manejo de señales
cleanup() {
    echo ""
    warning "Script interrumpido por el usuario"
    log "Script interrumpido por señal"
    exit 130
}

# Configurar manejo de señales
trap cleanup SIGINT SIGTERM

# Ejecutar función principal
main "$@"
