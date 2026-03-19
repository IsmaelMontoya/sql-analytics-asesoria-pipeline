/* ============================================================
   PROYECTO SQL - 03_transform_core.sql
   Dataset: Asesoría
   Motor SQL: SQLite
   ============================================================ */

/* QUE HACES EN ESTE ARCHIVO
   - Transformar datos crudos de staging en tablas limpias core
   - Cargar dimensiones
   - Cargar hechos
   - Excluir filas inválidas y deduplicar

   IDEA CLAVE
   - dim_clients y dim_advisors describen entidades
   - fct_services, fct_invoices y fct_payments almacenan eventos de negocio

   GRANO
   - fct_services: 1 fila = 1 servicio
   - fct_invoices: 1 fila = 1 factura
   - fct_payments: 1 fila = 1 pago
*/

PRAGMA foreign_keys = OFF;

BEGIN TRANSACTION;

/* ============================================================
   1. LIMPIEZA PREVIA DE TABLAS CORE
   ============================================================ */

DELETE FROM fct_payments;
DELETE FROM fct_invoices;
DELETE FROM fct_services;
DELETE FROM dim_advisors;
DELETE FROM dim_clients;

/* Reiniciar autoincrement en SQLite */
DELETE FROM sqlite_sequence WHERE name IN (
    'dim_clients',
    'dim_advisors',
    'fct_services',
    'fct_invoices',
    'fct_payments'
);



/* ============================================================
   2. CARGA DE DIM_CLIENTS
   - deduplicamos por client_id
   - limpiamos espacios
   - normalizamos email a minúsculas
   - convertimos vacíos en NULL
   ============================================================ */

INSERT INTO dim_clients (
    client_id,
    client_name,
    client_type,
    city,
    sector,
    signup_date,
    email,
    phone
)
SELECT
    TRIM(raw_client_id) AS client_id,
    TRIM(raw_client_name) AS client_name,
    NULLIF(TRIM(raw_client_type), '') AS client_type,
    NULLIF(TRIM(raw_city), '') AS city,
    NULLIF(TRIM(raw_sector), '') AS sector,
    NULLIF(TRIM(raw_signup_date), '') AS signup_date,
    CASE
        WHEN TRIM(COALESCE(raw_email, '')) = '' THEN NULL
        ELSE LOWER(TRIM(raw_email))
    END AS email,
    NULLIF(TRIM(raw_phone), '') AS phone
FROM stg_clients_raw
WHERE TRIM(COALESCE(raw_client_id, '')) <> ''
GROUP BY TRIM(raw_client_id);

/*
 * Comprobación de lineas de dim_clients
 * 
 */
/*SELECT COUNT(*) AS total_rows FROM dim_clients;
 * 
 */


/* ============================================================
   3. CARGA DE DIM_ADVISORS
   - deduplicamos por advisor_id
   - limpiamos textos
   ============================================================ */
/*
 * Comprobación de lineas de stg_advisors_raw
 * 
 */
/*SELECT COUNT(*) AS total_rows FROM stg_advisors_raw;
 * 
 */

INSERT INTO dim_advisors (
    advisor_id,
    advisor_name,
    specialty,
    hire_date,
    office_city
)
SELECT
    TRIM(raw_advisor_id) AS advisor_id,
    TRIM(raw_advisor_name) AS advisor_name,
    NULLIF(TRIM(raw_specialty), '') AS specialty,
    NULLIF(TRIM(raw_hire_date), '') AS hire_date,
    NULLIF(TRIM(raw_office_city), '') AS office_city
FROM stg_advisors_raw
WHERE TRIM(COALESCE(raw_advisor_id, '')) <> ''
GROUP BY TRIM(raw_advisor_id);


/*
 * Comprobación de lineas de dim_advisors (12)
 * 
 */
/*SELECT COUNT(*) AS total_rows FROM dim_advisors;
 * 
 */

/* ============================================================
   4. CARGA DE FCT_SERVICES
   - solo servicios con client_id y advisor_id válidos
   - excluimos service_id vacío
   - deduplicamos por service_id
   - convertimos numéricos vacíos a NULL
   ============================================================ */

/*
 * Comprobación de lineas de stg_services_raw (400)
 * 
 */
/*SELECT COUNT(*) AS total_rows FROM stg_services_raw;
 * 
 */

INSERT INTO fct_services (
    service_id,
    client_key,
    advisor_key,
    service_date,
    service_type,
    hours_worked,
    base_fee,
    service_status
)
SELECT
    TRIM(s.raw_service_id) AS service_id,
    dc.client_key,
    da.advisor_key,
    NULLIF(TRIM(s.raw_service_date), '') AS service_date,
    NULLIF(TRIM(s.raw_service_type), '') AS service_type,
    CASE
        WHEN TRIM(COALESCE(s.raw_hours_worked, '')) = '' THEN NULL
        ELSE CAST(TRIM(s.raw_hours_worked) AS REAL)
    END AS hours_worked,
    CASE
        WHEN TRIM(COALESCE(s.raw_base_fee, '')) = '' THEN NULL
        ELSE CAST(TRIM(s.raw_base_fee) AS REAL)
    END AS base_fee,
    CASE
        WHEN TRIM(COALESCE(s.raw_service_status, '')) = '' THEN NULL
        ELSE
            CASE LOWER(TRIM(s.raw_service_status))
                WHEN 'completado' THEN 'Completado'
                WHEN 'pendiente' THEN 'Pendiente'
                WHEN 'cancelado' THEN 'Cancelado'
                ELSE TRIM(s.raw_service_status)
            END
    END AS service_status
FROM stg_services_raw s
JOIN dim_clients dc
    ON TRIM(s.raw_client_id) = dc.client_id
JOIN dim_advisors da
    ON TRIM(s.raw_advisor_id) = da.advisor_id
WHERE TRIM(COALESCE(s.raw_service_id, '')) <> ''
GROUP BY TRIM(s.raw_service_id);

/*
 * Comprobación de lineas de fct_services (397)
 * 
 */
/*SELECT COUNT(*) AS total_rows FROM fct_services;
 * 
 */

/* ============================================================
   5. CARGA DE FCT_INVOICES
   - solo facturas con service_id válido
   - excluimos invoice_id vacío
   - deduplicamos por invoice_id
   ============================================================ */
/*
 * Comprobación de lineas de stg_invoices_raw (370)
 * 
 */
/*SELECT COUNT(*) AS total_rows FROM stg_invoices_raw;
 * 
 */

INSERT INTO fct_invoices (
    invoice_id,
    service_key,
    invoice_date,
    due_date,
    amount,
    tax_rate,
    total_amount,
    status
)
SELECT
    TRIM(i.raw_invoice_id) AS invoice_id,
    fs.service_key,
    NULLIF(TRIM(i.raw_invoice_date), '') AS invoice_date,
    NULLIF(TRIM(i.raw_due_date), '') AS due_date,
    CASE
        WHEN TRIM(COALESCE(i.raw_amount, '')) = '' THEN NULL
        ELSE CAST(TRIM(i.raw_amount) AS REAL)
    END AS amount,
    CASE
        WHEN TRIM(COALESCE(i.raw_tax_rate, '')) = '' THEN NULL
        ELSE CAST(TRIM(i.raw_tax_rate) AS REAL)
    END AS tax_rate,
    CASE
        WHEN TRIM(COALESCE(i.raw_total_amount, '')) = '' THEN NULL
        ELSE CAST(TRIM(i.raw_total_amount) AS REAL)
    END AS total_amount,
    CASE
        WHEN TRIM(COALESCE(i.raw_status, '')) = '' THEN NULL
        ELSE
            CASE LOWER(TRIM(i.raw_status))
                WHEN 'pagada' THEN 'Pagada'
                WHEN 'pendiente' THEN 'Pendiente'
                WHEN 'vencida' THEN 'Vencida'
                ELSE TRIM(i.raw_status)
            END
    END AS status
FROM stg_invoices_raw i
JOIN fct_services fs
    ON TRIM(i.raw_service_id) = fs.service_id
WHERE TRIM(COALESCE(i.raw_invoice_id, '')) <> ''
GROUP BY TRIM(i.raw_invoice_id);

/*
 * Comprobación de lineas de fct_invoices (365)
 * 
 */
/*SELECT COUNT(*) AS total_rows FROM fct_invoices;
 * 
 */

/* ============================================================
   6. CARGA DE FCT_PAYMENTS
   - solo pagos con invoice_id válido
   - excluimos payment_id vacío
   - deduplicamos por payment_id
   ============================================================ */

/*
 * Comprobación de lineas de stg_invoices_raw (370)
 * 
 */
/*SELECT COUNT(*) AS total_rows FROM stg_invoices_raw;
 */

INSERT INTO fct_payments (
    payment_id,
    invoice_key,
    payment_date,
    amount_paid,
    payment_method
)
SELECT
    TRIM(p.raw_payment_id) AS payment_id,
    fi.invoice_key,
    NULLIF(TRIM(p.raw_payment_date), '') AS payment_date,
    CASE
        WHEN TRIM(COALESCE(p.raw_amount_paid, '')) = '' THEN NULL
        ELSE CAST(TRIM(p.raw_amount_paid) AS REAL)
    END AS amount_paid,
    CASE
        WHEN TRIM(COALESCE(p.raw_payment_method, '')) = '' THEN NULL
        ELSE TRIM(p.raw_payment_method)
    END AS payment_method
FROM stg_payments_raw p
JOIN fct_invoices fi
    ON TRIM(p.raw_invoice_id) = fi.invoice_id
WHERE TRIM(COALESCE(p.raw_payment_id, '')) <> ''
GROUP BY TRIM(p.raw_payment_id);

/*
 * Comprobación de lineas de fct_payments (284)
 * 
 */
/*SELECT COUNT(*) AS total_rows FROM fct_payments;
 * 
 */

COMMIT;

PRAGMA foreign_keys = ON;



/* ============================================================
   7. VALIDACIÓN RÁPIDA POST-CARGA
   ============================================================ */

SELECT 'dim_clients' AS table_name, COUNT(*) AS n_rows FROM dim_clients
UNION ALL
SELECT 'dim_advisors' AS table_name, COUNT(*) AS n_rows FROM dim_advisors
UNION ALL
SELECT 'fct_services' AS table_name, COUNT(*) AS n_rows FROM fct_services
UNION ALL
SELECT 'fct_invoices' AS table_name, COUNT(*) AS n_rows FROM fct_invoices
UNION ALL
SELECT 'fct_payments' AS table_name, COUNT(*) AS n_rows FROM fct_payments;

