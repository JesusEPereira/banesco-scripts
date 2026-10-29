# =========================================================================
# Guardarrail PostToolUse: post-tool-ps1.ps1
# Banesco - Capa 4 de la Arquitectura Neurosimbolica
# Accion: Inyeccion atomica de BOM UTF-8 y saneamiento de codificacion
# Contrato: Emite exclusivamente {} a stdout
# =========================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $inputJson = [Console]::In.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($inputJson)) {
        # 1. Extraccion agnostica de rutas sobre el payload crudo
        $pathPattern = '(?i)"([a-zA-Z]:[^\r\n"<>|]+?\.(?:ps1|psm1))"'
        $regexMatches = [regex]::Matches($inputJson, $pathPattern)

        $utf8Bom = [byte[]](0xEF, 0xBB, 0xBF)

        foreach ($match in $regexMatches) {
            $filePath = $match.Groups[1].Value
            if (Test-Path -LiteralPath $filePath -PathType Leaf) {
                try {
                    $bytes = [System.IO.File]::ReadAllBytes($filePath)
                    $hasBom = ($bytes.Length -ge 3 -and 
                               $bytes[0] -eq 0xEF -and 
                               $bytes[1] -eq 0xBB -and 
                               $bytes[2] -eq 0xBF)

                    if (-not $hasBom) {
                        # Inyeccion atomica del BOM UTF-8
                        $newBytes = New-Object byte[] ($bytes.Length + 3)
                        [System.Buffer]::BlockCopy($utf8Bom, 0, $newBytes, 0, 3)
                        [System.Buffer]::BlockCopy($bytes, 0, $newBytes, 3, $bytes.Length)
                        [System.IO.File]::WriteAllBytes($filePath, $newBytes)
                    }
                }
                catch {
                    # No interrumpir si el archivo esta bloqueado temporalmente
                }
            }
        }
    }
}
catch {
    # Silencioso ante fallos del hook
}

# Respuesta obligatoria del contrato PostToolUse
Write-Output '{}'
exit 0

