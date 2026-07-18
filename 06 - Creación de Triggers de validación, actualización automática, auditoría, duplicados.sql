/*
  Triggers de la base Soldadura_De_Sedas.
  Incluye validaciones, actualización de saldo y auditoría.
*/

USE [Soldadura_De_Sedas];
GO

SET NOCOUNT ON;
GO

/* Verifica que existan las tablas y columnas necesarias. */
IF OBJECT_ID(N'dbo.Auditoria', N'U') IS NULL
    RAISERROR('Falta la tabla dbo.Auditoria.', 16, 1);

IF OBJECT_ID(N'dbo.cliente', N'U') IS NULL
    RAISERROR('Falta la tabla dbo.cliente.', 16, 1);

IF OBJECT_ID(N'dbo.cotizaciones', N'U') IS NULL
    RAISERROR('Falta la tabla dbo.cotizaciones.', 16, 1);

IF OBJECT_ID(N'dbo.proyecto', N'U') IS NULL
    RAISERROR('Falta la tabla dbo.proyecto.', 16, 1);

IF OBJECT_ID(N'dbo.nomina', N'U') IS NULL
    RAISERROR('Falta la tabla dbo.nomina.', 16, 1);

IF OBJECT_ID(N'dbo.nomina_monto', N'U') IS NULL
    RAISERROR('Falta la tabla dbo.nomina_monto.', 16, 1);

IF OBJECT_ID(N'dbo.estados_cuenta_proyecto', N'U') IS NULL
    RAISERROR('Falta la tabla dbo.estados_cuenta_proyecto.', 16, 1);

IF OBJECT_ID(N'dbo.asignacion_personal', N'U') IS NULL
    RAISERROR('Falta la tabla dbo.asignacion_personal.', 16, 1);

IF COL_LENGTH(N'dbo.cotizaciones', N'estado_cotizacion') IS NULL
    RAISERROR('Falta dbo.cotizaciones.estado_cotizacion.', 16, 1);

IF COL_LENGTH(N'dbo.proyecto', N'id_cotizacion') IS NULL
    RAISERROR('Falta dbo.proyecto.id_cotizacion.', 16, 1);

IF COL_LENGTH(N'dbo.nomina_monto', N'monto_cancelado') IS NULL
    RAISERROR('Falta dbo.nomina_monto.monto_cancelado.', 16, 1);

IF COL_LENGTH(N'dbo.estados_cuenta_proyecto', N'saldo_cuenta') IS NULL
    RAISERROR('Falta dbo.estados_cuenta_proyecto.saldo_cuenta.', 16, 1);

IF COL_LENGTH(N'dbo.asignacion_personal', N'fecha_inicio_asignacion') IS NULL
   OR COL_LENGTH(N'dbo.asignacion_personal', N'fecha_fin_asignacion') IS NULL
    RAISERROR('Faltan las fechas de inicio o fin en dbo.asignacion_personal.', 16, 1);
GO

/* Trigger 1: solo permite proyectos con cotización aprobada. */
CREATE OR ALTER TRIGGER dbo.trg_proyecto_validar_cotizacion_aprobada
ON dbo.proyecto
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF ROWCOUNT_BIG() = 0
        RETURN;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        LEFT JOIN dbo.cotizaciones AS c
            ON c.id_cotizacion = i.id_cotizacion
        WHERE c.id_cotizacion IS NULL
           OR UPPER(LTRIM(RTRIM(c.estado_cotizacion))) <> 'APROBADA'
    )
    BEGIN
        RAISERROR(
            'No se puede crear o actualizar el proyecto: la cotizacion asociada debe existir y estar en estado Aprobada.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* Trigger 2: descuenta los pagos del saldo del proyecto. */
CREATE OR ALTER TRIGGER dbo.trg_nomina_monto_descontar_saldo_estado_cuenta
ON dbo.nomina_monto
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF ROWCOUNT_BIG() = 0
        RETURN;

    ;WITH montos_por_proyecto AS
    (
        SELECT
            n.id_proyecto,
            SUM(CONVERT(DECIMAL(19, 4), i.monto_cancelado)) AS monto_total
        FROM inserted AS i
        INNER JOIN dbo.nomina AS n
            ON n.id_nomina = i.id_nomina
        WHERE n.id_proyecto IS NOT NULL
        GROUP BY n.id_proyecto
    )
    UPDATE ec
       SET ec.saldo_cuenta =
           ec.saldo_cuenta - CONVERT(DECIMAL(12, 2), mp.monto_total)
    FROM dbo.estados_cuenta_proyecto AS ec
    INNER JOIN montos_por_proyecto AS mp
        ON mp.id_proyecto = ec.id_proyecto;
END;
GO

/* Trigger 3A: guarda cambios de clientes en Auditoria. */
CREATE OR ALTER TRIGGER dbo.trg_auditoria_cliente
ON dbo.cliente
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF ROWCOUNT_BIG() = 0
        RETURN;

    DECLARE @Operacion VARCHAR(10) =
        CASE
            WHEN EXISTS (SELECT 1 FROM inserted)
             AND EXISTS (SELECT 1 FROM deleted) THEN 'UPDATE'
            WHEN EXISTS (SELECT 1 FROM inserted) THEN 'INSERT'
            ELSE 'DELETE'
        END;

    DECLARE @ValoresAnteriores XML =
        (SELECT * FROM deleted FOR XML PATH('fila'), ROOT('deleted'), TYPE);

    DECLARE @ValoresNuevos XML =
        (SELECT * FROM inserted FOR XML PATH('fila'), ROOT('inserted'), TYPE);

    INSERT INTO dbo.Auditoria
    (
        tabla,
        operacion,
        fecha,
        usuario_sql,
        valores_anteriores,
        valores_nuevos
    )
    VALUES
    (
        N'cliente',
        @Operacion,
        SYSUTCDATETIME(),
        SUSER_SNAME(),
        @ValoresAnteriores,
        @ValoresNuevos
    );
END;
GO

/* Trigger 3B: guarda cambios de proyectos en Auditoria. */
CREATE OR ALTER TRIGGER dbo.trg_auditoria_proyecto
ON dbo.proyecto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF ROWCOUNT_BIG() = 0
        RETURN;

    DECLARE @Operacion VARCHAR(10) =
        CASE
            WHEN EXISTS (SELECT 1 FROM inserted)
             AND EXISTS (SELECT 1 FROM deleted) THEN 'UPDATE'
            WHEN EXISTS (SELECT 1 FROM inserted) THEN 'INSERT'
            ELSE 'DELETE'
        END;

    DECLARE @ValoresAnteriores XML =
        (SELECT * FROM deleted FOR XML PATH('fila'), ROOT('deleted'), TYPE);

    DECLARE @ValoresNuevos XML =
        (SELECT * FROM inserted FOR XML PATH('fila'), ROOT('inserted'), TYPE);

    INSERT INTO dbo.Auditoria
    (
        tabla,
        operacion,
        fecha,
        usuario_sql,
        valores_anteriores,
        valores_nuevos
    )
    VALUES
    (
        N'proyecto',
        @Operacion,
        SYSUTCDATETIME(),
        SUSER_SNAME(),
        @ValoresAnteriores,
        @ValoresNuevos
    );
END;
GO

/* Trigger 3C: guarda cambios de cotizaciones en Auditoria. */
CREATE OR ALTER TRIGGER dbo.trg_auditoria_cotizaciones
ON dbo.cotizaciones
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF ROWCOUNT_BIG() = 0
        RETURN;

    DECLARE @Operacion VARCHAR(10) =
        CASE
            WHEN EXISTS (SELECT 1 FROM inserted)
             AND EXISTS (SELECT 1 FROM deleted) THEN 'UPDATE'
            WHEN EXISTS (SELECT 1 FROM inserted) THEN 'INSERT'
            ELSE 'DELETE'
        END;

    DECLARE @ValoresAnteriores XML =
        (SELECT * FROM deleted FOR XML PATH('fila'), ROOT('deleted'), TYPE);

    DECLARE @ValoresNuevos XML =
        (SELECT * FROM inserted FOR XML PATH('fila'), ROOT('inserted'), TYPE);

    INSERT INTO dbo.Auditoria
    (
        tabla,
        operacion,
        fecha,
        usuario_sql,
        valores_anteriores,
        valores_nuevos
    )
    VALUES
    (
        N'cotizaciones',
        @Operacion,
        SYSUTCDATETIME(),
        SUSER_SNAME(),
        @ValoresAnteriores,
        @ValoresNuevos
    );
END;
GO

/* Trigger 4: evita asignaciones con fechas cruzadas. */
CREATE OR ALTER TRIGGER dbo.trg_asignacion_personal_prevenir_solapamiento
ON dbo.asignacion_personal
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF ROWCOUNT_BIG() = 0
        RETURN;

    IF EXISTS
    (
        SELECT 1
        FROM inserted
        WHERE fecha_fin_asignacion IS NOT NULL
          AND fecha_fin_asignacion < fecha_inicio_asignacion
    )
    BEGIN
        RAISERROR(
            'La fecha fin de la asignacion no puede ser menor que la fecha de inicio.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    CREATE TABLE #nuevas_asignaciones
    (
        rn INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        id_proyecto INT NOT NULL,
        id_trabajador INT NOT NULL,
        fecha_inicio_asignacion DATE NOT NULL,
        fecha_fin_asignacion DATE NULL
    );

    INSERT INTO #nuevas_asignaciones
    (
        id_proyecto,
        id_trabajador,
        fecha_inicio_asignacion,
        fecha_fin_asignacion
    )
    SELECT
        id_proyecto,
        id_trabajador,
        fecha_inicio_asignacion,
        fecha_fin_asignacion
    FROM inserted;

    /* Revisa cruces dentro del mismo INSERT. */
    IF EXISTS
    (
        SELECT 1
        FROM #nuevas_asignaciones AS a
        INNER JOIN #nuevas_asignaciones AS b
            ON a.rn < b.rn
           AND a.id_proyecto = b.id_proyecto
           AND a.id_trabajador = b.id_trabajador
           AND a.fecha_inicio_asignacion <=
               COALESCE(b.fecha_fin_asignacion, CONVERT(DATE, '99991231'))
           AND b.fecha_inicio_asignacion <=
               COALESCE(a.fecha_fin_asignacion, CONVERT(DATE, '99991231'))
    )
    BEGIN
        RAISERROR(
            'No se puede asignar el mismo trabajador al mismo proyecto con fechas solapadas dentro del mismo lote.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    /* Revisa cruces con datos existentes. */
    IF EXISTS
    (
        SELECT 1
        FROM #nuevas_asignaciones AS i
        INNER JOIN dbo.asignacion_personal AS a
            ON a.id_proyecto = i.id_proyecto
           AND a.id_trabajador = i.id_trabajador
           AND i.fecha_inicio_asignacion <=
               COALESCE(a.fecha_fin_asignacion, CONVERT(DATE, '99991231'))
           AND a.fecha_inicio_asignacion <=
               COALESCE(i.fecha_fin_asignacion, CONVERT(DATE, '99991231'))
    )
    BEGIN
        RAISERROR(
            'No se puede registrar el mismo trabajador en el mismo proyecto con fechas solapadas.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    INSERT INTO dbo.asignacion_personal
    (
        id_proyecto,
        id_trabajador,
        fecha_inicio_asignacion,
        fecha_fin_asignacion
    )
    SELECT
        id_proyecto,
        id_trabajador,
        fecha_inicio_asignacion,
        fecha_fin_asignacion
    FROM #nuevas_asignaciones;
END;
GO

/* Muestra los seis triggers creados. */
SELECT
    t.name AS trigger_name,
    OBJECT_SCHEMA_NAME(t.parent_id) AS esquema,
    OBJECT_NAME(t.parent_id) AS tabla,
    t.is_disabled,
    t.create_date,
    t.modify_date
FROM sys.triggers AS t
WHERE t.name IN
(
    N'trg_proyecto_validar_cotizacion_aprobada',
    N'trg_nomina_monto_descontar_saldo_estado_cuenta',
    N'trg_auditoria_cliente',
    N'trg_auditoria_proyecto',
    N'trg_auditoria_cotizaciones',
    N'trg_asignacion_personal_prevenir_solapamiento'
)
ORDER BY t.name;
GO

/*
  Pruebas manuales. Están comentadas para que no se ejecuten al crear los triggers.
  Use una base de pruebas y cambie los IDs cuando sea necesario.
*/
/*
-- Prueba 1: permite una cotización aprobada.
BEGIN TRANSACTION;
DECLARE @cliente_prueba INT;
DECLARE @cotizacion_aprobada INT;

INSERT INTO dbo.cliente (nombre_empresa_cliente)
VALUES ('Cliente prueba triggers');
SET @cliente_prueba = CONVERT(INT, SCOPE_IDENTITY());

INSERT INTO dbo.cotizaciones
    (id_cliente, monto_cotizado, estado_cotizacion)
VALUES
    (@cliente_prueba, 1000.00, 'Aprobada');
SET @cotizacion_aprobada = CONVERT(INT, SCOPE_IDENTITY());

INSERT INTO dbo.proyecto
    (id_cliente, id_cotizacion, nombre_proyecto, costo_total_proyecto)
VALUES
    (@cliente_prueba, @cotizacion_aprobada, 'Proyecto permitido', 1000.00);
ROLLBACK TRANSACTION;
GO

-- Prueba 2: rechaza una cotización pendiente.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @cliente_prueba_2 INT;
    DECLARE @cotizacion_pendiente INT;

    INSERT INTO dbo.cliente (nombre_empresa_cliente)
    VALUES ('Cliente prueba pendiente');
    SET @cliente_prueba_2 = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO dbo.cotizaciones
        (id_cliente, monto_cotizado, estado_cotizacion)
    VALUES
        (@cliente_prueba_2, 1000.00, 'Pendiente');
    SET @cotizacion_pendiente = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO dbo.proyecto
        (id_cliente, id_cotizacion, nombre_proyecto, costo_total_proyecto)
    VALUES
        (@cliente_prueba_2, @cotizacion_pendiente, 'Proyecto rechazado', 1000.00);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS resultado_esperado_trigger_1;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;
GO

-- Prueba 3: descuenta un pago del saldo.
-- Cambie estos IDs por valores existentes.
DECLARE @id_proyecto_prueba INT = 1;
DECLARE @id_trabajador_prueba INT = 1;

BEGIN TRANSACTION;
DECLARE @id_nomina_prueba INT;

SELECT saldo_cuenta AS saldo_antes
FROM dbo.estados_cuenta_proyecto
WHERE id_proyecto = @id_proyecto_prueba;

INSERT INTO dbo.nomina
    (id_trabajador, id_proyecto, periodo_quincenal_nomina, horas_trabajadas_nomina)
VALUES
    (@id_trabajador_prueba, @id_proyecto_prueba, 'Prueba trigger', 8.00);
SET @id_nomina_prueba = CONVERT(INT, SCOPE_IDENTITY());

INSERT INTO dbo.nomina_monto
    (id_nomina, id_monto, monto_cancelado, fecha_pago)
VALUES
    (@id_nomina_prueba, 1.00, 100.00, CONVERT(DATE, GETDATE()));

SELECT saldo_cuenta AS saldo_despues
FROM dbo.estados_cuenta_proyecto
WHERE id_proyecto = @id_proyecto_prueba;
ROLLBACK TRANSACTION;
GO

-- Prueba 4: registra un cambio en Auditoria.
BEGIN TRANSACTION;
UPDATE dbo.cliente
SET nombre_empresa_cliente = nombre_empresa_cliente
WHERE id_cliente = (SELECT MIN(id_cliente) FROM dbo.cliente);

SELECT TOP (5) *
FROM dbo.Auditoria
ORDER BY id_auditoria DESC;
ROLLBACK TRANSACTION;
GO

-- Prueba 5: rechaza una asignación con fechas cruzadas.
-- Cambie estos IDs por valores existentes.
DECLARE @id_proyecto_asignacion INT = 1;
DECLARE @id_trabajador_asignacion INT = 1;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.asignacion_personal
        (id_proyecto, id_trabajador, fecha_inicio_asignacion, fecha_fin_asignacion)
    VALUES
        (@id_proyecto_asignacion, @id_trabajador_asignacion, '2026-01-01', '2026-01-15');

    INSERT INTO dbo.asignacion_personal
        (id_proyecto, id_trabajador, fecha_inicio_asignacion, fecha_fin_asignacion)
    VALUES
        (@id_proyecto_asignacion, @id_trabajador_asignacion, '2026-01-10', '2026-01-20');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS resultado_esperado_trigger_4;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;
GO
*/
