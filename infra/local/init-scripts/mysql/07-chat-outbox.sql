CREATE DATABASE IF NOT EXISTS chat_message_service
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE chat_message_service;


CREATE TABLE IF NOT EXISTS message_producer_outbox (
    id VARCHAR(36) PRIMARY KEY,
    conversation_id BINARY(16) NOT NULL,
    topic VARCHAR(255) NOT NULL,
    payload JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL DEFAULT NULL,
    status ENUM('PENDING', 'PROCESSED', 'FAILED') DEFAULT 'PENDING'
    ) ENGINE=InnoDB;
)

