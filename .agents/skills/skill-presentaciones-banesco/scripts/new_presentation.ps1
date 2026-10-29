<#
.SYNOPSIS
    Crea una nueva presentacion corporativa basada en la Plantilla Maestra Oficial Banesco Banco 2026_V2.
.PARAMETER ProjectName
    Nombre del proyecto o presentacion (ej. "Comite_Auditoria_Q3").
.PARAMETER DestinationFolder
    Carpeta de destino donde se guardara la nueva presentacion. Por defecto se usa la carpeta actual.
.PARAMETER Overwrite
    Fuerza la sobreescritura si el archivo ya existe.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ProjectName,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$DestinationFolder = ".",

    [Parameter(Mandatory = $false)]
    [switch]$Overwrite
)

$templateCandidates = @(
    "D:\Cerebro Digital\09_Scripts_y_Herramientas\Plantillas\Plantilla Corporativa Banesco Banco 2026_V2.pptx",
    "D:\Cerebro Digital\Plantilla Corporativa Banesco Banco 2026_V2.pptx"
)
$templatePath = $templateCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $templatePath) {
    Write-Error "No se encontro la plantilla maestra oficial en ninguna de las ubicaciones esperadas."
    exit 1
}

if (-not (Test-Path -Path $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
    Write-Host "Carpeta de destino creada: $DestinationFolder" -ForegroundColor Cyan
}

# Sanitizar nombre del archivo
$cleanName = $ProjectName -replace '[\\/:*?"<>|]', '_'
if (-not $cleanName.EndsWith(".pptx")) {
    $cleanName += ".pptx"
}

$destPath = Join-Path -Path (Resolve-Path $DestinationFolder).Path -ChildPath $cleanName

if ((Test-Path -Path $destPath) -and (-not $Overwrite)) {
    Write-Error "El archivo de destino ya existe: $destPath. Use -Overwrite para reemplazarlo."
    exit 1
}

Copy-Item -Path $templatePath -Destination $destPath -Force

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  PRESENTACION CORPORATIVA BANESCO CREADA EXITOSAMENTE   " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Archivo generado : $destPath" -ForegroundColor White
Write-Host "Plantilla origen : $templatePath" -ForegroundColor Gray
Write-Host "`nRecordatorios clave para la edicion:" -ForegroundColor Yellow
Write-Host " - Maximo 16 laminas (1 Portada, 1 Resumen, <=10 Contenido, 1 Portadilla anexo, <=2 Anexos, 1 Cierre)"
Write-Host " - Titulares de contenido: Frases activas de maximo 15 palabras."
Write-Host " - Colores predominantes: Verde #08543C (30-50%) y Blanco #FFFFFF (30-50%)."
Write-Host " - Tipografia oficial: Poppins."
