-- ============================================================
--  SaasStyle — PostgreSQL Schema
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
--  CATALOG / SHARED TABLES
--  No foreign dependencies — created first
-- ============================================================

CREATE TABLE tax_regimes (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    code        VARCHAR(20)  NOT NULL UNIQUE,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE roles (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    code        VARCHAR(50)  NOT NULL UNIQUE,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE plans (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(100)  NOT NULL,
    code          VARCHAR(50)   NOT NULL UNIQUE,
    max_branches  INTEGER       NOT NULL DEFAULT 1,
    max_users     INTEGER       NOT NULL DEFAULT 5,
    price_month   NUMERIC(10,2) NOT NULL,
    price_yearly  NUMERIC(10,2) NOT NULL,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE identification_types (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name             VARCHAR(100) NOT NULL,
    code             VARCHAR(20)  NOT NULL UNIQUE,
    validation_regex VARCHAR(255),
    max_length       INTEGER,
    is_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE payment_methods (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE contact_channels (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,   -- WhatsApp, SMS, Email, etc.
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ============================================================
--  MULTI-TENANT: businesses, branches, subscriptions
-- ============================================================

CREATE TABLE businesses (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(200) NOT NULL,
    tax_id      VARCHAR(50),             -- legal ID / RUC
    category    VARCHAR(100),            -- salon, barbershop, spa…
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE subscriptions (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id  UUID        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    plan_code    VARCHAR(50) NOT NULL REFERENCES plans(code) ON UPDATE CASCADE,
    status       VARCHAR(30) NOT NULL DEFAULT 'active'
                 CHECK (status IN ('active', 'expired', 'cancelled', 'trial')),
    starts_at    DATE        NOT NULL,
    ends_at      DATE        NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE branches (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id  UUID         NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name         VARCHAR(200) NOT NULL,
    address      VARCHAR(500),
    phone        VARCHAR(30),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE branch_schedules (
    id          UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id   UUID      NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    weekday     SMALLINT  NOT NULL CHECK (weekday BETWEEN 0 AND 6),  -- 0=Monday
    opens_at    TIME      NOT NULL,
    closes_at   TIME      NOT NULL,
    is_closed   BOOLEAN   NOT NULL DEFAULT FALSE,
    UNIQUE (branch_id, weekday)
);

-- ============================================================
--  USERS AND MEMBERSHIPS
-- ============================================================

CREATE TABLE users (
    id                     UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name             VARCHAR(100) NOT NULL,
    last_name              VARCHAR(100) NOT NULL,
    identification_type_id UUID         REFERENCES identification_types(id),
    identification         VARCHAR(50),
    email                  VARCHAR(255) NOT NULL UNIQUE,
    phone                  VARCHAR(30),
    is_active              BOOLEAN      NOT NULL DEFAULT TRUE,
    is_verified            BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- User membership at business level (e.g. owner, business admin)
CREATE TABLE business_memberships (
    id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_id  UUID    NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    role_id      UUID    NOT NULL REFERENCES roles(id),
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, business_id)
);

-- User membership at branch level (e.g. stylist assigned to a specific branch)
CREATE TABLE branch_memberships (
    id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    branch_id   UUID    NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    role_id     UUID    NOT NULL REFERENCES roles(id),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, branch_id)
);

-- ============================================================
--  CLIENTS
-- ============================================================

CREATE TABLE clients (
    id                   UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id            UUID          NOT NULL REFERENCES branches(id),
    first_name           VARCHAR(100)  NOT NULL,
    last_name            VARCHAR(100)  NOT NULL,
    birth_date           DATE,
    phone                VARCHAR(30),
    email                VARCHAR(255),
    contact_channel_id   UUID          REFERENCES contact_channels(id),
    accepts_promotions   BOOLEAN       NOT NULL DEFAULT FALSE,
    service_notes        TEXT,                                    -- allergies, preferences
    -- visit metrics (updated on each completed appointment)
    last_visit           TIMESTAMPTZ,
    total_visits         INTEGER       NOT NULL DEFAULT 0,
    total_spent          NUMERIC(12,2) NOT NULL DEFAULT 0,
    cancellations        INTEGER       NOT NULL DEFAULT 0,
    source               VARCHAR(100),                            -- referral, instagram, etc.
    is_active            BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    created_by           UUID          REFERENCES users(id)
);

-- ============================================================
--  CATALOG: services and products (per branch)
-- ============================================================

CREATE TABLE services (
    id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id    UUID          NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name         VARCHAR(200)  NOT NULL,
    description  TEXT,
    price        NUMERIC(10,2) NOT NULL,
    duration_min INTEGER       NOT NULL,   -- duration in minutes
    is_active    BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE products (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id     UUID          NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name          VARCHAR(200)  NOT NULL,
    description   TEXT,
    price         NUMERIC(10,2) NOT NULL,
    stock         INTEGER       NOT NULL DEFAULT 0,
    min_stock     INTEGER       NOT NULL DEFAULT 0,
    unit          VARCHAR(50),             -- unit, ml, gr, etc.
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ============================================================
--  APPOINTMENT HISTORY
-- ============================================================

CREATE TABLE appointment_history (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id   UUID          NOT NULL REFERENCES branches(id),
    client_id   UUID          NOT NULL REFERENCES clients(id),
    service_id  UUID          NOT NULL REFERENCES services(id),
    user_id     UUID          NOT NULL REFERENCES users(id),     -- stylist / staff
    scheduled_at TIMESTAMPTZ  NOT NULL,
    total       NUMERIC(10,2) NOT NULL DEFAULT 0,
    status      VARCHAR(30)   NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'completed', 'cancelled', 'no_show')),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ============================================================
--  RATINGS
-- ============================================================

CREATE TABLE ratings (
    id              UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id       UUID      NOT NULL REFERENCES clients(id),
    appointment_id  UUID      NOT NULL REFERENCES appointment_history(id) UNIQUE,
    score           SMALLINT  NOT NULL CHECK (score BETWEEN 1 AND 5),
    comment         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
--  INVOICES AND LINE ITEMS
-- ============================================================

CREATE TABLE invoices (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id         UUID          NOT NULL REFERENCES branches(id),
    client_id         UUID          NOT NULL REFERENCES clients(id),
    user_id           UUID          NOT NULL REFERENCES users(id),
    invoice_number    VARCHAR(50)   NOT NULL UNIQUE,
    issued_at         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    subtotal          NUMERIC(12,2) NOT NULL DEFAULT 0,
    discount          NUMERIC(12,2) NOT NULL DEFAULT 0,
    tax               NUMERIC(12,2) NOT NULL DEFAULT 0,
    total             NUMERIC(12,2) NOT NULL DEFAULT 0,
    status            VARCHAR(30)   NOT NULL DEFAULT 'draft'
                      CHECK (status IN ('draft', 'issued', 'paid', 'voided')),
    payment_method_id UUID          REFERENCES payment_methods(id),
    notes             TEXT,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE invoice_items (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id       UUID          NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_type        VARCHAR(20)   NOT NULL CHECK (item_type IN ('service', 'product')),
    reference_id     UUID          NOT NULL,              -- flexible FK → services or products
    -- snapshot: preserves billing history against catalog changes
    snap_name        VARCHAR(200)  NOT NULL,
    snap_description TEXT,
    unit_price       NUMERIC(10,2) NOT NULL,
    quantity         INTEGER       NOT NULL DEFAULT 1,
    discount         NUMERIC(10,2) NOT NULL DEFAULT 0,
    subtotal         NUMERIC(12,2) NOT NULL DEFAULT 0,    -- (unit_price * quantity) - discount
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

