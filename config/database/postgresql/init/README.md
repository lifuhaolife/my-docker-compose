# PostgreSQL 初始化脚本目录

此目录用于存放 PostgreSQL 容器启动时自动执行的初始化脚本。

## 使用说明

1. 脚本文件格式：`.sql` 或 `.sh`
2. 脚本按字母顺序执行
3. 建议命名规则：`01-create-user.sql`, `02-create-tables.sql`

## 示例脚本

### 创建用户和数据库
```sql
-- 01-init.sql
CREATE USER myuser WITH PASSWORD 'mypassword';
CREATE DATABASE mydb OWNER myuser;
GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;
```

### 创建表结构
```sql
-- 02-create-tables.sql
\c mydb;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
```

## 注意事项

- 初始化脚本只在容器**首次启动**时执行
- 如果数据卷已存在数据，脚本不会执行
- 脚本执行失败会导致容器启动失败
