# =============================================================================
# k6 Test Runner Script for Windows PowerShell
# =============================================================================

$TEST_DIR = "./src/k6-tests"
$REPORTS_DIR = "./reports"
$TEST_EXTENSION = "*.test.js"

# Crea el directorio reports si no existe
if (-not (Test-Path -Path $REPORTS_DIR)) {
    New-Item -ItemType Directory -Path $REPORTS_DIR | Out-Null
}

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

function Print-Header {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                       k6 Test Runner                          ║" -ForegroundColor Blue
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Print-Separator {
    Write-Host "───────────────────────────────────────────────────────────────────" -ForegroundColor Blue
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

Print-Header

# -------------------- BUSCAR ARCHIVOS --------------------

Write-Host "Pruebas disponibles:" -ForegroundColor Yellow
Print-Separator

$tests = Get-ChildItem -Path $TEST_DIR -Filter $TEST_EXTENSION -Recurse -File | Sort-Object FullName
$testArray = @()

if ($tests.Count -eq 0) {
    Write-Host "No se encontraron tests en $TEST_DIR" -ForegroundColor Red
    exit 1
}

$i = 1
foreach ($test in $tests) {
    $relativePath = $test.FullName.Replace((Resolve-Path $TEST_DIR).Path + "\", "")
    $testArray += $test.FullName
    Write-Host "  [$i] $relativePath" -ForegroundColor Green -NoNewline
    Write-Host ""
    $i++
}

Print-Separator

# -------------------- SELECCIONAR TEST A EJECUTAR --------------------

Write-Host "Selecciona el número del test o ingresa la ruta relativa del script: " -ForegroundColor Yellow -NoNewline
$testSelection = Read-Host

$selectedTest = $null

# Verifica si es una ruta de archivo
if ($testSelection -like "*.js") {
    if (Test-Path -Path $testSelection) {
        $selectedTest = (Resolve-Path $testSelection).Path
    } else {
        Write-Host "Archivo no encontrado: $testSelection" -ForegroundColor Red
        exit 1
    }
}
# Verifica si es un número válido
elseif ($testSelection -match '^\d+$' -and [int]$testSelection -ge 1 -and [int]$testSelection -le $testArray.Count) {
    $selectedTest = $testArray[[int]$testSelection - 1]
}
else {
    Write-Host "Selección inválida. Ingresa un número o ruta relativa del script" -ForegroundColor Red
    exit 1
}

$testName = [System.IO.Path]::GetFileNameWithoutExtension($selectedTest)
$relativeTestPath = $selectedTest.Replace((Resolve-Path $TEST_DIR).Path + "\", "")
$testSubdir = [System.IO.Path]::GetDirectoryName($relativeTestPath)

Write-Host "✓ Test seleccionado: $testName" -ForegroundColor Green
Print-Separator

# -------------------- CREA LA CARPETA DONDE SE GUARDA EL REPORTE --------------------
# Crea la misma carpeta donde esta el test en k6-tests pero en reports

if ([string]::IsNullOrEmpty($testSubdir) -or $testSubdir -eq ".") {
    $reportSubdir = $REPORTS_DIR
} else {
    $reportSubdir = Join-Path $REPORTS_DIR $testSubdir
    if (-not (Test-Path -Path $reportSubdir)) {
        New-Item -ItemType Directory -Path $reportSubdir | Out-Null
    }
}

# -------------------- CREA EL NOMBRE DEL REPORTE --------------------
# Por defecto se crea basado en el nombre del test y la fecha/hora actual

$defaultReport = "${testName}_$(Get-Date -Format 'ddMMyyyy_HHmmss')"
Write-Host "Nombre del reporte [" -ForegroundColor Yellow -NoNewline
Write-Host "$defaultReport" -NoNewline
Write-Host "]: " -ForegroundColor Yellow -NoNewline
$reportName = Read-Host

if ([string]::IsNullOrEmpty($reportName)) {
    $reportName = $defaultReport
}

# Si el nombre del reporte no termina con .html, se le agrega la extensión
if (-not $reportName.EndsWith(".html")) {
    $reportName = "$reportName.html"
}

Write-Host "✓ Reporte: $reportSubdir\$reportName" -ForegroundColor Green
Print-Separator

# -------------------- CONFIGURACIÓN DE VARIABLES DE ENTORNO - K6 --------------------

Write-Host "Variables de entorno (presiona Enter para usar valores por defecto):" -ForegroundColor Yellow
Write-Host ""

# K6_WEB_DASHBOARD
# Write-Host "  K6_WEB_DASHBOARD [" -NoNewline
# Write-Host "true" -ForegroundColor Green -NoNewline
# Write-Host "]: " -NoNewline
# $webDashboard = Read-Host
if ([string]::IsNullOrEmpty($webDashboard)) { $webDashboard = "true" }

# K6_WEB_DASHBOARD_OPEN
# Write-Host "  K6_WEB_DASHBOARD_OPEN [" -NoNewline
# Write-Host "$webDashboard" -ForegroundColor Green -NoNewline
# Write-Host "]: " -NoNewline
# $webDashboardOpen = Read-Host
if ([string]::IsNullOrEmpty($webDashboardOpen)) { $webDashboardOpen = $webDashboard }

# BASE_URL
Write-Host "  BASE_URL (opcional) [" -NoNewline
Write-Host "-" -ForegroundColor Green -NoNewline
Write-Host "]: " -NoNewline
$baseUrl = Read-Host

# VUs
Write-Host "  VUs (virtual users, opcional) [" -NoNewline
Write-Host "-" -ForegroundColor Green -NoNewline
Write-Host "]: " -NoNewline
$vus = Read-Host

# DURATION
Write-Host "  DURATION (ej: 30s, 1m, opcional) [" -NoNewline
Write-Host "-" -ForegroundColor Green -NoNewline
Write-Host "]: " -NoNewline
$duration = Read-Host

Print-Separator

$env:K6_WEB_DASHBOARD = $webDashboard
$env:K6_WEB_DASHBOARD_OPEN = $webDashboardOpen
$env:K6_WEB_DASHBOARD_EXPORT = Join-Path $reportSubdir $reportName
if (-not [string]::IsNullOrEmpty($baseUrl)) {
    $env:BASE_URL = $baseUrl
}

# -------------------- CONSTRUCCIÓN DEL COMANDO --------------------

$cmdArgs = @("run")

if (-not [string]::IsNullOrEmpty($vus)) {
    $cmdArgs += "--vus"
    $cmdArgs += $vus
}

if (-not [string]::IsNullOrEmpty($duration)) {
    $cmdArgs += "--duration"
    $cmdArgs += $duration
}

$cmdArgs += $selectedTest

# Muestra un resumen de la configuración
Write-Host "Resumen de ejecución:" -ForegroundColor Yellow
Write-Host "  Test:        " -NoNewline
Write-Host "$selectedTest" -ForegroundColor Green
Write-Host "  Reporte:     " -NoNewline
Write-Host "$reportSubdir\$reportName" -ForegroundColor Green
Write-Host "  BASE_URL:    " -NoNewline
Write-Host "$baseUrl" -ForegroundColor Green
Write-Host "  Dashboard:   " -NoNewline
Write-Host "$webDashboard" -ForegroundColor Green
Write-Host "  Auto-open:   " -NoNewline
Write-Host "$webDashboardOpen" -ForegroundColor Green
if (-not [string]::IsNullOrEmpty($vus)) {
    Write-Host "  VUs:         " -NoNewline
    Write-Host "$vus" -ForegroundColor Green
}
if (-not [string]::IsNullOrEmpty($duration)) {
    Write-Host "  Duration:    " -NoNewline
    Write-Host "$duration" -ForegroundColor Green
}
Print-Separator

# -------------------- EJECUCIÓN DEL TEST --------------------

Write-Host "¿Ejecutar test? (s/N) [" -ForegroundColor Yellow -NoNewline
Write-Host "s" -ForegroundColor Green -NoNewline
Write-Host "]: " -ForegroundColor Yellow -NoNewline
$confirm = Read-Host
if ([string]::IsNullOrEmpty($confirm)) { $confirm = "s" }

if ($confirm -notmatch '^[sS]$') {
    Write-Host "Ejecución cancelada" -ForegroundColor Red
    exit 0
}

# Ejecuta el comando
Write-Host ""
Write-Host "Ejecutando: k6 $($cmdArgs -join ' ')" -ForegroundColor Green
Print-Separator
Write-Host ""

& k6 $cmdArgs

$exitCode = $LASTEXITCODE

Write-Host ""
Print-Separator
if ($exitCode -eq 0) {
    Write-Host "✓ Test completado exitosamente" -ForegroundColor Green
    Write-Host "✓ Reporte guardado en: $reportSubdir\$reportName" -ForegroundColor Green
} else {
    Write-Host "✗ Test finalizado con errores (código: $exitCode)" -ForegroundColor Red
}

exit $exitCode
