-- ============================================================================
-- FRAUD DETECTION SYSTEM - DML SEED DATA
-- Version: 1.0
-- Description: Sample data for demo and testing
-- ============================================================================

-- Make sure we're using the correct schema
SET search_path TO fraud_detection, public;

-- ============================================================================
-- SECTION 1: DEMO USERS (For Hackathon Demo)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Insert Users (3 Good + 1 Fraudster + 1 Analyst + 1 Admin)
-- ----------------------------------------------------------------------------

-- GOOD USER 1: Alice Johnson (Low Risk, Established Customer)
INSERT INTO users (id, name, email, password_hash, role, status, phone, country_code, risk_score, account_age_days, fraud_history, created_at, last_login)
VALUES (
    'user_001',
    'Alice Johnson',
    'alice@demo.com',
    -- Password: demo123 (hashed with bcrypt)
    '$2a$10$rXxJ5K7z3qVj8sYp7xQGZO9zX7yG5K6jX8pY9qZ0A1bC2dE3fG4hI',
    'CUSTOMER',
    'ACTIVE',
    '+1-555-0101',
    'USA',
    12,  -- Low risk
    730, -- 2 years old account
    FALSE,
    CURRENT_TIMESTAMP - INTERVAL '730 days',
    CURRENT_TIMESTAMP - INTERVAL '2 hours'
) ON CONFLICT (email) DO NOTHING;

-- GOOD USER 2: Charlie Davis (Very Low Risk, Long-time Customer)
INSERT INTO users (id, name, email, password_hash, role, status, phone, country_code, risk_score, account_age_days, fraud_history, created_at, last_login)
VALUES (
    'user_002',
    'Charlie Davis',
    'charlie@demo.com',
    '$2a$10$rXxJ5K7z3qVj8sYp7xQGZO9zX7yG5K6jX8pY9qZ0A1bC2dE3fG4hI',
    'CUSTOMER',
    'ACTIVE',
    '+1-555-0102',
    'USA',
    8,   -- Very low risk
    1095, -- 3 years
    FALSE,
    CURRENT_TIMESTAMP - INTERVAL '1095 days',
    CURRENT_TIMESTAMP - INTERVAL '5 hours'
) ON CONFLICT (email) DO NOTHING;

-- GOOD USER 3: Diana Martinez (Low Risk)
INSERT INTO users (id, name, email, password_hash, role, status, phone, country_code, risk_score, account_age_days, fraud_history, created_at, last_login)
VALUES (
    'user_003',
    'Diana Martinez',
    'diana@demo.com',
    '$2a$10$rXxJ5K7z3qVj8sYp7xQGZO9zX7yG5K6jX8pY9qZ0A1bC2dE3fG4hI',
    'CUSTOMER',
    'ACTIVE',
    '+1-555-0103',
    'USA',
    15,  -- Low risk
    545, -- 1.5 years
    FALSE,
    CURRENT_TIMESTAMP - INTERVAL '545 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day'
) ON CONFLICT (email) DO NOTHING;

-- BAD USER: Bob Fraudster (High Risk, Compromised Account)
INSERT INTO users (id, name, email, password_hash, role, status, phone, country_code, risk_score, account_age_days, fraud_history, failed_login_attempts, created_at, last_login)
VALUES (
    'user_004',
    'Bob Fraudster',
    'bob@demo.com',
    '$2a$10$rXxJ5K7z3qVj8sYp7xQGZO9zX7yG5K6jX8pY9qZ0A1bC2dE3fG4hI',
    'CUSTOMER',
    'ACTIVE',  -- Not blocked yet
    '+234-555-6666',
    'NGA',
    87,  -- HIGH RISK
    15,  -- New account
    TRUE, -- Has fraud history
    3,    -- Multiple failed login attempts
    CURRENT_TIMESTAMP - INTERVAL '15 days',
    CURRENT_TIMESTAMP - INTERVAL '30 minutes'
) ON CONFLICT (email) DO NOTHING;

-- FRAUD ANALYST: Sarah Analyst
INSERT INTO users (id, name, email, password_hash, role, status, country_code, risk_score, account_age_days, created_at)
VALUES (
    'analyst_001',
    'Sarah Analyst',
    'analyst@demo.com',
    '$2a$10$rXxJ5K7z3qVj8sYp7xQGZO9zX7yG5K6jX8pY9qZ0A1bC2dE3fG4hI',
    'FRAUD_ANALYST',
    'ACTIVE',
    'USA',
    0,
    365,
    CURRENT_TIMESTAMP - INTERVAL '365 days'
) ON CONFLICT (email) DO NOTHING;

-- ADMIN: Admin User
INSERT INTO users (id, name, email, password_hash, role, status, country_code, risk_score, account_age_days, created_at)
VALUES (
    'admin_001',
    'Admin User',
    'admin@demo.com',
    '$2a$10$rXxJ5K7z3qVj8sYp7xQGZO9zX7yG5K6jX8pY9qZ0A1bC2dE3fG4hI',
    'ADMIN',
    'ACTIVE',
    'USA',
    0,
    730,
    CURRENT_TIMESTAMP - INTERVAL '730 days'
) ON CONFLICT (email) DO NOTHING;

-- ----------------------------------------------------------------------------
-- Insert Cards (One card per customer)
-- ----------------------------------------------------------------------------

-- Alice's Card (Good)
INSERT INTO cards (user_id, card_number_hash, card_token, last_4, card_type, card_brand, expiry_month, expiry_year, issuer_bank, issuer_country, bin_number, status, is_verified)
VALUES (
    'user_001',
    encode(digest('4532123456781234', 'sha256'), 'hex'),
    'tok_alice_4532_1234',
    '1234',
    'CREDIT',
    'VISA',
    12,
    2026,
    'Chase Bank',
    'USA',
    '453212',
    'ACTIVE',
    TRUE
) ON CONFLICT (card_token) DO NOTHING;

-- Charlie's Card (Good)
INSERT INTO cards (user_id, card_number_hash, card_token, last_4, card_type, card_brand, expiry_month, expiry_year, issuer_bank, issuer_country, bin_number, status, is_verified)
VALUES (
    'user_002',
    encode(digest('4532567890125678', 'sha256'), 'hex'),
    'tok_charlie_4532_5678',
    '5678',
    'CREDIT',
    'VISA',
    3,
    2027,
    'Bank of America',
    'USA',
    '453256',
    'ACTIVE',
    TRUE
) ON CONFLICT (card_token) DO NOTHING;

-- Diana's Card (Good)
INSERT INTO cards (user_id, card_number_hash, card_token, last_4, card_type, card_brand, expiry_month, expiry_year, issuer_bank, issuer_country, bin_number, status, is_verified)
VALUES (
    'user_003',
    encode(digest('4532901234569012', 'sha256'), 'hex'),
    'tok_diana_4532_9012',
    '9012',
    'DEBIT',
    'VISA',
    6,
    2026,
    'Wells Fargo',
    'USA',
    '453290',
    'ACTIVE',
    TRUE
) ON CONFLICT (card_token) DO NOTHING;

-- Bob's Card (Stolen/Compromised)
INSERT INTO cards (user_id, card_number_hash, card_token, last_4, card_type, card_brand, expiry_month, expiry_year, issuer_bank, issuer_country, bin_number, status, is_verified)
VALUES (
    'user_004',
    encode(digest('4532666666666666', 'sha256'), 'hex'),
    'tok_bob_4532_6666',
    '6666',
    'CREDIT',
    'VISA',
    9,
    2026,
    'Citibank',
    'USA',  -- Card issued in USA
    '453266',
    'ACTIVE',
    FALSE   -- Not verified
) ON CONFLICT (card_token) DO NOTHING;

-- ============================================================================
-- SECTION 2: MERCHANTS
-- ============================================================================

INSERT INTO merchants (merchant_id, name, category, mcc_code, country, city, risk_score, reputation_score, is_verified, total_transactions, fraud_rate)
VALUES
    ('merch_001', 'Amazon', 'E-Commerce', '5311', 'USA', 'Seattle', 5, 9.80, TRUE, 1000000, 0.0012),
    ('merch_002', 'Walmart', 'Retail', '5411', 'USA', 'Bentonville', 8, 9.50, TRUE, 850000, 0.0015),
    ('merch_003', 'Starbucks', 'Food & Beverage', '5812', 'USA', 'Seattle', 3, 9.90, TRUE, 500000, 0.0005),
    ('merch_004', 'Target', 'Retail', '5411', 'USA', 'Minneapolis', 7, 9.40, TRUE, 600000, 0.0018),
    ('merch_005', 'Home Depot', 'Home Improvement', '5211', 'USA', 'Atlanta', 10, 9.20, TRUE, 400000, 0.0022),
    ('merch_006', 'Costco', 'Wholesale', '5399', 'USA', 'Issaquah', 6, 9.60, TRUE, 550000, 0.0010),
    ('merch_007', 'Netflix', 'Streaming', '7841', 'USA', 'Los Gatos', 2, 9.95, TRUE, 2000000, 0.0003),
    ('merch_008', 'Uber', 'Transportation', '4121', 'USA', 'San Francisco', 12, 8.80, TRUE, 3000000, 0.0025),
    ('merch_009', 'DoorDash', 'Food Delivery', '5812', 'USA', 'San Francisco', 15, 8.50, TRUE, 1500000, 0.0032),
    ('merch_010', 'Tech Gadgets Store', 'Electronics', '5732', 'USA', 'New York', 25, 7.80, TRUE, 50000, 0.0045),
    ('merch_011', 'Suspicious Online Store', 'Electronics', '5732', 'NGA', 'Lagos', 85, 3.20, FALSE, 1200, 0.3500),
    ('merch_012', 'Unknown Seller', 'General', '5999', 'CHN', 'Shenzhen', 90, 2.50, FALSE, 450, 0.4200)
ON CONFLICT (merchant_id) DO NOTHING;

-- ============================================================================
-- SECTION 3: USER PROFILES (Behavioral Data)
-- ============================================================================

-- Alice's Profile (Good behavior pattern)
INSERT INTO user_profiles (
    user_id, total_transactions, total_amount, avg_amount, median_amount, p95_amount,
    common_merchants, common_categories, typical_hours, typical_days,
    home_location_city, home_location_country, home_location_lat, home_location_lon,
    known_devices, overall_risk_score, trust_score, last_transaction_at
)
VALUES (
    'user_001',
    450,
    33750.00,
    75.00,
    65.00,
    180.00,
    ARRAY['Amazon', 'Walmart', 'Starbucks', 'Target'],
    ARRAY['E-Commerce', 'Retail', 'Food & Beverage'],
    ARRAY[9, 12, 14, 18, 20],  -- Common hours
    ARRAY['Mon', 'Wed', 'Fri', 'Sat'],
    'New York',
    'USA',
    40.7128,
    -74.0060,
    '[
        {"device_id": "dev_alice_iphone", "device_type": "mobile", "first_seen": "2024-01-01", "trust_score": 95},
        {"device_id": "dev_alice_laptop", "device_type": "desktop", "first_seen": "2024-02-15", "trust_score": 90}
    ]'::jsonb,
    12,  -- Low risk
    88,  -- High trust
    CURRENT_TIMESTAMP - INTERVAL '2 hours'
) ON CONFLICT (user_id) DO NOTHING;

-- Charlie's Profile (Very good behavior)
INSERT INTO user_profiles (
    user_id, total_transactions, total_amount, avg_amount, median_amount, p95_amount,
    common_merchants, common_categories, typical_hours, typical_days,
    home_location_city, home_location_country, home_location_lat, home_location_lon,
    known_devices, overall_risk_score, trust_score, last_transaction_at
)
VALUES (
    'user_002',
    890,
    111250.00,
    125.00,
    110.00,
    280.00,
    ARRAY['Target', 'Home Depot', 'Costco', 'Amazon'],
    ARRAY['Retail', 'Home Improvement', 'Wholesale'],
    ARRAY[10, 13, 15, 17, 19],
    ARRAY['Tue', 'Thu', 'Sat', 'Sun'],
    'Los Angeles',
    'USA',
    34.0522,
    -118.2437,
    '[
        {"device_id": "dev_charlie_android", "device_type": "mobile", "first_seen": "2023-01-01", "trust_score": 98},
        {"device_id": "dev_charlie_desktop", "device_type": "desktop", "first_seen": "2023-03-10", "trust_score": 95}
    ]'::jsonb,
    8,   -- Very low risk
    92,  -- Very high trust
    CURRENT_TIMESTAMP - INTERVAL '5 hours'
) ON CONFLICT (user_id) DO NOTHING;

-- Diana's Profile (Good behavior)
INSERT INTO user_profiles (
    user_id, total_transactions, total_amount, avg_amount, median_amount, p95_amount,
    common_merchants, common_categories, typical_hours, typical_days,
    home_location_city, home_location_country, home_location_lat, home_location_lon,
    known_devices, overall_risk_score, trust_score, last_transaction_at
)
VALUES (
    'user_003',
    320,
    19200.00,
    60.00,
    55.00,
    140.00,
    ARRAY['Netflix', 'Uber', 'DoorDash', 'Starbucks'],
    ARRAY['Streaming', 'Transportation', 'Food Delivery'],
    ARRAY[11, 13, 18, 20, 22],
    ARRAY['Mon', 'Wed', 'Fri'],
    'Chicago',
    'USA',
    41.8781,
    -87.6298,
    '[
        {"device_id": "dev_diana_iphone", "device_type": "mobile", "first_seen": "2024-07-01", "trust_score": 85}
    ]'::jsonb,
    15,  -- Low risk
    80,  -- Good trust
    CURRENT_TIMESTAMP - INTERVAL '1 day'
) ON CONFLICT (user_id) DO NOTHING;

-- Bob's Profile (Suspicious/Fraudulent behavior)
INSERT INTO user_profiles (
    user_id, total_transactions, total_amount, avg_amount, median_amount, p95_amount,
    common_merchants, common_categories, typical_hours,
    home_location_city, home_location_country, home_location_lat, home_location_lon,
    fraud_attempts, overall_risk_score, trust_score, last_transaction_at
)
VALUES (
    'user_004',
    3,
    75.00,
    25.00,
    20.00,
    35.00,
    ARRAY[]::TEXT[],  -- No established pattern
    ARRAY[]::TEXT[],
    ARRAY[2, 3, 4],    -- Unusual hours (2am-4am)
    'Lagos',
    'NGA',
    6.5244,
    3.3792,
    2,   -- Previous fraud attempts
    87,  -- HIGH RISK
    12,  -- Very low trust
    CURRENT_TIMESTAMP - INTERVAL '30 minutes'
) ON CONFLICT (user_id) DO NOTHING;

-- ============================================================================
-- SECTION 4: HISTORICAL TRANSACTIONS (Good Users)
-- ============================================================================

-- Alice's Recent Transactions (All Approved)
INSERT INTO transactions (
    id, user_id, card_id, merchant_id, merchant_name, merchant_category,
    amount, currency, status, decision, fraud_score, fraud_probability,
    location_city, location_country, location_ip,
    device_id, device_type, transaction_channel,
    processing_time_ms, latency_ms, created_at, processed_at
)
VALUES
    ('txn_20260107_001', 'user_001', 1, 1, 'Amazon', 'E-Commerce', 45.00, 'USD', 'APPROVED', 'ALLOW', 8, 0.0800, 'New York', 'USA', '192.168.1.100', 'dev_alice_iphone', 'mobile', 'mobile', 85, 87, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
    ('txn_20260106_001', 'user_001', 1, 2, 'Walmart', 'Retail', 120.50, 'USD', 'APPROVED', 'ALLOW', 5, 0.0500, 'New York', 'USA', '192.168.1.100', 'dev_alice_laptop', 'desktop', 'web', 92, 95, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('txn_20260105_001', 'user_001', 1, 3, 'Starbucks', 'Food & Beverage', 8.75, 'USD', 'APPROVED', 'ALLOW', 3, 0.0300, 'New York', 'USA', '192.168.1.100', 'dev_alice_iphone', 'mobile', 'mobile', 78, 82, CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days'),
    ('txn_20260104_001', 'user_001', 1, 7, 'Netflix', 'Streaming', 15.99, 'USD', 'APPROVED', 'ALLOW', 2, 0.0200, 'New York', 'USA', '192.168.1.100', 'dev_alice_laptop', 'desktop', 'web', 65, 70, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days')
ON CONFLICT (id) DO NOTHING;

-- Charlie's Recent Transactions (All Approved)
INSERT INTO transactions (
    id, user_id, card_id, merchant_id, merchant_name, merchant_category,
    amount, currency, status, decision, fraud_score, fraud_probability,
    location_city, location_country, location_ip,
    device_id, device_type, transaction_channel,
    processing_time_ms, latency_ms, created_at, processed_at
)
VALUES
    ('txn_20260107_002', 'user_002', 2, 4, 'Target', 'Retail', 85.30, 'USD', 'APPROVED', 'ALLOW', 6, 0.0600, 'Los Angeles', 'USA', '10.0.0.50', 'dev_charlie_android', 'mobile', 'mobile', 88, 90, CURRENT_TIMESTAMP - INTERVAL '5 hours', CURRENT_TIMESTAMP - INTERVAL '5 hours'),
    ('txn_20260106_002', 'user_002', 2, 5, 'Home Depot', 'Home Improvement', 245.00, 'USD', 'APPROVED', 'ALLOW', 10, 0.1000, 'Los Angeles', 'USA', '10.0.0.50', 'dev_charlie_android', 'mobile', 'mobile', 95, 98, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('txn_20260105_002', 'user_002', 2, 6, 'Costco', 'Wholesale', 189.99, 'USD', 'APPROVED', 'ALLOW', 7, 0.0700, 'Los Angeles', 'USA', '10.0.0.50', 'dev_charlie_desktop', 'desktop', 'web', 82, 85, CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

-- Diana's Recent Transactions (All Approved)
INSERT INTO transactions (
    id, user_id, card_id, merchant_id, merchant_name, merchant_category,
    amount, currency, status, decision, fraud_score, fraud_probability,
    location_city, location_country, location_ip,
    device_id, device_type, transaction_channel,
    processing_time_ms, latency_ms, created_at, processed_at
)
VALUES
    ('txn_20260107_003', 'user_003', 3, 7, 'Netflix', 'Streaming', 15.99, 'USD', 'APPROVED', 'ALLOW', 4, 0.0400, 'Chicago', 'USA', '172.16.0.20', 'dev_diana_iphone', 'mobile', 'mobile', 70, 75, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('txn_20260106_003', 'user_003', 3, 8, 'Uber', 'Transportation', 28.50, 'USD', 'APPROVED', 'ALLOW', 8, 0.0800, 'Chicago', 'USA', '172.16.0.20', 'dev_diana_iphone', 'mobile', 'mobile', 85, 88, CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days'),
    ('txn_20260105_003', 'user_003', 3, 9, 'DoorDash', 'Food Delivery', 42.75, 'USD', 'APPROVED', 'ALLOW', 12, 0.1200, 'Chicago', 'USA', '172.16.0.20', 'dev_diana_iphone', 'mobile', 'mobile', 92, 95, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days')
ON CONFLICT (id) DO NOTHING;

-- Bob's Previous Small Transactions (Establishing pattern before fraud)
INSERT INTO transactions (
    id, user_id, card_id, merchant_id, merchant_name, merchant_category,
    amount, currency, status, decision, fraud_score, fraud_probability,
    location_city, location_country, location_ip,
    device_id, device_type, transaction_channel,
    processing_time_ms, latency_ms, created_at, processed_at
)
VALUES
    ('txn_20260102_004', 'user_004', 4, 1, 'Amazon', 'E-Commerce', 10.00, 'USD', 'APPROVED', 'ALLOW', 45, 0.4500, 'Lagos', 'NGA', '197.210.55.100', 'dev_bob_unknown', 'mobile', 'mobile', 95, 98, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '5 days'),
    ('txn_20260103_004', 'user_004', 4, 3, 'Starbucks', 'Food & Beverage', 15.00, 'USD', 'APPROVED', 'ALLOW', 50, 0.5000, 'Lagos', 'NGA', '197.210.55.101', 'dev_bob_unknown', 'mobile', 'mobile', 98, 100, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
    ('txn_20260104_004', 'user_004', 4, 2, 'Walmart', 'Retail', 20.00, 'USD', 'APPROVED', 'ALLOW', 55, 0.5500, 'Lagos', 'NGA', '197.210.55.102', 'dev_bob_unknown', 'mobile', 'mobile', 100, 105, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SECTION 5: FRAUD RULES
-- ============================================================================

INSERT INTO fraud_rules (
    rule_id, name, description, rule_type, condition, threshold, action, priority,
    category, is_active, is_hard_rule, created_by
)
VALUES
    ('R001', 'High Amount Threshold', 'Flag transactions 10x above user average', 'amount', 'amount > user_avg_amount * 10', 10.00, 'FLAG', 8, 'amount_based', TRUE, FALSE, 'admin_001'),
    ('R002', 'Velocity Check - 1 Hour', 'Block if more than 10 transactions in 1 hour', 'velocity', 'transaction_count_1h > 10', 10.00, 'BLOCK', 9, 'velocity_based', TRUE, TRUE, 'admin_001'),
    ('R003', 'New Device Alert', 'Challenge transactions from unknown devices', 'device', 'device_id NOT IN known_devices', NULL, 'CHALLENGE', 6, 'device_based', TRUE, FALSE, 'admin_001'),
    ('R004', 'International Transaction', 'Flag international transactions for new accounts', 'location', 'is_international = TRUE AND account_age_days < 30', 30.00, 'FLAG', 7, 'location_based', TRUE, FALSE, 'admin_001'),
    ('R005', 'Impossible Travel', 'Block transactions with impossible geographic velocity', 'location', 'distance_km / time_hours > 800', 800.00, 'BLOCK', 10, 'location_based', TRUE, TRUE, 'admin_001'),
    ('R006', 'High Risk Merchant', 'Flag transactions to merchants with fraud_rate > 10%', 'merchant', 'merchant_fraud_rate > 0.10', 0.10, 'FLAG', 7, 'merchant_based', TRUE, FALSE, 'admin_001'),
    ('R007', 'Blacklisted Card', 'Block transactions from blacklisted cards', 'card', 'card_hash IN blacklist', NULL, 'BLOCK', 10, 'card_based', TRUE, TRUE, 'admin_001'),
    ('R008', 'Unusual Time', 'Flag transactions between 1am-5am', 'time', 'EXTRACT(HOUR FROM timestamp) BETWEEN 1 AND 5', NULL, 'FLAG', 5, 'time_based', TRUE, FALSE, 'admin_001'),
    ('R009', 'Amount Spike', 'Flag if transaction > p95 of user history', 'amount', 'amount > user_p95_amount', NULL, 'FLAG', 6, 'amount_based', TRUE, FALSE, 'admin_001'),
    ('R010', 'Multiple Failed Auths', 'Block if user has > 3 failed login attempts in 24h', 'security', 'failed_login_attempts > 3', 3.00, 'BLOCK', 9, 'security_based', TRUE, TRUE, 'admin_001')
ON CONFLICT (rule_id) DO NOTHING;

-- ============================================================================
-- SECTION 6: ML MODELS
-- ============================================================================

INSERT INTO ml_models (
    model_id, name, version, description, model_type, algorithm, framework,
    status, is_production, features_used, num_features,
    metrics, training_dataset_size, inference_latency_ms,
    deployed_at, created_by
)
VALUES
    (
        'model_xgb_v47',
        'XGBoost Fraud Detector',
        'v47',
        'Production fraud detection model using gradient boosting',
        'xgboost',
        'Gradient Boosting Trees',
        'scikit-learn',
        'PRODUCTION',
        TRUE,
        ARRAY[
            'amount', 'amount_log', 'amount_zscore', 'hour_of_day', 'day_of_week',
            'is_weekend', 'is_international', 'velocity_1h', 'velocity_24h',
            'device_is_new', 'location_is_new', 'merchant_risk_score',
            'user_risk_score', 'amount_to_avg_ratio', 'days_since_signup'
        ],
        15,
        '{
            "precision": 0.89,
            "recall": 0.92,
            "f1_score": 0.90,
            "auc_roc": 0.95,
            "false_positive_rate": 0.021,
            "accuracy": 0.94
        }'::jsonb,
        500000,
        18,
        CURRENT_TIMESTAMP - INTERVAL '7 days',
        'admin_001'
    ),
    (
        'model_xgb_v48',
        'XGBoost Fraud Detector',
        'v48',
        'New model with improved features (shadow testing)',
        'xgboost',
        'Gradient Boosting Trees',
        'scikit-learn',
        'SHADOW',
        FALSE,
        ARRAY[
            'amount', 'amount_log', 'amount_zscore', 'hour_of_day', 'day_of_week',
            'is_weekend', 'is_international', 'velocity_1h', 'velocity_24h',
            'device_is_new', 'location_is_new', 'merchant_risk_score',
            'user_risk_score', 'amount_to_avg_ratio', 'days_since_signup',
            'device_switches_7d', 'chargeback_history'
        ],
        17,
        '{
            "precision": 0.91,
            "recall": 0.93,
            "f1_score": 0.92,
            "auc_roc": 0.96,
            "false_positive_rate": 0.018,
            "accuracy": 0.95
        }'::jsonb,
        600000,
        20,
        NULL,
        'admin_001'
    )
ON CONFLICT (model_id) DO NOTHING;

-- ============================================================================
-- SECTION 7: SAMPLE FRAUD ALERTS (For Demo)
-- ============================================================================

-- Alert for Bob's potential fraud (will be created when he tries to transact)
-- This is a sample of what gets created when suspicious activity is detected

-- ============================================================================
-- SECTION 8: AUDIT LOGS (Sample entries)
-- ============================================================================

INSERT INTO audit_logs (
    user_id, user_email, user_role, action, action_type, entity_type, entity_id,
    ip_address, request_method, request_path, response_status, response_time_ms
)
VALUES
    ('user_001', 'alice@demo.com', 'CUSTOMER', 'login', 'READ', 'session', 'sess_001', '192.168.1.100', 'POST', '/api/v1/auth/login', 200, 45),
    ('user_001', 'alice@demo.com', 'CUSTOMER', 'payment_initiated', 'CREATE', 'transaction', 'txn_20260107_001', '192.168.1.100', 'POST', '/api/v1/payments/initiate', 200, 87),
    ('analyst_001', 'analyst@demo.com', 'FRAUD_ANALYST', 'login', 'READ', 'session', 'sess_002', '10.0.0.5', 'POST', '/api/v1/auth/login', 200, 52),
    ('admin_001', 'admin@demo.com', 'ADMIN', 'update_rule', 'UPDATE', 'fraud_rule', 'R001', '10.0.0.10', 'PUT', '/api/v1/fraud/rules/R001', 200, 125)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 9: NOTIFICATIONS (Sample)
-- ============================================================================

INSERT INTO notifications (
    user_id, type, title, message, priority, entity_type, entity_id, is_read
)
VALUES
    ('user_001', 'transaction_approved', 'Transaction Approved', 'Your payment of $45.00 to Amazon was approved.', 'LOW', 'transaction', 'txn_20260107_001', FALSE),
    ('analyst_001', 'fraud_alert', 'High Risk Transaction Detected', 'Transaction from Bob Fraudster flagged with 87% fraud score.', 'HIGH', 'transaction', NULL, FALSE)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 10: STATISTICS UPDATE
-- ============================================================================

-- Update merchant statistics based on transactions
UPDATE merchants m
SET 
    total_transactions = (
        SELECT COUNT(*) 
        FROM transactions t 
        WHERE t.merchant_id = m.id
    ),
    fraud_rate = (
        SELECT COALESCE(
            CAST(COUNT(*) FILTER (WHERE is_fraud = TRUE) AS DECIMAL) / NULLIF(COUNT(*), 0),
            0.0000
        )
        FROM transactions t 
        WHERE t.merchant_id = m.id
    );

-- ============================================================================
-- SECTION 11: DEMO SCENARIO DATA (For Jury Presentation)
-- ============================================================================

-- This section prepares specific demo scenarios

-- SCENARIO 1: Alice makes a normal payment (will be approved)
-- Data already inserted above

-- SCENARIO 2: Bob attempts fraud (will be blocked)
-- Transaction will be created during demo, but we can pre-create an alert template

-- Mark Bob's account with fraud indicators
UPDATE users 
SET 
    risk_score = 87,
    fraud_history = TRUE,
    failed_login_attempts = 3
WHERE id = 'user_004';

-- ============================================================================
-- VERIFICATION QUERIES (Run these to verify data insertion)
-- ============================================================================

-- Count users by role
DO $$
DECLARE
    customer_count INTEGER;
    analyst_count INTEGER;
    admin_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO customer_count FROM users WHERE role = 'CUSTOMER';
    SELECT COUNT(*) INTO analyst_count FROM users WHERE role = 'FRAUD_ANALYST';
    SELECT COUNT(*) INTO admin_count FROM users WHERE role = 'ADMIN';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DATA SEEDING COMPLETED';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Users Created:';
    RAISE NOTICE '  - Customers: %', customer_count;
    RAISE NOTICE '  - Fraud Analysts: %', analyst_count;
    RAISE NOTICE '  - Admins: %', admin_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Demo Users (Login Credentials):';
    RAISE NOTICE '  Email: alice@demo.com | Password: demo123 | Role: Customer (Good)';
    RAISE NOTICE '  Email: charlie@demo.com | Password: demo123 | Role: Customer (Good)';
    RAISE NOTICE '  Email: diana@demo.com | Password: demo123 | Role: Customer (Good)';
    RAISE NOTICE '  Email: bob@demo.com | Password: demo123 | Role: Customer (FRAUDSTER)';
    RAISE NOTICE '  Email: analyst@demo.com | Password: demo123 | Role: Fraud Analyst';
    RAISE NOTICE '  Email: admin@demo.com | Password: demo123 | Role: Admin';
    RAISE NOTICE '';
    RAISE NOTICE 'Cards: % cards created', (SELECT COUNT(*) FROM cards);
    RAISE NOTICE 'Merchants: % merchants created', (SELECT COUNT(*) FROM merchants);
    RAISE NOTICE 'Transactions: % historical transactions', (SELECT COUNT(*) FROM transactions);
    RAISE NOTICE 'Fraud Rules: % rules configured', (SELECT COUNT(*) FROM fraud_rules);
    RAISE NOTICE 'ML Models: % models registered', (SELECT COUNT(*) FROM ml_models);
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'SYSTEM READY FOR DEMO!';
    RAISE NOTICE '========================================';
END $$;

-- Display sample transaction data
SELECT 
    'Sample Transactions' AS info,
    u.name AS user_name,
    t.merchant_name,
    t.amount,
    t.fraud_score,
    t.decision,
    t.status
FROM transactions t
JOIN users u ON t.user_id = u.id
ORDER BY t.created_at DESC
LIMIT 10;

-- Display user risk scores
SELECT 
    'User Risk Scores' AS info,
    name,
    email,
    role,
    risk_score,
    account_age_days,
    fraud_history
FROM users
WHERE role = 'CUSTOMER'
ORDER BY risk_score DESC;