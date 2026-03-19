/* ============================================================
   PROYECTO SQL - 06_quality_checks.sql
   Dataset: Asesoría
   Motor SQL: SQLite
   ============================================================ */

/* QUE HACES EN ESTE ARCHIVO
   - Validar calidad de datos en staging y core
   - Revisar nulos, duplicados, integridad y coherencia
   - Dejar trazabilidad de los problemas detectados
*/

/* ============================================================
   1. CHECKS DE VOLUMEN: STAGING VS CORE
   ============================================================ */

SELECT 'stg_clients_raw' AS table_name, COUNT(*) AS n_rows FROM stg_clients_raw
UNION ALL
SELECT 'dim_clients', COUNT(*) FROM dim_clients
UNION ALL
SELECT 'stg_advisors_raw', COUNT(*) FROM stg_advisors_raw
UNION ALL
SELECT 'dim_advisors', COUNT(*) FROM dim_advisors
UNION ALL
SELECT 'stg_services_raw', COUNT(*) FROM stg_services_raw
UNION ALL
SELECT 'fct_services', COUNT(*) FROM fct_services
UNION ALL
SELECT 'stg_invoices_raw', COUNT(*) FROM stg_invoices_raw
UNION ALL
SELECT 'fct_invoices', COUNT(*) FROM fct_invoices
UNION ALL
SELECT 'stg_payments_raw', COUNT(*) FROM stg_payments_raw
UNION ALL
SELECT 'fct_payments', COUNT(*) FROM fct_payments;

/* ============================================================
   2. DUPLICADOS EN CORE (deberían ser 0)
   ============================================================ */

SELECT client_id, COUNT(*) AS n
FROM dim_clients
GROUP BY client_id
HAVING COUNT(*) > 1;

SELECT advisor_id, COUNT(*) AS n
FROM dim_advisors
GROUP BY advisor_id
HAVING COUNT(*) > 1;

SELECT service_id, COUNT(*) AS n
FROM fct_services
GROUP BY service_id
HAVING COUNT(*) > 1;

SELECT invoice_id, COUNT(*) AS n
FROM fct_invoices
GROUP BY invoice_id
HAVING COUNT(*) > 1;

SELECT payment_id, COUNT(*) AS n
FROM fct_payments
GROUP BY payment_id
HAVING COUNT(*) > 1;

/* ============================================================
   3. IDS NULOS O VACÍOS EN CORE (deberían ser 0)
   ============================================================ */

SELECT
    SUM(CASE WHEN client_id IS NULL OR TRIM(client_id) = '' THEN 1 ELSE 0 END) AS bad_client_id
FROM dim_clients;

SELECT
    SUM(CASE WHEN advisor_id IS NULL OR TRIM(advisor_id) = '' THEN 1 ELSE 0 END) AS bad_advisor_id
FROM dim_advisors;

SELECT
    SUM(CASE WHEN service_id IS NULL OR TRIM(service_id) = '' THEN 1 ELSE 0 END) AS bad_service_id
FROM fct_services;

SELECT
    SUM(CASE WHEN invoice_id IS NULL OR TRIM(invoice_id) = '' THEN 1 ELSE 0 END) AS bad_invoice_id
FROM fct_invoices;

SELECT
    SUM(CASE WHEN payment_id IS NULL OR TRIM(payment_id) = '' THEN 1 ELSE 0 END) AS bad_payment_id
FROM fct_payments;

/* ============================================================
   4. NULOS EN CAMPOS CLAVE DE NEGOCIO
   ============================================================ */

SELECT
    SUM(CASE WHEN client_name IS NULL OR TRIM(client_name) = '' THEN 1 ELSE 0 END) AS empty_client_name,
    SUM(CASE WHEN city IS NULL OR TRIM(city) = '' THEN 1 ELSE 0 END) AS empty_city,
    SUM(CASE WHEN sector IS NULL OR TRIM(sector) = '' THEN 1 ELSE 0 END) AS empty_sector
FROM dim_clients;

SELECT
    SUM(CASE WHEN advisor_name IS NULL OR TRIM(advisor_name) = '' THEN 1 ELSE 0 END) AS empty_advisor_name,
    SUM(CASE WHEN specialty IS NULL OR TRIM(specialty) = '' THEN 1 ELSE 0 END) AS empty_specialty
FROM dim_advisors;

SELECT
    SUM(CASE WHEN service_date IS NULL OR TRIM(service_date) = '' THEN 1 ELSE 0 END) AS empty_service_date,
    SUM(CASE WHEN service_type IS NULL OR TRIM(service_type) = '' THEN 1 ELSE 0 END) AS empty_service_type,
    SUM(CASE WHEN hours_worked IS NULL THEN 1 ELSE 0 END) AS empty_hours_worked,
    SUM(CASE WHEN base_fee IS NULL THEN 1 ELSE 0 END) AS empty_base_fee
FROM fct_services;

SELECT
    SUM(CASE WHEN invoice_date IS NULL OR TRIM(invoice_date) = '' THEN 1 ELSE 0 END) AS empty_invoice_date,
    SUM(CASE WHEN due_date IS NULL OR TRIM(due_date) = '' THEN 1 ELSE 0 END) AS empty_due_date,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS empty_amount,
    SUM(CASE WHEN tax_rate IS NULL THEN 1 ELSE 0 END) AS empty_tax_rate,
    SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS empty_total_amount
FROM fct_invoices;

SELECT
    SUM(CASE WHEN payment_date IS NULL OR TRIM(payment_date) = '' THEN 1 ELSE 0 END) AS empty_payment_date,
    SUM(CASE WHEN amount_paid IS NULL THEN 1 ELSE 0 END) AS empty_amount_paid,
    SUM(CASE WHEN payment_method IS NULL OR TRIM(payment_method) = '' THEN 1 ELSE 0 END) AS empty_payment_method
FROM fct_payments;

/* ============================================================
   5. INTEGRIDAD REFERENCIAL EN CORE (debería ser 0)
   ============================================================ */

SELECT COUNT(*) AS services_without_valid_client_key
FROM fct_services fs
LEFT JOIN dim_clients dc
    ON fs.client_key = dc.client_key
WHERE dc.client_key IS NULL;

SELECT COUNT(*) AS services_without_valid_advisor_key
FROM fct_services fs
LEFT JOIN dim_advisors da
    ON fs.advisor_key = da.advisor_key
WHERE da.advisor_key IS NULL;

SELECT COUNT(*) AS invoices_without_valid_service_key
FROM fct_invoices fi
LEFT JOIN fct_services fs
    ON fi.service_key = fs.service_key
WHERE fs.service_key IS NULL;

SELECT COUNT(*) AS payments_without_valid_invoice_key
FROM fct_payments fp
LEFT JOIN fct_invoices fi
    ON fp.invoice_key = fi.invoice_key
WHERE fi.invoice_key IS NULL;

/* ============================================================
   6. COHERENCIA DE IMPORTES
   - total_amount debería aproximarse a amount * (1 + tax_rate)
   ============================================================ */

SELECT
    invoice_id,
    amount,
    tax_rate,
    total_amount,
    ROUND(amount * (1 + tax_rate), 2) AS expected_total_amount
FROM fct_invoices
WHERE amount IS NOT NULL
  AND tax_rate IS NOT NULL
  AND total_amount IS NOT NULL
  AND ABS(total_amount - ROUND(amount * (1 + tax_rate), 2)) > 0.05;

/* ============================================================
   7. CAMPOS NUMÉRICOS NEGATIVOS O NO VÁLIDOS
   ============================================================ */

SELECT COUNT(*) AS negative_or_zero_hours
FROM fct_services
WHERE hours_worked IS NOT NULL
  AND hours_worked <= 0;

SELECT COUNT(*) AS negative_base_fee
FROM fct_services
WHERE base_fee IS NOT NULL
  AND base_fee < 0;

SELECT COUNT(*) AS negative_amount
FROM fct_invoices
WHERE amount IS NOT NULL
  AND amount < 0;

SELECT COUNT(*) AS negative_total_amount
FROM fct_invoices
WHERE total_amount IS NOT NULL
  AND total_amount < 0;

SELECT COUNT(*) AS negative_amount_paid
FROM fct_payments
WHERE amount_paid IS NOT NULL
  AND amount_paid < 0;

/* ============================================================
   8. COHERENCIA DE ESTADOS
   ============================================================ */

SELECT service_status, COUNT(*) AS n
FROM fct_services
GROUP BY service_status
ORDER BY n DESC;

SELECT status AS invoice_status, COUNT(*) AS n
FROM fct_invoices
GROUP BY status
ORDER BY n DESC;

/* ============================================================
   9. FACTURAS MARCADAS COMO PAGADAS PERO SIN PAGO
   ============================================================ */

SELECT
    fi.invoice_id,
    fi.status,
    fi.total_amount
FROM fct_invoices fi
LEFT JOIN fct_payments fp
    ON fi.invoice_key = fp.invoice_key
WHERE fi.status = 'Pagada'
  AND fp.payment_id IS NULL;

/* ============================================================
   10. PAGOS CON DIFERENCIA RESPECTO AL TOTAL FACTURADO
   ============================================================ */

SELECT
    fi.invoice_id,
    fi.total_amount,
    fp.amount_paid,
    ROUND(fp.amount_paid - fi.total_amount, 2) AS payment_difference
FROM fct_invoices fi
JOIN fct_payments fp
    ON fi.invoice_key = fp.invoice_key
WHERE fi.total_amount IS NOT NULL
  AND fp.amount_paid IS NOT NULL
  AND ABS(fp.amount_paid - fi.total_amount) > 0.05;