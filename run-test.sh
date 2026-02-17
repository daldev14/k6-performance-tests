#!/bin/bash

# =============================================================================
# k6 Test Runner Script for Linux
# =============================================================================

TEST_DIR="./src/k6-tests"
REPORTS_DIR="./reports"
TEST_EXTENSION="*.test.js"

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

# -------------------- BUSCAR ARCHIVOS --------------------

echo -e "${YELLOW}Pruebas disponibles:${NC}"
print_separator

tests=()
i=1
while IFS= read -r file; do
    relative_path="${file#$TEST_DIR/}"
    tests+=("$file")
    echo -e "  ${GREEN}[$i]${NC} $relative_path"
    ((i++))
done < <(find "$TEST_DIR" -name $TEST_EXTENSION -type f | sort)

if [ ${#tests[@]} -eq 0 ]; then
    echo -e "${RED}No se encontraron tests en $TEST_DIR${NC}"
    exit 1
fi

print_separator

# -------------------- SELECCIONAR TEST A EJECUTAR --------------------

echo -e -n "${YELLOW}Selecciona el número del test o ingresa la ruta relativa del script:${NC} "
read -r test_selection

# Verifica si el valor ingresado es la ruta relativa del archivo
if [[ "$test_selection" == $TEST_EXTENSION ]]; then
    if [ -f "$test_selection" ]; then
        selected_test="$test_selection"
    else
        echo -e "${RED}Archivo no encontrado: $test_selection${NC}"
        exit 1
    fi

# Verifica si el valor ingresado en un número
elif [[ "$test_selection" =~ ^[0-9]+$ ]] && [ "$test_selection" -ge 1 ] && [ "$test_selection" -le ${#tests[@]} ]; then
    selected_test="${tests[$((test_selection-1))]}"
else
    echo -e "${RED}Selección inválida. Ingresa un número o ruta relativa del script${NC}"
    exit 1
fi

relative_test_path="${selected_test#$TEST_DIR/}"
test_subdir=$(dirname "$relative_test_path")
filename=$(basename "$selected_test")
# Quitar solo la extensión .js para conservar ".test" en el nombre del reporte
if [ "$test_subdir" = "." ]; then
    test_name="${filename%.js}"
else
    # Para tests en subcarpetas, también quitar únicamente la extensión .js
    test_name="${filename%.js}"
fi

echo -e "${GREEN}✓ Test seleccionado: $test_name${NC}"
print_separator

# -------------------- CREA LA CARPETA DONDE SE GUARDA EL REPORTE --------------------
# Crea la misma carpeta donde esta el test en k6-tests pero en reports

if [ "$test_subdir" != "." ]; then
    report_subdir="$REPORTS_DIR/$test_subdir"
    mkdir -p "$report_subdir"
else
    report_subdir="$REPORTS_DIR"
fi

# -------------------- CREA EL NOMBRE DEL REPORTE --------------------
# Por defecto se crea basado en el nombre del test y la fecha/hora actual

default_report="${test_name}_$(date '+%d%m%Y_%H%M%S')"
echo -e -n "${YELLOW}Nombre del reporte [${NC}${default_report}${YELLOW}]:${NC} "
read -r report_name

if [ -z "$report_name" ]; then
    report_name="$default_report"
fi

# Si el nombre del reporte no termina con .html, se le agrega la extensión
if [[ "$report_name" != *.html ]]; then
    report_name="${report_name}.html"
fi

echo -e "${GREEN}✓ Reporte: $report_subdir/$report_name${NC}"
print_separator

# -------------------- CONFIGURACIÓN DE VARIABLES DE ENTORNO - K6 --------------------

# Solicita al usuario configurar variables de entorno para la ejecución del test, con valores por defecto sugeridos
echo -e "${YELLOW}Variables de entorno (presiona Enter para usar valores por defecto):${NC}"
echo ""

# 1. K6_WEB_DASHBOARD (activa el dashboard web para visualizar el progreso del test en tiempo real)
# echo -e -n "  K6_WEB_DASHBOARD [${GREEN}true${NC}]: "
# read -r web_dashboard
web_dashboard=${web_dashboard:-true}

# 2. K6_WEB_DASHBOARD_OPEN (define si el dashboard se abre automáticamente en el navegador al iniciar el test)
# echo -e -n "  K6_WEB_DASHBOARD_OPEN [${GREEN}true${NC}]: "
# read -r web_dashboard_open
web_dashboard_open=${web_dashboard_open:-$web_dashboard}

# 3. BASE_URL (opcional) sobrescribe la URL base definida en el test, solo si se proporciona un valor
echo -e -n "  BASE_URL (opcional) [${GREEN}-${NC}]: "
read -r base_url

# 4. VUs (Opcional) sobrescribe el número de usuario virtuales definido en el test, solo si se proporciona un valor
echo -e -n "  VUs (virtual users, opcional) [${GREEN}-${NC}]: "
read -r vus

# 5. Duration (opcional) sobrescribe la duración del test definido en el test, solo si se proporciona un valor
echo -e -n "  DURATION (ej: 30s, 1m, opcional) [${GREEN}-${NC}]: "
read -r duration

print_separator

# Establece las variables de entorno para ejecutar el test con k6
export K6_WEB_DASHBOARD="$web_dashboard"
export K6_WEB_DASHBOARD_OPEN="$web_dashboard_open"
export K6_WEB_DASHBOARD_EXPORT="$report_subdir/$report_name"
export BASE_URL="$base_url"

# -------------------- CONSTRUCCIÓN DEL COMANDO --------------------

cmd="k6 run"

if [ -n "$vus" ]; then
    cmd="$cmd --vus $vus"
fi

if [ -n "$duration" ]; then
    cmd="$cmd --duration $duration"
fi

cmd="$cmd $selected_test"

# Muestra un resumen de la configuración
echo -e "${YELLOW}Resumen de ejecución:${NC}"
echo -e "  Test:        ${GREEN}$selected_test${NC}"
echo -e "  Reporte:     ${GREEN}$report_subdir/$report_name${NC}"
echo -e "  BASE_URL:    ${GREEN}$base_url${NC}"
echo -e "  Dashboard:   ${GREEN}$web_dashboard${NC}"
echo -e "  Auto-open:   ${GREEN}$web_dashboard_open${NC}"
[ -n "$vus" ] && echo -e "  VUs:         ${GREEN}$vus${NC}"
[ -n "$duration" ] && echo -e "  Duration:    ${GREEN}$duration${NC}"

print_separator

# -------------------- EJECUCIÓN DEL TEST --------------------

echo -e -n "${YELLOW}¿Ejecutar test? (s/N) [${GREEN}s${NC}${YELLOW}]:${NC} "
read -r confirm
confirm=${confirm:-s}

if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo -e "${RED}Ejecución cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}Ejecutando: $cmd${NC}"
print_separator
echo ""

# Ejecuta el comando construido
eval "$cmd"

exit_code=$?

echo ""
print_separator
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✓ Test completado exitosamente${NC}"
    echo -e "${GREEN}✓ Reporte guardado en: $report_subdir/$report_name${NC}"
else
    echo -e "${RED}✗ Test finalizado con errores (código: $exit_code)${NC}"
fi
