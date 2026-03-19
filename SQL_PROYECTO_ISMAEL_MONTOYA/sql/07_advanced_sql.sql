/* ============================================================
   PROYECTO SQL - 07_advanced_sql.sql
   Dataset: Asesoría
   Motor SQL: SQLite
   ============================================================ */

/* QUE HACES EN ESTE ARCHIVO
   - Mostrar uso de SQL avanzado compatible con SQLite
   - Incluir CTEs, window functions, rankings y acumulados
   - Profundizar en el análisis de negocio
*/

/* ============================================================
   Q1. Ranking de asesores por facturación total
   - uso de CTE + RANK()
   ============================================================ */

WITH advisor_revenue AS (
    SELECT
        advisor_id,
        advisor_name,
        specialty,
        ROUND(SUM(total_amount), 2) AS total_revenue
    FROM vw_revenue_overview
    WHERE invoice_id IS NOT NULL
    GROUP BY advisor_id, advisor_name, specialty
)
SELECT
    advisor_id,
    advisor_name,
    specialty,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM advisor_revenue
ORDER BY revenue_rank;

/* ============================================================
   Q2. Ranking de clientes dentro de cada sector
   - uso de PARTITION BY
   ============================================================ */

WITH client_sector_revenue AS (
    SELECT
        sector,
        client_id,
        client_name,
        ROUND(SUM(total_billed), 2) AS revenue
    FROM vw_client_profitability
    GROUP BY sector, client_id, client_name
)
SELECT
    sector,
    client_id,
    client_name,
    revenue,
    RANK() OVER (PARTITION BY sector ORDER BY revenue DESC) AS sector_rank
FROM client_sector_revenue
ORDER BY sector, sector_rank;

/* ============================================================
   Q3. Evolución mensual de facturación con acumulado
   - uso de CTE + SUM() OVER
   ============================================================ */

WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', invoice_date) AS year_month,
        ROUND(SUM(total_amount), 2) AS monthly_revenue
    FROM fct_invoices
    WHERE invoice_date IS NOT NULL
    GROUP BY strftime('%Y-%m', invoice_date)
)
SELECT
    year_month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY year_month), 2) AS cumulative_revenue
FROM monthly_revenue
ORDER BY year_month;

/* ============================================================
   Q4. Variación mensual frente al mes anterior
   - uso de LAG()
   ============================================================ */

WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', invoice_date) AS year_month,
        ROUND(SUM(total_amount), 2) AS monthly_revenue
    FROM fct_invoices
    WHERE invoice_date IS NOT NULL
    GROUP BY strftime('%Y-%m', invoice_date)
)
SELECT
    year_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY year_month) AS previous_month_revenue,
    ROUND(
        monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year_month),
        2
    ) AS revenue_diff_vs_previous
FROM monthly_revenue
ORDER BY year_month;

/* ============================================================
   Q5. Top 3 servicios más facturados por tipo de servicio
   - uso de RANK() con partición
   ============================================================ */

WITH ranked_services AS (
    SELECT
        service_type,
        service_id,
        client_name,
        advisor_name,
        total_amount,
        RANK() OVER (
            PARTITION BY service_type
            ORDER BY total_amount DESC
        ) AS service_rank
    FROM vw_revenue_overview
    WHERE total_amount IS NOT NULL
)
SELECT
    service_type,
    service_id,
    client_name,
    advisor_name,
    total_amount,
    service_rank
FROM ranked_services
WHERE service_rank <= 3
ORDER BY service_type, service_rank;

/* ============================================================
   Q6. Clientes con facturación superior a la media global
   - uso de subconsulta
   ============================================================ */

SELECT
    client_id,
    client_name,
    total_billed
FROM vw_client_profitability
WHERE total_billed > (
    SELECT AVG(total_billed)
    FROM vw_client_profitability
)
ORDER BY total_billed DESC;

/* ============================================================
   Q7. Días medios de retraso por cliente
   - combinación de vistas + agregación
   ============================================================ */

WITH payment_delay_by_client AS (
    SELECT
        vro.client_id,
        vro.client_name,
        vps.days_payment_delay
    FROM vw_revenue_overview vro
    JOIN vw_payment_status vps
        ON vro.invoice_id = vps.invoice_id
    WHERE vps.payment_id IS NOT NULL
)
SELECT
    client_id,
    client_name,
    ROUND(AVG(days_payment_delay), 2) AS avg_delay_days,
    COUNT(*) AS paid_invoices
FROM payment_delay_by_client
GROUP BY client_id, client_name
ORDER BY avg_delay_days DESC, paid_invoices DESC;

/* ============================================================
   Q8. Peso porcentual de cada sector sobre la facturación total
   - uso de CTE + cálculo porcentual
   ============================================================ */

WITH sector_revenue AS (
    SELECT
        sector,
        ROUND(SUM(total_billed), 2) AS revenue
    FROM vw_client_profitability
    GROUP BY sector
),
total_revenue AS (
    SELECT SUM(revenue) AS grand_total
    FROM sector_revenue
)
SELECT
    sr.sector,
    sr.revenue,
    ROUND((sr.revenue * 100.0) / tr.grand_total, 2) AS revenue_pct
FROM sector_revenue sr
CROSS JOIN total_revenue tr
ORDER BY revenue_pct DESC;

/* ============================================================
   Q9. Clientes con más de un servicio y ticket medio alto
   - filtrado analítico con HAVING
   ============================================================ */

SELECT
    client_id,
    client_name,
    total_services,
    total_invoices,
    total_billed,
    avg_invoice_amount
FROM vw_client_profitability
WHERE total_services > 1
  AND avg_invoice_amount > (
      SELECT AVG(avg_invoice_amount)
      FROM vw_client_profitability
  )
ORDER BY avg_invoice_amount DESC, total_billed DESC;

/* ============================================================
   Q10. Diferencia entre amount_paid y total_amount con clasificación
   - CASE + join analítico
   ============================================================ */

SELECT
    fi.invoice_id,
    fi.total_amount,
    fp.amount_paid,
    ROUND(fp.amount_paid - fi.total_amount, 2) AS payment_difference,
    CASE
        WHEN fp.amount_paid IS NULL OR fi.total_amount IS NULL THEN 'Sin dato'
        WHEN ABS(fp.amount_paid - fi.total_amount) <= 0.05 THEN 'Cuadrado'
        WHEN fp.amount_paid > fi.total_amount THEN 'Sobrepagado'
        WHEN fp.amount_paid < fi.total_amount THEN 'Infrapagado'
        ELSE 'Revisar'
    END AS payment_check
FROM fct_invoices fi
LEFT JOIN fct_payments fp
    ON fi.invoice_key = fp.invoice_key
WHERE fp.payment_id IS NOT NULL
ORDER BY ABS(fp.amount_paid - fi.total_amount) DESC, fi.invoice_id;