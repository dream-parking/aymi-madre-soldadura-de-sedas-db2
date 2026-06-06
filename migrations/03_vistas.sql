-- Vista de proyectos con información del cliente

CREATE VIEW vista_proyectos_clientes AS
SELECT
    p.id_proyecto,
    p.nombre_proyecto,
    p.estado_proyecto,
    p.costo_total_proyecto,
    c.id_cliente,
    c.nombre_empresa_cliente
FROM proyectos p
         INNER JOIN clientes c
                    ON p.id_cliente = c.id_cliente;

------------------------------------------------------------------

-- Vista de nómina de trabajadores

CREATE VIEW vista_nomina_trabajadores AS
SELECT
    t.id_trabajador,
    t.nombre_completo_trabajador,
    p.nombre_proyecto,
    n.horas_trabajadas,
    n.monto_cancelado,
    n.fecha_pago
FROM nomina n
         INNER JOIN trabajadores t
                    ON n.id_trabajador = t.id_trabajador
         INNER JOIN proyectos p
                    ON n.id_proyecto = p.id_proyecto;


------------------------------------------------------------------

-- Vistas de materiales utilizados por proyectos

CREATE VIEW vista_materiales_proyecto AS
SELECT
    p.nombre_proyecto,
    m.descripcion_material,
    d.cantidad_utilizada,
    u.nombre_unidad
FROM detalle_materiales_obra d
         INNER JOIN proyectos p
                    ON d.id_proyecto = p.id_proyecto
         INNER JOIN materiales m
                    ON d.id_material = m.id_material
         INNER JOIN unidades_medida u
                            ON u.id_unidad = m.id_unidad;

------------------------------------------------------------------
-- Vista de costo de mano de obra por proyecto

CREATE VIEW vista_costo_mano_obra_proyecto AS
SELECT
    p.id_proyecto,
    p.nombre_proyecto,
    COUNT(n.id_nomina) AS cantidad_pagos,
    SUM(ISNULL(n.monto_cancelado, 0)) AS total_pagado_nomina
FROM proyectos p
         INNER JOIN nomina n
                    ON p.id_proyecto = n.id_proyecto
GROUP BY
    p.id_proyecto,
    p.nombre_proyecto;

------------------------------------------------------------------

-- Vista de clientes con cantidad de proyectos

CREATE VIEW vista_clientes_proyectos AS
SELECT
    c.id_cliente,
    c.nombre_empresa_cliente,
    COUNT(p.id_proyecto) AS cantidad_proyectos,
    SUM(p.costo_total_proyecto) AS valor_total_proyectos
FROM clientes c
         LEFT JOIN proyectos p
                   ON c.id_cliente = p.id_cliente
GROUP BY
    c.id_cliente,
    c.nombre_empresa_cliente;}