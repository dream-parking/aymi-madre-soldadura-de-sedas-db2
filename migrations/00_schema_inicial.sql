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


-- Relaciones y llaves compuestas
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
