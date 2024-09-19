-- Crear la tabla temporal para almacenar los usuarios y su tipo
CREATE TABLE ##PisadaXListTemp (
    UserID VARCHAR(100),
    TipoUsuario VARCHAR(50)
);

-- Insertar los usuarios de cada categoría en la tabla temporal

-- Usuarios de SISTEMAS
INSERT INTO ##PisadaXListTemp (UserID, TipoUsuario)
SELECT UserID, 'SISTEMAS' FROM (VALUES
    ('sa'),


) AS UserList(UserID);

-- Usuarios ADMINISTRADOR
INSERT INTO ##PisadaXListTemp (UserID, TipoUsuario)
SELECT UserID, 'ADMINISTRADOR' FROM (VALUES
    ('sa')
) AS UserList(UserID);

-- Usuarios ROBOTS
INSERT INTO ##PisadaXListTemp (UserID, TipoUsuario)
SELECT UserID, 'ROBOTS' FROM (VALUES
    ('sa')
) AS UserList(UserID);

-- Usuarios ESCOAPI
INSERT INTO ##PisadaXListTemp (UserID, TipoUsuario)
SELECT UserID, 'ESCOAPI' FROM (VALUES
    ('sa')
) AS UserList(UserID);


