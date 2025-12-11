CREATE
DATABASE  IF NOT EXISTS `user_db`;
USE `user_db`;


DROP TABLE IF EXISTS `user_auth`;
CREATE TABLE `user_auth`
(
    `id`                 binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `username`           varchar(50)  NOT NULL,
    `email`              varchar(255) NOT NULL,
    `password_hash`      varchar(255) NOT NULL,
    `status`             VARCHAR(50)  NOT NULL,
    `two_factor_enabled` tinyint(1) DEFAULT '0',
    `is_kyc`             tinyint(1) DEFAULT '0',
    `two_factor_secret`  varchar(100) DEFAULT NULL,
    `created_at`         timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `last_login_at`      timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `username` (`username`),
    UNIQUE KEY `email` (`email`),
    KEY                  `idx_user_auth_email` (`email`),
    KEY                  `idx_user_auth_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs`
(
    `id`          binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `user_id`     binary(16) DEFAULT (uuid_to_bin(uuid())) NULL,
    `action`      varchar(100) NOT NULL,
    `description` varchar(255) DEFAULT NULL,
    `created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY           `idx_audit_logs_user_id` (`user_id`),
    CONSTRAINT `audit_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user_auth` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


LOCK
TABLES `audit_logs` WRITE;
UNLOCK
TABLES;



DROP TABLE IF EXISTS `device_manager`;

CREATE TABLE `device_manager`
(
    `id`            binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    `created_at`    datetime(6) NOT NULL,
    `device_name`   varchar(100) NOT NULL,
    `device_type`   varchar(50)  NOT NULL,
    `last_login_at` datetime(6) DEFAULT NULL,
    `user_id`       binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK
TABLES `device_manager` WRITE;
UNLOCK
TABLES;


DROP TABLE IF EXISTS `login_history`;
CREATE TABLE `login_history`
(
    `id`          binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `user_id`     binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `login_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `ip_address`  varchar(45) DEFAULT NULL,
    `device_info` text,
    `success`     tinyint(1) NOT NULL,
    PRIMARY KEY (`id`),
    KEY           `idx_login_history_user_id` (`user_id`),
    CONSTRAINT `login_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user_auth` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


LOCK
TABLES `login_history` WRITE;
UNLOCK
TABLES;



DROP TABLE IF EXISTS `password_history`;

CREATE TABLE `password_history`
(
    `id`            binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `user_id`       binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `password_hash` varchar(255) NOT NULL,
    `created_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `current_index` int          NOT NULL,
    PRIMARY KEY (`id`),
    KEY             `user_id` (`user_id`),
    CONSTRAINT `password_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user_auth` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK
TABLES `password_history` WRITE;
UNLOCK
TABLES;



DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles`
(
    `id`          binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `name`        varchar(50) NOT NULL,
    `description` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `roles` (`id`, `name`, `description`)
VALUES (uuid_to_bin(uuid()), 'ROLE_USER', 'Standard user role'),
       (uuid_to_bin(uuid()), 'ROLE_ADMIN', 'Administrator role'),
        (uuid_to_bin(uuid()), 'ROLE_SELLER', 'Seller role');


DROP TABLE IF EXISTS `user_roles`;
CREATE TABLE `user_roles`
(
    `id`          binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `user_id` binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `role_id` binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    PRIMARY KEY (`user_id`, `role_id`),
    KEY       `role_id` (`role_id`),
    CONSTRAINT `user_roles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user_auth` (`id`) ON DELETE CASCADE,
    CONSTRAINT `user_roles_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE `send_message_error`
(
    `id`         binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())),
    `topic`       varchar(255) NOT NULL,
    `message` text NOT NULL,
    `status` varchar(50) NOT NULL,
    `created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);


CREATE TABLE user_inf
(
    id           binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())) PRIMARY KEY, -- UUID from AuthService
    display_name VARCHAR(50)         NOT NULL,
    email        VARCHAR(100) UNIQUE NOT NULL,
    country      VARCHAR(50),
    status       VARCHAR(20),
    avatar_url   VARCHAR(255),
    is_seller    BOOLEAN     DEFAULT FALSE,
    seller_bio   TEXT,
    created_at   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at   TIMESTAMP NULL,          -- Soft delete for compliance
    INDEX        idx_email (email)
);

-- Table for user preferences
CREATE TABLE preferences
(
    id                     binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())) PRIMARY KEY, -- UUID
    user_id                binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    notification_email     BOOLEAN   DEFAULT TRUE,
    notification_push      BOOLEAN   DEFAULT TRUE,
    preferred_currency     VARCHAR(10),             -- e.g., USD, BTC
    preferred_platform     VARCHAR(50),             -- e.g., Web, Mobile
    privacy_public_profile BOOLEAN   DEFAULT TRUE,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_inf (id) ON DELETE CASCADE
);

-- Table for transactions
CREATE TABLE transactions
(
    id               binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())) PRIMARY KEY, -- UUID
    user_id          binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    product_id       binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL, -- UUID from Product Service
    order_id         binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL, -- UUID from Order Service
    transaction_type VARCHAR(20)    NOT NULL,
    amount           DECIMAL(10, 2) NOT NULL,
    status           VARCHAR(20)    NOT NULL,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_inf (id) ON DELETE CASCADE,
    INDEX            idx_user_id (user_id),
    INDEX            idx_product_id (product_id)
);

-- Table for seller ratings
CREATE TABLE seller_ratings
(
    id             binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())) PRIMARY KEY, -- UUID
    seller_id      binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    buyer_id       binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    transaction_id binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    rating_score   TINYINT     NOT NULL CHECK (rating_score BETWEEN 1 AND 5),
    review_text    TEXT,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES user_inf (id) ON DELETE CASCADE,
    FOREIGN KEY (buyer_id) REFERENCES user_inf (id) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
    INDEX          idx_seller_id (seller_id)
);

-- Table for seller verifications
CREATE TABLE user_verifications
(
    id                  binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())) PRIMARY KEY, -- UUID
    user_id             binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    verification_status VARCHAR(20) NOT NULL,
    face_id_url   TEXT,            -- Link to secure storage

    document_front_url  TEXT,
    document_back_url   TEXT,            -- Link to secure storage
    version             INT,                     -- Versioning for KYC documents
    verified_at         TIMESTAMP NULL,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_inf (id) ON DELETE CASCADE
);

CREATE TABLE delete_kyc_requests
(
    id           binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())) PRIMARY KEY, -- UUID
    user_id      binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    selfie_url   VARCHAR(255),            -- Link to secure storage for selfie
    status       VARCHAR(20) NOT NULL,    -- e.g., 'pending', 'approved', 'rejected'
    FOREIGN KEY (user_id) REFERENCES user_inf (id) ON DELETE CASCADE
);


CREATE TABLE billing_address
(
    id             binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())) PRIMARY KEY,
    user_id          binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    address        VARCHAR(255) NOT NULL,
    city           VARCHAR(100) NOT NULL,
    postal_code    VARCHAR(20)  NOT NULL,
    state          VARCHAR(100),
    province       VARCHAR(100),
    country_region VARCHAR(100) NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_inf (id) ON DELETE CASCADE
);

CREATE TABLE seller_applications
(
    id                 binary(16) NOT NULL DEFAULT (uuid_to_bin(uuid())) PRIMARY KEY,
    user_id            binary(16) DEFAULT (uuid_to_bin(uuid())) NOT NULL,
    application_status VARCHAR(30) NOT NULL, -- e.g., 'PENDING', 'APPROVED', 'REJECTED', 'DRAFT', 'SUBMITTED', 'NEEDS_MORE_INFO'
    submission_date    TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    review_date        TIMESTAMP NULL,
    reviewer_id        binary(16) DEFAULT NULL,
    rejection_reason   TEXT,
    notes              TEXT,
    created_at         TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_inf (id) ON DELETE CASCADE,
    INDEX              idx_user_id (user_id),
    INDEX              idx_application_status (application_status)
);

CREATE TABLE transactional_outbox (
    id            BINARY(16) NOT NULL,          -- UUID của sự kiện
    aggregate_type VARCHAR(50) NOT NULL,        -- Tên aggregate: 'Order', 'Wallet', 'Payment'
    aggregate_id   BINARY(16) NULL,             -- Id của aggregate liên quan (order_id, wallet_id)
    event_type     VARCHAR(100) NOT NULL,       -- Tên event: 'order.created', 'wallet.reservation_created'
    payload        JSON NOT NULL,               -- Payload event (dạng JSON)
    status         VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, PUBLISHED, FAILED
    attempts       INT NOT NULL DEFAULT 0,      -- Số lần thử gửi đi
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at   TIMESTAMP NULL,
    
    PRIMARY KEY (id),
    KEY idx_status_created (status, created_at),
    KEY idx_aggregate (aggregate_type, aggregate_id)
);
