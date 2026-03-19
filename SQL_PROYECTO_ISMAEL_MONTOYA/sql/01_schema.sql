/* ============================================================
   PROYECTO SQL - 01_schema.sql
   Dataset: Asesoría (clientes, asesores, servicios, facturas, pagos)
   Motor SQL: SQLite
   ============================================================ */

/* QUE HACES EN ESTE ARCHIVO
   - Definir la estructura base del proyecto
   - Crear staging (`stg_*`) y core (`dim_*`, `fct_*`)
   - Preparar el modelo para cargar datos crudos y luego limpiarlos

   IDEA CLAVE
   - staging = datos crudos, tipos flexibles
   - core = datos limpios, relaciones y métricas listas para análisis
*/

PRAGMA foreign_keys = OFF;

/* ============================================================
   DROP TABLES
   ============================================================ */

/* ---------- Staging ---------- */
DROP TABLE IF EXISTS stg_clients_raw;
DROP TABLE IF EXISTS stg_advisors_raw;
DROP TABLE IF EXISTS stg_services_raw;
DROP TABLE IF EXISTS stg_invoices_raw;
DROP TABLE IF EXISTS stg_payments_raw;

/* ---------- Core ---------- */
DROP TABLE IF EXISTS fct_payments;
DROP TABLE IF EXISTS fct_invoices;
DROP TABLE IF EXISTS fct_services;
DROP TABLE IF EXISTS dim_advisors;
DROP TABLE IF EXISTS dim_clients;

/* ============================================================
   STAGING (raw, casi todo texto)
   ============================================================ */

CREATE TABLE stg_clients_raw (
    raw_client_id TEXT,
    raw_client_name TEXT,
    raw_client_type TEXT,
    raw_city TEXT,
    raw_sector TEXT,
    raw_signup_date TEXT,
    raw_email TEXT,
    raw_phone TEXT,
    source_file TEXT,
    ingested_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg_advisors_raw (
    raw_advisor_id TEXT,
    raw_advisor_name TEXT,
    raw_specialty TEXT,
    raw_hire_date TEXT,
    raw_office_city TEXT,
    source_file TEXT,
    ingested_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg_services_raw (
    raw_service_id TEXT,
    raw_client_id TEXT,
    raw_advisor_id TEXT,
    raw_service_date TEXT,
    raw_service_type TEXT,
    raw_hours_worked TEXT,
    raw_base_fee TEXT,
    raw_service_status TEXT,
    source_file TEXT,
    ingested_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg_invoices_raw (
    raw_invoice_id TEXT,
    raw_service_id TEXT,
    raw_invoice_date TEXT,
    raw_due_date TEXT,
    raw_amount TEXT,
    raw_tax_rate TEXT,
    raw_total_amount TEXT,
    raw_status TEXT,
    source_file TEXT,
    ingested_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg_payments_raw (
    raw_payment_id TEXT,
    raw_invoice_id TEXT,
    raw_payment_date TEXT,
    raw_amount_paid TEXT,
    raw_payment_method TEXT,
    source_file TEXT,
    ingested_at TEXT DEFAULT CURRENT_TIMESTAMP
);

/* ============================================================
   CORE (clean)
   ============================================================ */

CREATE TABLE dim_clients (
    client_key INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id TEXT NOT NULL UNIQUE,
    client_name TEXT NOT NULL,
    client_type TEXT,
    city TEXT,
    sector TEXT,
    signup_date TEXT,
    email TEXT,
    phone TEXT
);

CREATE TABLE dim_advisors (
    advisor_key INTEGER PRIMARY KEY AUTOINCREMENT,
    advisor_id TEXT NOT NULL UNIQUE,
    advisor_name TEXT NOT NULL,
    specialty TEXT,
    hire_date TEXT,
    office_city TEXT
);

CREATE TABLE fct_services (
    service_key INTEGER PRIMARY KEY AUTOINCREMENT,
    service_id TEXT NOT NULL UNIQUE,
    client_key INTEGER NOT NULL,
    advisor_key INTEGER NOT NULL,
    service_date TEXT,
    service_type TEXT,
    hours_worked REAL,
    base_fee REAL,
    service_status TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_key) REFERENCES dim_clients(client_key),
    FOREIGN KEY (advisor_key) REFERENCES dim_advisors(advisor_key)
);

CREATE TABLE fct_invoices (
    invoice_key INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id TEXT NOT NULL UNIQUE,
    service_key INTEGER NOT NULL,
    invoice_date TEXT,
    due_date TEXT,
    amount REAL,
    tax_rate REAL,
    total_amount REAL,
    status TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (service_key) REFERENCES fct_services(service_key)
);

CREATE TABLE fct_payments (
    payment_key INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT NOT NULL UNIQUE,
    invoice_key INTEGER NOT NULL,
    payment_date TEXT,
    amount_paid REAL,
    payment_method TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_key) REFERENCES fct_invoices(invoice_key)
);

/* ============================================================
   INDEXES
   ============================================================ */

CREATE INDEX idx_fct_services_client_key ON fct_services(client_key);
CREATE INDEX idx_fct_services_advisor_key ON fct_services(advisor_key);
CREATE INDEX idx_fct_services_service_date ON fct_services(service_date);

CREATE INDEX idx_fct_invoices_service_key ON fct_invoices(service_key);
CREATE INDEX idx_fct_invoices_invoice_date ON fct_invoices(invoice_date);
CREATE INDEX idx_fct_invoices_status ON fct_invoices(status);

CREATE INDEX idx_fct_payments_invoice_key ON fct_payments(invoice_key);
CREATE INDEX idx_fct_payments_payment_date ON fct_payments(payment_date);
