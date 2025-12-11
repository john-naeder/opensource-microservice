

CREATE DATABASE IF NOT EXISTS transaction_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE transaction_db;

-- 1) orders
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  id              BINARY(16)      NOT NULL,
  buyer_id        BINARY(16)      NOT NULL,
  seller_id       BINARY(16)      NOT NULL,

  total_amount    DECIMAL(18,2)   NOT NULL DEFAULT 0.00,
  currency        CHAR(3)         NOT NULL DEFAULT 'USD',

  status          VARCHAR(50)     NOT NULL DEFAULT 'PENDING',
  payment_status  VARCHAR(50)     NOT NULL DEFAULT 'PENDING',
  audit_flag      TINYINT(1)      NOT NULL DEFAULT 0,

  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  expired_at      DATETIME        NULL,

  PRIMARY KEY (id),
  KEY idx_orders_buyer_status   (buyer_id, status),
  KEY idx_orders_seller_status  (seller_id, status),
  KEY idx_orders_payment_status (payment_status),
  KEY idx_orders_created_at     (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2) order_items
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
  id            BINARY(16)     NOT NULL,
  order_id      BINARY(16)     NOT NULL,
  product_id    VARCHAR(255)   NOT NULL,
  product_variant_id VARCHAR(255)   NOT NULL,
  unit_price    DECIMAL(18,2)  NOT NULL,
  quantity      INT            NOT NULL CHECK (quantity > 0),
  subtotal      DECIMAL(18,2)  AS (unit_price * quantity) STORED,

  created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  KEY idx_order_items_order_id (order_id),
  KEY idx_order_items_product  (product_id),
  CONSTRAINT fk_order_items__orders
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3) order_proofs
DROP TABLE IF EXISTS order_proofs;
CREATE TABLE order_proofs (
  id            BINARY(16)   NOT NULL,
  order_id      BINARY(16)   NOT NULL,
  seller_id     BINARY(16)   NOT NULL,
  type          VARCHAR(50)  NOT NULL,   -- SCREENSHOT, VIDEO, TEXT_NOTE
  url           VARCHAR(1024) NOT NULL,
  note          VARCHAR(500) NULL,
  uploaded_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  KEY idx_order_proofs_order (order_id),
  KEY idx_order_proofs_seller (seller_id),
  CONSTRAINT fk_order_proofs__orders
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4) order_refunds
DROP TABLE IF EXISTS order_refunds;
CREATE TABLE order_refunds (
  id             BINARY(16)     NOT NULL,
  order_id       BINARY(16)     NOT NULL,
  request_by     BINARY(16)     NOT NULL,
  status         VARCHAR(50)    NOT NULL DEFAULT 'REQUESTED',
  reason         TEXT           NULL,
  created_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at   DATETIME       NULL,

  PRIMARY KEY (id),
  KEY idx_refunds_order (order_id),
  KEY idx_refunds_status (status),
  CONSTRAINT fk_order_refunds__orders
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 5) order_disputes
DROP TABLE IF EXISTS order_disputes;
CREATE TABLE order_disputes (
  id            BINARY(16)   NOT NULL,
  order_id      BINARY(16)   NOT NULL,
  opened_by     BINARY(16)   NOT NULL,
  issue_type    VARCHAR(50)  NOT NULL,
  description   TEXT         NULL,
  status        VARCHAR(50)  NOT NULL ,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at   DATETIME     NULL,

  PRIMARY KEY (id),
  KEY idx_disputes_order  (order_id),
  KEY idx_disputes_status (status),
  CONSTRAINT fk_order_disputes__orders
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 6) order_logs
DROP TABLE IF EXISTS order_logs;
CREATE TABLE order_logs (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id      BINARY(16)   NOT NULL,
  from_status   VARCHAR(50)  NULL,
  to_status     VARCHAR(50)  NOT NULL,
  changed_by    BINARY(16)   NULL,
  note          VARCHAR(500) NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  KEY idx_logs_order (order_id, created_at),
  CONSTRAINT fk_order_logs__orders
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
