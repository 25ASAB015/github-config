# 📝 Guía de Plantilla para Pull Requests

Esta guía explica cómo usar la plantilla de Pull Request para crear PRs descriptivos y consistentes.

## 📍 Ubicación

La plantilla está ubicada en: `.github/pull_request_template.md`

GitHub automáticamente detecta esta plantilla cuando creas un nuevo PR.

## 🎯 Propósito

La plantilla ayuda a:
- ✅ Documentar cambios de manera consistente
- ✅ Facilitar la revisión de código
- ✅ Mantener un historial claro del proyecto
- ✅ Asegurar que no se olviden aspectos importantes

## 📋 Cómo Usar

### Opción 1: GitHub Web Interface

1. Cuando crees un nuevo PR en GitHub, la plantilla se cargará automáticamente
2. Completa cada sección según corresponda
3. Elimina las secciones que no apliquen a tu cambio

### Opción 2: GitHub CLI

```bash
# Crear PR usando la plantilla
gh pr create --title "Título del PR" --body-file .github/pull_request_template.md --base master --head tu-rama
```

### Opción 3: Manual

1. Copia el contenido de `.github/pull_request_template.md`
2. Edita según tu cambio específico
3. Pega en el campo de descripción del PR

## 📝 Secciones de la Plantilla

### Resumen
- **Qué incluir**: 2-3 líneas explicando el cambio principal
- **Ejemplo**: "Este PR implementa una suite de verificación que automatiza la validación de componentes configurados"

### Problema Resuelto
- **Qué incluir**: Contexto sobre por qué este cambio es necesario
- **Ejemplo**: "Los usuarios no tenían forma automatizada de verificar la configuración"

### Características Implementadas
- **Qué incluir**: Lista detallada de funcionalidades nuevas o mejoradas
- **Formato**: Usar viñetas con ✅, 🔧, 📚, 🎨 según el tipo de cambio

### Archivos Modificados
- **Qué incluir**: Lista organizada de archivos nuevos, modificados o eliminados
- **Formato**: Agrupar por tipo (Nuevos/Modificados/Eliminados)

### Testing
- **Qué incluir**: Descripción de cómo se probó el cambio
- **Formato**: Lista de casos de prueba ejecutados

### Ejemplo de Salida
- **Cuándo incluir**: Si el cambio afecta la salida del usuario
- **Formato**: Bloque de código con ejemplo real

### Relacionado
- **Qué incluir**: Referencias a OpenSpec changes, issues, o especificaciones relacionadas

### Checklist
- **Qué hacer**: Marcar todos los items que aplican antes de solicitar review

## 💡 Tips

1. **Sé específico**: En lugar de "Mejoré el código", di "Agregué validación de email y mejoré manejo de errores"

2. **Incluye ejemplos**: Si es posible, muestra ejemplos de salida o comportamiento

3. **Referencia OpenSpec**: Si el cambio tiene un OpenSpec change asociado, inclúyelo

4. **Elimina lo que no aplica**: No dejes secciones vacías o con placeholders

5. **Revisa antes de crear**: Asegúrate de que toda la información sea precisa

## 📚 Ejemplo Completo

Ver el PR #7 como ejemplo de uso completo de la plantilla:
- https://github.com/25ASAB015/github-config/pull/7

## 🔄 Actualización de la Plantilla

Si necesitas actualizar la plantilla:
1. Edita `.github/pull_request_template.md`
2. Considera crear un PR para actualizar la plantilla
3. Documenta cambios significativos en esta guía

