#!/bin/bash
#  ██████╗ ██╗ ██████╗███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗
#  ██╔══██╗██║██╔════╝██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
#  ██████╔╝██║██║     █████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
#  ██╔══██╗██║██║     ██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
#  ██║  ██║██║╚██████╗███████╗    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
#  ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
#
#	Author	-	25asab015
#	Repo	-	https://github.com/25asab015/dotfiles
#	Last updated	-	24.03.2025 08:58:16
#
#	gitconfig - Script to configure git
#
# Copyright (C) 2021-2025 25asab015 <25asab015@ujmd.edu.sv>
# Licensed under GPL-3.0 license

# Colors
CRE=$(tput setaf 1)    # Red
CYE=$(tput setaf 3)    # Yellow
CGR=$(tput setaf 2)    # Green
CBL=$(tput setaf 4)    # Blue
CMA=$(tput setaf 5)    # Magenta
CCY=$(tput setaf 6)    # Cyan
CWH=$(tput setaf 7)    # White
BLD=$(tput bold)       # Bold
DIM=$(tput dim)        # Dim
CNC=$(tput sgr0)       # Reset colors

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
    printf "%b\n" "${CBL}─────────────────────────────────────────────────────────────────────────────${CNC}"
}

# Función para mostrar mensajes de éxito
success() {
    printf "%b\n" "${BLD}${CGR}✅ $1${CNC}"
    log "SUCCESS: $1"
}

# Función para mostrar mensajes de error
error() {
    printf "%b\n" "${BLD}${CRE}❌ ERROR: $1${CNC}"
    log "ERROR: $1"
}

# Función para mostrar advertencias
warning() {
    printf "%b\n" "${BLD}${CYE}⚠️  ADVERTENCIA: $1${CNC}"
    log "WARNING: $1"
}

# Función para mostrar información
info() {
    printf "%b\n" "${BLD}${CBL}ℹ️  $1${CNC}"
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
    text="$1"
    printf "%b" "
               %%%
        %%%%%//%%%%%
      %%************%%%
  (%%//############*****%%
 %%%%**###&&&&&&&&&###**//
 %%(**##&&&#########&&&##**
 %%(**##*****#####*****##**%%%
 %%(**##     *****     ##**
   //##   @@**   @@   ##//
     ##     **###     ##
     #######     #####//
       ###**&&&&&**###
       &&&         &&&
       &&&////   &&
          &&//@@@**
            ..***

   ${BLD}${CRE}[ ${CYE}${text} ${CRE}]${CNC}\n\n"
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
    
    printf "%b" "${BLD}${CBL}${message}${CNC} "
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r%b %s " "${BLD}${CBL}${message}${CNC}" "${CYE}${spinstr:0:1}${CNC}"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    
    wait "$pid"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf "\r%b %s\n" "${BLD}${CBL}${message}${CNC}" "${CGR}✓${CNC}"
    else
        printf "\r%b %s\n" "${BLD}${CBL}${message}${CNC}" "${CRE}✗${CNC}"
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
    
    printf "\r${BLD}${CCY}[%3d%%]${CNC} ${CGR}%s${CNC}${DIM}%s${CNC} ${CBL}%s${CNC}" \
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
                        error "Los siguientes paquetes no se pudieron instalar:${CYE}$retry_failed${CNC}"
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
                        warning "Los siguientes paquetes de AUR fallaron:${CYE}$aur_failed${CNC}"
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
                        warning "Los siguientes paquetes de AUR fallaron:${CYE}$aur_failed${CNC}"
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
                        error "Los siguientes paquetes no se pudieron instalar:${CYE}$retry_failed${CNC}"
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
                    error "Los siguientes paquetes no se pudieron instalar:${CYE}$retry_failed${CNC}"
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
        printf "%b\n" "${BLD}${CYE}$retry_failed${CNC}"
        echo ""
        info "Creando archivo ${CBL}$missing_file${CNC} con la lista de paquetes fallidos..."
        
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
        
        success "Archivo creado: ${CBL}$missing_file${CNC}"
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

    printf "%b" "${BLD}${CGR}Este script te ayudará a dejar lista tu configuración de Git y GitHub:${CNC}

  ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Generar y/o registrar tu clave SSH para GitHub
  ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Generar una clave GPG para firmar tus commits
  ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Configurar tu archivo ${CBL}.gitconfig${CNC} con nombre, email y preferencias recomendadas
  ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Instalar y/o autenticar ${CBL}GitHub CLI (gh)${CNC}
  ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Instalar y configurar ${CBL}GitKraken CLI (gk)${CNC}

${BLD}${CGR}[${CRE}!${CGR}]${CNC} ${BLD}${CRE}Este script NO realiza cambios peligrosos en tu sistema${CNC}
${BLD}${CGR}[${CRE}!${CGR}]${CNC} ${BLD}${CRE}Solo edita configuraciones relacionadas a Git y GitHub en tu usuario${CNC}

"

    # Mostrar información sobre modo no-interactivo si está activo
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        echo ""
        printf "%b\n" "${BLD}${CCY}ℹ️  MODO NO-INTERACTIVO ACTIVO${CNC}"
        if [[ -n "$USER_EMAIL" ]] && [[ -n "$USER_NAME" ]]; then
            printf "%b\n" "${DIM}   Usando: ${CBL}USER_EMAIL=${USER_EMAIL}${DIM}, ${CBL}USER_NAME=${USER_NAME}${CNC}"
        else
            printf "%b\n" "${CYE}   ⚠️  ADVERTENCIA: USER_EMAIL y USER_NAME deben estar definidos${CNC}"
            printf "%b\n" "${DIM}   Ejemplo: ${CBL}USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive${CNC}"
        fi
        echo ""
    fi

    ask_yes_no "¿Deseas continuar?" "n" "true"
}

# Función para mostrar ayuda
show_help() {
    printf "%b\n" "${BLD}${CMA}╔══════════════════════════════════════════════════════════════════════════════╗${CNC}"
    printf "%b\n" "${BLD}${CMA}║${CNC}  ${BLD}${CWH}                    GITCONFIG.SH - CONFIGURADOR DE GIT                        ${CNC}${BLD}${CMA}║${CNC}"
    printf "%b\n" "${BLD}${CMA}╚══════════════════════════════════════════════════════════════════════════════╝${CNC}"
    printf "%b\n" "${BLD}${CCY}📋 DESCRIPCIÓN:${CNC} ${DIM}Script interactivo para configurar Git, SSH, GPG y GitHub CLI${CNC}"
    printf "%b\n" "${BLD}${CCY}🚀 USO:${CNC} ${CBL}./gitconfig.sh${CNC} ${DIM}[OPCIONES]${CNC}"
    echo ""
    printf "%b\n" "${BLD}${CCY}⚙️  OPCIONES:${CNC}"
    printf "%b\n" "   ${CGR}-h, --help${CNC}              ${DIM}Mostrar esta ayuda${CNC}"
    printf "%b\n" "   ${CGR}--non-interactive${CNC}        ${DIM}Modo no-interactivo (requiere USER_EMAIL y USER_NAME)${CNC}"
    printf "%b\n" "   ${CGR}--auto-upload${CNC}            ${DIM}Subir llaves a GitHub usando gh CLI (requiere autenticación previa)${CNC}"
    echo ""
    printf "%b\n" "${BLD}${CCY}🔧 VARIABLES DE ENTORNO:${CNC}"
    printf "%b\n" "   ${CBL}INTERACTIVE_MODE${CNC}         ${DIM}true|false${CNC} ${CYE}(default: true)${CNC} - Controla si el script espera entrada del usuario${CNC}"
    printf "%b\n" "   ${CBL}USER_EMAIL${CNC} ${CYE}(requerido en modo no-interactivo)${CNC} - Email de GitHub para configurar Git${CNC}"
    printf "%b\n" "   ${CBL}USER_NAME${CNC} ${CYE}(requerido en modo no-interactivo)${CNC} - Nombre completo para configurar Git${CNC}"
    echo ""
    printf "%b\n" "${BLD}${CCY}💡 EJEMPLOS:${CNC}"
    printf "%b\n" "   ${DIM}# Interactivo:${CNC} ${CGR}./gitconfig.sh${CNC}"
    printf "%b\n" "   ${DIM}# No-interactivo (requiere variables):${CNC}"
    printf "%b\n" "   ${CGR}USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive${CNC}"
    printf "%b\n" "   ${DIM}# No-interactivo + auto-upload:${CNC}"
    printf "%b\n" "   ${CGR}USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive --auto-upload${CNC}"
    echo ""
    printf "%b\n" "${BLD}${CCY}⚠️  NOTAS IMPORTANTES:${CNC}"
    printf "%b\n" "   ${CYE}•${CNC} ${DIM}En modo no-interactivo, ${CBL}USER_EMAIL${DIM} y ${CBL}USER_NAME${DIM} son ${CRE}OBLIGATORIOS${DIM}${CNC}"
    printf "%b\n" "   ${CYE}•${CNC} ${DIM}Las preguntas sí/no usan sus valores por defecto (no existe auto-confirmación de 'sí')${CNC}"
    printf "%b\n" "   ${CYE}•${CNC} ${DIM}Las respuestas automáticas se registran en el archivo de log${CNC}"
    printf "%b\n" "   ${CYE}•${CNC} ${DIM}El modo interactivo es el comportamiento por defecto${CNC}"
    printf "%b\n" "   ${CYE}•${CNC} ${DIM}Archivo de log: ${CBL}~/.github-keys-setup/setup.log${CNC}${DIM}${CNC}"
    show_separator
    printf "%b\n" "${DIM}AUTOR:${CNC} ${CBL}25asab015${CNC} ${DIM}<25asab015@ujmd.edu.sv>${CNC}  ${DIM}│${CNC}  ${DIM}LICENCIA:${CNC} ${CBL}GPL-3.0${CNC}"
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
            printf " %b" "${BLD}${CGR}${prompt}${CNC} [Y/n]: "
        else
            printf " %b" "${BLD}${CGR}${prompt}${CNC} [y/N]: "
        fi

        read -r response
        response=${response:-$default}

        case "${response}" in
            [Yy]|[Ss]|yes|si)
                return 0 ;;
            [Nn]|no)
                if [ "$exit_on_no" = "true" ]; then
                    printf "\n%b\n" "${BLD}${CYE}Operación cancelada${CNC}"
                    exit 0
                else
                    return 1
                fi
                ;;
            *)
                printf "\n%b\n\n" "${BLD}${CRE}Error:${CNC} Solo escribe '${BLD}${CYE}s${CNC}', '${BLD}${CYE}n${CNC}', '${BLD}${CYE}y${CNC}' o '${BLD}${CYE}N${CNC}'" ;;
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
        info "Instala una de estas: ${CBL}xsel${CNC}, ${CBL}xclip${CNC} (X11), ${CBL}wl-clipboard${CNC} (Wayland)"
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
                printf "%b\n" "  ${BLD}${CRE}• Una herramienta de portapapeles: ${CYE}${dep}${CNC}"
            else
                printf "%b\n" "  ${BLD}${CRE}• $dep${CNC}"
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
                    printf "%b\n" "${BLD}${CYE}Arch Linux:${CNC}    ${CGR}sudo pacman -S --noconfirm${arch_pkgs}${CNC}"
                    if [[ "$arch_pkgs" == *"gitkraken-cli"* ]] || [[ "$arch_pkgs" == *"git-credential-manager-bin"* ]]; then
                        printf "%b\n" "${BLD}${CYE}Arch Linux (AUR):${CNC} ${CGR}yay -S --noconfirm${arch_pkgs}${CNC}"
                    fi
                    printf "%b\n" "${BLD}${CYE}Ubuntu/Debian:${CNC} ${CGR}sudo apt update && sudo apt install -y${debian_pkgs}${CNC}"
                    printf "%b\n" "${BLD}${CYE}CentOS/RHEL:${CNC}   ${CGR}sudo yum install -y${centos_pkgs}${CNC}"
                    printf "%b\n" "${BLD}${CYE}Fedora:${CNC}        ${CGR}sudo dnf install -y${fedora_pkgs}${CNC}"
                    printf "%b\n" "${BLD}${CYE}macOS:${CNC}         ${CGR}brew install${brew_pkgs}${CNC}"
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
            
            success "Backup completado en: ${CBL}$BACKUP_DIR${CNC}"
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
    echo -e "${BLD}📝 INFORMACIÓN DEL USUARIO${CNC}"
    show_separator

    # Modo no-interactivo: usar variables de entorno
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        if [[ -z "$USER_EMAIL" ]]; then
            error "USER_EMAIL no está definido. Requerido en modo no-interactivo."
            echo ""
            info "Ejemplo de uso:"
            printf "%b\n" "${CBL}USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive${CNC}"
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
            printf "%b\n" "${CBL}USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive${CNC}"
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
        echo -ne "${CBL}Ingresa tu email de GitHub: ${CNC}"
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
        echo -ne "${CBL}Ingresa tu nombre completo para Git: ${CNC}"
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

# Función para generar llave SSH
generate_ssh_key() {
    show_separator
    echo -e "${BLD}🔑 GENERACIÓN DE LLAVE SSH${CNC}"
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
    printf "%b\n" "${BLD}${CWH}🔐 GENERACIÓN DE LLAVE GPG${CNC}"
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
        printf "%b\n" "${CYE}Contenido del archivo de configuración GPG:${CNC}"
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
    echo -e "${BLD}⚙️  CONFIGURACIÓN DE GIT${CNC}"
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
    info "Puedes ver tu configuración con: ${CBL}git config --global --list${CNC}"
    
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
	defaultBranch = main

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
    success "Plantilla de commit creada: ${CBL}$template_path${CNC}"
    
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
                info "Reinicia tu terminal o ejecuta: ${CBL}source ~/.bashrc${CNC} / ${CBL}source ~/.zshrc${CNC}"
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
    echo -e "${BLD}📋 RESUMEN DE LLAVES GENERADAS${CNC}"
    show_separator
    echo ""

    # ========== LLAVE SSH ==========
    info "1. LLAVE SSH PÚBLICA (para agregar a GitHub):"
    echo ""
    
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        show_separator
        printf "%b\n" "${BLD}${CGR}$(cat "$HOME/.ssh/id_ed25519.pub")${CNC}"
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
        info "ID de la llave GPG: ${CBL}$GPG_KEY_ID${CNC}"
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
    echo "  ${BLD}${CYE}Para la llave SSH:${CNC}"
    echo "    1. Ve a: ${CBL}https://github.com/settings/ssh/new${CNC}"
    echo "    2. Pega la llave SSH mostrada arriba"
    echo "    3. Dale un título descriptivo"
    echo ""
    
    if [[ -n "$GPG_KEY_ID" ]]; then
        echo "  ${BLD}${CYE}Para la llave GPG:${CNC}"
        echo "    1. Ve a: ${CBL}https://github.com/settings/gpg/new${CNC}"
        echo "    2. Pega la llave GPG mostrada arriba"
        echo "    3. Tus commits aparecerán como 'Verified' ✓"
        echo ""
    fi
    
    show_separator
}

# Función para guardar llaves en archivos
save_keys_to_files() {
    show_separator
    printf "%b\n" "${BLD}${CWH}💾 GUARDANDO LLAVES EN ARCHIVOS${CNC}"
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
        printf "%b\n" "${BLD}${CYE}⚠️  GITHUB CLI NO ESTÁ INSTALADO${CNC}"
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
                                info "Instala GitHub CLI manualmente y vuelve a ejecutar el script con ${CBL}--auto-upload${CNC}"
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
                                info "Instala GitHub CLI manualmente y vuelve a ejecutar el script con ${CBL}--auto-upload${CNC}"
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
                            info "Instala GitHub CLI manualmente y vuelve a ejecutar el script con ${CBL}--auto-upload${CNC}"
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
                    info "El script no puede continuar sin GitHub CLI. Instálalo y vuelve a ejecutar con ${CBL}--auto-upload${CNC}"
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
                echo "     ${CBL}sudo pacman -S github-cli${CNC}  # Arch Linux"
                echo "     ${CBL}sudo apt install gh${CNC}        # Ubuntu/Debian"
                echo ""
                echo "  2. Autentica GitHub CLI:"
                echo "     ${CBL}gh auth login${CNC}"
                echo ""
                echo "  3. Vuelve a ejecutar este script con ${CBL}--auto-upload${CNC}"
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
    printf "%b\n" "${BLD}${CYE}⚠️  GITHUB CLI NO ESTÁ AUTENTICADO${CNC}"
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
        echo "  1. ${CBL}gh auth login${CNC} - Autenticación interactiva (recomendada)"
        echo "  2. ${CBL}gh auth login --with-token${CNC} - Autenticación con token"
        echo ""
        
        if ask_yes_no "¿Deseas ejecutar 'gh auth login' ahora?" "y"; then
            echo ""
            info "Ejecutando autenticación de GitHub CLI..."
            echo "${DIM}Nota: Sigue las instrucciones en pantalla para completar la autenticación.${CNC}"
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
                    info "Autentica GitHub CLI manualmente con ${CBL}gh auth login${CNC} y vuelve a ejecutar el script con ${CBL}--auto-upload${CNC}"
                    exit 1
                fi
                info "Puedes autenticarte manualmente más tarde con: ${CBL}gh auth login${CNC}"
                return 1
            fi
        else
            echo ""
            if [[ "$early_mode" == "early" ]]; then
                error "El flag --auto-upload requiere GitHub CLI autenticado."
                echo ""
                info "El script no puede continuar sin autenticación. Autentica GitHub CLI con ${CBL}gh auth login${CNC} y vuelve a ejecutar con ${CBL}--auto-upload${CNC}"
                exit 1
            fi
            warning "Autenticación omitida. Las llaves no se subirán automáticamente."
            echo ""
            info "Para autenticarte más tarde, ejecuta: ${CBL}gh auth login${CNC}"
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
            echo "     ${CBL}gh auth login${CNC}"
            echo ""
            echo "  2. O usa un token de GitHub:"
            echo "     ${CBL}echo 'tu_token_github' | gh auth login --with-token${CNC}"
            echo ""
            echo "  3. Vuelve a ejecutar este script con ${CBL}--auto-upload${CNC}"
            echo ""
            exit 1
        else
            info "GitHub CLI está instalado pero requiere autenticación para subir llaves."
            echo ""
            printf "%b\n" "${CYE}Para habilitar la subida automática en modo no-interactivo:${CNC}"
            echo ""
            echo "  1. Autentica GitHub CLI manualmente:"
            echo "     ${CBL}gh auth login${CNC}"
            echo ""
            echo "  2. O usa un token de GitHub:"
            echo "     ${CBL}echo 'tu_token_github' | gh auth login --with-token${CNC}"
            echo ""
            echo "  3. Luego vuelve a ejecutar este script con ${CBL}--auto-upload${CNC}"
            echo ""
            warning "Omitiendo subida automática. Las llaves se guardarán localmente."
            return 1
        fi
    fi
}

show_manual_gh_install_instructions() {
    local os_type="$1"
    echo ""
    printf "%b\n" "${BLD}${CCY}📦 INSTRUCCIONES DE INSTALACIÓN MANUAL:${CNC}"
    echo ""
    
    case "$os_type" in
        arch|manjaro|endeavouros|garuda)
            printf "%b\n" "${CYE}Arch Linux / Manjaro:${CNC}"
            echo "  ${CBL}sudo pacman -S github-cli${CNC}"
            echo "  ${DIM}o desde AUR:${CNC} ${CBL}yay -S github-cli${CNC}"
            ;;
        ubuntu|debian|linuxmint|pop)
            printf "%b\n" "${CYE}Ubuntu / Debian:${CNC}"
            echo "  ${CBL}sudo apt update && sudo apt install gh${CNC}"
            ;;
        fedora|rhel|centos|rocky|alma)
            printf "%b\n" "${CYE}Fedora / RHEL / CentOS:${CNC}"
            echo "  ${CBL}sudo dnf install gh${CNC}"
            ;;
        *)
            printf "%b\n" "${CYE}Instalación genérica:${CNC}"
            echo "  Visita: ${CBL}https://cli.github.com${CNC}"
            ;;
    esac
    
    echo ""
    info "Después de instalar, vuelve a ejecutar este script con ${CBL}--auto-upload${CNC}"
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

    # Verificar si la llave GPG ya existe en GitHub
    local existing_keys
    existing_keys=$(gh gpg-key list 2>/dev/null | grep -i "$GPG_KEY_ID" || true)
    if [[ -n "$existing_keys" ]]; then
        info "La llave GPG ${CBL}$GPG_KEY_ID${CNC} ya existe en tu cuenta de GitHub."
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
            info "La llave GPG ${CBL}$GPG_KEY_ID${CNC} ya existe en tu cuenta de GitHub."
            GPG_KEY_UPLOADED=true
            rm -f "$gpg_temp"
            return 0
        else
            warning "No se pudo subir la llave GPG automáticamente."
            if [[ -n "$gh_output" ]]; then
                printf "%b\n" "${DIM}Error: ${gh_output}${CNC}"
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
    printf "%b\n" "${BLD}${CGR}🚀 SUBIENDO LLAVES A GITHUB${CNC}"
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
            info "  • Llave SSH: ${CGR}Subida exitosamente${CNC}"
        fi
        if [[ "$gpg_uploaded" == "true" ]]; then
            info "  • Llave GPG: ${CGR}Subida exitosamente${CNC}"
        fi
    else
        warning "No se pudieron subir las llaves automáticamente"
        echo ""
        info "Puedes subirlas manualmente desde:"
        echo "  ${CBL}https://github.com/settings/ssh/new${CNC} (SSH)"
        echo "  ${CBL}https://github.com/settings/gpg/new${CNC} (GPG)"
    fi
    
    show_separator
    echo ""
}

# Función para test de conectividad
test_github_connection() {
    show_separator
    printf "%b\n" "${BLD}${CWH}🧪 PRUEBA DE CONECTIVIDAD${CNC}"
    show_separator

    if ask_yes_no "¿Deseas probar la conexión SSH con GitHub ahora?"; then
        info "Probando conexión SSH con GitHub..."

        # Test SSH connection
        ssh_output=$(ssh -T git@github.com 2>&1)
        ssh_exit_code=$?

        if [[ $ssh_exit_code -eq 1 ]] && [[ $ssh_output == *"successfully authenticated"* ]]; then
            success "¡Conexión SSH con GitHub exitosa!"
            printf "%b\n" "${CGR}$ssh_output${CNC}"
        else
            warning "La conexión SSH falló o está pendiente de configuración"
            printf "%b\n" "${CYE}Salida: $ssh_output${CNC}"
            printf "%b\n" "${CBL}Asegúrate de haber agregado la llave SSH a tu cuenta de GitHub${CNC}"
        fi
    fi
}


# Función para mostrar instrucciones finales
show_final_instructions() {
    echo ""
    show_separator
    printf "%b\n" "${BLD}${CMA}╔══════════════════════════════════════════════════════════════════════════════╗${CNC}"
    printf "%b\n" "${BLD}${CMA}║${CNC}  ${BLD}${CWH}📚  INSTRUCCIONES FINALES PARA GITHUB${CNC}                                    ${BLD}${CMA}║${CNC}"
    printf "%b\n" "${BLD}${CMA}╚══════════════════════════════════════════════════════════════════════════════╝${CNC}"
    echo ""

    if [[ "$SSH_KEY_UPLOADED" == true ]] || [[ "$GPG_KEY_UPLOADED" == true ]]; then
        info "Subida automática: ${CGR}SSH $( [[ "$SSH_KEY_UPLOADED" == true ]] && echo '✓' || echo '✗' )${CNC}  |  ${CGR}GPG $( [[ "$GPG_KEY_UPLOADED" == true ]] && echo '✓' || echo '✗' )${CNC}"
        echo ""
    fi

    # Solo mostrar pasos de agregar llaves si no se subieron automáticamente
    if [[ "$SSH_KEY_UPLOADED" != true ]]; then
        printf "%b\n" "${BLD}${CCY}🔐 PASO 1: AGREGAR LLAVE SSH${CNC}"
        printf "%b\n" "${DIM}${CNC}   ├─ ${CBL}URL:${CNC} ${BLD}https://github.com/settings/ssh/new${CNC}"
        printf "%b\n" "${DIM}${CNC}   ├─ ${CBL}Título sugerido:${CNC} $(hostname)-$(date +%Y%m%d)"
        printf "%b\n" "${DIM}${CNC}   └─ ${CYE}Pega la llave SSH pública que se mostró arriba${CNC}"
        echo ""
    else
        printf "%b\n" "${BLD}${CCY}🔐 PASO 1: LLAVE SSH${CNC}"
        printf "%b\n" "${DIM}${CNC}   └─ ${CGR}✓ Ya agregada automáticamente a tu cuenta de GitHub${CNC}"
        echo ""
    fi
    
    if [[ "$GPG_KEY_UPLOADED" != true ]]; then
        if [[ -n "$GPG_KEY_ID" ]]; then
            printf "%b\n" "${BLD}${CCY}🔑 PASO 2: AGREGAR LLAVE GPG (Opcional)${CNC}"
            printf "%b\n" "${DIM}${CNC}   ├─ ${CBL}URL:${CNC} ${BLD}https://github.com/settings/gpg/new${CNC}"
            printf "%b\n" "${DIM}${CNC}   ├─ ${CYE}Pega la llave GPG pública que se mostró arriba${CNC}"
            printf "%b\n" "${DIM}${CNC}   └─ ${DIM}Esto permitirá que tus commits aparezcan como 'Verified'${CNC}"
            echo ""
        fi
    else
        printf "%b\n" "${BLD}${CCY}🔑 PASO 2: LLAVE GPG${CNC}"
        printf "%b\n" "${DIM}${CNC}   └─ ${CGR}✓ Ya agregada automáticamente a tu cuenta de GitHub${CNC}"
        echo ""
    fi
    
    # Ajustar número de paso según si se mostraron los pasos anteriores
    local paso_num=3
    if [[ "$SSH_KEY_UPLOADED" == true ]] && [[ "$GPG_KEY_UPLOADED" == true ]]; then
        paso_num=1
    elif [[ "$SSH_KEY_UPLOADED" == true ]] || [[ "$GPG_KEY_UPLOADED" == true ]]; then
        paso_num=2
    fi
    
    printf "%b\n" "${BLD}${CCY}✅ PASO ${paso_num}: VERIFICAR CONFIGURACIÓN${CNC}"
    printf "%b\n" "${DIM}${CNC}   ├─ ${CBL}Probar SSH:${CNC} ${BLD}${CGR}ssh -T git@github.com${CNC}"
    printf "%b\n" "${DIM}${CNC}   │  ${DIM}→ Deberías ver: 'Hi username! You've successfully authenticated...'${CNC}"
    printf "%b\n" "${DIM}${CNC}   └─ ${CBL}Probar GPG:${CNC} ${DIM}Haz un commit y verifica el badge 'Verified' en GitHub${CNC}"
    echo ""
    
    ((paso_num++))
    printf "%b\n" "${BLD}${CCY}📁 PASO ${paso_num}: ARCHIVOS GENERADOS${CNC}"
    printf "%b\n" "${DIM}${CNC}   ├─ ${BLD}${CBL}~/.gitconfig${CNC}     ${DIM}→ Configuración profesional de Git${CNC}"
    printf "%b\n" "${DIM}${CNC}   ├─ ${BLD}${CBL}~/.gitmessage${CNC}    ${DIM}→ Plantilla para mensajes de commit${CNC}"
    printf "%b\n" "${DIM}${CNC}   ├─ ${BLD}${CBL}~/.ssh/config${CNC}    ${DIM}→ Configuración SSH optimizada${CNC}"
    printf "%b\n" "${DIM}${CNC}   └─ ${BLD}${CBL}~/.ssh/id_ed25519${CNC} ${DIM}→ Tu llave SSH privada (¡nunca la compartas!)${CNC}"
    echo ""
    
    ((paso_num++))
    printf "%b\n" "${BLD}${CCY}🔐 PASO ${paso_num}: CREDENTIAL MANAGER${CNC}"
    printf "%b\n" "${DIM}${CNC}   ├─ ${CGR}✓${CNC} Git Credential Manager configurado"
    printf "%b\n" "${DIM}${CNC}   ├─ ${DIM}No se solicitará contraseña en cada operación${CNC}"
    printf "%b\n" "${DIM}${CNC}   ├─ ${CYE}En el primer push, se abrirá el navegador para autenticar${CNC}"
    printf "%b\n" "${DIM}${CNC}   └─ ${CBL}Pre-autenticar (opcional):${CNC} ${BLD}${CGR}git-credential-manager github login${CNC}"
    echo ""
    
    printf "%b\n" "${BLD}${CCY}💡 COMANDOS ÚTILES:${CNC}"
    printf "%b\n" "${DIM}${CNC}   ├─ ${CBL}Ver configuración Git:${CNC}    ${BLD}git config --list --show-origin${CNC}"
    printf "%b\n" "${DIM}${CNC}   ├─ ${CBL}Ver llaves SSH:${CNC}          ${BLD}ls -la ~/.ssh/${CNC}"
    printf "%b\n" "${DIM}${CNC}   ├─ ${CBL}Ver llaves GPG:${CNC}          ${BLD}gpg --list-secret-keys --keyid-format=long${CNC}"
    printf "%b\n" "${DIM}${CNC}   └─ ${CBL}Ver logs del script:${CNC}     ${BLD}cat $LOG_FILE${CNC}"
    echo ""
    
    show_separator
    printf "%b\n" "${BLD}${CGR}✨ ¡CONFIGURACIÓN COMPLETADA EXITOSAMENTE! ✨${CNC}"
    printf "%b\n" "${CCY}Tu entorno de desarrollo Git está configurado de forma profesional.${CNC}"
    printf "%b\n" "${DIM}Ahora puedes trabajar con GitHub con autenticación SSH y commits firmados.${CNC}"
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

    # Generar llave SSH
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ! generate_ssh_key; then
        exit 1
    fi

    # Generar llave GPG
    ((CURRENT_STEP++))
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS "${WORKFLOW_STEPS[$CURRENT_STEP]}"
    if ask_yes_no "¿Deseas generar también una llave GPG para firmar commits?"; then
        generate_gpg_key
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
