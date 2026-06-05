# Soldaduras de Sedas — Base de Datos

Sistema de gestión para una empresa de **estructuras metálicas / soldadura**:
clientes → cotizaciones → proyectos → medidas técnicas, asignación de
trabajadores, materiales, nómina, pagos y estado de cuenta.

Motor: **Azure SQL Database** (`soldadura-de-sedas-aymi-madre-db2`).
Para el entregable de Moodle se puede concatenar en un solo `.sql` y correr en
SQL Server local con SSMS.

## Organización por migraciones

| # | Archivo | Contenido |
|---|---------|-----------|
| 00 | `00_schema_inicial.sql` | Esquema base del equipo (línea histórica). |
| 01 | `01_normalizacion_geografia_panama.sql` | Normalización, catálogos, geografía de Panamá y arquitectura financiera. |
| 02 | *(pendiente)* | Datos de prueba (25 clientes, 10 trabajadores, 20 proyectos, etc.). |
| 03 | *(pendiente)* | Consultas, procedimientos almacenados y **vistas** (incl. `vw_estado_cuenta_proyecto`) — a cargo de otro compañero. |

> En Azure, la `00` ya está aplicada (los objetos existen). La `01` está
> diseñada para correr directamente sobre la base, es **idempotente** y
> **atómica** (si algo falla, revierte todo).

## Cómo aplicar la migración 01

Usando los datos de conexión del archivo `.env` (no exponer la contraseña):

```bash
sqlcmd -S aymi-madre-soldadura-de-sedas.database.windows.net,1433 \
       -U alambritos -P "$DB_PASSWORD" \
       -d soldadura-de-sedas-aymi-madre-db2 -C \
       -i migrations/01_normalizacion_geografia_panama.sql
```

## Decisiones de normalización (01)

| Cambio | Norma / motivo |
|--------|----------------|
| `unidad_medida` se mueve de `detalle_materiales_obra` a `materiales` | **2FN**: la unidad depende solo del material, no del par proyecto-material. |
| `cargo_trabajador` (texto) → catálogo `cargos` | 3FN / consistencia. |
| `tipo_estructura` (texto) → catálogo `tipos_estructura` | 3FN / consistencia. |
| `materiales` recibe `id_categoria` (catálogo `categorias_material`) | Requisito de entidad de clasificación. |
| Montos `FLOAT` → `DECIMAL(12,2)` | Precisión monetaria (evita errores de redondeo). |
| `ubicacion_proyecto` (texto libre) → `direcciones` | 1FN / consultable por región. |
| `estados_cuenta_proyecto` (saldo almacenado) → **vista** `vw_estado_cuenta_proyecto` | No almacenar datos derivables. |
| `solicitudes_quincenales` recibe `fecha_solicitud` | Integridad (faltaba la fecha). |
| `correo_cliente` con índice único filtrado | Evita correos duplicados. |
| Corrección de typos `...cotizancion` → `...cotizacion` | Calidad. |

## Modelo geográfico (Panamá)

Jerarquía oficial panameña, normalizada:

```
provincias (incluye comarcas, flag es_comarca)
   └── distritos
         └── corregimientos
               └── direcciones  (vía, barrio/urbanización, edificio/casa,
                                 punto de referencia, latitud, longitud)
```

`clientes.id_direccion` (opcional) y `proyectos.id_direccion` (obligatorio)
referencian `direcciones`. Los catálogos geográficos se cargan en la migración
de datos (02).

## Arquitectura financiera (escalable)

Se eligió un enfoque de **ledger derivado**:

- `pagos_cliente`: registro **inmutable** (append-only) de los ingresos del
  cliente por proyecto, con método de pago (`metodos_pago`) y referencia.
- El **estado de cuenta NO se almacena** (saldo derivable). La **vista**
  `vw_estado_cuenta_proyecto` que lo expone se crea en la migración de
  **vistas (03)**, a cargo de otro compañero. La migración 01 solo elimina la
  tabla `estados_cuenta_proyecto` y agrega `pagos_cliente` con sus datos base
  (proyectos, nómina, solicitudes) para que esa vista sea posible.

**Por qué es lo más escalable:** una sola fuente de verdad (las filas de
movimientos), saldo siempre consistente (sin anomalías de actualización),
auditable peso por peso y con escrituras append-only. Guardar un `saldo`
mutable obliga a actualizar dos lugares a la vez y tiende a desincronizarse.
