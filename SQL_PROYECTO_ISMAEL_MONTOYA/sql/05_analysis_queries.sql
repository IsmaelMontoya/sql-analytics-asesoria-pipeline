/* ============================================================
   PROYECTO SQL - 05_analysis_queries.sql
   Dataset: Asesoría
   Motor SQL: SQLite
   ============================================================ */

/* QUE HACES EN ESTE ARCHIVO
   - Responder preguntas de negocio con consultas analíticas
   - Apoyarte en la capa semántica y en las tablas core
   - Mostrar uso de agregaciones, CTEs y window functions
*/

/* ============================================================
   Q1. Top 10 clientes por facturación total
   ============================================================ */
SELECT
    client_id,
    client_name,
    client_type,
    sector,
    total_billed
FROM vw_client_profitability
ORDER BY total_billed DESC
LIMIT 10;

/* ============================================================
   Q2. Facturación total por sector
   ============================================================ */
SELECT
    sector,
    ROUND(SUM(total_billed), 2) AS sector_revenue
FROM vw_client_profitability
GROUP BY sector
ORDER BY sector_revenue DESC;

/* ============================================================
   Q3. Facturación total por asesor
   ============================================================ */
SELECT
    advisor_id,
    advisor_name,
    specialty,
    ROUND(SUM(total_amount), 2) AS advisor_revenue
FROM vw_revenue_overview
WHERE invoice_id IS NOT NULL
GROUP BY advisor_id, advisor_name, specialty
ORDER BY advisor_revenue DESC;

/* ============================================================
   Q4. Servicios realizados por tipo de servicio
   ============================================================ */
SELECT
    service_type,
    COUNT(*) AS total_services,
    ROUND(AVG(base_fee), 2) AS avg_base_fee
FROM vw_revenue_overview
GROUP BY service_type
ORDER BY total_services DESC;

/* ============================================================
   Q5. Evolución mensual de facturación
   ============================================================ */
SELECT
    strftime('%Y-%m', invoice_date) AS year_month,
    ROUND(SUM(total_amount), 2) AS monthly_revenue
FROM vw_revenue_overview
WHERE invoice_date IS NOT NULL
GROUP BY strftime('%Y-%m', invoice_date)
ORDER BY year_month;

/* ============================================================
   Q6. Facturación mensual acumulada (window function)
   ============================================================ */
WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', invoice_date) AS year_month,
        ROUND(SUM(total_amount), 2) AS monthly_revenue
    FROM vw_revenue_overview
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
   Q7. Ranking de clientes por ciudad
   ============================================================ */
WITH client_city_revenue AS (
    SELECT
        city,
        client_id,
        client_name,
        ROUND(SUM(total_billed), 2) AS revenue
    FROM vw_client_profitability
    GROUP BY city, client_id, client_name
)
SELECT
    city,
    client_id,
    client_name,
    revenue,
    RANK() OVER (PARTITION BY city ORDER BY revenue DESC) AS city_rank
FROM client_city_revenue
ORDER BY city, city_rank;

/* ============================================================
   Q8. Facturas pendientes o no pagadas
   ============================================================ */
SELECT
    invoice_id,
    invoice_date,
    due_date,
    total_amount,
    invoice_status,
    payment_presence
FROM vw_payment_status
WHERE payment_presence = 'No pagada'
   OR invoice_status IN ('Pendiente', 'Vencida')
ORDER BY due_date;

/* ============================================================
   Q9. Retraso medio de pago por método de pago
   ============================================================ */
SELECT
    payment_method,
    ROUND(AVG(days_payment_delay), 2) AS avg_payment_delay_days,
    COUNT(*) AS total_payments
FROM vw_payment_status
WHERE payment_id IS NOT NULL
GROUP BY payment_method
ORDER BY avg_payment_delay_days DESC;

/* ============================================================
   Q10. Top 5 servicios más facturados
   ============================================================ */
SELECT
    service_id,
    service_type,
    client_name,
    advisor_name,
    total_amount
FROM vw_revenue_overview
WHERE total_amount IS NOT NULL
ORDER BY total_amount DESC
LIMIT 5;