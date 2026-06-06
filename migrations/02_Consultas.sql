--Consultas
--1. Una consulta que muestre los recursos disponibles del sistema.

--2. Una consulta que calcule totales o ingresos 
--en un período determinado.
--Cuales fueron los totales de los pagos del primer trimestre del año
Select 
	DATENAME(month, pc.fecha_pago) as 'Mes',
	SUM(pc.monto_pago) as Total_Mensual
from 
	dbo.pagos_cliente pc
Where 
	pc.fecha_pago between '2026-01-01' and '2026-03-31'
group by 
	DATENAME(MONTH, pc.fecha_pago),
	MONTH(pc.fecha_pago)
order by 
	MONTH(pc.fecha_pago);

--3. Una consulta que muestre los elementos asociados 
--a una categoría o departamento específico.
--Cuales son los trabajadores asignados a proyectos
select distinct  
ap.id_trabajador,
t.nombre_completo_trabajador,
t.id_cargo,
p.id_direccion,
p.nombre_proyecto
FROM 
	dbo.asignacion_personal ap
INNER JOIN dbo.trabajadores t 
	ON ap.id_trabajador = t.id_trabajador
INNER JOIN dbo.proyectos p 
	ON ap.id_proyecto = p.id_proyecto
ORDER BY 
	t.nombre_completo_trabajador;

--4. Una consulta que muestre el detalle de una transacción, 
--reserva o proceso específico.
SELECT 
    mt.id_tipo_estructura,
    mt.dimensiones_exactas,
    um.abreviatura,
    (
        TRY_CAST(REPLACE(LTRIM(RTRIM(mt.dimensiones_exactas)), ',', '') AS NUMERIC(18,2)) *
        TRY_CAST(REPLACE(LTRIM(RTRIM(mt.pago_por_unidades)), ',', '') AS NUMERIC(18,2))
    ) AS [Pago total]
from dbo.medidas_tecnicas mt
INNER JOIN dbo.unidades_medida um
    ON um.id_unidad = mt.id_unidad;

--5. Cinco consultas adicionales propuestas por el grupo 
--que utilicen funciones de agregación, subconsultas o ambas.

-- 1.Proyectos por provincia
select 
	p.nombre_proyecto,
	pro.nombre_provincia
from 
	dbo.proyectos p
inner join dbo.direcciones d
	ON d.id_direccion = p.id_direccion
inner join dbo.corregimientos c
	on c.id_corregimiento = d.id_corregimiento
inner join dbo.distritos dis
	on dis.id_distrito = c.id_distrito
inner join dbo.provincias pro
	on pro.id_provincia = dis.id_provincia;

--2. El total de dinero que se ha solicitado del prosupuesto de cada proyecto  
select 
	p.id_proyecto,
	p.nombre_proyecto,
	SUM(sq.monto_solicitud) as 'Total solicitado'
from 
	dbo.solicitudes_quincenales sq
inner join dbo.proyectos p
	on p.id_proyecto = sq.id_proyecto
group by 
	p.id_proyecto,
	p.nombre_proyecto;

--3 Los pagos que relizaron a cada empleado en un determiando mes
SELECT 
    t.nombre_completo_trabajador AS [Empleado],
    COUNT(n.id_nomina) AS [Pagos realizados],
    SUM(n.monto_cancelado) AS [Total pagado],
    AVG(n.monto_cancelado) AS [Promedio por pago]
FROM dbo.nomina n
INNER JOIN dbo.trabajadores t
    ON t.id_trabajador = n.id_trabajador
WHERE n.fecha_pago BETWEEN '2026-01-01' AND '2026-01-31'
GROUP BY 
    t.nombre_completo_trabajador
ORDER BY
    SUM(n.monto_cancelado) DESC;

--4. Cada uno de los pagos que se le hicieron a los trabajdores y su fehca
SELECT 
    t.nombre_completo_trabajador AS [Empleado],
    n.monto_cancelado AS [Monto Pagado],
    n.fecha_pago AS [Fecha de Pago]
FROM dbo.nomina n
INNER JOIN dbo.trabajadores t ON t.id_trabajador = n.id_trabajador
ORDER BY 
    t.nombre_completo_trabajador ASC, 
    n.fecha_pago ASC;

--5 La cantidad de proyectos que tienen cada cliente y la suma de sus proyectos
select 
	c.nombre_empresa_cliente,
	COUNT(p.id_proyecto) as 'Cantidad de proyectos',
	SUM(p.costo_total_proyecto) as 'Suma de sus proyectos'
from dbo.clientes c
inner join dbo.proyectos p
	on p.id_cliente = c.id_cliente
group by 
	c.nombre_empresa_cliente
ORDER BY 'Suma de sus proyectos' DESC;
