@{
    # =========================================================================
    # Banesco - Manifiesto Declarativo de Infraestructura (SSOT)
    # Capa 1 de la Arquitectura Neurosimbólica de Ingeniería Agéntica
    # Formato: PowerShell Data File (.psd1) - Restricted Language Mode
    # Regla: Exclusivamente comillas simples (') para evitar errores de AST
    # =========================================================================

    ActiveDirectory = @{
        Domain               = 'intra.banesco.com'
        LdapsPort            = 636
        TargetOU             = 'OU=Usuarios,DC=intra,DC=banesco,DC=com'
        ServiceAccountOU     = 'OU=Cuentas de Servicios,DC=intra,DC=banesco,DC=com'
        ServiceAccountPrefix = '^(?i)svc_?'
    }

    OracleRRHH = @{
        ConnectionName = 'fucsion.intra.banesco.com'
        Host           = 'sdb8023.intra.banesco.com'
        Port           = 1521
        Sid            = 'rrhh'
        User           = 'actived'
        TableActive    = 'actived'
        TableEgress    = 'actived_ret'
    }

    AS400 = @{
        LparHost             = '10.137.0.138'
        Version              = 'v7.5'
        UserCatalogTable     = 'QSYS2.USER_INFO'
        CommandExecProcedure = 'QSYS2.QCMDEXC'
        LdapsPort            = 636
        SessionTimeoutMin    = 15
    }

    MatricesUNC = @{
        RootPath          = '\\intra.banesco.com\datos\Central\Gerencias\Vp Ejec Prev Perdidas y Cont Neg\Vp Cont del Negocio\Gcia Div Gesti*n y Control\VP PREVENCION\AdminSegTI'
        DefaultPath       = '\\intra.banesco.com\datos\Central\Gerencias\Vp Ejec Prev Perdidas y Cont Neg\Vp Cont del Negocio\Gcia Div Gesti*n y Control\VP PREVENCION\AdminSegTI\Prueba2026'
        BackupSubfolder   = '_Versiones_Historicas'
        UsersSheetName    = 'Usuarios'
        MatrixSheetName   = 'Matriz'
        HeaderRow         = 11
        DataStartRow      = 12
    }

    CerebroDigital = @{
        RootDrive         = 'D:\Cerebro Digital'
        DailyScanTaskName = 'CerebroDigital_DailyScan'
        ScanLogFile       = 'D:\Cerebro Digital\Daily_Scan_Log.txt'
    }
}

