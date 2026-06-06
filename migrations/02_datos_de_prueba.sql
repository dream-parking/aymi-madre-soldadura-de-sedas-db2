USE [soldadura-de-sedas-aymi-madre-db2]

LIMPIEZA

DELETE FROM medidas_tecnicas;
DELETE FROM detalle_materiales_obra;
DELETE FROM nomina;
DELETE FROM asignacion_personal;
DELETE FROM solicitudes_quincenales;
DELETE FROM pagos_cliente;
DELETE FROM proyectos;
DELETE FROM cotizaciones;
DELETE FROM clientes;
DELETE FROM direcciones;
DELETE FROM corregimientos;
DELETE FROM distritos;
DELETE FROM provincias;
DELETE FROM materiales;
DELETE FROM categorias_material;
DELETE FROM unidades_medida;
DELETE FROM trabajadores;
DELETE FROM cargos;
DELETE FROM tipos_estructura;
DELETE FROM metodos_pago;
DELETE FROM _migraciones;
GO

-- =====================================================================
-- 1. TABLAS DE CLASIFICACIÓN / CATÁLOGOS (~10 REGISTROS POR TABLA)
-- =====================================================================

INSERT INTO _migraciones (version, descripcion, aplicada_utc) VALUES
('01', 'Inicialización Azure SQL', SYSUTCDATETIME()),
('02', 'Sembrado de catálogos', SYSUTCDATETIME());
GO

-- 10 Cargos
INSERT INTO cargos (id_cargo, nombre_cargo) VALUES
('C01', 'Maestro de Obra'), ('C02', 'Albañil'), ('C03', 'Soldador'),
('C04', 'Ayudante General'), ('C05', 'Electricista'), ('C06', 'Plomero'),
('C07', 'Carpintero'), ('C08', 'Pintor'), ('C09', 'Topógrafo'),
('C10', 'Ingeniero Residente');

-- 10 Categorías de Materiales
INSERT INTO categorias_material (id_categoria, nombre_categoria) VALUES
('T01', 'Aceros y Metales'), ('T02', 'Cementos y Agregados'),
('T03', 'Plomería y Tuberías'), ('T04', 'Electricidad e Iluminación'),
('T05', 'Maderas y Encofrados'), ('T06', 'Pinturas y Acabados'),
('T07', 'Herramientas Consumibles'), ('T08', 'Cerámicas y Pisos'),
('T09', 'Impermeabilizantes'), ('T10', 'Vidrios y Aluminios');

-- 6 Métodos de pago (suficientes para la lógica)
INSERT INTO metodos_pago (id_metodo_pago, nombre_metodo_pago) VALUES
('M01', 'Transferencia ACH'), ('M02', 'Cheque'), ('M03', 'Efectivo'),
('M04', 'Tarjeta de Crédito'), ('M05', 'Yappy / Billetera Digital'), ('M06', 'Wire Transfer');

-- 10 Tipos de Estructura
INSERT INTO tipos_estructura (id_tipo_estructura, nombre_tipo_estructura) VALUES
('E01', 'Fundación / Cimientos'), ('E02', 'Viga de Amarre'),
('E03', 'Losa de Concreto'), ('E04', 'Columnas'), ('E05', 'Muros de Bloque'),
('E06', 'Techo / Cubierta'), ('E07', 'Escaleras'), ('E08', 'Zapatas'),
('E09', 'Pilotes'), ('E10', 'Aceras y Pavimentos');

-- 10 Unidades de Medida
INSERT INTO unidades_medida (id_unidad, nombre_unidad, abreviatura) VALUES
('U01', 'Metro Lineal', 'ml'), ('U02', 'Metro Cuadrado', 'm2'),
('U03', 'Metro Cúbico', 'm3'), ('U04', 'Bolsa 94lbs', 'bls'),
('U05', 'Unidad', 'ud'), ('U06', 'Kilogramo', 'kg'),
('U07', 'Libra', 'lb'), ('U08', 'Galón', 'gal'),
('U09', 'Pie de Tabla', 'pt'), ('U10', 'Quintal', 'qq');
GO


-- =====================================================================
-- 2. GEOGRAFÍA Y DIRECCIONES (SOPORTE PARA CLIENTES Y PROYECTOS)


INSERT INTO provincias (id_provincia, nombre_provincia, es_comarca) VALUES
('08', 'Panamá', 0), ('04', 'Chiriquí', 0), ('03', 'Colón', 0);

INSERT INTO distritos (id_distrito, id_provincia, nombre_distrito) VALUES
('0801', '08', 'Panamá'), ('0802', '08', 'San Miguelito'), ('0401', '04', 'David'), ('0301', '03', 'Colón');

INSERT INTO corregimientos (id_corregimiento, id_distrito, nombre_corregimiento) VALUES
('080101', '0801', 'San Francisco'), ('080102', '0801', 'Bella Vista'),
('080103', '0801', 'Juan Díaz'), ('080201', '0802', 'Rufina Alfaro'),
('040101', '0401', 'David Centro'), ('030101', '0301', 'Cristóbal');

-- 25 Direcciones (Para clientes y proyectos)
INSERT INTO direcciones (id_direccion, id_corregimiento, via_principal, barrio_urbanizacion, edificio_casa, latitud, longitud) VALUES
('D0001', '080101', 'Calle 50', 'Obarrio', 'Torre 1', 8.98, -79.51), ('D0002', '080102', 'Ave. Balboa', 'Marbella', 'Casa 2', 8.97, -79.52),
('D0003', '080103', 'Vía Tocumen', 'Costa del Este', 'Local 3', 9.01, -79.45), ('D0004', '080201', 'Brisas del Golf', 'Brisas', 'Casa 4', 9.05, -79.43),
('D0005', '040101', 'Calle F Sur', 'Bolívar', 'Edif 5', 8.42, -82.43), ('D0006', '030101', 'Ave. Central', 'Zona Libre', 'Bodega 6', 9.35, -79.89),
('D0007', '080101', 'Vía Israel', 'Paitilla', 'PH 7', 8.98, -79.50), ('D0008', '080102', 'Calle Uruguay', 'Bella Vista', 'Local 8', 8.97, -79.52),
('D0009', '080103', 'Santa María', 'Golf Club', 'Casa 9', 9.02, -79.46), ('D0010', '080201', 'Cerro Viento', 'Principal', 'Casa 10', 9.06, -79.44),
('D0011', '080101', 'Calle 73', 'San Francisco', 'Edif 11', 8.99, -79.51), ('D0012', '080102', 'Ave. España', 'Cangrejo', 'Apto 12', 8.98, -79.53),
('D0013', '040101', 'Vía Boquete', 'Doleguita', 'Plaza 13', 8.44, -82.43), ('D0014', '030101', 'Randolph', 'Margarita', 'Galera 14', 9.33, -79.88),
('D0015', '080101', 'Vía Porras', 'San Francisco', 'Local 15', 8.99, -79.50), ('D0016', '080103', 'Chanis', 'Romeral', 'Casa 16', 9.03, -79.47),
('D0017', '080201', 'San Antonio', 'Villa Flor', 'Casa 17', 9.07, -79.43), ('D0018', '040101', 'Red Grey', 'Aeropuerto', 'Hangar 18', 8.40, -82.42),
('D0019', '080101', 'Coco del Mar', 'Coco', 'PH 19', 8.99, -79.49), ('D0020', '080102', 'Vía Argentina', 'Cangrejo', 'Local 20', 8.98, -79.53),
('D0021', '030101', 'Cuatro Altos', 'Plaza', 'Local 21', 9.34, -79.87), ('D0022', '080103', 'Llano Bonito', 'Industrial', 'Bodega 22', 9.02, -79.45),
('D0023', '080201', 'Brisas Norte', 'Alpes', 'Casa 23', 9.08, -79.42), ('D0024', '040101', 'San Mateo', 'Centro', 'Local 24', 8.43, -82.43),
('D0025', '080101', 'Punta Pacífica', 'Pacífica', 'Torre 25', 8.97, -79.51);
GO

-- =====================================================================
-- 3. CLIENTES (25 REGISTROS)
-- =====================================================================

INSERT INTO clientes (id_cliente, nombre_empresa_cliente, telefono_cliente, correo_cliente, fecha_registro, id_direccion) VALUES
('CL001', 'Constructora Alfa S.A.', '230-0001', 'info@alfa.com', '2025-01-01', 'D0001'),
('CL002', 'Desarrollos del Istmo', '230-0002', 'contacto@istmo.com', '2025-01-05', 'D0002'),
('CL003', 'Inversiones Omega', '230-0003', 'ventas@omega.com', '2025-01-10', 'D0003'),
('CL004', 'Proyectos Zenith', '230-0004', 'admin@zenith.com', '2025-01-15', 'D0004'),
('CL005', 'Bienes Raíces Sur', '230-0005', 'gerencia@brsur.com', '2025-01-20', 'D0005'),
('CL006', 'Logística Atlántica', '230-0006', 'ops@atlantica.com', '2025-01-25', 'D0006'),
('CL007', 'Grupo Horizonte', '230-0007', 'info@ghorizonte.com', '2025-02-01', 'D0007'),
('CL008', 'Consorcio Balboa', '230-0008', 'finanzas@balboa.com', '2025-02-05', 'D0008'),
('CL009', 'Torres del Parque', '230-0009', 'ventas@torres.com', '2025-02-10', 'D0009'),
('CL010', 'Urbanismo Siglo XXI', '230-0010', 'contacto@sigloxxi.com', '2025-02-15', 'D0010'),
('CL011', 'Viviendas Premium', '230-0011', 'hola@vpremium.com', '2025-02-20', 'D0011'),
('CL012', 'Edificaciones Doradas', '230-0012', 'proyectos@doradas.com', '2025-02-25', 'D0012'),
('CL013', 'Constructora Valle', '230-0013', 'info@cvalle.com', '2025-03-01', 'D0013'),
('CL014', 'Puertos y Logística', '230-0014', 'admin@puertos.com', '2025-03-05', 'D0014'),
('CL015', 'Desarrollo Costero', '230-0015', 'costero@gmail.com', '2025-03-10', 'D0015'),
('CL016', 'Inmobiliaria Este', '230-0016', 'ventas@oeste.com', '2025-03-15', 'D0016'),
('CL017', 'Obras Civiles S.A.', '230-0017', 'civil@obras.com', '2025-03-20', 'D0017'),
('CL018', 'Grupo Aéreo', '230-0018', 'ops@aereo.com', '2025-03-25', 'D0018'),
('CL019', 'Mares y Ríos S.A.', '230-0019', 'info@mares.com', '2025-04-01', 'D0019'),
('CL020', 'Corporación Centro', '230-0020', 'contacto@centro.com', '2025-04-05', 'D0020'),
('CL021', 'Bodegas Nacionales', '230-0021', 'admin@bodegas.com', '2025-04-10', 'D0021'),
('CL022', 'Parques Industriales', '230-0022', 'ventas@parques.com', '2025-04-15', 'D0022'),
('CL023', 'Grupo Residencial', '230-0023', 'info@gresidencial.com', '2025-04-20', 'D0023'),
('CL024', 'Plazas Comerciales', '230-0024', 'gerencia@plazas.com', '2025-04-25', 'D0024'),
('CL025', 'Inversiones del Sol', '230-0025', 'contacto@sol.com', '2025-04-30', 'D0025');
GO

-- =====================================================================
-- 4. EMPLEADOS O RESPONSABLES (10 REGISTROS)
-- =====================================================================

INSERT INTO trabajadores (id_trabajador, nombre_completo_trabajador, tarifa_base_trabajador, id_cargo) VALUES
('TR001', 'Juan Pérez', 6.50, 'C01'), ('TR002', 'Carlos Sánchez', 4.50, 'C02'),
('TR003', 'Luis Gómez', 5.00, 'C03'), ('TR004', 'Mario Ruiz', 3.80, 'C04'),
('TR005', 'Ana Martínez', 5.50, 'C05'), ('TR006', 'Jorge Díaz', 5.00, 'C06'),
('TR007', 'Roberto Luna', 4.80, 'C07'), ('TR008', 'Pedro Ramos', 4.20, 'C08'),
('TR009', 'Elena Ríos', 7.50, 'C09'), ('TR010', 'David Cruz', 12.00, 'C10');
GO

-- =====================================================================
-- 5. ENTIDADES OPERATIVAS: COTIZACIONES Y PROYECTOS (20 REGISTROS MAIN)
-- =====================================================================

-- 25 Cotizaciones (5 pendientes/rechazadas, 20 aprobadas para los proyectos)
INSERT INTO cotizaciones (id_cotizacion, id_cliente, fecha_emision_cotizacion, descripcion_trabajo_cotizacion, monto_estimado_cotizacion, estado_cotizacion) VALUES
('CQ001', 'CL001', '2025-05-01', 'Excavaciones', 15000.00, 'Aprobada'), ('CQ002', 'CL002', '2025-05-02', 'Losa y Vigas', 45000.00, 'Aprobada'),
('CQ003', 'CL003', '2025-05-03', 'Fundaciones', 22000.00, 'Aprobada'), ('CQ004', 'CL004', '2025-05-04', 'Acabados Exteriores', 12500.00, 'Aprobada'),
('CQ005', 'CL005', '2025-05-05', 'Techos', 30000.00, 'Aprobada'), ('CQ006', 'CL006', '2025-05-06', 'Pintura General', 8000.00, 'Aprobada'),
('CQ007', 'CL007', '2025-05-07', 'Remodelación', 18000.00, 'Aprobada'), ('CQ008', 'CL008', '2025-05-08', 'Muro Perimetral', 9500.00, 'Aprobada'),
('CQ009', 'CL009', '2025-05-09', 'Instalación Eléctrica', 11000.00, 'Aprobada'), ('CQ010', 'CL010', '2025-05-10', 'Plomería Completa', 13000.00, 'Aprobada'),
('CQ011', 'CL011', '2025-05-11', 'Aceras', 5000.00, 'Aprobada'), ('CQ012', 'CL012', '2025-05-12', 'Estructura Metálica', 55000.00, 'Aprobada'),
('CQ013', 'CL013', '2025-05-13', 'Ventanas', 7000.00, 'Aprobada'), ('CQ014', 'CL014', '2025-05-14', 'Pisos Cerámicos', 14000.00, 'Aprobada'),
('CQ015', 'CL015', '2025-05-15', 'Zapatas', 21000.00, 'Aprobada'), ('CQ016', 'CL016', '2025-05-16', 'Impermeabilización', 6500.00, 'Aprobada'),
('CQ017', 'CL017', '2025-05-17', 'Topografía', 3500.00, 'Aprobada'), ('CQ018', 'CL018', '2025-05-18', 'Pilotes', 85000.00, 'Aprobada'),
('CQ019', 'CL019', '2025-05-19', 'Escaleras', 9000.00, 'Aprobada'), ('CQ020', 'CL020', '2025-05-20', 'Cielo Raso', 10500.00, 'Aprobada'),
('CQ021', 'CL021', '2025-05-21', 'Fachada', 25000.00, 'Pendiente'), ('CQ022', 'CL022', '2025-05-22', 'Piscina', 32000.00, 'Rechazada'),
('CQ023', 'CL023', '2025-05-23', 'Bodega', 60000.00, 'Pendiente'), ('CQ024', 'CL024', '2025-05-24', 'Gazebo', 4500.00, 'Rechazada'),
('CQ025', 'CL025', '2025-05-25', 'Estacionamientos', 19000.00, 'Pendiente');

-- 20 Proyectos Operativos (basados en las cotizaciones aprobadas)
INSERT INTO proyectos (id_proyecto, id_cliente, id_cotizacion, nombre_proyecto, fecha_inicio_proyecto, estado_proyecto, costo_total_proyecto, id_direccion) VALUES
('PR001', 'CL001', 'CQ001', 'Torre Alfa F1', '2025-06-01', 'En proceso', 15000.00, 'D0001'),
('PR002', 'CL002', 'CQ002', 'Losa Nivel 2', '2025-06-02', 'En proceso', 45000.00, 'D0002'),
('PR003', 'CL003', 'CQ003', 'Fundación Bodegas', '2025-06-03', 'Finalizado', 22000.00, 'D0003'),
('PR004', 'CL004', 'CQ004', 'Exteriores Zenith', '2025-06-04', 'En proceso', 12500.00, 'D0004'),
('PR005', 'CL005', 'CQ005', 'Techos Galera Sur', '2025-06-05', 'En proceso', 30000.00, 'D0005'),
('PR006', 'CL006', 'CQ006', 'Pintura Fachada', '2025-06-06', 'Finalizado', 8000.00, 'D0006'),
('PR007', 'CL007', 'CQ007', 'Remodelación Lobby', '2025-06-07', 'En proceso', 18000.00, 'D0007'),
('PR008', 'CL008', 'CQ008', 'Muro Balboa', '2025-06-08', 'Finalizado', 9500.00, 'D0008'),
('PR009', 'CL009', 'CQ009', 'Luz Parque', '2025-06-09', 'En proceso', 11000.00, 'D0009'),
('PR010', 'CL010', 'CQ010', 'Sanitario XXI', '2025-06-10', 'En proceso', 13000.00, 'D0010'),
('PR011', 'CL011', 'CQ011', 'Aceras Premium', '2025-06-11', 'Finalizado', 5000.00, 'D0011'),
('PR012', 'CL012', 'CQ012', 'Nave Metálica', '2025-06-12', 'En proceso', 55000.00, 'D0012'),
('PR013', 'CL013', 'CQ013', 'Vidrios Valle', '2025-06-13', 'En proceso', 7000.00, 'D0013'),
('PR014', 'CL014', 'CQ014', 'Pisos Logística', '2025-06-14', 'Finalizado', 14000.00, 'D0014'),
('PR015', 'CL015', 'CQ015', 'Zapatas Costeras', '2025-06-15', 'En proceso', 21000.00, 'D0015'),
('PR016', 'CL016', 'CQ016', 'Impermeable Este', '2025-06-16', 'Finalizado', 6500.00, 'D0016'),
('PR017', 'CL017', 'CQ017', 'Topografía Civil', '2025-06-17', 'Finalizado', 3500.00, 'D0017'),
('PR018', 'CL018', 'CQ018', 'Pilotes Aéreos', '2025-06-18', 'En proceso', 85000.00, 'D0018'),
('PR019', 'CL019', 'CQ019', 'Escaleras Mares', '2025-06-19', 'En proceso', 9000.00, 'D0019'),
('PR020', 'CL020', 'CQ020', 'Cielo Raso Centro', '2025-06-20', 'En proceso', 10500.00, 'D0020');
GO

-- =====================================================================
-- 6. PAGOS O MOVIMIENTOS FINANCIEROS (10 REGISTROS)
-- =====================================================================

INSERT INTO pagos_cliente (id_pago, id_proyecto, id_metodo_pago, fecha_pago, monto_pago, referencia_pago) VALUES
('PG001', 'PR001', 'M01', '2025-06-05', 5000.00, 'ACH-1111'), ('PG002', 'PR002', 'M02', '2025-06-06', 15000.00, 'CHQ-2222'),
('PG003', 'PR003', 'M01', '2025-06-15', 22000.00, 'ACH-3333'), ('PG004', 'PR004', 'M04', '2025-06-20', 6000.00, 'TC-4444'),
('PG005', 'PR006', 'M03', '2025-06-25', 8000.00, 'EFECTIVO'), ('PG006', 'PR008', 'M01', '2025-07-01', 9500.00, 'ACH-5555'),
('PG007', 'PR011', 'M02', '2025-07-05', 5000.00, 'CHQ-6666'), ('PG008', 'PR014', 'M01', '2025-07-10', 14000.00, 'ACH-7777'),
('PG009', 'PR016', 'M05', '2025-07-15', 6500.00, 'YAPPY-8888'), ('PG010', 'PR017', 'M01', '2025-07-20', 3500.00, 'ACH-9999');
GO

-- =====================================================================
-- 7. TRANSACCIONES Y REGISTROS EQUIVALENTES (20 REGISTROS C/U)
-- =====================================================================

-- 20 Solicitudes Quincenales
INSERT INTO solicitudes_quincenales (id_solicitud, id_proyecto, monto_solicitud, fecha_solicitud) VALUES
('SQ001', 'PR001', 2000.00, '2025-06-15'), ('SQ002', 'PR002', 8000.00, '2025-06-15'),
('SQ003', 'PR004', 3000.00, '2025-06-15'), ('SQ004', 'PR005', 5000.00, '2025-06-15'),
('SQ005', 'PR007', 4000.00, '2025-06-15'), ('SQ006', 'PR009', 2500.00, '2025-06-15'),
('SQ007', 'PR010', 3500.00, '2025-06-15'), ('SQ008', 'PR012', 12000.00,'2025-06-15'),
('SQ009', 'PR013', 1500.00, '2025-06-15'), ('SQ010', 'PR015', 4500.00, '2025-06-15'),
('SQ011', 'PR018', 15000.00,'2025-06-15'), ('SQ012', 'PR019', 2000.00, '2025-06-15'),
('SQ013', 'PR020', 2500.00, '2025-06-15'), ('SQ014', 'PR001', 3000.00, '2025-06-30'),
('SQ015', 'PR002', 10000.00,'2025-06-30'), ('SQ016', 'PR004', 3500.00, '2025-06-30'),
('SQ017', 'PR005', 6000.00, '2025-06-30'), ('SQ018', 'PR007', 4500.00, '2025-06-30'),
('SQ019', 'PR012', 15000.00,'2025-06-30'), ('SQ020', 'PR018', 20000.00,'2025-06-30');

-- 20 Asignaciones de Personal
INSERT INTO asignacion_personal (id_proyecto, id_trabajador, fecha_inicio_asignacion) VALUES
('PR001', 'TR001', '2025-06-01'), ('PR001', 'TR002', '2025-06-01'), ('PR002', 'TR001', '2025-06-02'), ('PR002', 'TR003', '2025-06-02'),
('PR003', 'TR004', '2025-06-03'), ('PR004', 'TR005', '2025-06-04'), ('PR005', 'TR006', '2025-06-05'), ('PR006', 'TR008', '2025-06-06'),
('PR007', 'TR007', '2025-06-07'), ('PR008', 'TR002', '2025-06-08'), ('PR009', 'TR005', '2025-06-09'), ('PR010', 'TR006', '2025-06-10'),
('PR011', 'TR004', '2025-06-11'), ('PR012', 'TR003', '2025-06-12'), ('PR013', 'TR007', '2025-06-13'), ('PR014', 'TR008', '2025-06-14'),
('PR015', 'TR001', '2025-06-15'), ('PR016', 'TR004', '2025-06-16'), ('PR017', 'TR009', '2025-06-17'), ('PR018', 'TR010', '2025-06-18');

-- 20 Registros de Nómina (Pagos a trabajadores)
INSERT INTO nomina (id_nomina, id_trabajador, id_proyecto, horas_trabajadas, monto_cancelado, fecha_pago) VALUES
('NM001', 'TR001', 'PR001', 80.00, 520.00, '2025-06-15'), ('NM002', 'TR002', 'PR001', 80.00, 360.00, '2025-06-15'),
('NM003', 'TR001', 'PR002', 80.00, 520.00, '2025-06-15'), ('NM004', 'TR003', 'PR002', 80.00, 400.00, '2025-06-15'),
('NM005', 'TR004', 'PR003', 40.00, 152.00, '2025-06-15'), ('NM006', 'TR005', 'PR004', 80.00, 440.00, '2025-06-15'),
('NM007', 'TR006', 'PR005', 80.00, 400.00, '2025-06-15'), ('NM008', 'TR008', 'PR006', 40.00, 168.00, '2025-06-15'),
('NM009', 'TR007', 'PR007', 80.00, 384.00, '2025-06-15'), ('NM010', 'TR002', 'PR008', 40.00, 180.00, '2025-06-15'),
('NM011', 'TR005', 'PR009', 80.00, 440.00, '2025-06-15'), ('NM012', 'TR006', 'PR010', 80.00, 400.00, '2025-06-15'),
('NM013', 'TR004', 'PR011', 40.00, 152.00, '2025-06-15'), ('NM014', 'TR003', 'PR012', 80.00, 400.00, '2025-06-15'),
('NM015', 'TR007', 'PR013', 80.00, 384.00, '2025-06-15'), ('NM016', 'TR008', 'PR014', 40.00, 168.00, '2025-06-15'),
('NM017', 'TR001', 'PR015', 80.00, 520.00, '2025-06-15'), ('NM018', 'TR004', 'PR016', 40.00, 152.00, '2025-06-15'),
('NM019', 'TR009', 'PR017', 40.00, 300.00, '2025-06-15'), ('NM020', 'TR010', 'PR018', 80.00, 960.00, '2025-06-15');

-- 10 Materiales Creados para el Detalle
INSERT INTO materiales (id_material, descripcion_material, especificaciones, id_categoria, id_unidad) VALUES
('MA001', 'Cemento Portland', 'Uso general 42.5kg', 'T02', 'U04'), ('MA002', 'Varilla Corrugada', '1/2 pulgada', 'T01', 'U05'),
('MA003', 'Tubo PVC Sanitario', '4 pulgadas', 'T03', 'U05'), ('MA004', 'Cable Eléctrico THHN', 'Calibre 12', 'T04', 'U01'),
('MA005', 'Bloque de Arcilla', '4x8x16', 'T02', 'U05'), ('MA006', 'Pintura Blanca', 'Acrílica Exterior', 'T06', 'U08'),
('MA007', 'Lámina de Zinc', 'Ondulada 12 pies', 'T01', 'U05'), ('MA008', 'Baldosa Cerámica', '60x60 Antideslizante', 'T08', 'U02'),
('MA009', 'Arena Continental', 'Lavada', 'T02', 'U03'), ('MA010', 'Impermeabilizante', 'Asfáltico en frío', 'T09', 'U08');

-- 20 Registros de Detalles de Materiales
INSERT INTO detalle_materiales_obra (id_proyecto, id_material, cantidad_utilizada) VALUES
('PR001', 'MA001', 50.00), ('PR001', 'MA002', 120.00), ('PR002', 'MA001', 300.00), ('PR002', 'MA002', 800.00),
('PR003', 'MA001', 80.00), ('PR004', 'MA006', 15.00), ('PR005', 'MA007', 150.00), ('PR006', 'MA006', 20.00),
('PR007', 'MA008', 45.00), ('PR008', 'MA005', 500.00), ('PR008', 'MA001', 30.00), ('PR009', 'MA004', 200.00),
('PR010', 'MA003', 40.00), ('PR011', 'MA001', 25.00), ('PR012', 'MA007', 400.00), ('PR014', 'MA008', 120.00),
('PR015', 'MA001', 100.00), ('PR016', 'MA010', 10.00), ('PR018', 'MA001', 500.00), ('PR020', 'MA006', 10.00);

-- 20 Registros de Medidas Técnicas
INSERT INTO medidas_tecnicas (id_medida, id_proyecto, dimensiones_exactas, pago_por_unidades, observaciones, id_tipo_estructura, id_unidad) VALUES
('MT001', 'PR001', '10x10x1', 1200.00, 'Zanja central', 'E01', 'U03'), ('MT002', 'PR002', '20x15x0.2', 4500.00, 'Losa nivel 2', 'E03', 'U02'),
('MT003', 'PR003', '15x15x1', 1800.00, 'Plataforma', 'E01', 'U03'), ('MT004', 'PR004', '50ml', 800.00, 'Acabado perimetral', 'E05', 'U01'),
('MT005', 'PR005', '30x20', 2500.00, 'Cubierta galera', 'E06', 'U02'), ('MT006', 'PR006', '100m2', 500.00, 'Frente de calle', 'E05', 'U02'),
('MT007', 'PR007', '80m2', 1200.00, 'Pisos y paredes', 'E05', 'U02'), ('MT008', 'PR008', '120ml', 3000.00, 'Cerca trasera', 'E05', 'U01'),
('MT009', 'PR009', '200ml', 1500.00, 'Acometida soterrada', 'E10', 'U01'), ('MT010', 'PR010', '50ml', 900.00, 'Línea de drenaje', 'E01', 'U01'),
('MT011', 'PR011', '60ml', 800.00, 'Acera peatonal', 'E10', 'U01'), ('MT012', 'PR012', '40x30', 8500.00, 'Pórticos', 'E04', 'U02'),
('MT013', 'PR013', '15 ventanas', 600.00, 'Marcos aluminio', 'E05', 'U05'), ('MT014', 'PR014', '200m2', 2000.00, 'Tráfico pesado', 'E03', 'U02'),
('MT015', 'PR015', '12 zapatas', 3500.00, 'Aisladas', 'E08', 'U05'), ('MT016', 'PR016', '150m2', 900.00, 'Azotea', 'E06', 'U02'),
('MT017', 'PR017', '1 Ha', 400.00, 'Levantamiento planimétrico', 'E10', 'U02'), ('MT018', 'PR018', '20 pilotes', 15000.00, 'Profundidad 12m', 'E09', 'U01'),
('MT019', 'PR019', '3 niveles', 1200.00, 'Escalera de emergencia', 'E07', 'U05'), ('MT020', 'PR020', '100m2', 800.00, 'Suspendido', 'E06', 'U02');
GO