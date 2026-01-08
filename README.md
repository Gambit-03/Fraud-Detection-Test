# Fraud Detection System - Database Documentation

## Overview

This database schema supports a real-time fraud detection system for banking and financial transactions. It includes comprehensive user management, transaction tracking, behavioral analytics, fraud detection rules, ML model registry, and audit logging.

---

## Quick Start

### Prerequisites

- PostgreSQL 14 or higher
- Superuser access to create database and users

### Installation Steps

#### Step 1: Create Database

```bash
# Connect to PostgreSQL as superuser
psql -U postgres

# Create the database
CREATE DATABASE fraud_detection_db;

# Exit
\q
```

#### Step 2: Run DDL Schema

```bash
# Run the DDL script to create all tables, users, and schema
psql -U postgres -d fraud_detection_db -f 01_ddl_schema.sql
```

#### Step 3: Run DML Seed Data

```bash
# Insert demo data
psql -U postgres -d fraud_detection_db -f 02_dml_seed_data.sql
```

#### Step 4: Connect with Application User

```bash
# Connect using the application user
psql -U fraud_detection_user -d fraud_detection_db -W

# When prompted, enter password: FraudDet3ct!2026#Secure
```

---

## Database Credentials

### Application User

- **Username:** `fraud_detection_user`
- **Password:** `FraudDet3ct!2026#Secure`
- **Database:** `fraud_detection_db`
- **Schema:** `fraud_detection`
- **Permissions:** SELECT, INSERT, UPDATE, DELETE on all tables

### Connection String

```
postgresql://fraud_detection_user:FraudDet3ct!2026#Secure@localhost:5432/fraud_detection_db
```

---

## Demo Users (For Hackathon)

All demo users have the password: **`demo123`**

### Good Customers (Low Risk)

#### Alice Johnson

- **Email:** alice@demo.com
- **Role:** Customer
- **Risk Score:** 12/100 (Low)
- **Card:** xxxx-xxxx-xxxx-1234
- **Profile:** Established customer, 2 years, 450 transactions
- **Typical Merchants:** Amazon, Walmart, Starbucks

#### Charlie Davis

- **Email:** charlie@demo.com
- **Role:** Customer
- **Risk Score:** 8/100 (Very Low)
- **Card:** xxxx-xxxx-xxxx-5678
- **Profile:** Long-time customer, 3 years, 890 transactions
- **Typical Merchants:** Target, Home Depot, Costco

#### Diana Martinez

- **Email:** diana@demo.com
- **Role:** Customer
- **Risk Score:** 15/100 (Low)
- **Card:** xxxx-xxxx-xxxx-9012
- **Profile:** Regular customer, 1.5 years, 320 transactions
- **Typical Merchants:** Netflix, Uber, DoorDash

### Fraudulent Customer (High Risk)

#### Bob Fraudster

- **Email:** bob@demo.com
- **Role:** Customer
- **Risk Score:** 87/100 (HIGH RISK)
- **Card:** xxxx-xxxx-xxxx-6666
- **Profile:** New account (15 days), 3 transactions, location mismatch
- **Red Flags:**
  - Account age: 15 days only
  - Location: Lagos, Nigeria (card issued in USA)
  - No established transaction pattern
  - Previous fraud attempts detected
  - Multiple failed authentication attempts

### System Users

#### Fraud Analyst

- **Email:** analyst@demo.com
- **Role:** Fraud Analyst
- **Access:** Can review flagged transactions, approve/block payments

#### System Admin

- **Email:** admin@demo.com
- **Role:** Admin
- **Access:** Full system configuration, user management, rule management

---

## Database Schema Overview

### Core Tables

#### 1. **users**

Stores all user accounts (customers, analysts, admins)

- Primary Key: `id` (VARCHAR)
- Unique: `email`
- Key Fields: `role`, `status`, `risk_score`, `account_age_days`

#### 2. **cards**

Payment cards linked to users (PCI-DSS compliant)

- Primary Key: `id` (SERIAL)
- Foreign Key: `user_id` → users.id
- Security: Card numbers are hashed, only last 4 digits stored
- Key Fields: `card_token`, `card_type`, `status`, `is_verified`

#### 3. **merchants**

Merchant information and reputation scoring

- Primary Key: `id` (SERIAL)
- Unique: `merchant_id`
- Key Fields: `risk_score`, `reputation_score`, `fraud_rate`

#### 4. **transactions**

All payment transactions with fraud detection results

- Primary Key: `id` (VARCHAR, format: txn_YYYYMMDD_NNNNNN)
- Foreign Keys: `user_id`, `card_id`, `merchant_id`
- Key Fields: `fraud_score`, `decision`, `status`, `is_fraud` (label)

#### 5. **user_profiles**

Behavioral analytics and user patterns

- Primary Key: `user_id` (references users.id)
- Stores: Transaction statistics, common patterns, location history, device trust
- Updated: Real-time via triggers and batch jobs

#### 6. **fraud_alerts**

Flagged transactions requiring analyst review

- Primary Key: `id` (SERIAL)
- Foreign Keys: `transaction_id`, `user_id`, `assigned_to`
- Key Fields: `severity`, `status`, `alert_type`

#### 7. **fraud_rules**

Configurable fraud detection rules

- Primary Key: `id` (SERIAL)
- Unique: `rule_id`
- Key Fields: `rule_type`, `condition`, `action`, `priority`, `is_active`

#### 8. **ml_models**

Machine learning model registry

- Primary Key: `id` (SERIAL)
- Unique: `model_id`
- Key Fields: `version`, `status`, `is_production`, `metrics`

#### 9. **model_predictions**

Log of ML model predictions (for analysis)

- Primary Key: `id` (BIGSERIAL)
- Foreign Keys: `transaction_id`, `model_id`
- Stores: Prediction, probability, SHAP values, feature importance

#### 10. **audit_logs**

Complete audit trail for compliance

- Primary Key: `id` (BIGSERIAL)
- Stores: All user actions, changes, API calls, errors

---

## Custom Types & Enums

### User Related

- `user_role`: CUSTOMER, FRAUD_ANALYST, ADMIN, MERCHANT
- `user_status`: ACTIVE, SUSPENDED, BLOCKED, PENDING_VERIFICATION

### Card Related

- `card_type`: DEBIT, CREDIT, PREPAID
- `card_status`: ACTIVE, BLOCKED, EXPIRED, LOST, STOLEN

### Transaction Related

- `transaction_status`: APPROVED, BLOCKED, CHALLENGED, PENDING, FAILED, CANCELLED
- `transaction_decision`: ALLOW, BLOCK, CHALLENGE

### Alert Related

- `alert_severity`: LOW, MEDIUM, HIGH, CRITICAL
- `alert_status`: PENDING, REVIEWING, RESOLVED, DISMISSED, ESCALATED

### Model Related

- `model_status`: TRAINING, TESTING, SHADOW, PRODUCTION, ARCHIVED, FAILED

### Feedback Related

- `feedback_label`: FRAUD, NOT_FRAUD, SUSPICIOUS, UNKNOWN
- `confidence_level`: HIGH, MEDIUM, LOW

---

## Indexes

All tables have optimized indexes for:

- Primary key lookups
- Foreign key joins
- Common filter conditions (status, date ranges, risk scores)
- Text search (using GIN indexes for JSONB and trigram for text)

---

## Functions & Triggers

### Automatic Triggers

#### 1. `update_updated_at_column()`

Automatically updates the `updated_at` timestamp on row modifications

- Applied to: users, cards, merchants, user_profiles, fraud_rules

#### 2. `update_user_profile_on_transaction()`

Updates user behavioral profile after each approved transaction

- Applied to: transactions (AFTER INSERT)
- Updates: transaction counts, amounts, last transaction timestamp

#### 3. `calculate_account_age()`

Calculates account age in days automatically

- Applied to: users (BEFORE UPDATE)

---

## Views

### 1. `v_high_risk_transactions`

Lists recent transactions with fraud score ≥ 60

```sql
SELECT * FROM fraud_detection.v_high_risk_transactions;
```

### 2. `v_user_risk_summary`

Comprehensive user risk assessment view

```sql
SELECT * FROM fraud_detection.v_user_risk_summary WHERE risk_score > 50;
```

### 3. `v_pending_alerts`

Fraud alerts awaiting analyst review

```sql
SELECT * FROM fraud_detection.v_pending_alerts;
```

---

## Common Queries

### Get User Profile with Transaction History

```sql
SELECT
    u.*,
    up.total_transactions,
    up.avg_amount,
    up.overall_risk_score
FROM fraud_detection.users u
LEFT JOIN fraud_detection.user_profiles up ON u.id = up.user_id
WHERE u.email = 'alice@demo.com';
```

### Get Recent Transactions for User

```sql
SELECT
    t.id,
    t.merchant_name,
    t.amount,
    t.fraud_score,
    t.decision,
    t.status,
    t.created_at
FROM fraud_detection.transactions t
WHERE t.user_id = 'user_001'
ORDER BY t.created_at DESC
LIMIT 10;
```

### Get Fraud Alerts Pending Review

```sql
SELECT
    fa.*,
    t.amount,
    t.merchant_name,
    u.name AS user_name
FROM fraud_detection.fraud_alerts fa
JOIN fraud_detection.transactions t ON fa.transaction_id = t.id
JOIN fraud_detection.users u ON fa.user_id = u.id
WHERE fa.status = 'PENDING'
ORDER BY fa.severity DESC, fa.created_at ASC;
```

### Get Active Fraud Rules

```sql
SELECT
    rule_id,
    name,
    rule_type,
    action,
    priority,
    times_triggered
FROM fraud_detection.fraud_rules
WHERE is_active = TRUE
ORDER BY priority DESC;
```

### Get Production ML Model

```sql
SELECT
    model_id,
    name,
    version,
    metrics->>'precision' AS precision,
    metrics->>'recall' AS recall,
    metrics->>'f1_score' AS f1_score,
    deployed_at
FROM fraud_detection.ml_models
WHERE is_production = TRUE;
```

---

## Data Privacy & Security

### PCI-DSS Compliance

- **Never store full card numbers** - only hashed values and last 4 digits
- CVV is hashed (if stored at all)
- Card tokens used for processing

### Encryption

- All sensitive data should be encrypted in transit (TLS)
- Password hashing uses bcrypt with salt
- Card hashes use SHA-256

### Audit Trail

- All user actions logged in `audit_logs` table
- 7-year retention for compliance
- Includes IP addresses, timestamps, changes

### Data Retention

- Transactions: 5 years
- Audit logs: 7 years
- Sessions: 24 hours (auto-expire)
- Model predictions: 1 year

---

## Performance Considerations

### Partitioning (Future Enhancement)

For high-volume systems, consider partitioning:

- `transactions` table by date (monthly partitions)
- `audit_logs` table by date
- `model_predictions` table by date

### Connection Pooling

Recommended settings:

- Min connections: 10
- Max connections: 100
- Connection timeout: 30 seconds

### Query Optimization

- All foreign keys have indexes
- JSONB fields use GIN indexes
- Text search uses trigram indexes (pg_trgm)

---

## Backup & Recovery

### Backup Strategy

```bash
# Full backup
pg_dump -U fraud_detection_user -d fraud_detection_db -F c -f fraud_detection_backup.dump

# Schema only
pg_dump -U fraud_detection_user -d fraud_detection_db --schema-only -f schema_backup.sql

# Data only
pg_dump -U fraud_detection_user -d fraud_detection_db --data-only -f data_backup.sql
```

### Restore

```bash
pg_restore -U fraud_detection_user -d fraud_detection_db fraud_detection_backup.dump
```

---

## Troubleshooting

### Common Issues

#### Issue: Cannot connect to database

```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check if database exists
psql -U postgres -l | grep fraud_detection_db
```

#### Issue: Permission denied

```bash
# Grant permissions again
psql -U postgres -d fraud_detection_db -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA fraud_detection TO fraud_detection_user;"
```

#### Issue: User doesn't exist

```bash
# Check if user exists
psql -U postgres -c "\du" | grep fraud_detection_user

# Create user if missing
psql -U postgres -c "CREATE USER fraud_detection_user WITH PASSWORD 'FraudDet3ct!2026#Secure';"
```

---

## Testing

### Verify Installation

```sql
-- Connect to database
\c fraud_detection_db

-- Set schema
SET search_path TO fraud_detection;

-- Check tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'fraud_detection';

-- Count records
SELECT
    'users' AS table_name, COUNT(*) FROM users
UNION ALL
SELECT 'cards', COUNT(*) FROM cards
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'merchants', COUNT(*) FROM merchants;
```

### Test Demo Login

```sql
-- Verify demo users exist
SELECT id, name, email, role, risk_score
FROM users
WHERE email IN ('alice@demo.com', 'bob@demo.com', 'analyst@demo.com');
```

---

## Database Diagram (ASCII)

```
┌─────────────┐
│    users    │
│─────────────│
│ id (PK)     │──┐
│ email       │  │
│ role        │  │
│ risk_score  │  │
└─────────────┘  │
                 │
     ┌───────────┼──────────────┐
     │           │              │
     ▼           ▼              ▼
┌─────────┐  ┌──────────────┐ ┌───────────────┐
│  cards  │  │ transactions │ │ user_profiles │
│─────────│  │──────────────│ │───────────────│
│ id (PK) │  │ id (PK)      │ │ user_id (PK)  │
│ user_id │  │ user_id (FK) │ │ risk_score    │
│ last_4  │  │ card_id (FK) │ │ trust_score   │
│ status  │──┤ merchant_id  │ └───────────────┘
└─────────┘  │ fraud_score  │
             │ decision     │
             └──────────────┘
                    │
                    ▼
             ┌──────────────┐
             │ fraud_alerts │
             │──────────────│
             │ id (PK)      │
             │ txn_id (FK)  │
             │ severity     │
             │ status       │
             └──────────────┘
```

---

## Support

For issues or questions:

- Check the troubleshooting section
- Review PostgreSQL logs: `/var/log/postgresql/`
- Verify permissions and connectivity

---

## License

Internal use only - Hackathon Demo Project

---

**Last Updated:** January 8, 2026  
**Version:** 1.0  
**Maintainer:** System Architecture Team

