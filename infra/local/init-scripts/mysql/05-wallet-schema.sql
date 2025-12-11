-- wallets: snapshot current balance per user+currency
CREATE DATABASE IF NOT EXISTS wallet_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE wallet_db;

CREATE TABLE wallets (
  id BINARY(16) NOT NULL PRIMARY KEY,
  user_id BINARY(16) NOT NULL,     -- id của user (owned by User Service)
  currency CHAR(3) NOT NULL DEFAULT 'VND',
  balance BIGINT NOT NULL DEFAULT 0,   -- minor units
  reserved BIGINT NOT NULL DEFAULT 0,  -- total held/reserved
  version BIGINT NOT NULL DEFAULT 0,   -- optimistic concurrency counter
  status TINYINT NOT NULL DEFAULT 1,   -- 1 = active, 0 = disabled

  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY ux_user_currency (user_id, currency),
  KEY idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ledger: immutable transaction records
CREATE TABLE wallet_transactions (
  id BINARY(16) NOT NULL PRIMARY KEY,
  wallet_id BINARY(16) NOT NULL,
  related_entity_id BINARY(16) DEFAULT NULL, -- order_id, payment_id, withdrawal_id...
  type VARCHAR(40) NOT NULL,   -- topup/payment/refund/withdrawal/transfer/fee/adjustment
  amount BIGINT NOT NULL,      -- always positive
  direction TINYINT NOT NULL,  -- 1 = credit to wallet, -1 = debit from wallet
  balance_after BIGINT NOT NULL,
  currency CHAR(3) NOT NULL,
  status VARCHAR(30) NOT NULL , -- posted/pending/reversed
  idempotency_key VARCHAR(255) DEFAULT NULL,
  metadata JSON DEFAULT NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_wallet_created (wallet_id, created_at),
  KEY idx_related (related_entity_id),
  KEY ux_idempotency (idempotency_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- reservations (holds)
CREATE TABLE wallet_reservations (
  id BINARY(16) NOT NULL PRIMARY KEY,
  wallet_id BINARY(16) NOT NULL,
  order_id BINARY(16) DEFAULT NULL,
  amount BIGINT NOT NULL,
  currency CHAR(3) NOT NULL,
  expires_at TIMESTAMP(6) NULL,
  status VARCHAR(30) NOT NULL , -- active/expired/captured/cancelled
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_wallet_status (wallet_id, status),
  KEY idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- payments (interaction with providers or order payments)
CREATE TABLE payments (
  id BINARY(16) NOT NULL PRIMARY KEY,
  user_id BINARY(16) NOT NULL,
  wallet_id BINARY(16) DEFAULT NULL,
  order_id BINARY(16) DEFAULT NULL,
  provider VARCHAR(50) DEFAULT NULL,  -- e.g. 'vnpay'
  provider_payment_id VARCHAR(255) DEFAULT NULL,
  type VARCHAR(30) NOT NULL, -- 'topup' | 'order_payment' | 'refund'
  payment_method VARCHAR(30), -- 'wallet' | 'direct'
  amount BIGINT NOT NULL,
  currency CHAR(3) NOT NULL,
  status VARCHAR(30) NOT NULL , -- created/processing/succeeded/failed
  idempotency_key VARCHAR(255) DEFAULT NULL,
  metadata VARCHAR(50) DEFAULT NULL,
  txn_ref VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  
  KEY idx_user_status (user_id, status),
  KEY ux_payment_provider (provider, provider_payment_id),
  KEY ux_payment_idempotency (idempotency_key),
  UNIQUE KEY ux_payment_txnref (txn_ref)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- payment attempts (detailed provider interactions / callbacks)
CREATE TABLE payment_attempts (
  id BINARY(16) NOT NULL PRIMARY KEY,
  payment_id BINARY(16) NOT NULL,
  attempt_data VARCHAR(2000) DEFAULT NULL, -- e.g. payment URL
  provider_response JSON,
  status VARCHAR(30),
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  expired_at TIMESTAMP(6) DEFAULT NULL,
  KEY idx_payment (payment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- withdrawal requests
CREATE TABLE withdrawal_requests (
  id BINARY(16) NOT NULL PRIMARY KEY,
  user_id BINARY(16) NOT NULL,
  wallet_id BINARY(16) NOT NULL,
  bank_account_id BINARY(16) NOT NULL,
  amount BIGINT NOT NULL,
  fee BIGINT NOT NULL DEFAULT 0,
  currency CHAR(3) NOT NULL,
  status VARCHAR(30) NOT NULL , -- pending/processing/completed/failed/cancelled
  idempotency_key VARCHAR(255) DEFAULT NULL,
  metadata JSON DEFAULT NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_user_status (user_id, status),
  KEY ux_withdraw_idempotency (idempotency_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- bank accounts (encrypted/masked)
CREATE TABLE bank_accounts (
  id BINARY(16) NOT NULL PRIMARY KEY,
  user_id BINARY(16) NOT NULL,
  bank_code VARCHAR(50),
  account_number_encrypted VARBINARY(512),   -- encrypted blob (use KMS)
  account_number_masked VARCHAR(50),         -- for display e.g. ****1234
  account_name VARCHAR(255),
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;




-- idempotency store (optional global mapping)
CREATE TABLE idempotency_store (
  id BINARY(16) NOT NULL PRIMARY KEY,
  idempotency_key VARCHAR(255) NOT NULL,
  resource_type VARCHAR(50),
  resource_id BINARY(16),
  response JSON,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY ux_idemp (idempotency_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


