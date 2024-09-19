# PisadaX.ps1 - Backup & Restore Automation Script

Este script, llamado **PisadaX.ps1**, automatiza el proceso de backup y restore de una base de datos en SQL Server, ejecuta scripts SQL basados en la base de datos y el ambiente detectado, y puede levantar RemoteApps si se especifica. Además, genera un log detallado de todas las operaciones realizadas y lo envía por correo electrónico.

## Funcionalidad

El script se encarga de las siguientes tareas principales:

1. **Backup de la base de datos de origen**:
   - Se realiza un backup de la base de datos especificada en la variable `$DB_a_Backupear_Origen` desde el servidor `$ServerSQLBackup_Origen`.
   - El backup se guarda en una ubicación compartida definida en `$RutadelBackup`.

2. **Restore de la base de datos en el servidor destino**:
   - Se restaura la base de datos especificada en `$DB_a_Restaurar_Destino` desde el servidor de destino `$ServerSQLRestore_Destino`.
   - El script gestiona el movimiento de archivos MDF y LDF a las rutas especificadas (`$RutaMDF` y `$RutaLDF`).
   - Si la base de datos ya existe, el script solicita confirmación para eliminarla antes de proceder con el restore.

3. **Detección de base y ambiente**:
   - Se detecta si la base es `VBCibsa` o `VFondos`, y se identifica el ambiente basado en las siglas en el nombre (UAT, INT, DEV, SBX, RS).
   - Si no se encuentra un ambiente válido, el script asigna "XXX" como valor por defecto para el ambiente.

4. **Ejecución de scripts SQL**:
   - Dependiendo de la base y el ambiente detectado, el script ejecuta los archivos `.sql` ubicados en los directorios correspondientes a `VBCibsa` o `VFondos`.
   - Los scripts SQL se ejecutan usando `sqlcmd`, y las variables `Base` y `Ambiente` se pasan como parámetros a los scripts.

5. **Aplicación de scripts generales**:
   - Se ejecutan scripts generales que son aplicables independientemente de la base o el ambiente.

6. **Levantamiento del ambiente RemoteApps**:
   - Si `$LevantaAmbiente_RA` está configurado como `$true`, el script ejecuta un script adicional llamado `LevantaAmbiente_RA.ps1`, que gestiona el levantamiento del ambiente RemoteApps.
   - El script verifica si el archivo `LevantaAmbiente_RA.ps1` existe antes de intentar ejecutarlo.

7. **Generación y envío de logs**:
   - El script genera un log detallado de todas las operaciones realizadas, el cual se guarda en la ruta especificada por `$LogPath`.
   - Una vez finalizado, el log se envía por correo a la dirección especificada en `$CorreoDestino` utilizando el servidor SMTP definido en `$SmtpServidor`.

## Flujo del Script

1. **Inicio de Transcripción**:
   - El script comienza registrando todas las operaciones en un archivo de log especificado por `$LogPath`.

2. **Verificación de la existencia de la base de datos**:
   - Se verifica si la base de datos destino ya existe en el servidor de destino. Si existe, el script pregunta si debe eliminarse antes de proceder con el restore.

3. **Backup de la base de datos de origen**:
   - Se realiza un backup de la base de datos de origen y se almacena en la ubicación de red especificada.

4. **Restore de la base de datos en el servidor de destino**:
   - Se restaura la base de datos destino utilizando el archivo de backup generado.

5. **Detección de base y ambiente**:
   - El script detecta si la base es `VBCibsa` o `VFondos` y establece el ambiente basado en el nombre de la base de datos.

6. **Ejecución de scripts SQL**:
   - Se ejecutan los scripts SQL correspondientes a la base y el ambiente detectados.
   - Luego, se aplican los scripts generales que son independientes de la base y el ambiente.

7. **Levantamiento del ambiente RemoteApps (opcional)**:
   - Si está habilitada la opción `$LevantaAmbiente_RA`, el script ejecuta `LevantaAmbiente_RA.ps1` para levantar el ambiente RemoteApps.

8. **Envío de logs por correo**:
   - El log generado se envía por correo electrónico a la dirección especificada.

9. **Fin de Transcripción**:
   - El script finaliza cerrando la transcripción y deteniendo la captura de log.

## Variables Clave

- **$ServerSQLBackup_Origen**: Servidor de origen donde se realiza el backup.
- **$DB_a_Backupear_Origen**: Nombre de la base de datos de origen para el backup.
- **$ServerSQLRestore_Destino**: Servidor de destino donde se realiza el restore.
- **$DB_a_Restaurar_Destino**: Nombre de la base de datos destino para el restore.
- **$LevantaAmbiente_RA**: Si está configurado como `$true`, se levanta el ambiente RemoteApps.
- **$RutaScriptsVBCibsa**: Ruta de los scripts SQL para `VBCibsa`.
- **$RutaScriptsVFondos**: Ruta de los scripts SQL para `VFondos`.
- **$RutaScriptsGenerales**: Ruta de los scripts SQL generales.
- **$CorreoDestino**: Dirección de correo electrónico donde se enviará el log.
- **$LogPath**: Ruta del archivo donde se guarda el log.

## Requisitos

1. **SQLCMD**: Se requiere la utilidad `SQLCMD` en la máquina donde se ejecuta el script para ejecutar comandos SQL.
2. **Permisos SQL**: El usuario especificado en `$UsuarioSQL` debe tener permisos suficientes para realizar backups, restores y ejecutar los scripts SQL.
3. **PowerShell**: El script está diseñado para ejecutarse en PowerShell y utiliza funciones como `Send-MailMessage` para el envío de correos.

## Ejecución

Para ejecutar el script, asegúrate de que todas las variables estén configuradas correctamente y luego ejecuta el archivo principal desde PowerShell:

```powershell
.\PisadaX.ps1
