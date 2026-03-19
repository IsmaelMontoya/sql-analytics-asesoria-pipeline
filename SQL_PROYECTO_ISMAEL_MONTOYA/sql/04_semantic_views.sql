/* ============================================================
   PROYECTO SQL - 04_semantic_views.sql
   Dataset: Asesoría
   Motor SQL: SQLite
   ============================================================ */

/* QUE HACES EN ESTE ARCHIVO
   - Crear vistas semánticas orientadas a negocio
   - Facilitar análisis sobre facturación, clientes y pagos
*/

/* ============================================================
   LIMPIEZA PREVIA
   ============================================================ */

DROP VIEW IF EXISTS vw_revenue_overview;
DROP VIEW IF EXISTS vw_client_profitability;
DROP VIEW IF EXISTS vw_payment_status;

/* ============================================================
   1. VISTA DE INGRESOS Y OPERACIÓN
   - une clientes, asesores, servicios y facturas
   - sirve para análisis general de facturación
   ============================================================ */

CREATE VIEW vw_revenue_overview AS
SELECT
    fs.service_id,
    fs.service_date,
    fs.service_type,
    fs.service_status,
    fs.hours_worked,
    fs.base_fee,

    dc.client_id,
    dc.client_name,
    dc.client_type,
    dc.city,
    dc.sector,

    da.advisor_id,
    da.advisor_name,
    da.specialty,

    fi.invoice_id,
    fi.invoice_date,
    fi.due_date,
    fi.amount,
    fi.tax_rate,
    fi.total_amount,
    fi.status AS invoice_status
FROM fct_services fs
JOIN dim_clients dc
    ON fs.client_key = dc.client_key
JOIN dim_advisors da
    ON fs.advisor_key = da.advisor_key
LEFT JOIN fct_invoices fi
    ON fs.service_key = fi.service_key;
   

/* ============================================================
   2. VISTA DE RENTABILIDAD / MÉTRICAS POR CLIENTE
   - agrega pedidos y facturación por cliente
   ============================================================ */

CREATE VIEW vw_client_profitability AS
SELECT
    dc.client_id,
    dc.client_name,
    dc.client_type,
    dc.city,
    dc.sector,
    COUNT(DISTINCT fs.service_id) AS total_services,
    COUNT(DISTINCT fi.invoice_id) AS total_invoices,
    ROUND(COALESCE(SUM(fi.total_amount), 0), 2) AS total_billed,
    ROUND(COALESCE(AVG(fi.total_amount), 0), 2) AS avg_invoice_amount
FROM dim_clients dc
LEFT JOIN fct_services fs
    ON dc.client_key = fs.client_key
LEFT JOIN fct_invoices fi
    ON fs.service_key = fi.service_key
GROUP BY
    dc.client_id,
    dc.client_name,
    dc.client_type,
    dc.city,
    dc.sector;

/* ============================================================
   3. VISTA DE ESTADO DE COBRO
   - une facturas y pagos
   - permite analizar cobro, pendiente y retrasos
   ============================================================ */

CREATE VIEW vw_payment_status AS
SELECT
    fi.invoice_id,
    fi.invoice_date,
    fi.due_date,
    fi.amount,
    fi.tax_rate,
    fi.total_amount,
    fi.status AS invoice_status,

    fp.payment_id,
    fp.payment_date,
    fp.amount_paid,
    fp.payment_method,

    CASE
        WHEN fp.payment_id IS NULL THEN 'No pagada'
        ELSE 'Pagada'
    END AS payment_presence,

    CASE
        WHEN fp.payment_date IS NOT NULL
             AND fi.due_date IS NOT NULL
             AND julianday(fp.payment_date) - julianday(fi.due_date) > 0
        THEN ROUND(julianday(fp.payment_date) - julianday(fi.due_date), 0)
        ELSE 0
    END AS days_payment_delay
FROM fct_invoices fi
LEFT JOIN fct_payments fp
    ON fi.invoice_key = fp.invoice_key;
    
    
/* ============================================================
   4. Comprobaciones
   ============================================================ */
    
SELECT * FROM vw_revenue_overview LIMIT 10;
SELECT * FROM vw_client_profitability LIMIT 10;
SELECT * FROM vw_payment_status LIMIT 10;

SELECT name 
FROM sqlite_master 
WHERE type = 'view';