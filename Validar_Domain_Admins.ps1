# ================================================================================
# Script de Auditoría de Seguridad: Validación de Cuentas Domain Admins
# Ubicación en Cerebro Digital: D:\Cerebro Digital\09_Scripts_y_Herramientas\PowerShell\Auditoria_Seguridad
# ================================================================================

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$outDir = "D:\Cerebro Digital\09_Scripts_y_Herramientas\PowerShell\Auditoria_Seguridad"
if (-not (Test-Path -Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = Join-Path $outDir "Reporte_Domain_Admins_$timestamp.csv"

function Fix-Text ($t) {
    if ([string]::IsNullOrEmpty($t)) { return $t }
    $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($t)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "         AUDITORÍA DE CUENTAS DOMAIN ADMINS (ACTIVE DIRECTORY)                  " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Fecha/Hora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray

$results = @()

# Función para extraer la OU legible desde un DistinguishedName
function Get-OUFromDN ($dn) {
    if ([string]::IsNullOrEmpty($dn)) { return "N/A" }
    $parts = $dn -split "," | Where-Object { $_ -like "OU=*" }
    if ($parts) {
        return (($parts -replace "OU=", "") -join "/")
    } else {
        return "Raíz / Containers Predeterminados"
    }
}

# Intentar primero con el módulo ActiveDirectory
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
}

if (Get-Command Get-ADGroupMember -ErrorAction SilentlyContinue) {
    Write-Host "[+] Obteniendo miembros del grupo Domain Admins usando el módulo ActiveDirectory..." -ForegroundColor Green
    try {
        # Buscar grupo por SID o nombre
        $group = Get-ADGroup -Filter "SID -like 'S-1-5-21-*-512' -or Name -eq 'Domain Admins' -or Name -eq 'Administradores del Dominio'" -ErrorAction Stop | Select-Object -First 1
        if ($group) {
            $members = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive | Where-Object { $_.objectClass -eq 'user' }
            foreach ($m in $members) {
                $u = Get-ADUser -Identity $m.DistinguishedName -Properties DisplayName, Description, Enabled, DistinguishedName
                $ou = Get-OUFromDN $u.DistinguishedName
                $estado = if ($u.Enabled) { "Habilitada" } else { "Deshabilitada" }

                $results += [PSCustomObject]@{
                    "Usuario"           = $u.sAMAccountName
                    "Nombre_Completo"   = if ($u.DisplayName) { Fix-Text $u.DisplayName } else { "N/A" }
                    "OU"                = Fix-Text $ou
                    "Descripcion"       = if ($u.Description) { Fix-Text $u.Description } else { "Sin Descripción" }
                    "Estado_Cuenta"     = $estado
                }
            }
        }
    } catch {
        Write-Warning "No se pudo consultar mediante cmdlet RSAT: $_. Se procederá con fallback ADSI..."
    }
}

# Fallback nativo mediante ADSI / DirectorySearcher si no hay resultados aún
if ($results.Count -eq 0) {
    Write-Host "[+] Ejecutando consulta nativa LDAP (ADSI Searcher)..." -ForegroundColor Yellow
    try {
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.Filter = "(|(samAccountName=Domain Admins)(samAccountName=Administradores del Dominio))"
        $groupResult = $searcher.FindOne()

        if ($groupResult) {
            $groupEntry = $groupResult.GetDirectoryEntry()
            foreach ($memberDN in $groupEntry.member) {
                $userEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$memberDN")
                if ($userEntry.SchemaClassName -eq "user") {
                    $uName = $userEntry.sAMAccountName.Value
                    $dispName = $userEntry.displayName.Value
                    $desc = $userEntry.description.Value
                    $userFlags = $userEntry.userAccountControl.Value
                    $isDisabled = [bool]($userFlags -band 2)
                    $estado = if ($isDisabled) { "Deshabilitada" } else { "Habilitada" }
                    $ou = Get-OUFromDN $memberDN

                    $results += [PSCustomObject]@{
                        "Usuario"           = $uName
                        "Nombre_Completo"   = if ($dispName) { Fix-Text $dispName } else { "N/A" }
                        "OU"                = Fix-Text $ou
                        "Descripcion"       = if ($desc) { Fix-Text $desc } else { "Sin Descripción" }
                        "Estado_Cuenta"     = $estado
                    }
                }
            }
        } else {
            Write-Warning "No se encontró el grupo Domain Admins en el dominio o no hay conectividad con un Controlador de Dominio."
        }
    } catch {
        Write-Error "Falla en la consulta LDAP ADSI: $_"
    }
}

# Presentación de Resultados en Consola
if ($results.Count -gt 0) {
    Write-Host "`n[RESULTADOS DE AUDITORÍA - $(${results}.Count) Cuentas Encontradas]`n" -ForegroundColor Cyan
    
    foreach ($r in $results) {
        $color = if ($r.Estado_Cuenta -eq "Habilitada") { "Green" } else { "Red" }
        Write-Host ("Usuario          : {0}" -f $r.Usuario) -ForegroundColor White
        Write-Host ("Nombre Completo  : {0}" -f $r.Nombre_Completo)
        Write-Host ("Unidad Org (OU)  : {0}" -f $r.OU)
        Write-Host ("Descripción      : {0}" -f $r.Descripcion)
        Write-Host ("Estado de Cuenta : {0}" -f $r.Estado_Cuenta) -ForegroundColor $color
        Write-Host ("-" * 60) -ForegroundColor Gray
    }

    # Exportar Reporte a CSV con codificación UTF8
    $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n[OK] Reporte exportado exitosamente a:" -ForegroundColor Green
    Write-Host "     $csvPath`n" -ForegroundColor White
} else {
    Write-Host "`n[i] Nota: Para ejecutar este script contra Active Directory, ejecútelo desde una máquina unida al dominio con credenciales de lectura.`n" -ForegroundColor Yellow
}
