/*
 Crea la seguridad de la base Soldadura_De_Sedas.
 Ejecutar con un usuario administrador.
 Cambiar las contraseñas antes de usar en producción.
 El script se puede volver a ejecutar.
*/

-- 1. Crear los logins en master.
USE [master];
GO

IF SUSER_ID(N'usuario_operador') IS NULL
BEGIN
    CREATE LOGIN [usuario_operador]
        WITH PASSWORD = N'Op3rador#RDS_2026!Temp',
             CHECK_POLICY = ON,
             CHECK_EXPIRATION = OFF;
END;
GO

IF SUSER_ID(N'usuario_registro') IS NULL
BEGIN
    CREATE LOGIN [usuario_registro]
        WITH PASSWORD = N'R3gistro#RDS_2026!Temp',
             CHECK_POLICY = ON,
             CHECK_EXPIRATION = OFF;
END;
GO

-- 2. Usar la base y crear el esquema seguridad.
USE [Soldadura_De_Sedas];
GO

IF SCHEMA_ID(N'seguridad') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA [seguridad] AUTHORIZATION [dbo];');
END;
GO

-- Usar dbo como propietario del esquema.
ALTER AUTHORIZATION ON SCHEMA::[seguridad] TO [dbo];
GO

-- 3. Crear vistas y procedimientos de seguridad.

-- Vista privada del historial de auditoría.
CREATE OR ALTER VIEW [seguridad].[vw_HistorialAuditoria]
AS
    SELECT
        a.id_auditoria,
        a.tabla,
        a.operacion,
        a.fecha,
        a.usuario_sql,
        a.valores_anteriores,
        a.valores_nuevos
    FROM dbo.Auditoria AS a;
GO

-- Consulta de proyectos activos para el operador.
CREATE OR ALTER PROCEDURE [seguridad].[sp_ConsultarProyectosActivos]
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.id_proyecto,
        p.nombre_proyecto,
        p.costo_total_proyecto,
        e.descripcion_state AS estado,
        c.id_cliente,
        c.nombre_empresa_cliente,
        c.telefono_cliente,
        c.correo_cliente,
        pfi.fecha_inicio AS fecha_inicio_proyecto,
        pfe.fecha_estimada AS fecha_fin_estimada,
        ecp.saldo_cuenta
    FROM dbo.proyecto AS p
    INNER JOIN dbo.estado_proyecto AS ep
        ON ep.id_proyecto = p.id_proyecto
    INNER JOIN dbo.estados AS e
        ON e.id_estado = ep.id_estado
       AND LOWER(e.descripcion_state) LIKE '%activo%'
    LEFT JOIN dbo.cliente AS c
        ON c.id_cliente = p.id_cliente
    LEFT JOIN dbo.proyecto_fecha_inicio AS pfi
        ON pfi.id_proyecto = p.id_proyecto
    LEFT JOIN dbo.proyecto_fecha_fin_estimada AS pfe
        ON pfe.id_proyecto = p.id_proyecto
    LEFT JOIN dbo.estados_cuenta_proyecto AS ecp
        ON ecp.id_proyecto = p.id_proyecto
    ORDER BY p.id_proyecto;
END;
GO

-- Actualizar horas de nómina.
CREATE OR ALTER PROCEDURE [seguridad].[sp_ActualizarHorasNomina]
    @id_nomina INT,
    @horas_trabajadas DECIMAL(5,2)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @horas_trabajadas <= 0 OR @horas_trabajadas > 744
        THROW 50001, 'Las horas trabajadas deben ser mayores que 0 y no exceder 744.', 1;

    UPDATE dbo.nomina
       SET horas_trabajadas_nomina = @horas_trabajadas
     WHERE id_nomina = @id_nomina;

    IF @@ROWCOUNT = 0
        THROW 50002, 'No existe la nómina indicada.', 1;
END;
GO

-- Registrar un cliente.
CREATE OR ALTER PROCEDURE [seguridad].[sp_RegistrarCliente]
    @nombre_empresa_cliente VARCHAR(150),
    @telefono_cliente       VARCHAR(20) = NULL,
    @correo_cliente         VARCHAR(100) = NULL,
    @id_direccion           INT = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@nombre_empresa_cliente)), '') IS NULL
        THROW 50003, 'El nombre de la empresa cliente es obligatorio.', 1;

    INSERT INTO dbo.cliente
    (
        nombre_empresa_cliente,
        telefono_cliente,
        correo_cliente,
        fecha_registro,
        id_direccion
    )
    VALUES
    (
        @nombre_empresa_cliente,
        @telefono_cliente,
        @correo_cliente,
        CONVERT(date, GETDATE()),
        @id_direccion
    );

    SELECT CONVERT(INT, SCOPE_IDENTITY()) AS id_cliente_creado;
END;
GO

-- Reporte permitido al operador y bloqueado para registro.
CREATE OR ALTER PROCEDURE [seguridad].[sp_ReporteOperacional]
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT COUNT_BIG(*) FROM dbo.nomina) AS total_nominas,
        (SELECT COUNT_BIG(*) FROM dbo.solicitudes_quincenales) AS total_solicitudes,
        (SELECT COUNT_BIG(*) FROM dbo.asignacion_personal) AS total_asignaciones,
        (SELECT COUNT_BIG(*) FROM dbo.detalle_material_obra) AS total_detalles_material,
        (SELECT COUNT_BIG(*) FROM dbo.medidas_tecnicas) AS total_medidas_tecnicas;
END;
GO

-- 4. Crear los roles.
IF DATABASE_PRINCIPAL_ID(N'rol_operador') IS NULL
    CREATE ROLE [rol_operador] AUTHORIZATION [dbo];
GO

IF DATABASE_PRINCIPAL_ID(N'rol_registro') IS NULL
    CREATE ROLE [rol_registro] AUTHORIZATION [dbo];
GO

IF DATABASE_PRINCIPAL_ID(N'rol_consultas') IS NULL
    CREATE ROLE [rol_consultas] AUTHORIZATION [dbo];
GO

-- 5. Crear los usuarios de la base.
IF DATABASE_PRINCIPAL_ID(N'usuario_operador') IS NULL
    CREATE USER [usuario_operador]
        FOR LOGIN [usuario_operador]
        WITH DEFAULT_SCHEMA = [dbo];
GO

IF DATABASE_PRINCIPAL_ID(N'usuario_registro') IS NULL
    CREATE USER [usuario_registro]
        FOR LOGIN [usuario_registro]
        WITH DEFAULT_SCHEMA = [dbo];
GO

GRANT CONNECT TO [usuario_operador];
GRANT CONNECT TO [usuario_registro];
GO

-- 6. Agregar cada usuario a su rol.
IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r
        ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS m
        ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'rol_operador'
      AND m.name = N'usuario_operador'
)
    ALTER ROLE [rol_operador] ADD MEMBER [usuario_operador];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r
        ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS m
        ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'rol_registro'
      AND m.name = N'usuario_registro'
)
    ALTER ROLE [rol_registro] ADD MEMBER [usuario_registro];
GO

-- 7. Dar permisos al rol operador.
GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.nomina                  TO [rol_operador];
GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.detalle_material_obra  TO [rol_operador];
GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.solicitudes_quincenales TO [rol_operador];
GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.asignacion_personal    TO [rol_operador];
GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.medidas_tecnicas       TO [rol_operador];
GO

GRANT EXECUTE ON OBJECT::[seguridad].[sp_ConsultarProyectosActivos] TO [rol_operador];
GRANT EXECUTE ON OBJECT::[seguridad].[sp_ActualizarHorasNomina]     TO [rol_operador];
GRANT EXECUTE ON OBJECT::[seguridad].[sp_ReporteOperacional]        TO [rol_operador];
GO

-- Permisos que deben quedar bloqueados.
DENY DELETE ON OBJECT::dbo.nomina                 TO [rol_operador];
DENY DELETE ON OBJECT::dbo.detalle_material_obra TO [rol_operador];
DENY DELETE ON OBJECT::dbo.solicitudes_quincenales TO [rol_operador];
DENY DELETE ON OBJECT::dbo.asignacion_personal   TO [rol_operador];
DENY DELETE ON OBJECT::dbo.medidas_tecnicas      TO [rol_operador];
DENY SELECT ON OBJECT::[seguridad].[vw_HistorialAuditoria] TO [rol_operador];
GO

-- 8. Dar permisos al rol registro.
GRANT SELECT, INSERT ON OBJECT::dbo.cliente      TO [rol_registro];
GRANT SELECT, INSERT ON OBJECT::dbo.cotizaciones TO [rol_registro];
GRANT SELECT, INSERT ON OBJECT::dbo.proyecto     TO [rol_registro];
GRANT SELECT, INSERT ON OBJECT::dbo.trabajadores TO [rol_registro];
GRANT SELECT, INSERT ON OBJECT::dbo.materiales   TO [rol_registro];
GO

GRANT EXECUTE ON OBJECT::[seguridad].[sp_RegistrarCliente] TO [rol_registro];
DENY EXECUTE ON OBJECT::[seguridad].[sp_ReporteOperacional] TO [rol_registro];
DENY SELECT  ON OBJECT::[seguridad].[vw_HistorialAuditoria] TO [rol_registro];
GO

/*
 9. Dar permisos al rol consultas.
 Puede leer vistas dbo, pero no tablas ni objetos de seguridad.
*/
DECLARE @sql_grant_views NVARCHAR(MAX) = N'';

SELECT @sql_grant_views = @sql_grant_views
    + N'GRANT SELECT ON OBJECT::'
    + QUOTENAME(SCHEMA_NAME(v.schema_id)) + N'.' + QUOTENAME(v.name)
    + N' TO [rol_consultas];' + CHAR(13) + CHAR(10)
FROM sys.views AS v
WHERE SCHEMA_NAME(v.schema_id) = N'dbo'
  AND v.is_ms_shipped = 0;

IF @sql_grant_views <> N''
    EXEC sys.sp_executesql @sql_grant_views;
GO

DECLARE @sql_deny_tables NVARCHAR(MAX) = N'';

SELECT @sql_deny_tables = @sql_deny_tables
    + N'DENY SELECT ON OBJECT::'
    + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
    + N' TO [rol_consultas];' + CHAR(13) + CHAR(10)
FROM sys.tables AS t
WHERE SCHEMA_NAME(t.schema_id) = N'dbo'
  AND t.is_ms_shipped = 0;

IF @sql_deny_tables <> N''
    EXEC sys.sp_executesql @sql_deny_tables;
GO

DENY SELECT ON SCHEMA::[seguridad] TO [rol_consultas];
GO

-- 10. Mostrar la configuración creada.
SELECT
    rol = r.name,
    miembro = m.name
FROM sys.database_role_members AS drm
INNER JOIN sys.database_principals AS r
    ON r.principal_id = drm.role_principal_id
INNER JOIN sys.database_principals AS m
    ON m.principal_id = drm.member_principal_id
WHERE r.name IN (N'rol_operador', N'rol_registro', N'rol_consultas')
ORDER BY r.name, m.name;
GO

SELECT
    principal = dp.name,
    permiso = p.permission_name,
    estado = p.state_desc,
    objeto = CASE
                WHEN p.class_desc = N'SCHEMA' THEN SCHEMA_NAME(p.major_id)
                ELSE QUOTENAME(OBJECT_SCHEMA_NAME(p.major_id))
                     + N'.' + QUOTENAME(OBJECT_NAME(p.major_id))
             END
FROM sys.database_permissions AS p
INNER JOIN sys.database_principals AS dp
    ON dp.principal_id = p.grantee_principal_id
WHERE dp.name IN (N'rol_operador', N'rol_registro', N'rol_consultas')
ORDER BY dp.name, p.state_desc, p.permission_name, objeto;
GO

/*
 11. Probar los permisos con EXECUTE AS.
 Los accesos bloqueados deben generar error 229.
 Los datos de prueba se deshacen con ROLLBACK.
*/
SET NOCOUNT ON;
GO

IF OBJECT_ID('tempdb..#ResultadosSeguridad') IS NOT NULL
    DROP TABLE #ResultadosSeguridad;

CREATE TABLE #ResultadosSeguridad
(
    id_prueba INT IDENTITY(1,1) PRIMARY KEY,
    usuario_prueba SYSNAME NOT NULL,
    escenario VARCHAR(200) NOT NULL,
    resultado VARCHAR(10) NOT NULL,
    detalle NVARCHAR(4000) NULL
);

-- Prueba 1: el operador consulta proyectos activos.
BEGIN TRY
    EXECUTE AS USER = N'usuario_operador';
    EXEC [seguridad].[sp_ConsultarProyectosActivos];
    REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_operador', 'Consulta proyectos activos', 'OK',
                N'EXECUTE autorizado sobre seguridad.sp_ConsultarProyectosActivos.');
END TRY
BEGIN CATCH
    DECLARE @p1_num INT = ERROR_NUMBER(), @p1_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF USER_NAME() = N'usuario_operador' REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_operador', 'Consulta proyectos activos', 'FALLO',
                CONCAT(N'Error ', @p1_num, N': ', @p1_msg));
END CATCH;

-- Prueba 2: el operador no puede eliminar.
BEGIN TRY
    EXECUTE AS USER = N'usuario_operador';
    DELETE FROM dbo.nomina WHERE 1 = 0;
    REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_operador', 'DELETE bloqueado', 'FALLO',
                N'El DELETE no generó el error de permisos esperado.');
END TRY
BEGIN CATCH
    DECLARE @p2_num INT = ERROR_NUMBER(), @p2_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF USER_NAME() = N'usuario_operador' REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES
        (
            N'usuario_operador',
            'DELETE bloqueado',
            CASE WHEN @p2_num = 229 THEN 'OK' ELSE 'FALLO' END,
            CONCAT(N'Error capturado ', @p2_num, N': ', @p2_msg)
        );
END CATCH;

-- Prueba 3: el operador no puede ver la auditoría.
BEGIN TRY
    EXECUTE AS USER = N'usuario_operador';
    SELECT TOP (1) * FROM [seguridad].[vw_HistorialAuditoria];
    REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_operador', 'Auditoría bloqueada', 'FALLO',
                N'La vista sensible fue accesible y debía estar bloqueada.');
END TRY
BEGIN CATCH
    DECLARE @p3_num INT = ERROR_NUMBER(), @p3_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF USER_NAME() = N'usuario_operador' REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES
        (
            N'usuario_operador',
            'Auditoría bloqueada',
            CASE WHEN @p3_num = 229 THEN 'OK' ELSE 'FALLO' END,
            CONCAT(N'Error capturado ', @p3_num, N': ', @p3_msg)
        );
END CATCH;

-- Prueba 4: registro puede insertar un cliente. Luego se revierte.
BEGIN TRANSACTION;
BEGIN TRY
    EXECUTE AS USER = N'usuario_registro';

    INSERT INTO dbo.cliente
    (
        nombre_empresa_cliente,
        telefono_cliente,
        correo_cliente,
        fecha_registro,
        id_direccion
    )
    VALUES
    (
        'CLIENTE_TEST_SEGURIDAD_DIRECTO',
        '0000-0000',
        'directo.test@example.invalid',
        CONVERT(date, GETDATE()),
        NULL
    );

    REVERT;
    ROLLBACK TRANSACTION;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_registro', 'INSERT cliente directo', 'OK',
                N'INSERT autorizado; la transacción de prueba fue revertida.');
END TRY
BEGIN CATCH
    DECLARE @p4_num INT = ERROR_NUMBER(), @p4_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF USER_NAME() = N'usuario_registro' REVERT;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_registro', 'INSERT cliente directo', 'FALLO',
                CONCAT(N'Error ', @p4_num, N': ', @p4_msg));
END CATCH;

-- Prueba 5: registro puede ejecutar sp_RegistrarCliente.
BEGIN TRANSACTION;
BEGIN TRY
    EXECUTE AS USER = N'usuario_registro';

    EXEC [seguridad].[sp_RegistrarCliente]
        @nombre_empresa_cliente = 'CLIENTE_TEST_SEGURIDAD_SP',
        @telefono_cliente = '0000-0000',
        @correo_cliente = 'sp.test@example.invalid',
        @id_direccion = NULL;

    REVERT;
    ROLLBACK TRANSACTION;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_registro', 'EXEC sp_RegistrarCliente', 'OK',
                N'EXECUTE autorizado; la transacción de prueba fue revertida.');
END TRY
BEGIN CATCH
    DECLARE @p5_num INT = ERROR_NUMBER(), @p5_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF USER_NAME() = N'usuario_registro' REVERT;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_registro', 'EXEC sp_RegistrarCliente', 'FALLO',
                CONCAT(N'Error ', @p5_num, N': ', @p5_msg));
END CATCH;

-- Prueba 6: registro no puede ejecutar el reporte.
BEGIN TRY
    EXECUTE AS USER = N'usuario_registro';
    EXEC [seguridad].[sp_ReporteOperacional];
    REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_registro', 'Reporte operacional bloqueado', 'FALLO',
                N'El procedimiento sensible fue ejecutado y debía estar bloqueado.');
END TRY
BEGIN CATCH
    DECLARE @p6_num INT = ERROR_NUMBER(), @p6_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF USER_NAME() = N'usuario_registro' REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES
        (
            N'usuario_registro',
            'Reporte operacional bloqueado',
            CASE WHEN @p6_num = 229 THEN 'OK' ELSE 'FALLO' END,
            CONCAT(N'Error capturado ', @p6_num, N': ', @p6_msg)
        );
END CATCH;

-- Pruebas del rol consultas con un usuario temporal.
DECLARE @usuario_consultas_creado BIT = 0;
DECLARE @membresia_consultas_agregada BIT = 0;

IF DATABASE_PRINCIPAL_ID(N'usuario_consultas_test') IS NULL
BEGIN
    CREATE USER [usuario_consultas_test] WITHOUT LOGIN;
    SET @usuario_consultas_creado = 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r
        ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS m
        ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'rol_consultas'
      AND m.name = N'usuario_consultas_test'
)
BEGIN
    ALTER ROLE [rol_consultas] ADD MEMBER [usuario_consultas_test];
    SET @membresia_consultas_agregada = 1;
END;

-- Prueba 7: consultas puede leer una vista dbo.
BEGIN TRY
    EXECUTE AS USER = N'usuario_consultas_test';
    SELECT TOP (1) * FROM dbo.vw_DetalleProyecto;
    REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_consultas_test', 'SELECT en vista dbo', 'OK',
                N'SELECT autorizado sobre dbo.vw_DetalleProyecto.');
END TRY
BEGIN CATCH
    DECLARE @p7_num INT = ERROR_NUMBER(), @p7_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF USER_NAME() = N'usuario_consultas_test' REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_consultas_test', 'SELECT en vista dbo', 'FALLO',
                CONCAT(N'Error ', @p7_num, N': ', @p7_msg));
END CATCH;

-- Prueba 8: consultas no puede leer una tabla.
BEGIN TRY
    EXECUTE AS USER = N'usuario_consultas_test';
    SELECT TOP (1) * FROM dbo.proyecto;
    REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_consultas_test', 'Tabla base bloqueada', 'FALLO',
                N'La tabla base fue accesible y debía estar bloqueada.');
END TRY
BEGIN CATCH
    DECLARE @p8_num INT = ERROR_NUMBER(), @p8_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF USER_NAME() = N'usuario_consultas_test' REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES
        (
            N'usuario_consultas_test',
            'Tabla base bloqueada',
            CASE WHEN @p8_num = 229 THEN 'OK' ELSE 'FALLO' END,
            CONCAT(N'Error capturado ', @p8_num, N': ', @p8_msg)
        );
END CATCH;

-- Prueba 9: consultas no puede leer vistas de seguridad.
BEGIN TRY
    EXECUTE AS USER = N'usuario_consultas_test';
    SELECT TOP (1) * FROM [seguridad].[vw_HistorialAuditoria];
    REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES (N'usuario_consultas_test', 'Vista seguridad bloqueada', 'FALLO',
                N'La vista de seguridad fue accesible y debía estar bloqueada.');
END TRY
BEGIN CATCH
    DECLARE @p9_num INT = ERROR_NUMBER(), @p9_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF USER_NAME() = N'usuario_consultas_test' REVERT;

    INSERT INTO #ResultadosSeguridad
        VALUES
        (
            N'usuario_consultas_test',
            'Vista seguridad bloqueada',
            CASE WHEN @p9_num = 229 THEN 'OK' ELSE 'FALLO' END,
            CONCAT(N'Error capturado ', @p9_num, N': ', @p9_msg)
        );
END CATCH;

-- Eliminar el usuario temporal.
IF @membresia_consultas_agregada = 1
    ALTER ROLE [rol_consultas] DROP MEMBER [usuario_consultas_test];

IF @usuario_consultas_creado = 1
    DROP USER [usuario_consultas_test];

-- Mostrar el resultado final.
SELECT
    id_prueba,
    usuario_prueba,
    escenario,
    resultado,
    detalle
FROM #ResultadosSeguridad
ORDER BY id_prueba;

IF EXISTS (SELECT 1 FROM #ResultadosSeguridad WHERE resultado = 'FALLO')
BEGIN
    THROW 51000, 'Una o más pruebas de seguridad fallaron. Revise #ResultadosSeguridad.', 1;
END;
ELSE
BEGIN
    PRINT 'Todas las pruebas de seguridad finalizaron correctamente.';
END;
GO
