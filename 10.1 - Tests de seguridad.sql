/*
  Pruebas de seguridad.
  Ejecute primero seguridad_soldadura_de_sedas.sql y luego este archivo completo.
*/
USE [Soldadura_De_Sedas];

/* Pruebas con EXECUTE AS. Los datos de prueba se eliminan con ROLLBACK. */
SET NOCOUNT ON;

SELECT DB_NAME() AS base_actual, @@SPID AS id_sesion, USER_NAME() AS usuario_actual;

-- Revisa la base y los usuarios necesarios.
IF DB_NAME() <> N'Soldadura_De_Sedas'
    THROW 50001, 'Las pruebas deben ejecutarse en la base Soldadura_De_Sedas.', 1;

IF USER_ID(N'usuario_operador') IS NULL
    THROW 50002, 'No existe el usuario de base de datos usuario_operador.', 1;

IF USER_ID(N'usuario_registro') IS NULL
    THROW 50003, 'No existe el usuario de base de datos usuario_registro.', 1;

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
    EXECUTE AS USER = 'usuario_operador';
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

-- Prueba 2: el operador no puede eliminar registros.
BEGIN TRY
    EXECUTE AS USER = 'usuario_operador';
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
    EXECUTE AS USER = 'usuario_operador';
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
    EXECUTE AS USER = 'usuario_registro';

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
    EXECUTE AS USER = 'usuario_registro';

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

-- Prueba 6: registro no puede ejecutar el reporte operacional.
BEGIN TRY
    EXECUTE AS USER = 'usuario_registro';
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

-- Crea un usuario temporal para probar rol_consultas.
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
    EXECUTE AS USER = 'usuario_consultas_test';
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

-- Prueba 8: consultas no puede leer una tabla base.
BEGIN TRY
    EXECUTE AS USER = 'usuario_consultas_test';
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
    EXECUTE AS USER = 'usuario_consultas_test';
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

-- Elimina el usuario temporal.
IF @membresia_consultas_agregada = 1
    ALTER ROLE [rol_consultas] DROP MEMBER [usuario_consultas_test];

IF @usuario_consultas_creado = 1
    DROP USER [usuario_consultas_test];

-- Muestra el resultado final.
SELECT
    id_prueba,
    usuario_prueba,
    escenario,
    resultado,
    detalle
FROM #ResultadosSeguridad
ORDER BY id_prueba;

SELECT
    total_pruebas = COUNT(*),
    pruebas_ok = SUM(CASE WHEN resultado = 'OK' THEN 1 ELSE 0 END),
    pruebas_fallidas = SUM(CASE WHEN resultado = 'FALLO' THEN 1 ELSE 0 END)
FROM #ResultadosSeguridad;

IF EXISTS (SELECT 1 FROM #ResultadosSeguridad WHERE resultado = 'FALLO')
BEGIN
    THROW 51000, 'Una o más pruebas de seguridad fallaron. Revise #ResultadosSeguridad.', 1;
END;
ELSE
BEGIN
    PRINT 'Todas las pruebas de seguridad finalizaron correctamente.';
END;
