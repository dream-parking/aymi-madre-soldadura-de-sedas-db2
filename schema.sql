DROP DATABASE IF EXISTS SoldadurasDeSedas;
CREATE DATABASE SoldadurasDeSedas;
USE SoldadurasDeSedas;

CREATE TABLE clientes(
	id_cliente CHAR(5) PRIMARY KEY,
	nombre_empresa_cliente VARCHAR(50) NOT NULL,
	telefono_cliente CHAR(15) NOT NULL,
	correo_cliente VARCHAR(50) NULL,
	fecha_registro DATE NOT NULL 
);


CREATE TABLE cotizaciones(
	id_cotizacion CHAR(5) PRIMARY KEY,
	id_cliente CHAR(5) NOT NULL,
	fecha_emision_cotizancion DATE NOT NULL, 
	descripcion_trabajo_cotizancion VARCHAR(50) NOT NULL, 
	monto_estimado_cotizacion FLOAT NOT NULL,
	estado_cotizacion VARCHAR(10) NOT NULL CHECK (estado_cotizacion IN ('Pendiente', 'Aprobada', 'Rechazada')),
	notas VARCHAR(100) NULL
);


CREATE TABLE proyectos(
	id_proyecto CHAR(5) PRIMARY KEY, 
	id_cliente CHAR(5) NOT NULL, 
	id_cotizacion CHAR(5) NOT NULL UNIQUE,
	nombre_proyecto VARCHAR(50) NOT NULL,
	ubicacion_proyecto VARCHAR(40) NOT NULL, 
	fecha_inicio_proyecto DATE NOT NULL, 
	fecha_fin_estimada_proyecto DATE NULL,
	estado_proyecto VARCHAR(10) NOT NULL CHECK (estado_proyecto IN ('En proceso', 'Finalizado')),
	costo_total_proyecto FLOAT NOT NULL
);


CREATE TABLE medidas_tecnicas(
	id_medida CHAR(5) PRIMARY KEY,
	id_proyecto CHAR(5) NOT NULL, 
	dimensiones_exactas VARCHAR(50) NOT NULL, 
	tipo_estructura VARCHAR(50) NOT NULL, 
	pago_por_unidades FLOAT NOT NULL, 
	unidad_medida VARCHAR(10) NOT NULL, 
	observaciones VARCHAR(50) NULL 
);


CREATE TABLE trabajadores(
	id_trabajador CHAR(5) PRIMARY KEY,
	nombre_completo_trabajador VARCHAR(50) NOT NULL, 
	cargo_trabajador VARCHAR(15) NOT NULL, 
	tarifa_base_trabajador FLOAT NOT NULL
);


CREATE TABLE nomina(
	id_nomina CHAR(5) PRIMARY KEY,
	id_trabajador CHAR(5) NOT NULL, 
	id_proyecto CHAR(5) NOT NULL,
	horas_trabajadas FLOAT NULL, 
	monto_cancelado FLOAT NULL, 
	fecha_pago DATE NOT NULL 
);


CREATE TABLE materiales(
	id_material CHAR(5) PRIMARY KEY,
	descripcion_material VARCHAR(50) NOT NULL,
	especificaciones VARCHAR(50) NOT NULL
);


CREATE TABLE asignacion_personal(
	id_proyecto CHAR(5) NOT NULL, 
	id_trabajador CHAR(5) NOT NULL, 
	fecha_inicio_asignacion DATE NOT NULL
);


CREATE TABLE detalle_materiales_obra(
	id_proyecto CHAR(5) NOT NULL,  
	id_material CHAR(5) NOT NULL, 
	cantidad_utilizada FLOAT NOT NULL,
	unidad_medida VARCHAR(10) NOT NULL
);


CREATE TABLE estados_cuenta_proyecto(
	id_cuenta CHAR(5) PRIMARY KEY, 
	id_proyecto CHAR(5) NOT NULL, 
	saldo_cuenta FLOAT NOT NULL
);


CREATE TABLE solicitudes_quincenales(
	id_solicitud CHAR(5) PRIMARY KEY, 
	id_proyecto CHAR(5) NOT NULL, 
	monto_solicitud FLOAT NOT NULL
);



--Relaciones y llaves compuestas
ALTER TABLE cotizaciones ADD FOREIGN KEY(id_cliente) REFERENCES clientes(id_cliente);

ALTER TABLE proyectos ADD FOREIGN KEY(id_cliente) REFERENCES clientes(id_cliente);
ALTER TABLE proyectos ADD FOREIGN KEY(id_cotizacion) REFERENCES cotizaciones(id_cotizacion);

ALTER TABLE medidas_tecnicas ADD FOREIGN KEY(id_proyecto) REFERENCES proyectos(id_proyecto);

ALTER TABLE nomina ADD FOREIGN KEY(id_trabajador) REFERENCES trabajadores(id_trabajador);
ALTER TABLE nomina ADD FOREIGN KEY(id_proyecto) REFERENCES proyectos(id_proyecto);

ALTER TABLE asignacion_personal ADD PRIMARY KEY(id_proyecto, id_trabajador);
ALTER TABLE asignacion_personal ADD FOREIGN KEY(id_proyecto) REFERENCES proyectos(id_proyecto);
ALTER TABLE asignacion_personal ADD FOREIGN KEY(id_trabajador) REFERENCES trabajadores(id_trabajador);

ALTER TABLE detalle_materiales_obra ADD PRIMARY KEY(id_proyecto, id_material);
ALTER TABLE detalle_materiales_obra ADD FOREIGN KEY(id_proyecto) REFERENCES proyectos(id_proyecto);
ALTER TABLE detalle_materiales_obra ADD FOREIGN KEY(id_material) REFERENCES materiales(id_material);

ALTER TABLE estados_cuenta_proyecto ADD FOREIGN KEY(id_proyecto) REFERENCES proyectos(id_proyecto);

ALTER TABLE solicitudes_quincenales ADD FOREIGN KEY(id_proyecto) REFERENCES proyectos(id_proyecto);


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

    -- Datos del cliente
    SELECT 
        c.id_cliente,
        c.nombre_empresa_cliente,
        c.telefono_cliente,
        c.correo_cliente,
        c.fecha_registro
    FROM clientes c
    WHERE c.id_cliente = @id_cliente;

    -- Cotizaciones del cliente
    SELECT 
        cot.id_cotizacion,
        cot.fecha_emision_cotizancion,
        cot.descripcion_trabajo_cotizancion,
        cot.monto_estimado_cotizacion,
        cot.estado_cotizacion,
        cot.notas
    FROM cotizaciones cot
    WHERE cot.id_cliente = @id_cliente;

    -- Proyectos del cliente
    SELECT 
        p.id_proyecto,
        p.nombre_proyecto,
        p.ubicacion_proyecto,
        p.fecha_inicio_proyecto,
        p.fecha_fin_estimada_proyecto,
        p.estado_proyecto,
        p.costo_total_proyecto
    FROM proyectos p
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
        t.cargo_trabajador,
        t.tarifa_base_trabajador
    FROM trabajadores t
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
        m.especificaciones
    FROM materiales m;
END;
GO

-- EXEC sp_RecursosDisponibles;

------------------------------------------------------------------------------------------------------------------------------
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
        ISNULL(SUM(n.monto_cancelado), 0)               AS total_pagado_nomina,
        p.costo_total_proyecto 
            - ISNULL(SUM(n.monto_cancelado), 0)         AS ganancia_estimada
    FROM proyectos p
    INNER JOIN clientes c ON p.id_cliente = c.id_cliente
    LEFT  JOIN nomina n   ON p.id_proyecto = n.id_proyecto
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
        COUNT(DISTINCT p.id_proyecto)                   AS total_proyectos,
        SUM(p.costo_total_proyecto)                     AS ingreso_total_proyectos,
        ISNULL(SUM(n.monto_cancelado), 0)               AS total_pagado_nomina,
        SUM(p.costo_total_proyecto) 
            - ISNULL(SUM(n.monto_cancelado), 0)         AS ganancia_total_estimada
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
        mt.tipo_estructura,
        mt.pago_por_unidades,
        mt.unidad_medida,
        mt.observaciones,
        p.id_proyecto,
        p.nombre_proyecto,
        p.ubicacion_proyecto,
        p.estado_proyecto,
        c.nombre_empresa_cliente
    FROM medidas_tecnicas mt
    INNER JOIN proyectos p ON mt.id_proyecto = p.id_proyecto
    INNER JOIN clientes c  ON p.id_cliente   = c.id_cliente
    WHERE mt.tipo_estructura = @tipo_estructura
    ORDER BY p.fecha_inicio_proyecto DESC;
END;
GO

-- EXEC sp_ProyectosPorTipoEstructura @tipo_estructura = 'Techo';


---------------------------------------------------------------
---------------------------------------------------------------




------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------
-- SP 5: Detalle completo de un proyecto
-- Mi obra maestra xd, devuelve todo lo del proyecto: cliente, cotizacion, medidas, personal, materiales, nomina y cuenta
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
        p.ubicacion_proyecto,
        p.fecha_inicio_proyecto,
        p.fecha_fin_estimada_proyecto,
        p.estado_proyecto,
        p.costo_total_proyecto,
        c.nombre_empresa_cliente,
        c.telefono_cliente,
        cot.descripcion_trabajo_cotizancion,
        cot.monto_estimado_cotizacion
    FROM proyectos p
    INNER JOIN clientes c       
    ON p.id_cliente    = c.id_cliente
        INNER JOIN cotizaciones cot 
        ON p.id_cotizacion = cot.id_cotizacion
        WHERE p.id_proyecto = @id_proyecto;

    -- Medidas tecnicas del proyecto
    SELECT 
        dimensiones_exactas,
        tipo_estructura,
        pago_por_unidades,
        unidad_medida,
        observaciones
    FROM medidas_tecnicas
    WHERE id_proyecto = @id_proyecto;

    -- Personal asignado
    SELECT 
        t.id_trabajador,
        t.nombre_completo_trabajador,
        t.cargo_trabajador,
        t.tarifa_base_trabajador,
        ap.fecha_inicio_asignacion
    FROM asignacion_personal ap
    INNER JOIN trabajadores t ON ap.id_trabajador = t.id_trabajador
    WHERE ap.id_proyecto = @id_proyecto;

    -- Materiales utilizados
    SELECT 
        m.descripcion_material,
        m.especificaciones,
        dmo.cantidad_utilizada,
        dmo.unidad_medida
    FROM detalle_materiales_obra dmo
    INNER JOIN materiales m ON dmo.id_material = m.id_material
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

    -- Estado de cuenta
    SELECT 
        id_cuenta,
        saldo_cuenta
    FROM estados_cuenta_proyecto
    WHERE id_proyecto = @id_proyecto;
END;
GO

-- EXEC sp_DetalleProyecto @id_proyecto = 'P0001';


---------------------------------------------------------------
---------------------------------------------------------------
