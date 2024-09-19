# Establecer la codificación en UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# Este script requiere la utilidad SQLCMD en la maquina donde se ejecuta
# https://github.com/microsoft/go-sqlcmd/releases/download/v1.8.0/sqlcmd-amd64.msi

#============================================================
# VARIABLES
#============================================================
# Definir los servidores disponibles
$ServerSQL_PRD = "hostname"
$ServerSQL_noPRD = "hostname"

# Solicitar al usuario que elija el servidor de origen
Write-Host "Elija el servidor SQL de origen:"
Write-Host "1. Produccion - $ServerSQL_PRD"
Write-Host "2. noProduccion - $ServerSQL_noPRD"
$eleccionOrigen = Read-Host "Ingrese 1 o 2 para seleccionar el servidor de origen"

# Asignar el servidor de origen según la elección del usuario
if ([string]::IsNullOrEmpty($eleccionOrigen) -or $eleccionOrigen -eq "1") {
    $ServerSQLBackup_Origen = $ServerSQL_PRD
} elseif ($eleccionOrigen -eq "2") {
    $ServerSQLBackup_Origen = $ServerSQL_noPRD
} else {
    Write-Host "Opción no válida. Saliendo del script." -ForegroundColor Red
    exit
}

# El destino siempre es $ServerSQL_noPRD
$ServerSQLRestore_Destino = $ServerSQL_noPRD
Write-Host "Servidor SQL de destino asignado a: $ServerSQLRestore_Destino"

# Solicitar al usuario que ingrese DB Origen y DB Destino
$DB_a_Backupear_Origen = Read-Host "Ingrese la DB Origen"
$DB_a_Restaurar_Destino = Read-Host "Ingrese la DB Destino"

# Preguntar si se debe levantar el ambiente, con 1-NO por defecto
Write-Host "¿Desea levantar el ambiente RemoteApps?"
Write-Host "1. NO (Predeterminado)"
Write-Host "2. SI"
$eleccionLevantaAmbiente = Read-Host "Ingrese 1 o 2 para seleccionar la opción"

# Asignar el valor de LevantaAmbiente_RA según la elección
if ([string]::IsNullOrEmpty($eleccionLevantaAmbiente) -or $eleccionLevantaAmbiente -eq "1") {
    $LevantaAmbiente_RA = $false
} elseif ($eleccionLevantaAmbiente -eq "2") {
    $LevantaAmbiente_RA = $true
} else {
    Write-Host "Opción no válida. Saliendo del script." -ForegroundColor Red
    exit
}

# Mostrar un resumen de las elecciones antes de proceder
Write-Host "`nResumen de las elecciones:"
Write-Host "-----------------------------------"
Write-Host "Servidor SQL de Origen: $ServerSQLBackup_Origen"
Write-Host "Servidor SQL de Destino: $ServerSQLRestore_Destino"
Write-Host "Base de Datos Origen: $DB_a_Backupear_Origen"
Write-Host "Base de Datos Destino: $DB_a_Restaurar_Destino"
Write-Host "Levantar Ambiente RemoteApps: $LevantaAmbiente_RA"
Write-Host "-----------------------------------"

# Confirmar si el usuario desea continuar
$confirmacion = Read-Host "¿Desea proceder con estas elecciones? (si/no)"
if ($confirmacion -ne "si") {
    Write-Host "Operación cancelada por el usuario." -ForegroundColor Red
    exit
}


$ArchivoBackupeado = $DB_a_Backupear_Origen + "_" + (Get-Date -Format yyyyMMdd_hhmm)
$RutadelBackup = "\\hostname\Shared\"
$UsuarioSQL = "userxxx"

# Solicitar la contraseña del usuario SQL de forma segura
$PassSQL = Read-Host "Ingrese la contraseña de $UsuarioSQL" -AsSecureString

# Convertir la contraseña segura a texto plano para usarla en SQLCMD
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PassSQL)
$PassSQLTextoPlano = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

$RutaMDF = "D:\SQLData\" + $DB_a_Restaurar_Destino
$RutaLDF = "L:\SQLLogs\" + $DB_a_Restaurar_Destino + "_log"

# Variables de envio de correo y log path
$CorreoDestino = "example@example.com"
$CorreoOrigen = "example@example.com"
$SmtpServidor = "hostname"
$SmtpPuerto = 25
$LogPath = "$HOME\Desktop\DB_Backup_Restore_Script.txt"  # Path para el archivo de log

# Obtener la ruta del directorio del script actual
$ScriptDirectory = $PSScriptRoot

# Definir las rutas relativas
$RutaScriptsVBCibsa = Join-Path $ScriptDirectory "scripts_unificados\VBCibsa"
$RutaScriptsVFondos = Join-Path $ScriptDirectory "scripts_unificados\VFondos"
$RutaScriptsGenerales = Join-Path $ScriptDirectory "scripts_unificados\Generales"

#============================================================
# FUNCIONES
#============================================================
function Ejecutar-SQL {
    param(
        [string]$ScriptPath,
        [string]$Base,
        [string]$Ambiente
    )

    $scriptName = [System.IO.Path]::GetFileName($ScriptPath)

    Write-Host "`n`n"
    Write-Host "============================================================"
    Write-Host "Ejecutando script: $scriptName"
    Write-Host "Ruta completa: $ScriptPath"
    Write-Host "------------------------------------------------------------"

    $result = SQLCMD -S $ServerSQLRestore_Destino -d $DB_a_Restaurar_Destino -U $UsuarioSQL -P $PassSQLTextoPlano -i $ScriptPath -v DB_a_Restaurar_Destino=$DB_a_Restaurar_Destino Base=$Base Ambiente=$Ambiente 2>&1

    if ($result) {
        Write-Host "Salida de la ejecucion:"
        $result -split "\r?\n" | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "No se recibieron mensajes de SQLCMD."
    }

    if ($result -match "Msg\s\d{4},\sLevel\s\d{1,2},\sState\s\d{1,2}") {
        Write-Host "Error al ejecutar el script: $scriptName" -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
    } else {
        Write-Host "Script ejecutado con exito: $scriptName" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green
    }
}

function Realizar-Backup {
    Write-Host "Comienzo: $(Get-Date)"
    Write-Host "Backupeando: $DB_a_Backupear_Origen"

    SQLCMD -S $ServerSQLBackup_Origen -U $UsuarioSQL -P $PassSQLTextoPlano -Q "BACKUP DATABASE [$DB_a_Backupear_Origen] TO DISK='$RutadelBackup$ArchivoBackupeado.bak' WITH COPY_ONLY, NOINIT"

    if (Test-Path $RutadelBackup$ArchivoBackupeado.bak) {
        Write-Host "BACKUP OK $RutadelBackup$ArchivoBackupeado.bak" -ForegroundColor Green
    } else {
        Write-Host "Error al realizar el backup." -ForegroundColor Red
    }
}

function Realizar-Restore {
    Write-Host "Comienzo: $(Get-Date)"
    Write-Host "Restaurando: $DB_a_Restaurar_Destino"

    $DB_a_Restaurar_DestinoExt = $ArchivoBackupeado + ".bak"
    $tmp = SQLCMD -S $ServerSQLRestore_Destino -U $UsuarioSQL -P $PassSQLTextoPlano -Q "RESTORE FILELISTONLY FROM DISK = '$RutadelBackup$DB_a_Restaurar_DestinoExt'"

    $data = $tmp[2]
    $log = $tmp[3]
    $dbnamedata = $data.Substring(0, $data.Indexof(" "))
    $dbnamelog = $log.Substring(0, $log.Indexof(" "))

    SQLCMD -S $ServerSQLRestore_Destino -U $UsuarioSQL -P $PassSQLTextoPlano -Q "
        RESTORE DATABASE [$DB_a_Restaurar_Destino] 
        FROM DISK = N'$RutadelBackup$DB_a_Restaurar_DestinoExt' 
        WITH FILE = 1, 
        MOVE N'$dbnamedata' TO N'$RutaMDF.mdf',  
        MOVE N'$dbnamelog' TO N'$RutaLDF.ldf',  
        NORECOVERY,  
        NOUNLOAD,  
        STATS = 10"

    SQLCMD -S $ServerSQLRestore_Destino -U $UsuarioSQL -P $PassSQLTextoPlano -Q "RESTORE LOG [$DB_a_Restaurar_Destino]"

    SQLCMD -S $ServerSQLRestore_Destino -U $UsuarioSQL -P $PassSQLTextoPlano -Q "ALTER DATABASE [$DB_a_Restaurar_Destino] MODIFY FILE ( NAME = '$dbnamedata', NEWNAME = '$DB_a_Restaurar_Destino' )"
    $dblog = $DB_a_Restaurar_Destino + "_log"
    SQLCMD -S $ServerSQLRestore_Destino -U $UsuarioSQL -P $PassSQLTextoPlano -Q "ALTER DATABASE [$DB_a_Restaurar_Destino] MODIFY FILE ( NAME = '$dbnamelog', NEWNAME = '$dblog' )"

    Write-Host "Restore completado con exito." -ForegroundColor Green
}

function Enviar-LogPorCorreo {
    param (
        [string]$Asunto
    )

    $cuerpo = Get-Content $LogPath | Out-String
    $adjunto = $LogPath

    Send-MailMessage -To $CorreoDestino -From $CorreoOrigen -Subject $Asunto -Body $cuerpo -SmtpServer $SmtpServidor -Port $SmtpPuerto -Attachments $adjunto

    Write-Host "Log enviado por correo a $CorreoDestino con exito." -ForegroundColor Green
}

function Ejecutar-ScriptsDirectorio {
    param(
        [string]$RutaDirectorio,
        [string]$Parametros = ""
    )
    Get-ChildItem -Path $RutaDirectorio -Filter "*.sql" | Sort-Object Name | ForEach-Object {
        Ejecutar-SQL $_.FullName $Base $Ambiente
    }
}

#============================================================
# EJECUCIONES
#============================================================
Start-Transcript -Path $LogPath

$sql = "SELECT COUNT(*) as Count FROM sys.databases WHERE LOWER(name) = LOWER('$DB_a_Restaurar_Destino')"
$comprueba = (sqlcmd -S $ServerSQLRestore_Destino -U $UsuarioSQL -P $PassSQLTextoPlano -d "master" -h -1 -W -Q $sql | Select-String -Pattern '^[0-9]').Line.Trim()

if ([int]$comprueba -eq 1) {
    Write-Host "La base de datos $DB_a_Restaurar_Destino ya existe." -ForegroundColor Red
    $decision = Read-Host "Desea eliminar la base de datos existente? (si/no)"
    
    if ($decision -eq "si") {
        $confirmacion = Read-Host "Escriba confirmar para confirmar la eliminacion"
        
        if ($confirmacion -eq "confirmar") {
            SQLCMD -S $ServerSQLRestore_Destino -U $UsuarioSQL -P $PassSQLTextoPlano -Q "ALTER DATABASE [$DB_a_Restaurar_Destino] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
            SQLCMD -S $ServerSQLRestore_Destino -U $UsuarioSQL -P $PassSQLTextoPlano -Q "DROP DATABASE [$DB_a_Restaurar_Destino]"
        } else {
            exit
        }
    } else {
        exit
    }
} else {
    Write-Host "La base de datos $DB_a_Restaurar_Destino no existe, procediendo con el restore." -ForegroundColor Green
}

Realizar-Backup
Realizar-Restore

# Detectar Base y Ambiente
if ($DB_a_Restaurar_Destino -match "^(VBCibsa|VFondos)(UAT|INT|DEV|SBX|RS).*") {
    $Base = $matches[1]
    $Ambiente = $matches[2]
} elseif ($DB_a_Restaurar_Destino -match "^(VBCibsa|VFondos).*") {
    $Base = $matches[1]
    $Ambiente = "XXX"
} else {
    # Si no se detecta VBCibsa o VFondos, asignar Base como el valor de $DB_a_Restaurar_Destino y continuar solo con los scripts generales
    Write-Host "No se detecto VBCibsa o VFondos. Base asignada a: $DB_a_Restaurar_Destino" -ForegroundColor Yellow
    $Base = $DB_a_Restaurar_Destino
    $Ambiente = "XXX"
}

Write-Host "Base detectada: $Base" -ForegroundColor Green
Write-Host "Ambiente detectado: $Ambiente" -ForegroundColor Green

# Aplica Scripts Generales
Ejecutar-ScriptsDirectorio $RutaScriptsGenerales

# Ejecutar scripts SQL segun la base detectada
if ($Base -eq "VBCibsa") {
    Ejecutar-ScriptsDirectorio $RutaScriptsVBCibsa
} elseif ($Base -eq "VFondos") {
    Ejecutar-ScriptsDirectorio $RutaScriptsVFondos
}

# Levantar el ambiente y ejecutar LevantaAmbiente_RA.ps1
if ($LevantaAmbiente_RA -eq $true) {
    $PisadaScriptPath = Join-Path $ScriptDirectory "LevantaAmbiente_RA.ps1"
    
    if (Test-Path $PisadaScriptPath) {
        Write-Host "Ejecutando el script LevantaAmbiente_RA.ps1 con la variable $DB_a_Restaurar_Destino"
        . $PisadaScriptPath -DB_a_Restaurar_Destino $DB_a_Restaurar_Destino
    } else {
        Write-Host "Error: No se encontro el archivo LevantaAmbiente_RA.ps1 en la ruta $PisadaScriptPath" -ForegroundColor Red
    }
}

Stop-Transcript
Enviar-LogPorCorreo -Asunto "Se restauro $DB_a_Restaurar_Destino con $DB_a_Backupear_Origen"
pause
