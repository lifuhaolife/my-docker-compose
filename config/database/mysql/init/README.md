# MySQL 初始化脚本目录

此目录用于存放 MySQL 容器启动时自动执行的初始化脚本。

## 使用说明

1. 脚本文件格式：`.sql`, `.sql.gz`, `.sh`
2. 脚本按字母顺序执行
3. 建议命名规则：`01-create-database.sql`, `02-create-tables.sql`

## 示例脚本

### 创建数据库和用户
```sql
-- 01-init.sql
CREATE DATABASE IF NOT EXISTS myapp;
CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON myapp.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
```

### 创建表结构
```sql
-- 02-create-tables.sql
USE myapp;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 注意事项

- 初始化脚本只在容器**首次启动**时执行
- 如果数据目录已存在数据，脚本不会执行
- 脚本执行失败会导致容器启动失败
