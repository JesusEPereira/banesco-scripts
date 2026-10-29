<#
.SYNOPSIS
    Valida el cumplimiento normativo de una presentacion (.pptx) contra los estandares de Banesco Banco 2026.
.PARAMETER PptxPath
    Ruta al archivo PowerPoint (.pptx) a auditar.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$PptxPath
)

if (-not (Test-Path -Path $PptxPath)) {
    Write-Error "El archivo especificado no existe: $PptxPath"
    exit 1
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$resolvedPath = (Resolve-Path $PptxPath).Path
$zip = [System.IO.Compression.ZipFile]::OpenRead($resolvedPath)

$slideEntries = $zip.Entries | Where-Object { $_.FullName -match "^ppt/slides/slide\d+\.xml$" }
$totalSlides = $slideEntries.Count

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " AUDITORIA DE PRESENTACION CORPORATIVA BANESCO 2026" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Archivo analizado: $resolvedPath" -ForegroundColor White
Write-Host "Total de laminas : $totalSlides`n" -ForegroundColor White

# 1. Validacion de Limite de Laminas (Regla de maximo 16 laminas)
if ($totalSlides -gt 16) {
    Write-Host "[ALERTA] Excede el limite de 16 laminas recomendado por Alida Ribbi ($totalSlides > 16)." -ForegroundColor Red
} else {
    Write-Host "[OK] Cumple la regla de tamano de presentacion ($totalSlides <= 16 laminas)." -ForegroundColor Green
}

# 2. Validacion de Resumen Ejecutivo en Lamina 2
$s2Entry = $zip.Entries | Where-Object { $_.FullName -eq "ppt/slides/slide2.xml" }
if ($s2Entry) {
    $s2Stream = $s2Entry.Open()
    $s2Reader = New-Object System.IO.StreamReader($s2Stream)
    $s2Txt = $s2Reader.ReadToEnd()
    $s2Reader.Close()
    $s2Stream.Close()

    if ($s2Txt -match "Resumen Ejecutivo" -or $s2Txt -match "Tipo de Punto" -or $s2Txt -match "Punto de Cuenta") {
        Write-Host "[OK] Lamina 2 incluye la estructura de Resumen Ejecutivo para organos de gobierno." -ForegroundColor Green
    } else {
        Write-Host "[ADVERTENCIA] Lamina 2 no parece contener el formato estandar de Resumen Ejecutivo." -ForegroundColor Yellow
    }
}

Write-Host "`n----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " AUDITORIA DE TITULARES (Regla de maximo 15 palabras)" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray

# Sort slides numerically
$sortedSlides = $slideEntries | Sort-Object { [int](([regex]::Match($_.FullName, '\d+')).Value) }

$titularIssues = 0
foreach ($entry in $sortedSlides) {
    $slideNum = [int](([regex]::Match($entry.FullName, '\d+')).Value)
    if ($slideNum -eq 1 -or $slideNum -eq 2) { continue } # Portada y Resumen Ejecutivo se omiten

    $stream = $entry.Open()
    $reader = New-Object System.IO.StreamReader($stream)
    $slideXml = $reader.ReadToEnd()
    $reader.Close()
    $stream.Close()

    # Intentar extraer el primer texto significativo que actua como titular
    $matches = [regex]::Matches($slideXml, "<a:t(?:[^>]*)>([^<]+)</a:t>")
    $texts = ($matches | ForEach-Object { $_.Groups[1].Value.Trim() } | Where-Object { $_.Length -gt 0 -and $_ -ne "‹#›" })
    
    if ($texts.Count -gt 0) {
        $titularCand = $texts[0]
        # Si el titular viene dividido en 2 runs iniciales
        if ($texts.Count -gt 1 -and $texts[1] -match "^[a-z]") {
            $titularCand += " " + $texts[1]
        }
        
        $wordCount = ($titularCand -split '\s+').Count
        if ($wordCount -gt 15) {
            $titularIssues++
            Write-Host ("[ALERTA] Lamina {0,2} ({1} palabras): '{2}'" -f $slideNum, $wordCount, $titularCand) -ForegroundColor Red
        } else {
            Write-Host ("[OK]     Lamina {0,2} ({1,2} palabras): '{2}'" -f $slideNum, $wordCount, $titularCand) -ForegroundColor Gray
        }
    }
}

if ($titularIssues -eq 0) {
    Write-Host "`n[EXITO] Todos los titulares evaluados cumplen con el limite de 15 palabras." -ForegroundColor Green
} else {
    Write-Host "`n[REVISION REQUERIDA] Se encontraron $titularIssues titular(es) con mas de 15 palabras." -ForegroundColor Yellow
}

$zip.Dispose()
