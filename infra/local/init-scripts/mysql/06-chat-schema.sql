CREATE DATABASE IF NOT EXISTS chat_message_service
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE chat_message_service;

-- ==========================================
-- USERS (mirror from auth service)
-- ==========================================
CREATE TABLE IF NOT EXISTS users (
                                     user_id BINARY(16) PRIMARY KEY,
    username VARCHAR(100),
    display_name VARCHAR(255),
    avatar_url VARCHAR(512),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;

CREATE INDEX idx_users_username ON users (username);

-- ==========================================
-- CONVERSATIONS (unified model: channel, DM, group DM)
-- ==========================================
CREATE TABLE IF NOT EXISTS conversations (
                                             conversation_id BINARY(16) PRIMARY KEY,
    type ENUM('CHANNEL', 'DM', 'GROUP_DM') NOT NULL,
    name VARCHAR(255),
    topic VARCHAR(255),
    is_private BOOLEAN DEFAULT FALSE,
    created_by BINARY(16) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;

CREATE INDEX idx_conversations_type ON conversations (type);
CREATE INDEX idx_conversations_created_by ON conversations (created_by);

-- ==========================================
-- CONVERSATION MEMBERS
-- ==========================================
CREATE TABLE IF NOT EXISTS conversation_members (
                                                    conversation_id BINARY(16) NOT NULL,
    user_id BINARY(16) NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    role ENUM('OWNER', 'MEMBER') DEFAULT 'MEMBER',
    PRIMARY KEY (conversation_id, user_id)
    ) ENGINE=InnoDB;

CREATE INDEX idx_conversation_members_user_id ON conversation_members (user_id);

-- ==========================================
-- CHANNEL SEQUENCES (used for ordering messages per conversation)
-- ==========================================
CREATE TABLE IF NOT EXISTS conversation_sequences (
                                                      conversation_id BINARY(16) PRIMARY KEY,
    last_seq BIGINT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;

-- ==========================================
-- MESSAGES
-- ==========================================
CREATE TABLE IF NOT EXISTS messages (
                                        message_id BINARY(16) PRIMARY KEY,
    conversation_id BINARY(16) NOT NULL,
    user_id BINARY(16) NOT NULL,
    server_seq BIGINT NOT NULL,
    thread_root_id BINARY(16) NULL,
    text TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'default',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL,
    edited BOOLEAN DEFAULT FALSE,
    deleted BOOLEAN DEFAULT FALSE
    ) ENGINE=InnoDB;

CREATE UNIQUE INDEX idx_messages_conversation_seq ON messages (conversation_id, server_seq);
CREATE INDEX idx_messages_conversation_id ON messages (conversation_id);
CREATE INDEX idx_messages_user_id ON messages (user_id);
CREATE INDEX idx_messages_created_at ON messages (created_at DESC);
CREATE INDEX idx_messages_thread_root ON messages (thread_root_id);

-- ==========================================
-- MESSAGE VERSIONS (audit history)
-- ==========================================
CREATE TABLE IF NOT EXISTS message_versions (
                                                version_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                                message_id BINARY(16) NOT NULL,
    old_text TEXT NOT NULL,
    edited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    edited_by BINARY(16) NOT NULL
    ) ENGINE=InnoDB;

CREATE INDEX idx_message_versions_message_id ON message_versions (message_id);

-- ==========================================
-- MESSAGE REACTIONS
-- ==========================================
CREATE TABLE IF NOT EXISTS message_reactions (
                                                 message_id BINARY(16) NOT NULL,
    emoji VARCHAR(64) NOT NULL,
    user_id BINARY(16) NOT NULL,
    reacted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (message_id, emoji, user_id)
    ) ENGINE=InnoDB;

-- ==========================================
-- MESSAGE ATTACHMENTS
-- ==========================================
CREATE TABLE IF NOT EXISTS message_attachments (
                                                   attachment_id BINARY(16) PRIMARY KEY,
    message_id BINARY(16) NOT NULL,
    type VARCHAR(30) NOT NULL,
    url TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;

CREATE INDEX idx_attachments_message_id ON message_attachments (message_id);

-- ==========================================
-- MESSAGE ACKS (delivered/seen tracking)
-- ==========================================
CREATE TABLE IF NOT EXISTS message_acks (
                                            message_id BINARY(16) NOT NULL,
    user_id BINARY(16) NOT NULL,
    delivered_at TIMESTAMP NULL,
    seen_at TIMESTAMP NULL,
    PRIMARY KEY (message_id, user_id)
    ) ENGINE=InnoDB;

CREATE INDEX idx_message_acks_user_id ON message_acks (user_id);
CREATE INDEX idx_message_acks_seen_at ON message_acks (seen_at);

-- ==========================================
-- MESSAGE PINS
-- ==========================================
CREATE TABLE IF NOT EXISTS message_pins (
                                            message_id BINARY(16) NOT NULL,
    pinned_by BINARY(16) NOT NULL,
    pinned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (message_id, pinned_by)
    ) ENGINE=InnoDB;

-- ==========================================
-- THREADS METADATA (optional but useful)
-- ==========================================
CREATE TABLE IF NOT EXISTS message_threads (
                                               thread_root_id BINARY(16) PRIMARY KEY,
    conversation_id BINARY(16) NOT NULL,
    reply_count INT DEFAULT 0,
    last_reply_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_replied_by BINARY(16)
    ) ENGINE=InnoDB;

CREATE INDEX idx_threads_conversation_id ON message_threads (conversation_id);

-- ==========================================
-- CONVERSATION SETTINGS (optional)
-- ==========================================
CREATE TABLE IF NOT EXISTS conversation_settings (
                                                     conversation_id BINARY(16) PRIMARY KEY,
    allow_reactions BOOLEAN DEFAULT TRUE,
    allow_pins BOOLEAN DEFAULT TRUE,
    allow_thread BOOLEAN DEFAULT TRUE,
    slow_mode_seconds INT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;
