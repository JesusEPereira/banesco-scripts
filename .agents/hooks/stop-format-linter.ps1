# =========================================================================
# Guardarrail Stop: stop-format-linter.ps1
# Banesco - Capa 4 de la Arquitectura Neurosimbolica
# Accion: Deteccion de fugas sintacticas de LaTeX / variables matematicas
# Contrato: Emite {"decision": "continue", "reason": "..."} si hay error
# =========================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $inputJson = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($inputJson)) {
        Write-Output '{}'
        exit 0
    }

    $payload = $inputJson | ConvertFrom-Json
    $transcriptPath = $payload.transcriptPath

    if ($transcriptPath -and (Test-Path -LiteralPath $transcriptPath)) {
        $lastLines = Get-Content -LiteralPath $transcriptPath -Tail 15 -ErrorAction SilentlyContinue
        $plannerText = ''

        foreach ($line in $lastLines) {
            if ($line -match '"type"\s*:\s*"PLANNER_RESPONSE"' -or $line -match '"source"\s*:\s*"MODEL"') {
                try {
                    $stepObj = $line | ConvertFrom-Json
                    if ($stepObj.content) {
                        $plannerText = $stepObj.content
                    }
                }
                catch {}
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($plannerText)) {
            # Descartar bloques de codigo cercados (fenced code blocks) para proteger variables legitimas
            $sanitized = [regex]::Replace($plannerText, '(?s)```.*?```', '')

            # Detectar formulas matematicas tipo LaTeX: $$...$$ o \(...\) o \[...\]
            if ($sanitized -match '\$\$[^\$]+\$\$' -or $sanitized -match '\\\([^\)]+\\\)' -or $sanitized -match '\\\[[^\]]+\\\]') {
                $continueObj = @{
                    decision = 'continue'
                    reason   = '[GUARDARRAIL] Se detecto sintaxis matematica LaTeX en el texto explicativo. Convierta las formulas a texto plano o flechas Unicode (A -> B) antes de finalizar el turno.'
                }
                Write-Output ($continueObj | ConvertTo-Json -Compress)
                exit 0
            }
        }
    }
}
catch {
    # Silencioso en caso de error de lectura
}

Write-Output '{}'
exit 0

