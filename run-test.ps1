# =============================================================================
# k6 Test Runner Script for Windows (PowerShell)
# =============================================================================

$TestsDir = ".\k6-tests"
$ReportsDir = ".\reports"

# Crea el directorio de reportes si no existe
if (!(Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir | Out-Null
}

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Print-Header {
    Write-Host ""
    Write-ColorText "╔═══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorText "║                       k6 Test Runner                          ║"
    Write-ColorText "╚═══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Print-Separator {
    Write-ColorText "───────────────────────────────────────────────────────────────────" "Cyan"
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

Print-Header

# Busca archivos .test.js en el directorio de tests y los muestra numerados para selección
Write-ColorText "Pruebas disponibles:" "Yellow"
Print-Separator

$tests = @()
$i = 1
Get-ChildItem -Path $TestsDir -Filter "*.test.js" -Recurse | Sort-Object FullName | ForEach-Object {
    $relativePath = $_.FullName -replace [regex]::Escape($TestsDir), "" | ($_ -replace "^\\" , "")
    $tests += $_.FullName
    Write-Host "  [" -NoNewline
    Write-Host $i -ForegroundColor Green -NoNewline
    Write-Host "] $relativePath"
    $i++
}

if ($tests.Count -eq 0) {
    Write-ColorText "No se encontraron tests en $TestsDir" "Red"
    exit 1
}

Print-Separator

# Solicita selección del test a ejecutar y valida la entrada
Write-Host "Selecciona el número del test o ingresa la ruta relativa del script: " -ForegroundColor Yellow -NoNewline
$testSelection = Read-Host

$selectedTest = $null

# Verifica si es una ruta de archivo
if ($testSelection -match "\.js$") {
    if (Test-Path $testSelection) {
        $selectedTest = (Resolve-Path $testSelection).Path
    } else {
        Write-ColorText "Archivo no encontrado: $testSelection" "Red"
        exit 1
    }
}
# Verifica si es un número válido
elseif ($testSelection -match "^\d+$") {
    $testIndex = [int]$testSelection
    if ($testIndex -lt 1 -or $testIndex -gt $tests.Count) {
        Write-ColorText "Selección inválida" "Red"
        exit 1
    }
    $selectedTest = $tests[$testIndex - 1]
}
else {
    Write-ColorText "Selección inválida. Ingresa un número o ruta relativa del script" "Red"
    exit 1
}

$testName = [System.IO.Path]::GetFileNameWithoutExtension($selectedTest)
$relativeTestPath = ($selectedTest -replace [regex]::Escape($TestsDir), "") -replace "^\\" , ""
$testSubdir = Split-Path -Parent $relativeTestPath

Write-ColorText "✓ Test seleccionado: $testName" "Green"
Print-Separator

# Crea la estructura de carpetas en reports si el test está en subcarpetas
if ($testSubdir -and $testSubdir -ne ".") {
    $reportSubdir = Join-Path $ReportsDir $testSubdir
    if (!(Test-Path $reportSubdir)) {
        New-Item -ItemType Directory -Path $reportSubdir | Out-Null
    }
} else {
    $reportSubdir = $ReportsDir
}

# Genera un nombre de reporte por defecto basado en el nombre del test y la fecha/hora actual
$timestamp = Get-Date -Format "ddMMyyyy_HHmmss"
$defaultReport = "${testName}_${timestamp}"

Write-Host "Nombre del reporte [" -ForegroundColor Yellow -NoNewline
Write-Host $defaultReport -NoNewline
Write-Host "]: " -ForegroundColor Yellow -NoNewline
$reportName = Read-Host

if ([string]::IsNullOrWhiteSpace($reportName)) {
    $reportName = $defaultReport
}

# Si el nombre del reporte no termina con .html, se le agrega la extensión
if (-not $reportName.EndsWith(".html")) {
    $reportName = "${reportName}.html"
}

Write-ColorText "✓ Reporte: $(Join-Path $reportSubdir $reportName)" "Green"
Print-Separator

# Solicita al usuario configurar variables de entorno para la ejecución del test, con valores por defecto sugeridos
Write-ColorText "Variables de entorno (presiona Enter para usar valores por defecto):" "Yellow"
Write-Host ""

# K6_WEB_DASHBOARD (activa el dashboard web para visualizar el progreso del test en tiempo real)
Write-Host "  K6_WEB_DASHBOARD [" -NoNewline
Write-Host "true" -ForegroundColor Green -NoNewline
Write-Host "]: " -NoNewline
$webDashboard = Read-Host
if ([string]::IsNullOrWhiteSpace($webDashboard)) { $webDashboard = "true" }

# K6_WEB_DASHBOARD_OPEN (define si el dashboard se abre automáticamente en el navegador al iniciar el test)
Write-Host "  K6_WEB_DASHBOARD_OPEN [" -NoNewline
Write-Host "true" -ForegroundColor Green -NoNewline
Write-Host "]: " -NoNewline
$webDashboardOpen = Read-Host
if ([string]::IsNullOrWhiteSpace($webDashboardOpen)) { $webDashboardOpen = "true" }

# BASE_URL (opcional) sobrescribe la URL base definida en el test, solo si se proporciona un valor
Write-Host "  BASE_URL [" -NoNewline
Write-Host "https://test-api.k6.io" -ForegroundColor Green -NoNewline
Write-Host "]: " -NoNewline
$baseUrl = Read-Host
if ([string]::IsNullOrWhiteSpace($baseUrl)) { $baseUrl = "https://test-api.k6.io" }

# VUs (Opcional) sobrescribe el número de usuario virtuales definido en el test, solo si se proporciona un valor
Write-Host "  VUs (virtual users, vacío para usar config del test) [" -NoNewline
Write-Host "-" -ForegroundColor Green -NoNewline
Write-Host "]: " -NoNewline
$vus = Read-Host

# Duration (opcional) sobrescribe la duración del test definido en el test, solo si se proporciona un valor
Write-Host "  DURATION (ej: 30s, 1m, vacío para usar config del test) [" -NoNewline
Write-Host "-" -ForegroundColor Green -NoNewline
Write-Host "]: " -NoNewline
$duration = Read-Host

Print-Separator

# Establece las variables de entorno para ejecutar el test con k6
$env:K6_WEB_DASHBOARD = $webDashboard
$env:K6_WEB_DASHBOARD_OPEN = $webDashboardOpen
$env:K6_WEB_DASHBOARD_EXPORT = "$(Join-Path $reportSubdir $reportName)"
$env:BASE_URL = $baseUrl

# Construye el comando agregando las opciones definidas
$cmdArgs = @("run")

if (-not [string]::IsNullOrWhiteSpace($vus)) {
    $cmdArgs += "--vus"
    $cmdArgs += $vus
}

if (-not [string]::IsNullOrWhiteSpace($duration)) {
    $cmdArgs += "--duration"
    $cmdArgs += $duration
}

$cmdArgs += $selectedTest

# Muestra un resumen de la configuración antes de ejecutar el test y solicita confirmación al usuario
Write-ColorText "Resumen de ejecución:" "Yellow"
Write-Host "  Test:        " -NoNewline; Write-ColorText $selectedTest "Green"
Write-Host "  Reporte:     " -NoNewline; Write-ColorText "$(Join-Path $reportSubdir $reportName)" "Green"
Write-Host "  BASE_URL:    " -NoNewline; Write-ColorText $baseUrl "Green"
Write-Host "  Dashboard:   " -NoNewline; Write-ColorText $webDashboard "Green"
Write-Host "  Auto-open:   " -NoNewline; Write-ColorText $webDashboardOpen "Green"
if (-not [string]::IsNullOrWhiteSpace($vus)) {
    Write-Host "  VUs:         " -NoNewline; Write-ColorText $vus "Green"
}
if (-not [string]::IsNullOrWhiteSpace($duration)) {
    Write-Host "  Duration:    " -NoNewline; Write-ColorText $duration "Green"
}

Print-Separator

Write-Host "¿Ejecutar test? (s/N): " -ForegroundColor Yellow -NoNewline
$confirm = Read-Host

if ($confirm -notmatch "^[sS]$") {
    Write-ColorText "Ejecución cancelada" "Red"
    exit 0
}

# Ejecuta el comando construido
Write-Host ""
$cmdDisplay = "k6 " + ($cmdArgs -join " ")
Write-ColorText "Ejecutando: $cmdDisplay" "Green"
Print-Separator
Write-Host ""

& k6 $cmdArgs

$exitCode = $LASTEXITCODE

Write-Host ""
Print-Separator

if ($exitCode -eq 0) {
    Write-ColorText "✓ Test completado exitosamente" "Green"
    Write-ColorText "✓ Reporte guardado en: $(Join-Path $reportSubdir $reportName)" "Green"
} else {
    Write-ColorText "✗ Test finalizado con errores (código: $exitCode)" "Red"
}

exit $exitCode
