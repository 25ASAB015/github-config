#!/usr/bin/env bash
#==============================================================================
#                              UI
#==============================================================================
# @file ui.sh
# @brief User interface utilities
# @description
#   Provides UI functions including logo display, spinners, progress bars,
#   and user prompts.
#
# Globals:
#   INTERACTIVE_MODE    Whether running in interactive mode (from defaults.sh)
#   COLORS              Color definitions (from defaults.sh)
#   WORKFLOW_STEPS      Step descriptions (from defaults.sh)
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_UI_SOURCED:-}" ]] && return 0
declare -r _UI_SOURCED=1

#==============================================================================
# LOGO AND BRANDING
#==============================================================================

# @description Display the Crixus ASCII art logo
# @example
#   logo
logo() {
    echo ""
    printf "%b\n" "$(c primary)   ██████╗██████╗ ██╗██╗  ██╗██╗   ██╗███████╗$(cr)"
    printf "%b\n" "$(c primary)  ██╔════╝██╔══██╗██║╚██╗██╔╝██║   ██║██╔════╝$(cr)"
    printf "%b\n" "$(c primary)  ██║     ██████╔╝██║ ╚███╔╝ ██║   ██║███████╗$(cr)"
    printf "%b\n" "$(c primary)  ██║     ██╔══██╗██║ ██╔██╗ ██║   ██║╚════██║$(cr)"
    printf "%b\n" "$(c primary)  ╚██████╗██║  ██║██║██╔╝ ██╗╚██████╔╝███████║$(cr)"
    printf "%b\n" "$(c primary)   ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝$(cr)"
    echo ""
    printf "%b\n" "$(c accent)  🔧 Configuración Profesional de Git & GitHub$(cr)"
    printf "%b\n" "$(c muted)     Automatiza tu entorno de desarrollo$(cr)"
    echo ""
}

#==============================================================================
# PROGRESS INDICATORS
#==============================================================================

# @description Display a spinner animation while a process runs
# @param $1 pid - Process ID to wait for
# @param $2 message - Message to display with spinner
# @example
#   long_command &
#   show_spinner $! "Processing..."
show_spinner() {
    local pid=$1
    local message="${2:-Procesando...}"
    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    # Only show spinner in interactive mode with a terminal
    if [[ ! -t 1 ]] || [[ "$INTERACTIVE_MODE" != "true" ]]; then
        wait "$pid"
        return $?
    fi
    
    printf "  "
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  $(c primary)${spin_chars:$i:1}$(cr) %s" "$message"
        i=$(( (i + 1) % ${#spin_chars} ))
        sleep 0.1
    done
    printf "\r  $(c success)✓$(cr) %s\n" "$message"
    
    wait "$pid"
    return $?
}

# @description Display a progress bar
# @param $1 current - Current step number
# @param $2 total - Total number of steps
# @param $3 message - Optional message to display
# @example
#   show_progress_bar 3 10 "Installing dependencies"
show_progress_bar() {
    local current=$1
    local total=$2
    local message="${3:-}"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Build progress bar
    local bar=""
    for ((i = 0; i < filled; i++)); do
        bar+="█"
    done
    for ((i = 0; i < empty; i++)); do
        bar+="░"
    done
    
    # Display progress bar
    printf "\r$(c primary)[%s]$(cr) $(c bold)%3d%%$(cr)" "$bar" "$percentage"
    
    if [[ -n "$message" ]]; then
        printf " $(c muted)%s$(cr)" "$message"
    fi
    
    # New line if complete
    if [[ $current -eq $total ]]; then
        printf "\n"
    fi
}

#==============================================================================
# USER PROMPTS
#==============================================================================

# @description Ask a yes/no question and return the response
# @param $1 prompt - Question to ask
# @param $2 default - Default answer (y/n), defaults to 'y'
# @return 0 if yes, 1 if no
# @example
#   if ask_yes_no "Continue?" "y"; then
#       echo "User said yes"
#   fi
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local response
    
    # In non-interactive mode, use default
    if [[ "$INTERACTIVE_MODE" != "true" ]]; then
        [[ "$default" == "y" || "$default" == "Y" ]]
        return $?
    fi
    
    # Format prompt with default indicator
    local prompt_indicator
    if [[ "$default" == "y" || "$default" == "Y" ]]; then
        prompt_indicator="[Y/n]"
    else
        prompt_indicator="[y/N]"
    fi
    
    # Keep asking until we get a valid response
    while true; do
        printf "%b " "$(c accent)$prompt$(cr) $(c muted)$prompt_indicator$(cr)"
        read -r response
        
        # Use default if empty response
        if [[ -z "$response" ]]; then
            response="$default"
        fi
        
        case "$response" in
            [yY]|[yY][eE][sS]|[sS]|[sS][iI])
                return 0
                ;;
            [nN]|[nN][oO])
                return 1
                ;;
            *)
                printf "%b\n" "$(c warning)Por favor responde 'y' (sí) o 'n' (no)$(cr)"
                ;;
        esac
    done
}

# @description Read user input with a prompt
# @param $1 prompt - Prompt to display
# @param $2 default - Default value (optional)
# @param $3 var_name - Variable name to store result in
# @example
#   read_input "Enter your name:" "John Doe" user_name
read_input() {
    local prompt="$1"
    local default="${2:-}"
    local var_name="$3"
    local input
    
    if [[ -n "$default" ]]; then
        printf "%b " "$(c accent)$prompt$(cr) $(c muted)[$default]$(cr):"
    else
        printf "%b " "$(c accent)$prompt$(cr):"
    fi
    
    read -r input
    
    # Use default if empty
    if [[ -z "$input" ]] && [[ -n "$default" ]]; then
        input="$default"
    fi
    
    # Set the variable
    eval "$var_name=\"\$input\""
}

#==============================================================================
# HELP AND WELCOME
#==============================================================================

# @description Display help information
# @example
#   show_help
show_help() {
    logo
    show_separator
    printf "%b\n" "$(c bold)$(c text)USO:$(cr)"
    printf "%b\n" "  $(c primary)./gitconfig.sh$(cr) $(c muted)[opciones]$(cr)"
    echo ""
    printf "%b\n" "$(c bold)$(c text)OPCIONES:$(cr)"
    printf "%b\n" "  $(c primary)--non-interactive$(cr)   Ejecutar sin prompts interactivos"
    printf "%b\n" "  $(c primary)--auto-upload$(cr)       Subir llaves automáticamente a GitHub"
    printf "%b\n" "  $(c primary)--help, -h$(cr)          Mostrar esta ayuda"
    echo ""
    printf "%b\n" "$(c bold)$(c text)EJEMPLOS:$(cr)"
    printf "%b\n" "  $(c muted)# Modo interactivo (por defecto)$(cr)"
    printf "%b\n" "  $(c primary)./gitconfig.sh$(cr)"
    echo ""
    printf "%b\n" "  $(c muted)# Modo automático con subida de llaves$(cr)"
    printf "%b\n" "  $(c primary)./gitconfig.sh --non-interactive --auto-upload$(cr)"
    echo ""
    show_separator
}

# @description Display welcome message
# @example
#   welcome
welcome() {
    logo
    show_separator
    printf "%b\n" "$(c bold)$(c text)Bienvenido al configurador de Git$(cr)"
    printf "%b\n" "$(c muted)Este script configurará:$(cr)"
    printf "%b\n" "  $(c success)•$(cr) Llaves SSH para autenticación con GitHub"
    printf "%b\n" "  $(c success)•$(cr) Llaves GPG para firmar commits (opcional)"
    printf "%b\n" "  $(c success)•$(cr) Configuración profesional de Git"
    printf "%b\n" "  $(c success)•$(cr) Git Credential Manager"
    show_separator
    echo ""
}
