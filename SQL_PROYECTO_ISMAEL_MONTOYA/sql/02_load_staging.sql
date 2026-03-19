/* ============================================================
   PROYECTO SQL - 02_load_staging.sql
   Dataset: Asesoría
   Motor SQL: SQLite
   ============================================================ */

/* QUE HACES EN ESTE ARCHIVO
   - Validar que la carga a staging ha salido bien
   - Revisar volumen, muestras y posibles problemas básicos
   - Confirmar que los CSV están correctamente importados antes de pasar a core

   IMPORTANTE
   - En SQLite la importación de CSV suele hacerse con DBeaver Import Wizard
   - Este archivo no carga los CSV: los valida después de importarlos
*/

/* ============================================================
   1. CHECKS DE VOLUMEN
   ============================================================ */


SELECT 'stg_clients_raw' AS table_name, COUNT(*) AS n_rows FROM stg_clients_raw
UNION ALL
SELECT 'stg_advisors_raw' AS table_name, COUNT(*) AS n_rows FROM stg_advisors_raw
UNION ALL
SELECT 'stg_services_raw' AS table_name, COUNT(*) AS n_rows FROM stg_services_raw
UNION ALL
SELECT 'stg_invoices_raw' AS table_name, COUNT(*) AS n_rows FROM stg_invoices_raw
UNION ALL
SELECT 'stg_payments_raw' AS table_name, COUNT(*) AS n_rows FROM stg_payments_raw;

/* ============================================================
   2. MUESTRAS
   ============================================================ */

SELECT * FROM stg_clients_raw LIMIT 10;
SELECT * FROM stg_advisors_raw LIMIT 10;
SELECT * FROM stg_services_raw LIMIT 10;
SELECT * FROM stg_invoices_raw LIMIT 10;
SELECT * FROM stg_payments_raw LIMIT 10;

/* ============================================================
   3. CHECKS BÁSICOS DE IDS NULOS O VACÍOS
   ============================================================ */

SELECT
    SUM(CASE WHEN raw_client_id IS NULL OR TRIM(raw_client_id) = '' THEN 1 ELSE 0 END) AS bad_client_id
FROM stg_clients_raw;

SELECT
    SUM(CASE WHEN raw_advisor_id IS NULL OR TRIM(raw_advisor_id) = '' THEN 1 ELSE 0 END) AS bad_advisor_id
FROM stg_advisors_raw;

SELECT
    SUM(CASE WHEN raw_service_id IS NULL OR TRIM(raw_service_id) = '' THEN 1 ELSE 0 END) AS bad_service_id,
    SUM(CASE WHEN raw_client_id IS NULL OR TRIM(raw_client_id) = '' THEN 1 ELSE 0 END) AS bad_client_id,
    SUM(CASE WHEN raw_advisor_id IS NULL OR TRIM(raw_advisor_id) = '' THEN 1 ELSE 0 END) AS bad_advisor_id
FROM stg_services_raw;

SELECT
    SUM(CASE WHEN raw_invoice_id IS NULL OR TRIM(raw_invoice_id) = '' THEN 1 ELSE 0 END) AS bad_invoice_id,
    SUM(CASE WHEN raw_service_id IS NULL OR TRIM(raw_service_id) = '' THEN 1 ELSE 0 END) AS bad_service_id
FROM stg_invoices_raw;

SELECT
    SUM(CASE WHEN raw_payment_id IS NULL OR TRIM(raw_payment_id) = '' THEN 1 ELSE 0 END) AS bad_payment_id,
    SUM(CASE WHEN raw_invoice_id IS NULL OR TRIM(raw_invoice_id) = '' THEN 1 ELSE 0 END) AS bad_invoice_id
FROM stg_payments_raw;

/* ============================================================
   4. CHECKS DE DUPLICADOS EN IDS PRINCIPALES
   ============================================================ */

SELECT raw_client_id, COUNT(*) AS n
FROM stg_clients_raw
GROUP BY raw_client_id
HAVING COUNT(*) > 1;

SELECT raw_advisor_id, COUNT(*) AS n
FROM stg_advisors_raw
GROUP BY raw_advisor_id
HAVING COUNT(*) > 1;

SELECT raw_service_id, COUNT(*) AS n
FROM stg_services_raw
GROUP BY raw_service_id
HAVING COUNT(*) > 1;

SELECT raw_invoice_id, COUNT(*) AS n
FROM stg_invoices_raw
GROUP BY raw_invoice_id
HAVING COUNT(*) > 1;

SELECT raw_payment_id, COUNT(*) AS n
FROM stg_payments_raw
GROUP BY raw_payment_id
HAVING COUNT(*) > 1;

/* ============================================================
   5. CHECKS BÁSICOS DE FECHAS VACÍAS
   ============================================================ */

SELECT
    SUM(CASE WHEN raw_signup_date IS NULL OR TRIM(raw_signup_date) = '' THEN 1 ELSE 0 END) AS empty_signup_date
FROM stg_clients_raw;

SELECT
    SUM(CASE WHEN raw_hire_date IS NULL OR TRIM(raw_hire_date) = '' THEN 1 ELSE 0 END) AS empty_hire_date
FROM stg_advisors_raw;

SELECT
    SUM(CASE WHEN raw_service_date IS NULL OR TRIM(raw_service_date) = '' THEN 1 ELSE 0 END) AS empty_service_date
FROM stg_services_raw;

SELECT
    SUM(CASE WHEN raw_invoice_date IS NULL OR TRIM(raw_invoice_date) = '' THEN 1 ELSE 0 END) AS empty_invoice_date,
    SUM(CASE WHEN raw_due_date IS NULL OR TRIM(raw_due_date) = '' THEN 1 ELSE 0 END) AS empty_due_date
FROM stg_invoices_raw;

SELECT
    SUM(CASE WHEN raw_payment_date IS NULL OR TRIM(raw_payment_date) = '' THEN 1 ELSE 0 END) AS empty_payment_date
FROM stg_payments_raw;

/* ============================================================
   6. CHECKS BÁSICOS DE CAMPOS NUMÉRICOS VACÍOS
   ============================================================ */

SELECT
    SUM(CASE WHEN raw_hours_worked IS NULL OR TRIM(raw_hours_worked) = '' THEN 1 ELSE 0 END) AS empty_hours_worked,
    SUM(CASE WHEN raw_base_fee IS NULL OR TRIM(raw_base_fee) = '' THEN 1 ELSE 0 END) AS empty_base_fee
FROM stg_services_raw;

SELECT
    SUM(CASE WHEN raw_amount IS NULL OR TRIM(raw_amount) = '' THEN 1 ELSE 0 END) AS empty_amount,
    SUM(CASE WHEN raw_tax_rate IS NULL OR TRIM(raw_tax_rate) = '' THEN 1 ELSE 0 END) AS empty_tax_rate,
    SUM(CASE WHEN raw_total_amount IS NULL OR TRIM(raw_total_amount) = '' THEN 1 ELSE 0 END) AS empty_total_amount
FROM stg_invoices_raw;

SELECT
    SUM(CASE WHEN raw_amount_paid IS NULL OR TRIM(raw_amount_paid) = '' THEN 1 ELSE 0 END) AS empty_amount_paid
FROM stg_payments_raw;

/* ============================================================
   7. CHECKS DE CONSISTENCIA BÁSICA DE RELACIONES
   ============================================================ */

-- services con client_id no existente en clients
SELECT COUNT(*) AS services_without_valid_client
FROM stg_services_raw s
LEFT JOIN stg_clients_raw c
    ON TRIM(s.raw_client_id) = TRIM(c.raw_client_id)
WHERE c.raw_client_id IS NULL;

-- services con advisor_id no existente en advisors
SELECT COUNT(*) AS services_without_valid_advisor
FROM stg_services_raw s
LEFT JOIN stg_advisors_raw a
    ON TRIM(s.raw_advisor_id) = TRIM(a.raw_advisor_id)
WHERE a.raw_advisor_id IS NULL;

-- invoices con service_id no existente en services
SELECT COUNT(*) AS invoices_without_valid_service
FROM stg_invoices_raw i
LEFT JOIN stg_services_raw s
    ON TRIM(i.raw_service_id) = TRIM(s.raw_service_id)
WHERE s.raw_service_id IS NULL;

-- payments con invoice_id no existente en invoices
SELECT COUNT(*) AS payments_without_valid_invoice
FROM stg_payments_raw p
LEFT JOIN stg_invoices_raw i
    ON TRIM(p.raw_invoice_id) = TRIM(i.raw_invoice_id)
WHERE i.raw_invoice_id IS NULL;