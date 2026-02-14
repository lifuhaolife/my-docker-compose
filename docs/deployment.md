# 部署指南

## 📋 部署前准备

### 系统要求

- 操作系统: Linux / macOS / Windows 10+ (WSL2)
- Docker: 20.10+
- Docker Compose: 2.0+
- Git: 2.0+
- 磁盘空间: 至少 10GB 可用空间
- 内存: 建议 8GB+ (根据运行的服务数量)

### 安装 Docker

#### Linux (Ubuntu/Debian)

```bash
# 安装 Docker
curl -fsSL https://get.docker.com | bash

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 添加当前用户到 docker 组
sudo usermod -aG docker $USER
```

#### macOS

```bash
# 安装 Docker Desktop
brew install --cask docker
```

#### Windows

下载并安装 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)

---

## 🚀 快速开始

### 1. 克隆项目

```bash
# 方式一: 递归克隆(推荐)
git clone --recursive https://github.com/yourusername/my-docker-compose.git
cd my-docker-compose

# 方式二: 先克隆后初始化
git clone https://github.com/yourusername/my-docker-compose.git
cd my-docker-compose
git submodule update --init --recursive
```

### 2. 配置 Secrets

#### 2.1 创建私有仓库

1. 访问 GitHub 创建新的私有仓库
   - 仓库名: `docker-compose-secrets`
   - 设置为 **Private**
   - 不要添加 README、.gitignore 等

2. 添加为 Submodule

```bash
# 删除默认的 secrets 目录
rm -rf secrets

# 添加私有仓库为 submodule
git submodule add https://github.com/YOUR_USERNAME/docker-compose-secrets.git secrets
```

#### 2.2 初始化配置文件

```bash
# 方式一: 自动生成配置和随机密码
./scripts/init-secrets.sh

# 方式二: 手动创建配置
cd secrets/templates
cp .env.common.example ../.env.common
cp database/.env.mysql.example ../database/.env.mysql
# ... 复制其他模板文件
# 编辑文件并填入实际密码
```

#### 2.3 提交 Secrets

```bash
cd secrets
git add .
git commit -m "Initialize secrets configuration"
git push origin main

# 返回主项目目录
cd ..
git add .
git commit -m "Add secrets submodule"
git push origin main
```

### 3. 初始化项目

```bash
./scripts/setup.sh
```

这个脚本会:
- 创建必要的目录结构
- 初始化 Git 仓库
- 检查 Docker 环境
- 设置脚本执行权限

### 4. 部署服务

#### 4.1 部署单个服务

```bash
# 部署 MySQL
./scripts/deploy.sh mysql

# 部署 Redis
./scripts/deploy.sh redis

# 部署 Nginx
./scripts/deploy.sh nginx
```

#### 4.2 部署多个服务

```bash
# 同时部署多个服务
./scripts/deploy.sh mysql redis nginx
```

#### 4.3 部署所有基础服务

```bash
# 部署 MySQL, Redis, Nginx
./scripts/deploy.sh --all
```

---

## 📦 服务管理

### 查看服务状态

```bash
# 查看所有容器状态
./scripts/deploy.sh --status

# 或直接使用 Docker 命令
docker ps
```

### 停止服务

```bash
# 停止单个服务
./scripts/deploy.sh --down mysql

# 停止多个服务
./scripts/deploy.sh --down redis nginx
```

### 重启服务

```bash
# 重启单个服务
./scripts/deploy.sh --restart mysql

# 重启多个服务
./scripts/deploy.sh --restart mysql redis
```

### 查看服务日志

```bash
# 查看容器日志
docker logs mysql
docker logs redis

# 实时查看日志
docker logs -f mysql

# 查看最近 100 行日志
docker logs --tail 100 mysql
```

---

## 🔄 更新配置

### 更新私有配置

```bash
# 拉取最新的 secrets 配置
./scripts/pull-secrets.sh
```

### 更新主项目

```bash
# 拉取主项目更新
git pull origin main

# 更新 submodule
git submodule update --remote
```

---

## 💾 数据备份

### 备份数据库

```bash
# 备份单个数据库
./scripts/backup.sh mysql

# 备份多个数据库
./scripts/backup.sh mysql postgres redis

# 备份所有数据库
./scripts/backup.sh --all
```

### 查看备份列表

```bash
./scripts/backup.sh --list
```

### 恢复数据

#### MySQL 恢复

```bash
# 解压备份文件
gunzip backup/20240101_120000/mysql_all_databases.sql.gz

# 恢复数据
docker exec -i mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < backup/20240101_120000/mysql_all_databases.sql
```

#### PostgreSQL 恢复

```bash
gunzip backup/20240101_120000/postgres_all_databases.sql.gz
docker exec -i postgres psql -U postgres < backup/20240101_120000/postgres_all_databases.sql
```

#### Redis 恢复

```bash
gunzip backup/20240101_120000/redis_dump.rdb.gz
docker cp backup/20240101_120000/redis_dump.rdb redis:/data/dump.rdb
docker restart redis
```

---

## 🌍 多环境部署

### 开发环境

```bash
# 使用默认配置
./scripts/deploy.sh mysql redis
```

### 生产环境

1. 创建生产环境配置

```bash
# 复制配置模板
cp secrets/database/.env.mysql secrets/database/.env.mysql.prod

# 编辑生产环境配置
vi secrets/database/.env.mysql.prod
```

2. 修改部署脚本或直接使用 Docker Compose

```bash
# 使用生产环境配置
docker-compose -f docker-compose/database/mysql.yml \
  --env-file secrets/database/.env.mysql.prod \
  up -d
```

---

## 🔧 高级配置

### 自定义 Docker Compose 配置

直接编辑 `docker-compose/` 目录下的 yml 文件:

```bash
vi docker-compose/database/mysql.yml
```

### 添加新的中间件

1. 创建配置文件

```bash
mkdir -p docker-compose/new-service
vi docker-compose/new-service/service.yml
```

2. 创建 secrets 配置

```bash
mkdir -p secrets/new-service
vi secrets/new-service/.env.service
```

3. 更新 `scripts/deploy.sh` 中的 `SERVICE_MAP`

### 性能调优

#### MySQL

编辑 `config/database/mysql/conf.d/my.cnf`:

```ini
[mysqld]
# 根据服务器内存调整
innodb_buffer_pool_size = 2G
max_connections = 1000
```

#### Redis

编辑 `config/cache/redis/redis.conf`:

```conf
maxmemory 4gb
maxmemory-policy allkeys-lru
```

---

## ❓ 常见问题

### 1. 端口冲突

**问题**: 端口已被占用

**解决**:

```bash
# 查看端口占用
netstat -tulpn | grep :3306

# 修改服务端口
vi secrets/database/.env.mysql
# 修改 MYSQL_PORT=3307
```

### 2. 权限问题

**问题**: 权限被拒绝

**解决**:

```bash
# 给脚本执行权限
chmod +x scripts/*.sh

# Docker 权限
sudo usermod -aG docker $USER
```

### 3. 容器无法启动

**问题**: 容器启动失败

**解决**:

```bash
# 查看详细错误日志
docker logs mysql

# 检查配置文件
docker-compose -f docker-compose/database/mysql.yml config
```

---

## 📚 相关文档

- [安全最佳实践](./security.md)
- [故障排查指南](./troubleshooting.md)
- [高级用法](./advanced-usage.md)
