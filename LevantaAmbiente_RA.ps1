# Obtener el nombre de usuario actual del sistema
$UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Nombre de usuario: $UserName"

# Leer la contraseña de forma segura (no se muestra en la pantalla)
$SecurePassword = Read-Host "Ingrese su contraseña de red" -AsSecureString

# Crear un objeto PSCredential con el nombre de usuario y la contraseña segura
$cred = New-Object System.Management.Automation.PSCredential ($UserName, $SecurePassword)

Invoke-Command -ComputerName "remoteapp_hostname" -Credential $cred -Authentication CredSSP -ScriptBlock {
    
    # Usar $using: para acceder a la variable local $DB_a_Restaurar_Destino
    $Alias = $using:DB_a_Restaurar_Destino  # Asignar $Alias desde $DB_a_Restaurar_Destino

    # Información de la RemoteApp
    $CollectionName = "ESCO"  # Nombre de la colección

    # Rutas de los ejecutables
    $FilePathVFondos = "C:\RemoteAPPs\ESCO\VFondos\UAT\VFondos.exe"  # Ruta para VFondosXXX
    $FilePathVBolsa = "C:\RemoteAPPs\ESCO\VBolsa\UAT\VBolsa.exe"     # Ruta para VBCibsaXXX
    $FilePathAppCustom = "C:\Custom\CustomApp.exe"                   # Ruta personalizada si no es VFondosXXX ni VBCibsaXXX


    # Ruta de red para guardar el archivo .rdp
    $NetworkPath = "\\hostname\shared"  # Ruta de red donde se guardará el archivo RDP

    # Configuración para eliminar RemoteApp existente
    $Delete_Rapp = $true  # Cambiar a $false si no deseas eliminar la RemoteApp existente

    # ======================== Importar módulo RemoteDesktop ========================
    Import-Module RemoteDesktop

    # ======================== Lógica para seleccionar el ejecutable ========================

    # Determinar el ejecutable según el alias
    if ($Alias -like "VFondos*") {
        $FilePath = $FilePathVFondos
        Write-Host "Usando el ejecutable de VFondos: $FilePathVFondos"
    } elseif ($Alias -like "VBCibsa*") {
        $FilePath = $FilePathVBolsa
        Write-Host "Usando el ejecutable de VBCibsa: $FilePathVBolsa"
    } else {
        $FilePath = $FilePathAppCustom
        Write-Host "Usando el ejecutable personalizado: $FilePathAppCustom"
    }

# ======================== Configuración de ODBC ========================
$ODBCName = $Alias
$Driver = "SQL Server"
$DBServer = "hostname"
$DBName = $ODBCName   # Definir la base de datos por defecto

# ======================== Configuración de ODBC 32 bits ========================
$ODBCKey32 = "HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\$ODBCName"

# Verificar si la configuración de ODBC de 32 bits ya existe y solo actualizar las propiedades
if (Test-Path $ODBCKey32) {
    Write-Host "Configuración de ODBC 32 bits ya existe. Sobrescribiendo las propiedades."
} else {
    # Crear una nueva configuración de ODBC 32 bits si no existe
    New-Item -Path "HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBC.INI" -Name $ODBCName
    Write-Host "Nueva configuración de ODBC 32 bits creada."
}

# Configurar las propiedades de la ODBC 32 bits
Set-ItemProperty -Path $ODBCKey32 -Name "Driver" -Value "C:\Windows\SysWOW64\sqlsrv32.dll"
Set-ItemProperty -Path $ODBCKey32 -Name "Server" -Value $DBServer
Set-ItemProperty -Path $ODBCKey32 -Name "Database" -Value $DBName  # Usar $DBName como base de datos por defecto
Set-ItemProperty -Path $ODBCKey32 -Name "Trusted_Connection" -Value "Yes"

# Agregar la ODBC al Administrador de DSN 32 bits
$ODBCDSNKey32 = "HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\ODBC Data Sources"
if (-not (Test-Path "$ODBCDSNKey32\$ODBCName")) {
    Set-ItemProperty -Path $ODBCDSNKey32 -Name $ODBCName -Value $Driver
    Write-Host "ODBC 32 bits añadida al Administrador de DSN."
}

Write-Host "ODBC de 32 bits configurada exitosamente con la base de datos por defecto '$DBName'."

# ======================== Configuración de ODBC 64 bits ========================
$ODBCKey64 = "HKLM:\SOFTWARE\ODBC\ODBC.INI\$ODBCName"

# Verificar si la configuración de ODBC de 64 bits ya existe y solo actualizar las propiedades
if (Test-Path $ODBCKey64) {
    Write-Host "Configuración de ODBC 64 bits ya existe. Sobrescribiendo las propiedades."
} else {
    # Crear una nueva configuración de ODBC 64 bits si no existe
    New-Item -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI" -Name $ODBCName
    Write-Host "Nueva configuración de ODBC 64 bits creada."
}

# Configurar las propiedades de la ODBC 64 bits
Set-ItemProperty -Path $ODBCKey64 -Name "Driver" -Value "C:\Windows\System32\sqlsrv32.dll"
Set-ItemProperty -Path $ODBCKey64 -Name "Server" -Value $DBServer
Set-ItemProperty -Path $ODBCKey64 -Name "Database" -Value $DBName  # Usar $DBName como base de datos por defecto
Set-ItemProperty -Path $ODBCKey64 -Name "Trusted_Connection" -Value "Yes"

# Agregar la ODBC al Administrador de DSN 64 bits
$ODBCDSNKey64 = "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources"
if (-not (Test-Path "$ODBCDSNKey64\$ODBCName")) {
    Set-ItemProperty -Path $ODBCDSNKey64 -Name $ODBCName -Value $Driver
    Write-Host "ODBC 64 bits añadida al Administrador de DSN."
}

Write-Host "ODBC de 64 bits configurada exitosamente con la base de datos por defecto '$DBName'."





    # ======================== RemoteApp ========================

    # Verificar si la RemoteApp ya existe
    $remoteApp = Get-RDRemoteApp -Alias $Alias -CollectionName $CollectionName -ErrorAction SilentlyContinue

    if ($remoteApp) {
        Write-Host "La RemoteApp con alias '$Alias' ya existe en la colección '$CollectionName'."

        # Eliminar la RemoteApp existente si Delete_Rapp es true
        if ($Delete_Rapp) {
            Remove-RDRemoteApp -Alias $Alias -CollectionName $CollectionName -Force
            Write-Host "RemoteApp con alias '$Alias' eliminada exitosamente."
        } else {
            Write-Host "No se eliminó la RemoteApp existente porque Delete_Rapp=$Delete_Rapp."
            return
        }
    }

    # Crear la nueva RemoteApp
    Write-Host "Creando la RemoteApp con alias '$Alias'."

    # Publicar la RemoteApp
    New-RDRemoteApp -Alias $Alias -DisplayName $Alias -FilePath $FilePath -CommandLineSetting Require -RequiredCommandLine "-dsn $Alias" -ShowInWebAccess $true -CollectionName $CollectionName

    Write-Host "RemoteApp publicada exitosamente."

    # ======================== Generar archivo .rdp ========================

    $RDPFilePath = "$NetworkPath\$Alias.rdp"

    # Contenido del archivo .rdp
    $rdpContent = @"
screen mode id:i:2
desktopwidth:i:1280
desktopheight:i:1024
session bpp:i:32
winposstr:s:0,1,0,0,800,600
compression:i:1
keyboardhook:i:2
audiocapturemode:i:1
videoplaybackmode:i:1
connection type:i:2
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
autoreconnection enabled:i:1
alternate shell:s:||$Alias
shell working directory:s:
remoteapplicationmode:i:1
remoteapplicationprogram:s:||$Alias
remoteapplicationname:s:$Alias
remoteapplicationcmdline:s:-dsn $Alias
full address:s:$env:COMPUTERNAME
"@

    # Escribir el archivo .rdp en la ubicación de red
    $rdpContent | Out-File -FilePath $RDPFilePath -Encoding ASCII

    Write-Host "Archivo RDP generado exitosamente en $RDPFilePath."

} -ArgumentList $DB_a_Restaurar_Destino
