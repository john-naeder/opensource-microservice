-- Disable foreign key checks to allow for out-of-order inserts
SET FOREIGN_KEY_CHECKS = 0;

-- Define a series of user UUIDs for consistent relationships
SET @user1_uuid = UUID_TO_BIN('b321a4f0-4d87-4d9f-a035-6b2e1189c4d9');
SET @user2_uuid = UUID_TO_BIN('e78f67e2-4c28-4c91-a12b-3e5f2298d5c1');
SET @user3_uuid = UUID_TO_BIN('f123b7a5-9c87-4e5a-a3d1-6e8f447d2b6c');
SET @user4_uuid = UUID_TO_BIN('a8c7e2b6-5e1d-4f2c-a9d8-7e4f113a2d5f');
SET @user5_uuid = UUID_TO_BIN('1c2e3f4a-5b6c-7d8e-9f0a-1b2c3d4e5f60');
SET @user6_uuid = UUID_TO_BIN('2c3e4f5a-6b7c-8d9e-0f1a-2b3c4d5e6f70');
SET @user7_uuid = UUID_TO_BIN('3c4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f80');
SET @user8_uuid = UUID_TO_BIN('4c5e6f7a-8b9c-0d1e-2f3a-4b5c6d7e8f90');

-- Password hash for 'Abcd1234@'
SET @password_hash = '$2a$10$wT8K8J5t2M2H4L2H4FGNV5T2M2H4L2H4FGNV5T2';

-- Insert into `user_auth`
INSERT INTO `user_auth` (`id`, `username`, `email`, `password_hash`, `status`, `two_factor_enabled`, `is_kyc`, `two_factor_secret`, `created_at`, `last_login_at`) VALUES
(@user1_uuid, 'john.doe', 'john.doe@example.com', @password_hash, 'ACTIVE', 1, 1, 'L4FGNV5T2M2H4L2H4FGNV5T2M2H4L2H4FGN', '2024-01-15 10:00:00', '2025-08-15 14:30:00'),
(@user2_uuid, 'jane.smith', 'jane.smith@example.com', @password_hash, 'ACTIVE', 0, 1, NULL, '2024-02-20 11:30:00', '2025-08-16 09:15:00'),
(@user3_uuid, 'admin.user', 'admin.user@example.com', @password_hash, 'ACTIVE', 1, 1, 'H4L2H4FGNV5T2M2H4L2H4FGNV5T2M2H4L2H4', '2024-03-01 12:00:00', '2025-08-16 15:30:00'),
(@user4_uuid, 'seller.user', 'seller.user@example.com', @password_hash, 'ACTIVE', 0, 1, NULL, '2024-04-10 09:00:00', '2025-08-16 16:00:00'),
(@user5_uuid, 'alice.wonder', 'alice.wonder@example.com', @password_hash, 'ACTIVE', 0, 0, NULL, '2024-05-01 08:00:00', '2025-08-16 10:00:00'),
(@user6_uuid, 'bob.builder', 'bob.builder@example.com', @password_hash, 'SUSPENDED', 1, 1, 'G4L2H4FGNV5T2M2H4L2H4FGNV5T2M2H4L2H4', '2024-06-12 14:00:00', NULL),
(@user7_uuid, 'charlie.chap', 'charlie.chap@example.com', @password_hash, 'ACTIVE', 0, 1, NULL, '2024-07-20 18:00:00', '2025-08-16 17:00:00'),
(@user8_uuid, 'david.davis', 'david.davis@example.com', @password_hash, 'ACTIVE', 1, 0, 'S4L2H4FGNV5T2M2H4L2H4FGNV5T2M2H4L2H4', '2024-08-05 09:30:00', '2025-08-16 12:00:00');

-- Insert into `user_inf`
INSERT INTO `user_inf` (`id`, `display_name`, `email`, `country`, `status`, `avatar_url`, `is_seller`, `seller_bio`, `created_at`) VALUES
(@user1_uuid, 'John Doe', 'john.doe@example.com', 'USA', 'active', 'https://example.com/avatars/john.jpg', FALSE, NULL, '2024-01-15 10:01:00'),
(@user2_uuid, 'Jane Smith', 'jane.smith@example.com', 'Canada', 'active', 'https://example.com/avatars/jane.jpg', FALSE, NULL, '2024-02-20 11:31:00'),
(@user3_uuid, 'Admin User', 'admin.user@example.com', 'Germany', 'active', 'https://example.com/avatars/admin.jpg', FALSE, NULL, '2024-03-01 12:01:00'),
(@user4_uuid, 'Artisan Seller', 'seller.user@example.com', 'Japan', 'active', 'https://example.com/avatars/seller.jpg', TRUE, 'Providing high-quality handmade goods.', '2024-04-10 09:01:00'),
(@user5_uuid, 'Alice Wonder', 'alice.wonder@example.com', 'UK', 'active', 'https://example.com/avatars/alice.jpg', FALSE, NULL, '2024-05-01 08:01:00'),
(@user6_uuid, 'Bob Builder', 'bob.builder@example.com', 'Australia', 'suspended', 'https://example.com/avatars/bob.jpg', TRUE, 'Construction and design services.', '2024-06-12 14:01:00'),
(@user7_uuid, 'Charlie Chap', 'charlie.chap@example.com', 'France', 'active', 'https://example.com/avatars/charlie.jpg', FALSE, NULL, '2024-07-20 18:01:00'),
(@user8_uuid, 'David Davis', 'david.davis@example.com', 'Mexico', 'active', 'https://example.com/avatars/david.jpg', FALSE, NULL, '2024-08-05 09:31:00');

-- Insert into `user_roles`
SET @role_user_id = (SELECT id FROM `roles` WHERE name = 'ROLE_USER');
SET @role_admin_id = (SELECT id FROM `roles` WHERE name = 'ROLE_ADMIN');
SET @role_seller_id = (SELECT id FROM `roles` WHERE name = 'ROLE_SELLER');

INSERT INTO `user_roles` (`user_id`, `role_id`) VALUES
(@user1_uuid, @role_user_id),
(@user2_uuid, @role_user_id),
(@user3_uuid, @role_admin_id),
(@user4_uuid, @role_user_id),
(@user4_uuid, @role_seller_id),
(@user5_uuid, @role_user_id),
(@user6_uuid, @role_user_id),
(@user6_uuid, @role_seller_id),
(@user7_uuid, @role_user_id),
(@user8_uuid, @role_user_id);

-- Insert into `login_history`
INSERT INTO `login_history` (`id`, `user_id`, `login_at`, `ip_address`, `device_info`, `success`) VALUES
(UUID_TO_BIN(UUID()), @user1_uuid, '2025-08-15 14:30:00', '192.168.1.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', 1),
(UUID_TO_BIN(UUID()), @user2_uuid, '2025-08-16 09:15:00', '203.0.113.5', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)', 1),
(UUID_TO_BIN(UUID()), @user3_uuid, '2025-08-16 15:30:00', '2001:db8::1', 'Mozilla/5.0 (Linux; Android 10; SM-G960F)', 1),
(UUID_TO_BIN(UUID()), @user4_uuid, '2025-08-16 16:00:00', '172.16.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', 1),
(UUID_TO_BIN(UUID()), @user5_uuid, '2025-08-16 10:00:00', '10.0.0.10', 'Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0)', 1);

-- Insert into `preferences`
INSERT INTO `preferences` (`id`, `user_id`, `notification_email`, `notification_push`, `preferred_currency`, `preferred_platform`, `privacy_public_profile`) VALUES
(UUID_TO_BIN(UUID()), @user1_uuid, 1, 1, 'USD', 'Web', 1),
(UUID_TO_BIN(UUID()), @user2_uuid, 0, 1, 'EUR', 'Mobile', 0),
(UUID_TO_BIN(UUID()), @user5_uuid, 1, 0, 'GBP', 'Web', 1),
(UUID_TO_BIN(UUID()), @user7_uuid, 1, 1, 'EUR', 'Mobile', 1);

-- Insert into `user_verifications`
INSERT INTO `user_verifications` (`id`, `user_id`, `verification_status`, `face_id_url`, `document_front_url`, `document_back_url`, `version`, `verified_at`) VALUES
(UUID_TO_BIN(UUID()), @user1_uuid, 'VERIFIED', 'https://example.com/kyc/face_id_john.jpg', 'https://example.com/kyc/doc_front_john.jpg', 'https://example.com/kyc/doc_back_john.jpg', 1, '2024-01-20 10:00:00'),
(UUID_TO_BIN(UUID()), @user2_uuid, 'PENDING', 'https://example.com/kyc/face_id_jane.jpg', 'https://example.com/kyc/doc_front_jane.jpg', 'https://example.com/kyc/doc_back_jane.jpg', 1, NULL),
(UUID_TO_BIN(UUID()), @user4_uuid, 'VERIFIED', 'https://example.com/kyc/face_id_seller.jpg', 'https://example.com/kyc/doc_front_seller.jpg', 'https://example.com/kyc/doc_back_seller.jpg', 1, '2024-04-12 15:00:00'),
(UUID_TO_BIN(UUID()), @user6_uuid, 'VERIFIED', 'https://example.com/kyc/face_id_bob.jpg', 'https://example.com/kyc/doc_front_bob.jpg', 'https://example.com/kyc/doc_back_bob.jpg', 1, '2024-06-15 10:00:00');

-- Insert into `seller_applications`
INSERT INTO `seller_applications` (`id`, `user_id`, `application_status`, `submission_date`, `review_date`, `reviewer_id`, `rejection_reason`) VALUES
(UUID_TO_BIN(UUID()), @user4_uuid, 'APPROVED', '2024-04-15 10:00:00', '2024-04-18 11:00:00', @user3_uuid, NULL),
(UUID_TO_BIN(UUID()), @user6_uuid, 'APPROVED', '2024-06-15 11:00:00', '2024-06-18 12:00:00', @user3_uuid, NULL),
(UUID_TO_BIN(UUID()), @user2_uuid, 'REJECTED', '2024-05-01 12:00:00', '2024-05-05 15:00:00', @user3_uuid, 'Insufficient documentation.'),
(UUID_TO_BIN(UUID()), @user7_uuid, 'PENDING', '2024-08-10 09:00:00', NULL, NULL, NULL);

-- Insert into `transactions`
SET @transaction1_uuid = UUID_TO_BIN(UUID());
SET @transaction2_uuid = UUID_TO_BIN(UUID());
SET @transaction3_uuid = UUID_TO_BIN(UUID());
SET @transaction4_uuid = UUID_TO_BIN(UUID());

INSERT INTO `transactions` (`id`, `user_id`, `product_id`, `order_id`, `transaction_type`, `amount`, `status`) VALUES
(@transaction1_uuid, @user1_uuid, UUID_TO_BIN(UUID()), UUID_TO_BIN(UUID()), 'PURCHASE', 50.00, 'COMPLETED'),
(@transaction2_uuid, @user2_uuid, UUID_TO_BIN(UUID()), UUID_TO_BIN(UUID()), 'PURCHASE', 25.00, 'COMPLETED'),
(@transaction3_uuid, @user5_uuid, UUID_TO_BIN(UUID()), UUID_TO_BIN(UUID()), 'PURCHASE', 120.00, 'COMPLETED'),
(@transaction4_uuid, @user7_uuid, UUID_TO_BIN(UUID()), UUID_TO_BIN(UUID()), 'PURCHASE', 35.00, 'PENDING');

-- Insert into `seller_ratings`
INSERT INTO `seller_ratings` (`id`, `seller_id`, `buyer_id`, `transaction_id`, `rating_score`, `review_text`) VALUES
(UUID_TO_BIN(UUID()), @user4_uuid, @user1_uuid, @transaction1_uuid, 5, 'Great product, fast shipping!'),
(UUID_TO_BIN(UUID()), @user4_uuid, @user2_uuid, @transaction2_uuid, 3, 'Item was not as described.'),
(UUID_TO_BIN(UUID()), @user6_uuid, @user5_uuid, @transaction3_uuid, 4, 'Good quality, but delivery was a bit slow.');

-- Insert into `billing_address`
INSERT INTO `billing_address` (`id`, `user_id`, `address`, `city`, `postal_code`, `country_region`) VALUES
(UUID_TO_BIN(UUID()), @user1_uuid, '123 Main St', 'New York', '10001', 'USA'),
(UUID_TO_BIN(UUID()), @user2_uuid, '456 Queen St', 'Toronto', 'M5V 2T3', 'Canada'),
(UUID_TO_BIN(UUID()), @user5_uuid, '789 High Street', 'London', 'SW1A 0AA', 'United Kingdom'),
(UUID_TO_BIN(UUID()), @user7_uuid, '10 Rue de la Paix', 'Paris', '75002', 'France');

-- Insert into `password_history`
INSERT INTO `password_history` (`id`, `user_id`, `password_hash`, `created_at`, `current_index`) VALUES
(UUID_TO_BIN(UUID()), @user1_uuid, @password_hash, '2024-01-15 10:00:00', 1),
(UUID_TO_BIN(UUID()), @user2_uuid, @password_hash, '2024-02-20 11:30:00', 1);

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;