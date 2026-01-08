-- ============================================================================
-- FRAUD DETECTION SYSTEM - DDL SCHEMA
-- Version: 1.0
-- Database: PostgreSQL 14+
-- Description: Complete database schema with users, roles, and tables
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATABASE & USER CREATION
-- ============================================================================

-- Check if database exists, create if not
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_database WHERE datname = 'fraud_detection_db'
    ) THEN
        -- Note: Cannot create database inside a transaction block
        -- This needs to be run separately or via psql command
        RAISE NOTICE 'Database fraud_detection_db does not exist. Please create it manually using:';
        RAISE NOTICE 'CREATE DATABASE fraud_detection_db;';
    ELSE
        RAISE NOTICE 'Database fraud_detection_db already exists.';
    END IF;
END $$;

-- Connect to the database (run this after creating database)
-- \c fraud_detection_db;

-- ============================================================================
-- Create application user with password
-- ============================================================================

-- Check if user exists, create if not
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_user WHERE usename = 'fraud_detection_user'
    ) THEN
        CREATE USER fraud_detection_user WITH PASSWORD 'FraudDet3ct!2026#Secure';
        RAISE NOTICE 'User fraud_detection_user created successfully.';
    ELSE
        RAISE NOTICE 'User fraud_detection_user already exists.';
    END IF;
END $$;

-- Grant database connection privileges
GRANT CONNECT ON DATABASE fraud_detection_db TO fraud_detection_user;

-- Create schema for application tables
CREATE SCHEMA IF NOT EXISTS fraud_detection;

-- Grant schema usage
GRANT USAGE ON SCHEMA fraud_detection TO fraud_detection_user;
GRANT CREATE ON SCHEMA fraud_detection TO fraud_detection_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA fraud_detection 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO fraud_detection_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA fraud_detection 
    GRANT USAGE, SELECT ON SEQUENCES TO fraud_detection_user;

-- ============================================================================
-- SECTION 2: EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";        -- Text search

-- ============================================================================
-- SECTION 3: CUSTOM TYPES & ENUMS
-- ============================================================================

-- User roles
DO $$ BEGIN
    CREATE TYPE fraud_detection.user_role AS ENUM (
        'CUSTOMER',
        'FRAUD_ANALYST', 
        'ADMIN',
        'MERCHANT'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- User status
DO $$ BEGIN
    CREATE TYPE fraud_detection.user_status AS ENUM (
        'ACTIVE',
        'SUSPENDED',
        'BLOCKED',
        'PENDING_VERIFICATION'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Card types
DO $$ BEGIN
    CREATE TYPE fraud_detection.card_type AS ENUM (
        'DEBIT',
        'CREDIT',
        'PREPAID'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Card status
DO $$ BEGIN
    CREATE TYPE fraud_detection.card_status AS ENUM (
        'ACTIVE',
        'BLOCKED',
        'EXPIRED',
        'LOST',
        'STOLEN'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Transaction status
DO $$ BEGIN
    CREATE TYPE fraud_detection.transaction_status AS ENUM (
        'APPROVED',
        'BLOCKED',
        'CHALLENGED',
        'PENDING',
        'FAILED',
        'CANCELLED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Transaction decision
DO $$ BEGIN
    CREATE TYPE fraud_detection.transaction_decision AS ENUM (
        'ALLOW',
        'BLOCK',
        'CHALLENGE'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Alert severity
DO $$ BEGIN
    CREATE TYPE fraud_detection.alert_severity AS ENUM (
        'LOW',
        'MEDIUM',
        'HIGH',
        'CRITICAL'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Alert status
DO $$ BEGIN
    CREATE TYPE fraud_detection.alert_status AS ENUM (
        'PENDING',
        'REVIEWING',
        'RESOLVED',
        'DISMISSED',
        'ESCALATED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Model status
DO $$ BEGIN
    CREATE TYPE fraud_detection.model_status AS ENUM (
        'TRAINING',
        'TESTING',
        'SHADOW',
        'PRODUCTION',
        'ARCHIVED',
        'FAILED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Feedback label
DO $$ BEGIN
    CREATE TYPE fraud_detection.feedback_label AS ENUM (
        'FRAUD',
        'NOT_FRAUD',
        'SUSPICIOUS',
        'UNKNOWN'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Confidence level
DO $$ BEGIN
    CREATE TYPE fraud_detection.confidence_level AS ENUM (
        'HIGH',
        'MEDIUM',
        'LOW'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- SECTION 4: MAIN TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: users
-- Description: Core user accounts for customers, analysts, and admins
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.users (
    id VARCHAR(50) PRIMARY KEY DEFAULT ('user_' || REPLACE(uuid_generate_v4()::TEXT, '-', '')),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role fraud_detection.user_role NOT NULL DEFAULT 'CUSTOMER',
    status fraud_detection.user_status NOT NULL DEFAULT 'ACTIVE',
    
    -- User metadata
    phone VARCHAR(20),
    date_of_birth DATE,
    country_code VARCHAR(3),
    
    -- Security
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    failed_login_attempts INTEGER DEFAULT 0,
    last_failed_login TIMESTAMP,
    
    -- Risk indicators
    risk_score INTEGER DEFAULT 50 CHECK (risk_score BETWEEN 0 AND 100),
    account_age_days INTEGER DEFAULT 0,
    fraud_history BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    email_verified_at TIMESTAMP,
    
    -- Soft delete
    deleted_at TIMESTAMP,
    
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_email ON fraud_detection.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON fraud_detection.users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON fraud_detection.users(status);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON fraud_detection.users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_risk_score ON fraud_detection.users(risk_score);

-- ----------------------------------------------------------------------------
-- Table: cards
-- Description: Payment cards associated with users
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.cards (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES fraud_detection.users(id) ON DELETE CASCADE,
    
    -- Card information (PCI-DSS compliant - never store full PAN)
    card_number_hash VARCHAR(255) UNIQUE NOT NULL, -- SHA-256 hash of card number
    card_token VARCHAR(100) UNIQUE NOT NULL,       -- Tokenized card for processing
    last_4 VARCHAR(4) NOT NULL,
    card_type fraud_detection.card_type NOT NULL,
    card_brand VARCHAR(20),                        -- VISA, MASTERCARD, AMEX, etc.
    
    -- Card details
    expiry_month INTEGER NOT NULL CHECK (expiry_month BETWEEN 1 AND 12),
    expiry_year INTEGER NOT NULL CHECK (expiry_year >= EXTRACT(YEAR FROM CURRENT_DATE)),
    
    -- Issuer information
    issuer_bank VARCHAR(100),
    issuer_country VARCHAR(3),
    bin_number VARCHAR(6),                         -- Bank Identification Number
    
    -- Card status
    status fraud_detection.card_status NOT NULL DEFAULT 'ACTIVE',
    
    -- Security
    cvv_hash VARCHAR(255),                         -- Hashed CVV (if stored)
    is_verified BOOLEAN DEFAULT FALSE,
    verification_method VARCHAR(50),               -- 3DS, AVS, etc.
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP,
    blocked_at TIMESTAMP,
    
    -- Soft delete
    deleted_at TIMESTAMP
);

-- Indexes for cards table
CREATE INDEX IF NOT EXISTS idx_cards_user_id ON fraud_detection.cards(user_id);
CREATE INDEX IF NOT EXISTS idx_cards_status ON fraud_detection.cards(status);
CREATE INDEX IF NOT EXISTS idx_cards_last_4 ON fraud_detection.cards(last_4);
CREATE INDEX IF NOT EXISTS idx_cards_token ON fraud_detection.cards(card_token);

-- ----------------------------------------------------------------------------
-- Table: merchants
-- Description: Merchant information for transactions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.merchants (
    id SERIAL PRIMARY KEY,
    merchant_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    
    -- Merchant classification
    category VARCHAR(100),                         -- Electronics, Fashion, Travel, etc.
    mcc_code VARCHAR(4),                          -- Merchant Category Code
    
    -- Location
    country VARCHAR(3),
    city VARCHAR(100),
    
    -- Risk scoring
    risk_score INTEGER DEFAULT 50 CHECK (risk_score BETWEEN 0 AND 100),
    reputation_score DECIMAL(3, 2) DEFAULT 5.00 CHECK (reputation_score BETWEEN 0.00 AND 10.00),
    
    -- Statistics
    total_transactions INTEGER DEFAULT 0,
    fraud_rate DECIMAL(5, 4) DEFAULT 0.0000,      -- Percentage (0.0000 to 1.0000)
    
    -- Status
    is_verified BOOLEAN DEFAULT FALSE,
    is_high_risk BOOLEAN DEFAULT FALSE,
    is_blacklisted BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Soft delete
    deleted_at TIMESTAMP
);

-- Indexes for merchants table
CREATE INDEX IF NOT EXISTS idx_merchants_merchant_id ON fraud_detection.merchants(merchant_id);
CREATE INDEX IF NOT EXISTS idx_merchants_category ON fraud_detection.merchants(category);
CREATE INDEX IF NOT EXISTS idx_merchants_risk_score ON fraud_detection.merchants(risk_score);
CREATE INDEX IF NOT EXISTS idx_merchants_name ON fraud_detection.merchants USING gin(name gin_trgm_ops);

-- ----------------------------------------------------------------------------
-- Table: transactions
-- Description: All payment transactions with fraud detection results
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.transactions (
    id VARCHAR(50) PRIMARY KEY DEFAULT ('txn_' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '_' || LPAD(NEXTVAL('fraud_detection.transaction_seq')::TEXT, 6, '0')),
    
    -- Transaction parties
    user_id VARCHAR(50) NOT NULL REFERENCES fraud_detection.users(id),
    card_id INTEGER REFERENCES fraud_detection.cards(id),
    merchant_id INTEGER REFERENCES fraud_detection.merchants(id),
    
    -- Transaction details
    merchant_name VARCHAR(200) NOT NULL,
    merchant_category VARCHAR(50),
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Transaction status
    status fraud_detection.transaction_status NOT NULL DEFAULT 'PENDING',
    decision fraud_detection.transaction_decision,
    decision_reason TEXT,
    
    -- Fraud detection results
    fraud_score INTEGER CHECK (fraud_score BETWEEN 0 AND 100),
    fraud_probability DECIMAL(5, 4),               -- ML model output (0.0000 to 1.0000)
    model_version VARCHAR(20),
    rules_triggered TEXT[],                        -- Array of rule IDs that triggered
    
    -- Location information
    location_ip VARCHAR(45),
    location_city VARCHAR(100),
    location_country VARCHAR(3),
    location_latitude DECIMAL(10, 8),
    location_longitude DECIMAL(11, 8),
    
    -- Device information
    device_id VARCHAR(100),
    device_fingerprint VARCHAR(255),
    device_type VARCHAR(50),                       -- mobile, desktop, tablet
    user_agent TEXT,
    
    -- Context
    transaction_channel VARCHAR(20),               -- web, mobile, pos, atm
    payment_method VARCHAR(50),                    -- card, wallet, upi
    is_recurring BOOLEAN DEFAULT FALSE,
    is_international BOOLEAN DEFAULT FALSE,
    
    -- Performance metrics
    processing_time_ms INTEGER,
    latency_ms INTEGER,
    
    -- Feedback & labeling
    is_fraud BOOLEAN,                              -- Ground truth label
    labeled_by VARCHAR(50) REFERENCES fraud_detection.users(id),
    labeled_at TIMESTAMP,
    label_confidence fraud_detection.confidence_level,
    label_source VARCHAR(50),                      -- analyst, chargeback, customer_dispute
    
    -- Additional metadata
    metadata JSONB,                                -- Flexible field for additional data
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- Soft delete
    deleted_at TIMESTAMP
);

-- Create sequence for transaction IDs
CREATE SEQUENCE IF NOT EXISTS fraud_detection.transaction_seq START 1;

-- Indexes for transactions table
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON fraud_detection.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_card_id ON fraud_detection.transactions(card_id);
CREATE INDEX IF NOT EXISTS idx_transactions_merchant_id ON fraud_detection.transactions(merchant_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON fraud_detection.transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_decision ON fraud_detection.transactions(decision);
CREATE INDEX IF NOT EXISTS idx_transactions_fraud_score ON fraud_detection.transactions(fraud_score);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON fraud_detection.transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_transactions_amount ON fraud_detection.transactions(amount);
CREATE INDEX IF NOT EXISTS idx_transactions_is_fraud ON fraud_detection.transactions(is_fraud);
CREATE INDEX IF NOT EXISTS idx_transactions_device_id ON fraud_detection.transactions(device_id);
CREATE INDEX IF NOT EXISTS idx_transactions_location_country ON fraud_detection.transactions(location_country);

-- GIN index for JSONB metadata
CREATE INDEX IF NOT EXISTS idx_transactions_metadata ON fraud_detection.transactions USING gin(metadata);

-- ----------------------------------------------------------------------------
-- Table: user_profiles
-- Description: Behavioral analytics and user patterns
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.user_profiles (
    user_id VARCHAR(50) PRIMARY KEY REFERENCES fraud_detection.users(id) ON DELETE CASCADE,
    
    -- Transaction statistics
    total_transactions INTEGER DEFAULT 0,
    total_amount DECIMAL(12, 2) DEFAULT 0.00,
    avg_amount DECIMAL(10, 2) DEFAULT 0.00,
    median_amount DECIMAL(10, 2) DEFAULT 0.00,
    p95_amount DECIMAL(10, 2) DEFAULT 0.00,
    std_dev_amount DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Velocity metrics (updated in real-time via triggers)
    transactions_last_1h INTEGER DEFAULT 0,
    transactions_last_24h INTEGER DEFAULT 0,
    transactions_last_7d INTEGER DEFAULT 0,
    amount_sum_last_1h DECIMAL(12, 2) DEFAULT 0.00,
    amount_sum_last_24h DECIMAL(12, 2) DEFAULT 0.00,
    
    -- Behavioral patterns
    common_merchants TEXT[],                       -- Array of frequent merchant names
    common_categories TEXT[],                      -- Array of frequent categories
    common_amounts DECIMAL(10, 2)[],               -- Array of typical amounts
    typical_hours INTEGER[],                       -- Array of hours (0-23)
    typical_days VARCHAR(3)[],                     -- Array of day names
    
    -- Location patterns
    home_location_city VARCHAR(100),
    home_location_country VARCHAR(3),
    home_location_lat DECIMAL(10, 8),
    home_location_lon DECIMAL(11, 8),
    work_location_city VARCHAR(100),
    work_location_lat DECIMAL(10, 8),
    work_location_lon DECIMAL(11, 8),
    recent_cities TEXT[],
    countries_visited_30d TEXT[],
    
    -- Device patterns
    known_devices JSONB DEFAULT '[]'::jsonb,       -- Array of device objects
    device_switches_7d INTEGER DEFAULT 0,
    primary_device_id VARCHAR(100),
    
    -- Risk indicators
    fraud_attempts INTEGER DEFAULT 0,
    chargeback_count_180d INTEGER DEFAULT 0,
    dispute_count_90d INTEGER DEFAULT 0,
    failed_auth_attempts_7d INTEGER DEFAULT 0,
    overall_risk_score INTEGER DEFAULT 50 CHECK (overall_risk_score BETWEEN 0 AND 100),
    
    -- Time patterns
    last_transaction_at TIMESTAMP,
    last_successful_transaction_at TIMESTAMP,
    last_failed_transaction_at TIMESTAMP,
    
    -- Profile metadata
    profile_completeness INTEGER DEFAULT 0 CHECK (profile_completeness BETWEEN 0 AND 100),
    trust_score INTEGER DEFAULT 50 CHECK (trust_score BETWEEN 0 AND 100),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_computed_at TIMESTAMP
);

-- Indexes for user_profiles table
CREATE INDEX IF NOT EXISTS idx_user_profiles_risk_score ON fraud_detection.user_profiles(overall_risk_score);
CREATE INDEX IF NOT EXISTS idx_user_profiles_trust_score ON fraud_detection.user_profiles(trust_score);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_transaction ON fraud_detection.user_profiles(last_transaction_at);

-- ----------------------------------------------------------------------------
-- Table: fraud_alerts
-- Description: Flagged transactions requiring analyst review
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.fraud_alerts (
    id SERIAL PRIMARY KEY,
    
    -- Related entities
    transaction_id VARCHAR(50) NOT NULL REFERENCES fraud_detection.transactions(id),
    user_id VARCHAR(50) NOT NULL REFERENCES fraud_detection.users(id),
    
    -- Alert details
    alert_type VARCHAR(50) NOT NULL,               -- high_amount, velocity, location_mismatch, etc.
    severity fraud_detection.alert_severity NOT NULL DEFAULT 'MEDIUM',
    status fraud_detection.alert_status NOT NULL DEFAULT 'PENDING',
    
    -- Assignment
    assigned_to VARCHAR(50) REFERENCES fraud_detection.users(id),
    assigned_at TIMESTAMP,
    
    -- Review details
    reviewed_by VARCHAR(50) REFERENCES fraud_detection.users(id),
    reviewed_at TIMESTAMP,
    review_notes TEXT,
    review_decision VARCHAR(20),                   -- approve, block, escalate
    
    -- Alert metadata
    description TEXT,
    recommendation TEXT,
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    escalated_at TIMESTAMP,
    
    -- Soft delete
    deleted_at TIMESTAMP
);

-- Indexes for fraud_alerts table
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_transaction_id ON fraud_detection.fraud_alerts(transaction_id);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_user_id ON fraud_detection.fraud_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_status ON fraud_detection.fraud_alerts(status);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_severity ON fraud_detection.fraud_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_assigned_to ON fraud_detection.fraud_alerts(assigned_to);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_created_at ON fraud_detection.fraud_alerts(created_at);

-- ----------------------------------------------------------------------------
-- Table: fraud_rules
-- Description: Configurable fraud detection rules
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.fraud_rules (
    id SERIAL PRIMARY KEY,
    rule_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Rule configuration
    rule_type VARCHAR(50) NOT NULL,                -- velocity, amount, location, device, etc.
    condition TEXT NOT NULL,                       -- SQL-like condition
    threshold DECIMAL(10, 2),
    
    -- Rule action
    action VARCHAR(20) NOT NULL,                   -- FLAG, BLOCK, CHALLENGE, ALLOW
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    
    -- Rule metadata
    category VARCHAR(50),
    tags TEXT[],
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_hard_rule BOOLEAN DEFAULT FALSE,            -- Hard rules cannot be overridden
    
    -- Performance tracking
    times_triggered INTEGER DEFAULT 0,
    true_positives INTEGER DEFAULT 0,
    false_positives INTEGER DEFAULT 0,
    accuracy DECIMAL(5, 4),
    
    -- Timestamps
    created_by VARCHAR(50) REFERENCES fraud_detection.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_triggered_at TIMESTAMP,
    
    -- Soft delete
    deleted_at TIMESTAMP
);

-- Indexes for fraud_rules table
CREATE INDEX IF NOT EXISTS idx_fraud_rules_rule_id ON fraud_detection.fraud_rules(rule_id);
CREATE INDEX IF NOT EXISTS idx_fraud_rules_is_active ON fraud_detection.fraud_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_fraud_rules_rule_type ON fraud_detection.fraud_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_fraud_rules_priority ON fraud_detection.fraud_rules(priority);

-- ----------------------------------------------------------------------------
-- Table: ml_models
-- Description: Machine learning model registry
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.ml_models (
    id SERIAL PRIMARY KEY,
    model_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    description TEXT,
    
    -- Model details
    model_type VARCHAR(50) NOT NULL,               -- xgboost, random_forest, neural_network
    algorithm VARCHAR(100),
    framework VARCHAR(50),                         -- scikit-learn, tensorflow, pytorch
    
    -- Model status
    status fraud_detection.model_status NOT NULL DEFAULT 'TRAINING',
    is_production BOOLEAN DEFAULT FALSE,
    
    -- Performance metrics
    metrics JSONB,                                 -- {precision, recall, f1, auc, etc.}
    training_metrics JSONB,
    validation_metrics JSONB,
    test_metrics JSONB,
    
    -- Feature information
    features_used TEXT[],
    feature_importance JSONB,
    num_features INTEGER,
    
    -- Training information
    training_dataset_size INTEGER,
    training_duration_seconds INTEGER,
    hyperparameters JSONB,
    
    -- Deployment information
    model_path TEXT,                               -- S3 path or local path
    model_size_mb DECIMAL(10, 2),
    inference_latency_ms INTEGER,
    
    -- Versioning
    parent_model_id INTEGER REFERENCES fraud_detection.ml_models(id),
    is_latest BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    training_started_at TIMESTAMP,
    training_completed_at TIMESTAMP,
    deployed_at TIMESTAMP,
    deprecated_at TIMESTAMP,
    created_by VARCHAR(50) REFERENCES fraud_detection.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Soft delete
    deleted_at TIMESTAMP,
    
    CONSTRAINT unique_model_version UNIQUE(name, version)
);

-- Indexes for ml_models table
CREATE INDEX IF NOT EXISTS idx_ml_models_model_id ON fraud_detection.ml_models(model_id);
CREATE INDEX IF NOT EXISTS idx_ml_models_status ON fraud_detection.ml_models(status);
CREATE INDEX IF NOT EXISTS idx_ml_models_is_production ON fraud_detection.ml_models(is_production);
CREATE INDEX IF NOT EXISTS idx_ml_models_version ON fraud_detection.ml_models(version);

-- GIN indexes for JSONB fields
CREATE INDEX IF NOT EXISTS idx_ml_models_metrics ON fraud_detection.ml_models USING gin(metrics);
CREATE INDEX IF NOT EXISTS idx_ml_models_feature_importance ON fraud_detection.ml_models USING gin(feature_importance);

-- ----------------------------------------------------------------------------
-- Table: model_predictions
-- Description: Log of all ML model predictions for analysis
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.model_predictions (
    id BIGSERIAL PRIMARY KEY,
    
    -- Related entities
    transaction_id VARCHAR(50) NOT NULL REFERENCES fraud_detection.transactions(id),
    model_id INTEGER NOT NULL REFERENCES fraud_detection.ml_models(id),
    
    -- Prediction details
    prediction BOOLEAN NOT NULL,                   -- fraud (true) or not_fraud (false)
    probability DECIMAL(5, 4) NOT NULL CHECK (probability BETWEEN 0 AND 1),
    fraud_score INTEGER NOT NULL CHECK (fraud_score BETWEEN 0 AND 100),
    
    -- Feature values used
    features_json JSONB NOT NULL,
    
    -- SHAP values for explainability
    shap_values JSONB,
    top_features JSONB,                           -- Top 5 contributing features
    
    -- Prediction metadata
    inference_time_ms INTEGER,
    model_version VARCHAR(20),
    
    -- Feedback
    actual_label BOOLEAN,                         -- Ground truth (if available)
    is_correct BOOLEAN,                           -- Whether prediction matched actual
    
    -- Timestamps
    predicted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    feedback_received_at TIMESTAMP
);

-- Indexes for model_predictions table
CREATE INDEX IF NOT EXISTS idx_model_predictions_transaction_id ON fraud_detection.model_predictions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_model_predictions_model_id ON fraud_detection.model_predictions(model_id);
CREATE INDEX IF NOT EXISTS idx_model_predictions_prediction ON fraud_detection.model_predictions(prediction);
CREATE INDEX IF NOT EXISTS idx_model_predictions_predicted_at ON fraud_detection.model_predictions(predicted_at);

-- Partitioning by date (for large-scale systems)
-- CREATE TABLE IF NOT EXISTS fraud_detection.model_predictions_y2026m01 PARTITION OF fraud_detection.model_predictions
--     FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

-- ----------------------------------------------------------------------------
-- Table: audit_logs
-- Description: System audit trail for compliance
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.audit_logs (
    id BIGSERIAL PRIMARY KEY,
    
    -- Actor information
    user_id VARCHAR(50),
    user_email VARCHAR(100),
    user_role VARCHAR(20),
    
    -- Action details
    action VARCHAR(100) NOT NULL,                  -- login, payment, block_user, etc.
    action_type VARCHAR(50),                       -- CREATE, READ, UPDATE, DELETE
    entity_type VARCHAR(50),                       -- user, transaction, card, etc.
    entity_id VARCHAR(50),
    
    -- Request details
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_method VARCHAR(10),
    request_path TEXT,
    request_params JSONB,
    
    -- Change tracking
    old_values JSONB,
    new_values JSONB,
    changes JSONB,
    
    -- Response details
    response_status INTEGER,
    response_time_ms INTEGER,
    
    -- Error tracking
    error_message TEXT,
    stack_trace TEXT,
    
    -- Additional metadata
    metadata JSONB,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for audit_logs table
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON fraud_detection.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON fraud_detection.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type ON fraud_detection.audit_logs(entity_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON fraud_detection.audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_ip_address ON fraud_detection.audit_logs(ip_address);

-- GIN index for JSONB fields
CREATE INDEX IF NOT EXISTS idx_audit_logs_metadata ON fraud_detection.audit_logs USING gin(metadata);

-- ----------------------------------------------------------------------------
-- Table: sessions
-- Description: User session management
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.sessions (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES fraud_detection.users(id) ON DELETE CASCADE,
    
    -- Session details
    token VARCHAR(500) UNIQUE NOT NULL,
    refresh_token VARCHAR(500),
    
    -- Session metadata
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_id VARCHAR(100),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    terminated_at TIMESTAMP
);

-- Indexes for sessions table
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON fraud_detection.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON fraud_detection.sessions(token);
CREATE INDEX IF NOT EXISTS idx_sessions_is_active ON fraud_detection.sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON fraud_detection.sessions(expires_at);

-- ----------------------------------------------------------------------------
-- Table: notifications
-- Description: User notifications and alerts
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_detection.notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES fraud_detection.users(id) ON DELETE CASCADE,
    
    -- Notification details
    type VARCHAR(50) NOT NULL,                     -- fraud_alert, transaction_approved, etc.
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    
    -- Priority
    priority VARCHAR(20) DEFAULT 'MEDIUM',
    
    -- Related entity
    entity_type VARCHAR(50),
    entity_id VARCHAR(50),
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    
    -- Delivery
    delivery_channel VARCHAR(20),                  -- in_app, email, sms
    delivered_at TIMESTAMP,
    
    -- Additional data
    metadata JSONB,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Indexes for notifications table
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON fraud_detection.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON fraud_detection.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON fraud_detection.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON fraud_detection.notifications(created_at);

-- ============================================================================
-- SECTION 5: FUNCTIONS & TRIGGERS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function: Update timestamp on row update
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fraud_detection.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON fraud_detection.users
    FOR EACH ROW EXECUTE FUNCTION fraud_detection.update_updated_at_column();

CREATE TRIGGER update_cards_updated_at BEFORE UPDATE ON fraud_detection.cards
    FOR EACH ROW EXECUTE FUNCTION fraud_detection.update_updated_at_column();

CREATE TRIGGER update_merchants_updated_at BEFORE UPDATE ON fraud_detection.merchants
    FOR EACH ROW EXECUTE FUNCTION fraud_detection.update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON fraud_detection.user_profiles
    FOR EACH ROW EXECUTE FUNCTION fraud_detection.update_updated_at_column();

CREATE TRIGGER update_fraud_rules_updated_at BEFORE UPDATE ON fraud_detection.fraud_rules
    FOR EACH ROW EXECUTE FUNCTION fraud_detection.update_updated_at_column();

-- ----------------------------------------------------------------------------
-- Function: Update user profile after transaction
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fraud_detection.update_user_profile_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update for approved transactions
    IF NEW.status = 'APPROVED' THEN
        INSERT INTO fraud_detection.user_profiles (
            user_id,
            total_transactions,
            total_amount,
            last_transaction_at
        )
        VALUES (
            NEW.user_id,
            1,
            NEW.amount,
            NEW.created_at
        )
        ON CONFLICT (user_id) DO UPDATE SET
            total_transactions = fraud_detection.user_profiles.total_transactions + 1,
            total_amount = fraud_detection.user_profiles.total_amount + NEW.amount,
            last_transaction_at = NEW.created_at,
            updated_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_profile
    AFTER INSERT ON fraud_detection.transactions
    FOR EACH ROW
    EXECUTE FUNCTION fraud_detection.update_user_profile_on_transaction();

-- ----------------------------------------------------------------------------
-- Function: Calculate account age in days
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fraud_detection.calculate_account_age()
RETURNS TRIGGER AS $$
BEGIN
    NEW.account_age_days = EXTRACT(DAY FROM (CURRENT_TIMESTAMP - NEW.created_at));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_account_age
    BEFORE UPDATE ON fraud_detection.users
    FOR EACH ROW
    EXECUTE FUNCTION fraud_detection.calculate_account_age();

-- ============================================================================
-- SECTION 6: GRANT PERMISSIONS TO APPLICATION USER
-- ============================================================================

-- Grant all permissions on all tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA fraud_detection TO fraud_detection_user;

-- Grant usage on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA fraud_detection TO fraud_detection_user;

-- Grant execute on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA fraud_detection TO fraud_detection_user;

-- ============================================================================
-- SECTION 7: VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: Recent high-risk transactions
CREATE OR REPLACE VIEW fraud_detection.v_high_risk_transactions AS
SELECT 
    t.id,
    t.user_id,
    u.name AS user_name,
    u.email AS user_email,
    t.merchant_name,
    t.amount,
    t.currency,
    t.fraud_score,
    t.decision,
    t.status,
    t.location_country,
    t.created_at
FROM fraud_detection.transactions t
JOIN fraud_detection.users u ON t.user_id = u.id
WHERE t.fraud_score >= 60
  AND t.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY t.fraud_score DESC, t.created_at DESC;

-- View: User risk summary
CREATE OR REPLACE VIEW fraud_detection.v_user_risk_summary AS
SELECT 
    u.id,
    u.name,
    u.email,
    u.role,
    u.status,
    u.risk_score,
    u.account_age_days,
    u.fraud_history,
    up.total_transactions,
    up.total_amount,
    up.overall_risk_score AS profile_risk_score,
    up.trust_score,
    up.last_transaction_at,
    u.created_at
FROM fraud_detection.users u
LEFT JOIN fraud_detection.user_profiles up ON u.id = up.user_id
WHERE u.deleted_at IS NULL;

-- View: Pending fraud alerts
CREATE OR REPLACE VIEW fraud_detection.v_pending_alerts AS
SELECT 
    fa.id,
    fa.transaction_id,
    t.amount,
    t.merchant_name,
    fa.user_id,
    u.name AS user_name,
    u.email AS user_email,
    fa.alert_type,
    fa.severity,
    fa.status,
    fa.assigned_to,
    fa.created_at
FROM fraud_detection.fraud_alerts fa
JOIN fraud_detection.transactions t ON fa.transaction_id = t.id
JOIN fraud_detection.users u ON fa.user_id = u.id
WHERE fa.status IN ('PENDING', 'REVIEWING')
  AND fa.deleted_at IS NULL
ORDER BY fa.severity DESC, fa.created_at ASC;

-- Grant permissions on views
GRANT SELECT ON fraud_detection.v_high_risk_transactions TO fraud_detection_user;
GRANT SELECT ON fraud_detection.v_user_risk_summary TO fraud_detection_user;
GRANT SELECT ON fraud_detection.v_pending_alerts TO fraud_detection_user;

-- ============================================================================
-- SCRIPT COMPLETION
-- ============================================================================

-- Display summary
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DDL SCHEMA CREATION COMPLETED';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database: fraud_detection_db';
    RAISE NOTICE 'Schema: fraud_detection';
    RAISE NOTICE 'User: fraud_detection_user';
    RAISE NOTICE 'Password: FraudDet3ct!2026#Secure';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables Created: 15';
    RAISE NOTICE 'Views Created: 3';
    RAISE NOTICE 'Functions Created: 3';
    RAISE NOTICE 'Triggers Created: 5';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Step: Run v2__seed_data_dml.sql';
    RAISE NOTICE '========================================';
END $$;