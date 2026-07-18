CREATE FUNCTION fn_CalcularTotalNomina
(
    @id_proyecto INT,
    @periodo VARCHAR(100)
)
    RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @total DECIMAL(12,2);

    SELECT @total = SUM(nm.monto_cancelado)
    FROM nomina n
             INNER JOIN nomina_monto nm
                        ON n.id_nomina = nm.id_nomina
    WHERE n.id_proyecto = @id_proyecto
      AND n.periodo_quincenal_nomina = @periodo;

    RETURN ISNULL(@total,0);
END;
GO

SELECT dbo.fn_CalcularTotalNomina(3, 'Primera quincena enero 2025') AS TotalNomina;

CREATE OR ALTER FUNCTION dbo.fn_ObtenerMaterialesPorProyecto
(
    @id_proyecto INT
)
    RETURNS TABLE
        AS
        RETURN
        (
        SELECT
            m.id_material,
            m.descripcion_material,
            dmo.cantidad_utilizada
        FROM detalle_material_obra AS dmo
                 INNER JOIN materiales AS m
                            ON dmo.id_material = m.id_material
        WHERE dmo.id_proyecto = @id_proyecto
        );
GO

SELECT * FROM dbo.fn_ObtenerMaterialesPorProyecto(1);
