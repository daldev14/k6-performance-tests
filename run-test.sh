#!/bin/bash

# =============================================================================
# k6 Test Runner Script for Linux
# =============================================================================

TEST_DIR="./k6-tests"
REPORTS_DIR="./reports"

# Colors for output
# Define códigos de colores para imprimir mensajes en la terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Crea el directorio reports si no existe
mkdir -p "$REPORTS_DIR"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                       k6 Test Runner                          ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_separator() {
    echo -e "${BLUE}───────────────────────────────────────────────────────────────────${NC}"
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

print_header

# Busca archivos .js en el directorio de tests y los muestra numerados para selección
echo -e "${YELLOW}Pruebas disponibles:${NC}"
print_separator

tests=()
i=1
for file in "$TEST_DIR"/*.js; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        tests+=("$file")
        echo -e "  ${GREEN}[$i]${NC} $filename"
        ((i++))
    fi
done

if [ ${#tests[@]} -eq 0 ]; then
    echo -e "${RED}No se encontraron tests en $TEST_DIR${NC}"
    exit 1
fi

print_separator

# Solicita selección del test a ejecutar y valida la entrada
echo -e -n "${YELLOW}Selecciona el número del test a ejecutar:${NC} "
read -r test_selection

if ! [[ "$test_selection" =~ ^[0-9]+$ ]] || [ "$test_selection" -lt 1 ] || [ "$test_selection" -gt ${#tests[@]} ]; then
    echo -e "${RED}Selección inválida${NC}"
    exit 1
fi

selected_test="${tests[$((test_selection-1))]}"
test_name=$(basename "$selected_test" .js)

echo -e "${GREEN}✓ Test seleccionado: $test_name${NC}"
print_separator

# Genera un nombre de reporte por defecto basado en el nombre del test y la fecha/hora actual
default_report="${test_name}_$(date '+%Y%m%d_%H%M%S')"
echo -e -n "${YELLOW}Nombre del reporte [${NC}${default_report}${YELLOW}]:${NC} "
read -r report_name

if [ -z "$report_name" ]; then
    report_name="$default_report"
fi

# Si el nombre del reporte no termina con .html, se le agrega la extensión
if [[ "$report_name" != *.html ]]; then
    report_name="${report_name}.html"
fi

echo -e "${GREEN}✓ Reporte: $REPORTS_DIR/$report_name${NC}"
print_separator

# Solicita al usuario configurar variables de entorno para la ejecución del test, con valores por defecto sugeridos
echo -e "${YELLOW}Variables de entorno (presiona Enter para usar valores por defecto):${NC}"
echo ""

# K6_WEB_DASHBOARD (activa el dashboard web para visualizar el progreso del test en tiempo real)
echo -e -n "  K6_WEB_DASHBOARD [${GREEN}true${NC}]: "
read -r web_dashboard
web_dashboard=${web_dashboard:-true}

# K6_WEB_DASHBOARD_OPEN (define si el dashboard se abre automáticamente en el navegador al iniciar el test)
echo -e -n "  K6_WEB_DASHBOARD_OPEN [${GREEN}true${NC}]: "
read -r web_dashboard_open
web_dashboard_open=${web_dashboard_open:-true}

# BASE_URL (opcional) sobrescribe la URL base definida en el test, solo si se proporciona un valor
echo -e -n "  BASE_URL [${GREEN}https://test-api.k6.io${NC}]: "
read -r base_url
base_url=${base_url:-https://test-api.k6.io}

# VUs (Opcional) sobrescribe el número de usuario virtuales definido en el test, solo si se proporciona un valor
echo -e -n "  VUs (virtual users, vacío para usar config del test) [${GREEN}-${NC}]: "
read -r vus

# Duration (opcional) sobrescribe la duración del test definido en el test, solo si se proporciona un valor
echo -e -n "  DURATION (ej: 30s, 1m, vacío para usar config del test) [${GREEN}-${NC}]: "
read -r duration

print_separator

# Establece las variables de entorno para ejecutar el test con k6
export K6_WEB_DASHBOARD="$web_dashboard"
export K6_WEB_DASHBOARD_OPEN="$web_dashboard_open"
export K6_WEB_DASHBOARD_EXPORT="$REPORTS_DIR/$report_name"
export BASE_URL="$base_url"

# Construye el comando agregando las opciones definidas
cmd="k6 run"

if [ -n "$vus" ]; then
    cmd="$cmd --vus $vus"
fi

if [ -n "$duration" ]; then
    cmd="$cmd --duration $duration"
fi

cmd="$cmd $selected_test"

# Muestra un resumen de la configuración antes de ejecutar el test y solicita confirmación al usuario
echo -e "${YELLOW}Resumen de ejecución:${NC}"
echo -e "  Test:        ${GREEN}$selected_test${NC}"
echo -e "  Reporte:     ${GREEN}$REPORTS_DIR/$report_name${NC}"
echo -e "  BASE_URL:    ${GREEN}$base_url${NC}"
echo -e "  Dashboard:   ${GREEN}$web_dashboard${NC}"
echo -e "  Auto-open:   ${GREEN}$web_dashboard_open${NC}"
[ -n "$vus" ] && echo -e "  VUs:         ${GREEN}$vus${NC}"
[ -n "$duration" ] && echo -e "  Duration:    ${GREEN}$duration${NC}"
print_separator

echo -e -n "${YELLOW}¿Ejecutar test? (s/N):${NC} "
read -r confirm

if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo -e "${RED}Ejecución cancelada${NC}"
    exit 0
fi

# Ejecuta el comando construido
echo ""
echo -e "${GREEN}Ejecutando: $cmd${NC}"
print_separator
echo ""

eval "$cmd"

exit_code=$?

echo ""
print_separator
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✓ Test completado exitosamente${NC}"
    echo -e "${GREEN}✓ Reporte guardado en: $REPORTS_DIR/$report_name${NC}"
else
    echo -e "${RED}✗ Test finalizado con errores (código: $exit_code)${NC}"
fi
