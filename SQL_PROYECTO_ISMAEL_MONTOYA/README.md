# SQL Analytics Pipeline – Asesoría

## 1. Descripción del proyecto

Este proyecto consiste en la construcción de un **pipeline SQL reproducible** sobre un dataset relacional simulado de una asesoría (fiscal, laboral y contable).

El objetivo es transformar datos crudos en información útil para negocio mediante:
- modelado de datos
- limpieza y validación
- construcción de capas analíticas
- generación de insights

---

## 2. Dataset

El dataset ha sido **generado artificialmente**, pero diseñado para simular un entorno real de una asesoría.

### Tablas originales (staging)
- `clients`
- `advisors`
- `services`
- `invoices`
- `payments`

### Relación entre entidades
- Un cliente puede tener múltiples servicios  
- Un asesor gestiona múltiples servicios  
- Cada servicio puede generar una factura  
- Cada factura puede tener un pago asociado  

---

## 3. Preguntas de negocio

El proyecto responde a preguntas como:

- ¿Qué clientes generan más ingresos?
- ¿Qué asesores gestionan mayor facturación?
- ¿Qué sectores son más rentables?
- ¿Cómo evoluciona la facturación en el tiempo?
- ¿Qué porcentaje de facturas está pendiente o vencido?
- ¿Cuál es el retraso medio en los pagos?
- ¿Qué servicios generan más ingresos?

---

## 4. Motor SQL utilizado

**SQLite**

Motivos:
- Ligero y fácil de reproducir  
- No requiere servidor  
- Compatible con CTEs y window functions  
- Permite entregar archivo `.db`  

---

## 5. Estructura del proyecto

proyecto-sql/ <br>
│ <br>
├── data/ <br>
│ ├── clients.csv <br>
│ ├── advisors.csv <br>
│ ├── services.csv <br>
│ ├── invoices.csv <br>
│ ├── payments.csv <br>
│ └── project_asesoria.db
│ <br>
├── sql/ <br>
│ ├── 01_schema.sql <br>
│ ├── 02_load_staging.sql <br>
│ ├── 03_transform_core.sql <br>
│ ├── 04_semantic_views.sql <br>
│ ├── 05_analysis_queries.sql <br>
│ ├── 06_quality_checks.sql <br>
│ ├── 07_advanced_sql.sql <br>
│ <br>
├── PROJECT_BRIEF.md <br>
└── README.md <br>


---

## 6. Arquitectura del pipeline

### 🔹 Staging (`stg_*`)
- Datos cargados desde CSV  
- Sin transformación relevante  
- Tipos flexibles (`TEXT`)  
- Contiene errores controlados  

---

### 🔹 Core (`dim_*`, `fct_*`)

#### Dimensiones
- `dim_clients`
- `dim_advisors`

#### Hechos
- `fct_services`
- `fct_invoices`
- `fct_payments`

Transformaciones aplicadas:
- limpieza (`TRIM`, `LOWER`)
- deduplicación  
- validación de claves  
- casting de tipos  
- normalización  

---

### 🔹 Semantic (`vw_*`)
- `vw_revenue_overview`
- `vw_client_profitability`
- `vw_payment_status`

Permiten análisis sin joins complejos.

---

## 7. Data Quality

### Staging

- IDs nulos: **0**
- Duplicados: **2 por tabla**
- Fechas vacías:
  - services: 1
  - invoices: 1
  - payments: 1
- Campos numéricos vacíos:
  - services: 1 por columna
  - invoices: 1 por columna (excepto total_amount)
  - payments: 1
- Problemas de integridad:
  - services sin cliente: 1
  - services sin advisor: 1
  - invoices sin service: 2
  - payments sin invoice: 1

---

### Core

- Duplicados: **0**
- Integridad referencial: **correcta (0 errores)**
- Nulos controlados:
  - `dim_clients`: 1 sector vacío
  - `fct_services`: 1 fecha, 1 hours, 1 fee
  - `fct_invoices`: 1 due_date, 1 amount, 1 tax_rate
  - `fct_payments`: 1 date, 1 amount, 1 method
- Coherencia de importes: **correcta**
- Valores negativos: **0**

---

## 8. SQL utilizado

### Básico
- JOIN
- GROUP BY
- CASE
- CAST
- NULLIF

### Intermedio
- Subqueries
- Agregaciones

### Avanzado
- CTE (`WITH`)
- RANK()
- LAG()
- SUM() OVER
- análisis temporal

---

## 9. Principales insights

- Identificación de clientes con mayor facturación  
- Ranking de asesores por ingresos  
- Sectores más rentables  
- Evolución mensual de ingresos  
- Detección de facturas pendientes  
- Análisis de retraso en pagos  
- Servicios con mayor impacto económico  

---

## 10. Supuestos y limitaciones

- Dataset simulado  
- Un pago por factura  
- No se modelan pagos parciales  
- Fechas en formato texto (SQLite)  
- Sin stored procedures  

---

## 11. Reproducibilidad

1. Crear base de datos:
  project_asesoria.db alojada dentro de data


2. Ejecutar:
  01_schema.sql


3. Importar CSV en `stg_*` (DBeaver)

4. Ejecutar:
  02_load_staging.sql
  03_transform_core.sql
  04_semantic_views.sql
  05_analysis_queries.sql
  06_quality_checks.sql
  07_advanced_sql.sql

  
---

## 12. Conclusión

Este proyecto demuestra:

- diseño de modelo de datos  
- construcción de pipeline SQL  
- control de calidad de datos  
- análisis de negocio  
- uso de SQL avanzado  

---

## Nota final

> El objetivo no era tener datos perfectos, sino demostrar cómo convertir datos imperfectos en información fiable para negocio.
