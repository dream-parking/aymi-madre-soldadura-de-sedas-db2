-- 01: normalización, catálogos, geografía (Panamá) y pagos
-- Asume tablas operativas vacías. Idempotente y atómica.

SET XACT_ABORT ON;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;

BEGIN TRY
BEGIN TRAN;

-- Salvaguarda: aborta si hay datos
IF EXISTS (SELECT 1 FROM clientes)        OR EXISTS (SELECT 1 FROM proyectos)
OR EXISTS (SELECT 1 FROM trabajadores)    OR EXISTS (SELECT 1 FROM cotizaciones)
OR EXISTS (SELECT 1 FROM medidas_tecnicas)OR EXISTS (SELECT 1 FROM detalle_materiales_obra)
OR EXISTS (SELECT 1 FROM nomina)          OR EXISTS (SELECT 1 FROM solicitudes_quincenales)
OR EXISTS (SELECT 1 FROM materiales)
    THROW 50000, 'Hay datos en tablas operativas. La migracion 01 asume tablas vacias. Abortada.', 1;

-- Catálogos
IF OBJECT_ID('dbo.cargos','U') IS NULL
CREATE TABLE cargos (
    id_cargo     CHAR(3)     NOT NULL CONSTRAINT PK_cargos PRIMARY KEY,
    nombre_cargo VARCHAR(40) NOT NULL CONSTRAINT UQ_cargos_nombre UNIQUE
);

IF OBJECT_ID('dbo.unidades_medida','U') IS NULL
CREATE TABLE unidades_medida (
    id_unidad     CHAR(3)     NOT NULL CONSTRAINT PK_unidades PRIMARY KEY,
    nombre_unidad VARCHAR(30) NOT NULL CONSTRAINT UQ_unidades_nombre UNIQUE,
    abreviatura   VARCHAR(10) NOT NULL CONSTRAINT UQ_unidades_abrev  UNIQUE
);

IF OBJECT_ID('dbo.tipos_estructura','U') IS NULL
CREATE TABLE tipos_estructura (
    id_tipo_estructura     CHAR(3)     NOT NULL CONSTRAINT PK_tipos_estructura PRIMARY KEY,
    nombre_tipo_estructura VARCHAR(50) NOT NULL CONSTRAINT UQ_tipos_estructura UNIQUE
);

IF OBJECT_ID('dbo.categorias_material','U') IS NULL
CREATE TABLE categorias_material (
    id_categoria     CHAR(3)     NOT NULL CONSTRAINT PK_categorias_material PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL CONSTRAINT UQ_categorias_material UNIQUE
);

IF OBJECT_ID('dbo.metodos_pago','U') IS NULL
CREATE TABLE metodos_pago (
    id_metodo_pago     CHAR(3)     NOT NULL CONSTRAINT PK_metodos_pago PRIMARY KEY,
    nombre_metodo_pago VARCHAR(30) NOT NULL CONSTRAINT UQ_metodos_pago UNIQUE
);

-- Geografía (Panamá): provincia > distrito > corregimiento > dirección
IF OBJECT_ID('dbo.provincias','U') IS NULL
CREATE TABLE provincias (
    id_provincia     CHAR(2)     NOT NULL CONSTRAINT PK_provincias PRIMARY KEY,
    nombre_provincia VARCHAR(60) NOT NULL CONSTRAINT UQ_provincias UNIQUE,
    es_comarca       BIT         NOT NULL CONSTRAINT DF_provincias_comarca DEFAULT (0)
);

IF OBJECT_ID('dbo.distritos','U') IS NULL
CREATE TABLE distritos (
    id_distrito     CHAR(4)     NOT NULL CONSTRAINT PK_distritos PRIMARY KEY,
    id_provincia    CHAR(2)     NOT NULL,
    nombre_distrito VARCHAR(60) NOT NULL,
    CONSTRAINT FK_distritos_provincia FOREIGN KEY (id_provincia) REFERENCES provincias(id_provincia),
    CONSTRAINT UQ_distritos UNIQUE (id_provincia, nombre_distrito)
);

IF OBJECT_ID('dbo.corregimientos','U') IS NULL
CREATE TABLE corregimientos (
    id_corregimiento     CHAR(6)     NOT NULL CONSTRAINT PK_corregimientos PRIMARY KEY,
    id_distrito          CHAR(4)     NOT NULL,
    nombre_corregimiento VARCHAR(80) NOT NULL,
    CONSTRAINT FK_corregimientos_distrito FOREIGN KEY (id_distrito) REFERENCES distritos(id_distrito),
    CONSTRAINT UQ_corregimientos UNIQUE (id_distrito, nombre_corregimiento)
);

IF OBJECT_ID('dbo.direcciones','U') IS NULL
CREATE TABLE direcciones (
    id_direccion        CHAR(5)      NOT NULL CONSTRAINT PK_direcciones PRIMARY KEY,
    id_corregimiento    CHAR(6)      NOT NULL,
    via_principal       VARCHAR(120) NULL,
    barrio_urbanizacion VARCHAR(120) NULL,
    edificio_casa       VARCHAR(120) NULL,
    punto_referencia    VARCHAR(200) NULL,
    latitud             DECIMAL(9,6) NULL,
    longitud            DECIMAL(9,6) NULL,
    CONSTRAINT FK_direcciones_corregimiento FOREIGN KEY (id_corregimiento) REFERENCES corregimientos(id_corregimiento)
);

-- clientes
ALTER TABLE clientes ALTER COLUMN telefono_cliente VARCHAR(20) NOT NULL;
IF COL_LENGTH('dbo.clientes','id_direccion') IS NULL
    ALTER TABLE clientes ADD id_direccion CHAR(5) NULL;
IF OBJECT_ID('FK_clientes_direccion','F') IS NULL
    ALTER TABLE clientes ADD CONSTRAINT FK_clientes_direccion
        FOREIGN KEY (id_direccion) REFERENCES direcciones(id_direccion);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_clientes_correo' AND object_id = OBJECT_ID('dbo.clientes'))
    CREATE UNIQUE INDEX UQ_clientes_correo ON clientes(correo_cliente) WHERE correo_cliente IS NOT NULL;

-- cotizaciones (corrige typos + DECIMAL)
IF COL_LENGTH('dbo.cotizaciones','fecha_emision_cotizancion') IS NOT NULL
   AND COL_LENGTH('dbo.cotizaciones','fecha_emision_cotizacion') IS NULL
    EXEC sp_rename 'dbo.cotizaciones.fecha_emision_cotizancion', 'fecha_emision_cotizacion', 'COLUMN';
IF COL_LENGTH('dbo.cotizaciones','descripcion_trabajo_cotizancion') IS NOT NULL
   AND COL_LENGTH('dbo.cotizaciones','descripcion_trabajo_cotizacion') IS NULL
    EXEC sp_rename 'dbo.cotizaciones.descripcion_trabajo_cotizancion', 'descripcion_trabajo_cotizacion', 'COLUMN';
ALTER TABLE cotizaciones ALTER COLUMN monto_estimado_cotizacion DECIMAL(12,2) NOT NULL;

-- proyectos (dirección reemplaza ubicacion_proyecto)
ALTER TABLE proyectos ALTER COLUMN costo_total_proyecto DECIMAL(12,2) NOT NULL;
IF COL_LENGTH('dbo.proyectos','id_direccion') IS NULL
    ALTER TABLE proyectos ADD id_direccion CHAR(5) NOT NULL;
IF OBJECT_ID('FK_proyectos_direccion','F') IS NULL
    ALTER TABLE proyectos ADD CONSTRAINT FK_proyectos_direccion
        FOREIGN KEY (id_direccion) REFERENCES direcciones(id_direccion);
IF COL_LENGTH('dbo.proyectos','ubicacion_proyecto') IS NOT NULL
    ALTER TABLE proyectos DROP COLUMN ubicacion_proyecto;

-- trabajadores (cargo -> catálogo)
ALTER TABLE trabajadores ALTER COLUMN tarifa_base_trabajador DECIMAL(12,2) NOT NULL;
IF COL_LENGTH('dbo.trabajadores','id_cargo') IS NULL
    ALTER TABLE trabajadores ADD id_cargo CHAR(3) NOT NULL;
IF OBJECT_ID('FK_trabajadores_cargo','F') IS NULL
    ALTER TABLE trabajadores ADD CONSTRAINT FK_trabajadores_cargo
        FOREIGN KEY (id_cargo) REFERENCES cargos(id_cargo);
IF COL_LENGTH('dbo.trabajadores','cargo_trabajador') IS NOT NULL
    ALTER TABLE trabajadores DROP COLUMN cargo_trabajador;

-- medidas_tecnicas (tipo y unidad -> catálogos)
ALTER TABLE medidas_tecnicas ALTER COLUMN pago_por_unidades DECIMAL(12,2) NOT NULL;
IF COL_LENGTH('dbo.medidas_tecnicas','id_tipo_estructura') IS NULL
    ALTER TABLE medidas_tecnicas ADD id_tipo_estructura CHAR(3) NOT NULL;
IF OBJECT_ID('FK_medidas_tipo','F') IS NULL
    ALTER TABLE medidas_tecnicas ADD CONSTRAINT FK_medidas_tipo
        FOREIGN KEY (id_tipo_estructura) REFERENCES tipos_estructura(id_tipo_estructura);
IF COL_LENGTH('dbo.medidas_tecnicas','tipo_estructura') IS NOT NULL
    ALTER TABLE medidas_tecnicas DROP COLUMN tipo_estructura;
IF COL_LENGTH('dbo.medidas_tecnicas','id_unidad') IS NULL
    ALTER TABLE medidas_tecnicas ADD id_unidad CHAR(3) NOT NULL;
IF OBJECT_ID('FK_medidas_unidad','F') IS NULL
    ALTER TABLE medidas_tecnicas ADD CONSTRAINT FK_medidas_unidad
        FOREIGN KEY (id_unidad) REFERENCES unidades_medida(id_unidad);
IF COL_LENGTH('dbo.medidas_tecnicas','unidad_medida') IS NOT NULL
    ALTER TABLE medidas_tecnicas DROP COLUMN unidad_medida;

-- materiales (categoría + unidad; 2FN)
IF COL_LENGTH('dbo.materiales','id_categoria') IS NULL
    ALTER TABLE materiales ADD id_categoria CHAR(3) NOT NULL;
IF OBJECT_ID('FK_materiales_categoria','F') IS NULL
    ALTER TABLE materiales ADD CONSTRAINT FK_materiales_categoria
        FOREIGN KEY (id_categoria) REFERENCES categorias_material(id_categoria);
IF COL_LENGTH('dbo.materiales','id_unidad') IS NULL
    ALTER TABLE materiales ADD id_unidad CHAR(3) NOT NULL;
IF OBJECT_ID('FK_materiales_unidad','F') IS NULL
    ALTER TABLE materiales ADD CONSTRAINT FK_materiales_unidad
        FOREIGN KEY (id_unidad) REFERENCES unidades_medida(id_unidad);

-- detalle_materiales_obra (quita unidad; 2FN)
ALTER TABLE detalle_materiales_obra ALTER COLUMN cantidad_utilizada DECIMAL(12,3) NOT NULL;
IF COL_LENGTH('dbo.detalle_materiales_obra','unidad_medida') IS NOT NULL
    ALTER TABLE detalle_materiales_obra DROP COLUMN unidad_medida;

-- nomina
ALTER TABLE nomina ALTER COLUMN horas_trabajadas DECIMAL(6,2)  NULL;
ALTER TABLE nomina ALTER COLUMN monto_cancelado  DECIMAL(12,2) NULL;

-- solicitudes_quincenales
ALTER TABLE solicitudes_quincenales ALTER COLUMN monto_solicitud DECIMAL(12,2) NOT NULL;
IF COL_LENGTH('dbo.solicitudes_quincenales','fecha_solicitud') IS NULL
    ALTER TABLE solicitudes_quincenales ADD fecha_solicitud DATE NOT NULL;

-- pagos_cliente
IF OBJECT_ID('dbo.pagos_cliente','U') IS NULL
CREATE TABLE pagos_cliente (
    id_pago         CHAR(5)       NOT NULL CONSTRAINT PK_pagos_cliente PRIMARY KEY,
    id_proyecto     CHAR(5)       NOT NULL,
    id_metodo_pago  CHAR(3)       NOT NULL,
    fecha_pago      DATE          NOT NULL,
    monto_pago      DECIMAL(12,2) NOT NULL CONSTRAINT CK_pagos_monto CHECK (monto_pago > 0),
    referencia_pago VARCHAR(50)   NULL,
    CONSTRAINT FK_pagos_proyecto FOREIGN KEY (id_proyecto)    REFERENCES proyectos(id_proyecto),
    CONSTRAINT FK_pagos_metodo   FOREIGN KEY (id_metodo_pago) REFERENCES metodos_pago(id_metodo_pago)
);

-- estado de cuenta: derivable; la vista se crea en 03
IF OBJECT_ID('dbo.estados_cuenta_proyecto','U') IS NOT NULL
    DROP TABLE estados_cuenta_proyecto;

-- Registro de migraciones
IF OBJECT_ID('dbo._migraciones','U') IS NULL
CREATE TABLE _migraciones (
    version      CHAR(2)      NOT NULL CONSTRAINT PK_migraciones PRIMARY KEY,
    descripcion  VARCHAR(200) NOT NULL,
    aplicada_utc DATETIME2(0) NOT NULL CONSTRAINT DF_migraciones_fecha DEFAULT (SYSUTCDATETIME())
);
IF NOT EXISTS (SELECT 1 FROM _migraciones WHERE version = '00')
    INSERT INTO _migraciones(version, descripcion) VALUES ('00','Esquema inicial (baseline del equipo)');
IF NOT EXISTS (SELECT 1 FROM _migraciones WHERE version = '01')
    INSERT INTO _migraciones(version, descripcion) VALUES ('01','Normalizacion, catalogos, geografia Panama y pagos_cliente');

COMMIT TRAN;
PRINT 'Migracion 01 aplicada correctamente.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    THROW;
END CATCH;
