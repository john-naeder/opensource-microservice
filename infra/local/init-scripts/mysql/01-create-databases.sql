-- Create databases for microservices
CREATE DATABASE IF NOT EXISTS user_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS transaction_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS wallet_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS slack_clone CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant privileges
GRANT ALL PRIVILEGES ON user_db.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON transaction_db.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON wallet_db.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON slack_clone.* TO 'root'@'%';

FLUSH PRIVILEGES;

SELECT 'Databases created successfully!' as message;
SHOW DATABASES;
