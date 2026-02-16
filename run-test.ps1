<#
  k6 Test Runner - PowerShell (cleaned)
  Single coherent script, ASCII-friendly to avoid encoding issues.
#>

param()

$TEST_DIR = 'k6-tests'
$REPORTS_DIR = 'reports'

function Print-Header {
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                       k6 Test Runner                          ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Print-Separator {
    Write-Host '------------------------------------------------' -ForegroundColor Cyan
}

# Crea el directorio reports si no existe
if (-not (Test-Path -Path $REPORTS_DIR)) {
    New-Item -ItemType Directory -Path $REPORTS_DIR -Force | Out-Null
}

Print-Header

Write-Host 'Pruebas disponibles:' -ForegroundColor Yellow
Print-Separator

try {
    $baseFull = (Get-Item $TEST_DIR -ErrorAction Stop).FullName
} catch {
    Write-Host "Directorio de tests no encontrado: $TEST_DIR" -ForegroundColor Red
    exit 1
}

$tests = Get-ChildItem -Path $TEST_DIR -Recurse -Filter '*.test.js' -File | Sort-Object FullName
if ($tests.Count -eq 0) {
    Write-Host "No se encontraron tests en $TEST_DIR" -ForegroundColor Red
    exit 1
}

$i = 1
$testsFull = @()
foreach ($file in $tests) {
    $rel = $file.FullName.Substring($baseFull.Length + 1)
    $testsFull += $file.FullName
    Write-Host "  [$i] $rel" -ForegroundColor Green
    $i++
}

Print-Separator

$selection = Read-Host -Prompt 'Selecciona el numero del test o ingresa la ruta relativa del script'

if ($selection -and $selection.ToLower().EndsWith('.js')) {
    if (-not [System.IO.Path]::IsPathRooted($selection)) { $candidate = Join-Path $TEST_DIR $selection } else { $candidate = $selection }
    if (Test-Path -Path $candidate) { $selected_test = (Get-Item $candidate).FullName } else { Write-Host "Archivo no encontrado: $selection" -ForegroundColor Red; exit 1 }
}
elseif ($selection -match '^[0-9]+$') {
    $idx = [int]$selection
    if ($idx -ge 1 -and $idx -le $testsFull.Count) { $selected_test = $testsFull[$idx - 1] } else { Write-Host 'Seleccion invalida' -ForegroundColor Red; exit 1 }
}
else { Write-Host 'Seleccion invalida' -ForegroundColor Red; exit 1 }

$test_name = [System.IO.Path]::GetFileNameWithoutExtension($selected_test)
if ($selected_test.StartsWith($baseFull)) { $relative_test_path = $selected_test.Substring($baseFull.Length + 1) } else { $relative_test_path = [System.IO.Path]::GetFileName($selected_test) }

$test_subdir = [System.IO.Path]::GetDirectoryName($relative_test_path)
if (-not $test_subdir) { $test_subdir = '.' }

Write-Host "Test seleccionado: $test_name" -ForegroundColor Green
Print-Separator

if ($test_subdir -ne '.') {
    $report_subdir = Join-Path $REPORTS_DIR $test_subdir
    if (-not (Test-Path -Path $report_subdir)) { New-Item -ItemType Directory -Path $report_subdir -Force | Out-Null }
} else { $report_subdir = $REPORTS_DIR }

$default_report = "${test_name}_$(Get-Date -Format 'ddMMyyyy_HHmmss')"
$report_name = Read-Host -Prompt "Nombre del reporte [$default_report]"
if ([string]::IsNullOrWhiteSpace($report_name)) { $report_name = $default_report }
if (-not $report_name.ToLower().EndsWith('.html')) { $report_name = "$report_name.html" }

Write-Host "Reporte: $report_subdir/$report_name" -ForegroundColor Green
Print-Separator

Write-Host 'Variables de entorno (presiona Enter para usar valores por defecto):' -ForegroundColor Yellow

$web_dashboard = Read-Host -Prompt '  K6_WEB_DASHBOARD [true]'
if ([string]::IsNullOrWhiteSpace($web_dashboard)) { $web_dashboard = 'true' }

$web_dashboard_open = Read-Host -Prompt '  K6_WEB_DASHBOARD_OPEN [true]'
if ([string]::IsNullOrWhiteSpace($web_dashboard_open)) { $web_dashboard_open = 'true' }

$base_url = Read-Host -Prompt '  BASE_URL (opcional) [-]'
$vus = Read-Host -Prompt '  VUs (virtual users, opcional) [-]'
$duration = Read-Host -Prompt '  DURATION (ej: 30s, 1m, opcional) [-]'

Print-Separator

$env:K6_WEB_DASHBOARD = $web_dashboard
$env:K6_WEB_DASHBOARD_OPEN = $web_dashboard_open
$env:K6_WEB_DASHBOARD_EXPORT = Join-Path $report_subdir $report_name
if ($base_url) { $env:BASE_URL = $base_url } else { Remove-Item Env:BASE_URL -ErrorAction SilentlyContinue }

$args = @('run','-l')
if (-not [string]::IsNullOrWhiteSpace($vus)) { $args += '--vus'; $args += $vus }
if (-not [string]::IsNullOrWhiteSpace($duration)) { $args += '--duration'; $args += $duration }
$args += $selected_test

Write-Host 'Resumen de ejecucion:' -ForegroundColor Yellow
Write-Host "  Test:        $selected_test" -ForegroundColor Green
Write-Host "  Reporte:     $report_subdir/$report_name" -ForegroundColor Green
Write-Host "  BASE_URL:    $base_url" -ForegroundColor Green
Write-Host "  Dashboard:   $web_dashboard" -ForegroundColor Green
Write-Host "  Auto-open:   $web_dashboard_open" -ForegroundColor Green
if (-not [string]::IsNullOrWhiteSpace($vus)) { Write-Host "  VUs:         $vus" -ForegroundColor Green }
if (-not [string]::IsNullOrWhiteSpace($duration)) { Write-Host "  Duration:    $duration" -ForegroundColor Green }
Print-Separator

$confirm = Read-Host -Prompt 'Ejecutar test? (s/N) [s]'
if ([string]::IsNullOrWhiteSpace($confirm)) { $confirm = 's' }
if ($confirm -notmatch '^[sS]') { Write-Host 'Ejecucion cancelada' -ForegroundColor Red; exit 0 }

Write-Host "" 
Write-Host "Ejecutando: k6 $($args -join ' ')" -ForegroundColor Green
Print-Separator
Write-Host ""

& k6 @args
$exit_code = $LASTEXITCODE

Write-Host ""
Print-Separator
if ($exit_code -eq 0) {
    Write-Host 'Test completado exitosamente' -ForegroundColor Green
    Write-Host "Reporte guardado en: $report_subdir/$report_name" -ForegroundColor Green
} else {
    Write-Host "Test finalizado con errores (codigo: $exit_code)" -ForegroundColor Red
}

exit $exit_code
