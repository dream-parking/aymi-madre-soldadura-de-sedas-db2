------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------
-- SP 1: Todos los registros asociados a un cliente específico
-- Osea las cotizaciones y proyectos de ese cliente
---------------------------------------------------------------:)
CREATE OR ALTER PROCEDURE sp_RegistrosPorCliente
    @id_cliente CHAR(5)
AS
BEGIN
    SET NOCOUNT ON;

    -- Datos del cliente con dirección
    SELECT 
        c.id_cliente,
        c.nombre_empresa_cliente,
        c.telefono_cliente,
        c.correo_cliente,
        c.fecha_registro,
        co.nombre_corregimiento,
        d.nombre_distrito,
        pr.nombre_provincia
    FROM clientes c
    LEFT JOIN direcciones    dir ON c.id_direccion       = dir.id_direccion
    LEFT JOIN corregimientos co  ON dir.id_corregimiento = co.id_corregimiento
    LEFT JOIN distritos      d   ON co.id_distrito       = d.id_distrito
    LEFT JOIN provincias     pr  ON d.id_provincia       = pr.id_provincia
    WHERE c.id_cliente = @id_cliente;

    -- Cotizaciones del cliente
    SELECT 
        cot.id_cotizacion,
        cot.fecha_emision_cotizacion,
        cot.descripcion_trabajo_cotizacion,
        cot.monto_estimado_cotizacion,
        cot.estado_cotizacion,
        cot.notas
    FROM cotizaciones cot
    WHERE cot.id_cliente = @id_cliente;

    -- Proyectos del cliente con ubicación normalizada
    SELECT 
        p.id_proyecto,
        p.nombre_proyecto,
        p.fecha_inicio_proyecto,
        p.fecha_fin_estimada_proyecto,
        p.estado_proyecto,
        p.costo_total_proyecto,
        co.nombre_corregimiento,
        d.nombre_distrito,
        pr.nombre_provincia
    FROM proyectos p
    LEFT JOIN direcciones    dir ON p.id_direccion       = dir.id_direccion
    LEFT JOIN corregimientos co  ON dir.id_corregimiento = co.id_corregimiento
    LEFT JOIN distritos      d   ON co.id_distrito       = d.id_distrito
    LEFT JOIN provincias     pr  ON d.id_provincia       = pr.id_provincia
    WHERE p.id_cliente = @id_cliente;
END;
GO

-- EXEC sp_RegistrosPorCliente @id_cliente = 'C0001';

-- Alguien lee esto? xd
---------------------------------------------------------------
---------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------
-- SP 2: Recursos disponibles del sistema
-- Osea que trabajadores estan libres y que materiales hay
---------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_RecursosDisponibles
AS
BEGIN
    SET NOCOUNT ON;

    -- Trabajadores no asignados a proyectos EN PROCESO
    SELECT 
        t.id_trabajador,
        t.nombre_completo_trabajador,
        ca.nombre_cargo,
        t.tarifa_base_trabajador
    FROM trabajadores t
    INNER JOIN cargos ca ON t.id_cargo = ca.id_cargo
    WHERE t.id_trabajador NOT IN (
        SELECT ap.id_trabajador
        FROM asignacion_personal ap
        INNER JOIN proyectos p ON ap.id_proyecto = p.id_proyecto
        WHERE p.estado_proyecto = 'En proceso'
    );

    -- Materiales registrados en el sistema
    SELECT 
        m.id_material,
        m.descripcion_material,
        m.especificaciones,
        cm.nombre_categoria,
        um.nombre_unidad
    FROM materiales m
    INNER JOIN categorias_material cm ON m.id_categoria = cm.id_categoria
    INNER JOIN unidades_medida     um ON m.id_unidad    = um.id_unidad;
END;
GO

-- EXEC sp_RecursosDisponibles;

---------------------------------------------------------------
---------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------
-- SP 3: Totales e ingresos en un periodo determinado
-- Le metes fecha inicio y fecha fin y te dice cuanto entro de dinero en ese tiempo
---------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_IngresosPorPeriodo
    @fecha_inicio DATE,
    @fecha_fin    DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.id_proyecto,
        p.nombre_proyecto,
        c.nombre_empresa_cliente,
        p.fecha_inicio_proyecto,
        p.fecha_fin_estimada_proyecto,
        p.costo_total_proyecto,
        p.estado_proyecto,
        ISNULL(SUM(n.monto_cancelado), 0)                   AS total_pagado_nomina,
        ISNULL((SELECT SUM(pc.monto_pago)
                FROM pagos_cliente pc
                WHERE pc.id_proyecto = p.id_proyecto), 0)   AS total_cobrado_cliente,
        p.costo_total_proyecto 
            - ISNULL(SUM(n.monto_cancelado), 0)             AS ganancia_estimada
    FROM proyectos p
    INNER JOIN clientes c ON p.id_cliente  = c.id_cliente
    LEFT  JOIN nomina   n ON p.id_proyecto = n.id_proyecto
    WHERE p.fecha_inicio_proyecto BETWEEN @fecha_inicio AND @fecha_fin
    GROUP BY 
        p.id_proyecto,
        p.nombre_proyecto,
        c.nombre_empresa_cliente,
        p.fecha_inicio_proyecto,
        p.fecha_fin_estimada_proyecto,
        p.costo_total_proyecto,
        p.estado_proyecto;

    -- Totales globales del periodo
    SELECT 
        COUNT(DISTINCT p.id_proyecto)                       AS total_proyectos,
        SUM(p.costo_total_proyecto)                         AS ingreso_total_proyectos,
        ISNULL(SUM(n.monto_cancelado), 0)                   AS total_pagado_nomina,
        SUM(p.costo_total_proyecto) 
            - ISNULL(SUM(n.monto_cancelado), 0)             AS ganancia_total_estimada
    FROM proyectos p
    LEFT JOIN nomina n ON p.id_proyecto = n.id_proyecto
    WHERE p.fecha_inicio_proyecto BETWEEN @fecha_inicio AND @fecha_fin;
END;
GO

-- EXEC sp_IngresosPorPeriodo @fecha_inicio = '2025-01-01', @fecha_fin = '2025-12-31';

---------------------------------------------------------------
---------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------
-- SP 4: Proyectos por tipo de estructura
-- Le metes el tipo de estructura y te muestra todos los proyectos que tienen ese tipo
---------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ProyectosPorTipoEstructura
    @tipo_estructura VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        mt.id_medida,
        mt.dimensiones_exactas,
        te.nombre_tipo_estructura,
        mt.pago_por_unidades,
        um.abreviatura        AS unidad_medida,
        mt.observaciones,
        p.id_proyecto,
        p.nombre_proyecto,
        p.estado_proyecto,
        c.nombre_empresa_cliente,
        co.nombre_corregimiento,
        d.nombre_distrito
    FROM medidas_tecnicas mt
    INNER JOIN tipos_estructura  te  ON mt.id_tipo_estructura = te.id_tipo_estructura
    INNER JOIN unidades_medida   um  ON mt.id_unidad          = um.id_unidad
    INNER JOIN proyectos         p   ON mt.id_proyecto        = p.id_proyecto
    INNER JOIN clientes          c   ON p.id_cliente          = c.id_cliente
    LEFT  JOIN direcciones       dir ON p.id_direccion        = dir.id_direccion
    LEFT  JOIN corregimientos    co  ON dir.id_corregimiento  = co.id_corregimiento
    LEFT  JOIN distritos         d   ON co.id_distrito        = d.id_distrito
    WHERE te.nombre_tipo_estructura = @tipo_estructura
    ORDER BY p.fecha_inicio_proyecto DESC;
END;
GO

-- EXEC sp_ProyectosPorTipoEstructura @tipo_estructura = 'Techo';

---------------------------------------------------------------
---------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------
-- SP 5: Detalle completo de un proyecto
-- Mi obra maestra xd, devuelve todo lo del proyecto: cliente, cotizacion, medidas, personal, materiales, nomina y pagos
---------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_DetalleProyecto
    @id_proyecto CHAR(5)
AS
BEGIN
    SET NOCOUNT ON;

    -- Info general del proyecto
    SELECT 
        p.id_proyecto,
        p.nombre_proyecto,
        p.fecha_inicio_proyecto,
        p.fecha_fin_estimada_proyecto,
        p.estado_proyecto,
        p.costo_total_proyecto,
        c.nombre_empresa_cliente,
        c.telefono_cliente,
        cot.descripcion_trabajo_cotizacion,
        cot.monto_estimado_cotizacion,
        co.nombre_corregimiento,
        d.nombre_distrito,
        pr.nombre_provincia,
        dir.via_principal,
        dir.punto_referencia
    FROM proyectos p
    INNER JOIN clientes          c   ON p.id_cliente         = c.id_cliente
    INNER JOIN cotizaciones      cot ON p.id_cotizacion      = cot.id_cotizacion
    LEFT  JOIN direcciones       dir ON p.id_direccion       = dir.id_direccion
    LEFT  JOIN corregimientos    co  ON dir.id_corregimiento = co.id_corregimiento
    LEFT  JOIN distritos         d   ON co.id_distrito       = d.id_distrito
    LEFT  JOIN provincias        pr  ON d.id_provincia       = pr.id_provincia
    WHERE p.id_proyecto = @id_proyecto;

    -- Medidas tecnicas del proyecto
    SELECT 
        mt.dimensiones_exactas,
        te.nombre_tipo_estructura,
        mt.pago_por_unidades,
        um.nombre_unidad,
        mt.observaciones
    FROM medidas_tecnicas mt
    INNER JOIN tipos_estructura te ON mt.id_tipo_estructura = te.id_tipo_estructura
    INNER JOIN unidades_medida  um ON mt.id_unidad          = um.id_unidad
    WHERE mt.id_proyecto = @id_proyecto;

    -- Personal asignado
    SELECT 
        t.id_trabajador,
        t.nombre_completo_trabajador,
        ca.nombre_cargo,
        t.tarifa_base_trabajador,
        ap.fecha_inicio_asignacion
    FROM asignacion_personal ap
    INNER JOIN trabajadores t  ON ap.id_trabajador = t.id_trabajador
    INNER JOIN cargos        ca ON t.id_cargo       = ca.id_cargo
    WHERE ap.id_proyecto = @id_proyecto;

    -- Materiales utilizados
    SELECT 
        m.descripcion_material,
        m.especificaciones,
        cm.nombre_categoria,
        dmo.cantidad_utilizada,
        um.abreviatura AS unidad_medida
    FROM detalle_materiales_obra dmo
    INNER JOIN materiales          m  ON dmo.id_material = m.id_material
    INNER JOIN categorias_material cm ON m.id_categoria  = cm.id_categoria
    INNER JOIN unidades_medida     um ON m.id_unidad      = um.id_unidad
    WHERE dmo.id_proyecto = @id_proyecto;

    -- Nomina del proyecto
    SELECT 
        t.nombre_completo_trabajador,
        n.horas_trabajadas,
        n.monto_cancelado,
        n.fecha_pago
    FROM nomina n
    INNER JOIN trabajadores t ON n.id_trabajador = t.id_trabajador
    WHERE n.id_proyecto = @id_proyecto
    ORDER BY n.fecha_pago;

    -- Pagos del cliente
    SELECT 
        pc.id_pago,
        pc.fecha_pago,
        pc.monto_pago,
        mp.nombre_metodo_pago,
        pc.referencia_pago
    FROM pagos_cliente pc
    INNER JOIN metodos_pago mp ON pc.id_metodo_pago = mp.id_metodo_pago
    WHERE pc.id_proyecto = @id_proyecto
    ORDER BY pc.fecha_pago;
END;
GO

-- EXEC sp_DetalleProyecto @id_proyecto = 'P0001';

---------------------------------------------------------------
---------------------------------------------------------------