#!/usr/bin/env bash
#==============================================================================
#                              GIT-CONFIG
#==============================================================================
# @file git-config.sh
# @brief Git configuration generation and management
# @description
#   Provides functions for generating .gitconfig file, commit templates,
#   and configuring Git settings.
#
# Globals:
#   USER_NAME     Git user name
#   USER_EMAIL    Git user email
#   GPG_KEY_ID    GPG key ID for signing
#   SCRIPT_DIR    Directory containing templates
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_GIT_CONFIG_SOURCED:-}" ]] && return 0
declare -r _GIT_CONFIG_SOURCED=1

#==============================================================================
# USER INFORMATION COLLECTION
#==============================================================================

# @description Collect user information for Git configuration
# @return 0 on success, 1 on failure
# @example
#   if ! collect_user_info; then
#       error "Failed to collect user info"
#   fi
collect_user_info() {
    show_separator
    echo -e "$(c bold)👤 INFORMACIÓN DEL USUARIO$(cr)"
    show_separator
    
    # Try to get existing Git config
    local existing_name
    local existing_email
    existing_name=$(git config --global user.name 2>/dev/null || echo "")
    existing_email=$(git config --global user.email 2>/dev/null || echo "")
    
    # Get user name
    if [[ -n "$existing_name" ]]; then
        info "Nombre actual en Git: $(c primary)$existing_name$(cr)"
        if ask_yes_no "¿Deseas usar este nombre?"; then
            USER_NAME="$existing_name"
        else
            read_input "Ingresa tu nombre completo" "" USER_NAME
        fi
    else
        read_input "Ingresa tu nombre completo" "" USER_NAME
    fi
    
    if [[ -z "$USER_NAME" ]]; then
        error "El nombre es requerido"
        return 1
    fi
    
    # Get user email
    if [[ -n "$existing_email" ]]; then
        info "Email actual en Git: $(c primary)$existing_email$(cr)"
        if ask_yes_no "¿Deseas usar este email?"; then
            USER_EMAIL="$existing_email"
        else
            while true; do
                read_input "Ingresa tu email" "" USER_EMAIL
                if validate_email "$USER_EMAIL"; then
                    break
                else
                    error "Email inválido. Por favor ingresa un email válido."
                fi
            done
        fi
    else
        while true; do
            read_input "Ingresa tu email" "" USER_EMAIL
            if validate_email "$USER_EMAIL"; then
                break
            else
                error "Email inválido. Por favor ingresa un email válido."
            fi
        done
    fi
    
    echo ""
    success "Información recopilada:"
    echo "  Nombre: $(c primary)$USER_NAME$(cr)"
    echo "  Email:  $(c primary)$USER_EMAIL$(cr)"
    echo ""
    
    log "User info collected: $USER_NAME <$USER_EMAIL>"
    return 0
}

#==============================================================================
# CHANGES SUMMARY
#==============================================================================

# @description Show a summary of changes before applying
# @return 0 if user confirms, 1 if cancelled
# @example
#   if ! show_changes_summary; then
#       exit 0
#   fi
show_changes_summary() {
    echo ""
    show_separator
    printf "%b\n" "$(c bold)$(c accent)📋 RESUMEN DE CAMBIOS A REALIZAR$(cr)"
    show_separator
    echo ""
    
    printf "%b\n" "$(c bold)Archivos que se crearán/modificarán:$(cr)"
    echo ""
    
    # SSH Key
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        printf "  $(c warning)~/.ssh/id_ed25519$(cr)     $(c muted)→ Ya existe (se puede respaldar)$(cr)\n"
    else
        printf "  $(c success)~/.ssh/id_ed25519$(cr)     $(c muted)→ Nueva llave SSH$(cr)\n"
    fi
    
    # GPG Key
    if [[ "${GENERATE_GPG:-false}" == "true" ]]; then
        if [[ -n "$GPG_KEY_ID" ]]; then
            printf "  $(c info)Llave GPG$(cr)              $(c muted)→ Usando existente: $GPG_KEY_ID$(cr)\n"
        else
            printf "  $(c success)Llave GPG$(cr)              $(c muted)→ Nueva llave para firmar commits$(cr)\n"
        fi
    else
        printf "  $(c muted)Llave GPG$(cr)              $(c muted)→ No se generará$(cr)\n"
    fi
    
    # Git config
    if [[ -f "$HOME/.gitconfig" ]]; then
        printf "  $(c warning)~/.gitconfig$(cr)          $(c muted)→ Se respaldará y reemplazará$(cr)\n"
    else
        printf "  $(c success)~/.gitconfig$(cr)          $(c muted)→ Nuevo archivo$(cr)\n"
    fi
    
    # Commit template
    printf "  $(c success)~/.gitmessage$(cr)         $(c muted)→ Plantilla de commit$(cr)\n"
    
    # SSH config
    if [[ -f "$HOME/.ssh/config" ]]; then
        printf "  $(c info)~/.ssh/config$(cr)         $(c muted)→ Ya existe$(cr)\n"
    else
        printf "  $(c success)~/.ssh/config$(cr)         $(c muted)→ Configuración SSH para GitHub$(cr)\n"
    fi
    
    echo ""
    show_separator
    
    if ! ask_yes_no "¿Deseas continuar con estos cambios?" "y"; then
        info "Operación cancelada por el usuario"
        return 1
    fi
    
    return 0
}

#==============================================================================
# GIT CONFIGURATION
#==============================================================================

# @description Configure Git with generated settings
# @return 0 on success, 1 on failure
# @example
#   configure_git
configure_git() {
    show_separator
    echo -e "$(c bold)⚙️  CONFIGURACIÓN DE GIT$(cr)"
    show_separator
    
    # Generate .gitconfig file
    generate_gitconfig || {
        error "No se pudo generar el archivo .gitconfig"
        return 1
    }
    
    # Configure Git Credential Manager if available
    if command -v git-credential-manager &> /dev/null; then
        info "Configurando Git Credential Manager..."
        
        if git-credential-manager configure &>/dev/null; then
            success "Git Credential Manager configurado automáticamente"
        fi
        
        success "Git Credential Manager listo para usar"
    fi
    
    success "Configuración Git completada exitosamente"
    echo ""
    info "Puedes ver tu configuración con: $(c primary)git config --global --list$(cr)"
    
    return 0
}

# @description Generate the .gitconfig file
# @return 0 on success, 1 on failure
# @example
#   generate_gitconfig
generate_gitconfig() {
    info "Generando archivo .gitconfig profesional..."
    
    local gitconfig_path="$HOME/.gitconfig"
    local backup_suffix=".backup-$(date +%Y%m%d_%H%M%S)"
    
    # Backup existing .gitconfig
    if [[ -f "$gitconfig_path" ]]; then
        warning "Se encontró un archivo .gitconfig existente"
        if ask_yes_no "¿Deseas hacer backup del .gitconfig actual antes de reemplazarlo?"; then
            cp "$gitconfig_path" "${gitconfig_path}${backup_suffix}"
            success "Backup creado: ${gitconfig_path}${backup_suffix}"
        fi
    fi
    
    # Determine credential helper
    local credential_helper="manager"
    local os_type
    os_type=$(uname -s)
    
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
    
    # Generate .gitconfig
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
    
    # Create commit template
    create_commit_template
    
    return 0
}

# @description Create the commit message template
# @return 0 always
# @example
#   create_commit_template
create_commit_template() {
    local template_path="$HOME/.gitmessage"
    
    info "Creando plantilla de mensaje de commit..."
    
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
