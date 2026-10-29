# =========================================================================
# Guardarrail PreToolUse: safety-gate.ps1
# Banesco - Capa 4 de la Arquitectura Neurosimbolica
# Invariante: Cero emojis, busqueda agnostica por Regex sobre payload crudo
# =========================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $inputJson = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($inputJson)) {
        Write-Output '{"decision": "allow"}'
        exit 0
    }

    # 1. Extraccion agnostica de rutas por Regex (Gotcha 1 del Manual)
    $pathPattern = '(?i)"([a-zA-Z]:[^\r\n"<>|]+?\.(?:ps1|psm1|json|html|js|css|py|md))"'
    $regexMatches = [regex]::Matches($inputJson, $pathPattern)

    # 2. Validacion de marcadores de incertidumbre en planes o modificaciones criticas
    $uncertaintyPattern = '(?i)\b(TBD|por confirmar|se asume que|a definir)\b'
    if ($inputJson -match $uncertaintyPattern) {
        $denyObj = @{
            decision = 'deny'
            reason   = '[GUARDARRAIL] Operacion bloqueada: Se detectaron marcadores de incertidumbre (TBD / por confirmar / suposiciones). Aclare los parametros antes de continuar.'
        }
        Write-Output ($denyObj | ConvertTo-Json -Compress)
        exit 0
    }

    # 3. Decision determinista: Permitir
    Write-Output '{"decision": "allow"}'
}
catch {
    # Fail-safe pasivo
    Write-Output '{"decision": "allow"}'
}
exit 0
