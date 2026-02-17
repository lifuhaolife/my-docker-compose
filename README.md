# Docker Compose 环境管理

简化版的 Docker Compose 配置管理系统，支持一键部署常见中间件服务。

## 🎯 设计理念

- ✅ **极简配置**: 只需修改 `.env` 文件即可配置所有服务
- ✅ **云端存储**: Docker Compose 配置存储在 GitHub
- ✅ **统一管理**: 所有密码和配置集中在一个环境变量文件
- ✅ **一键部署**: 无需 Git，通过 HTTP 下载即可部署
- ✅ **统一目录**: 部署到统一的 `/opt/docker-containers` 目录

## 🚀 快速开始

### 方式 1: 远程一键部署

```bash
# 一键部署 MySQL 和 Redis（需要 sudo 权限）
curl -fsSL https://raw.githubusercontent.com/lifuhaolife/my-docker-compose/main/bootstrap-simple.sh | sudo bash

# 部署指定服务
curl -fsSL https://raw.githubusercontent.com/lifuhaolife/my-docker-compose/main/bootstrap-simple.sh | sudo bash -s -- mysql redis nginx
```

### 方式 2: 本地部署

```bash
# 克隆仓库到统一部署目录
sudo git clone https://github.com/lifuhaolife/my-docker-compose.git /opt/docker-containers
cd /opt/docker-containers

# 复制环境变量模板
sudo cp .env.example .env

# 编辑密码配置
sudo vi .env

# 部署服务
sudo docker-compose -f docker-compose/database/mysql.yml up -d
sudo docker-compose -f docker-compose/cache/redis.yml up -d
```

## 📂 统一部署目录

所有服务统一部署到 `/opt/docker-containers` 目录：

```
/opt/docker-containers/
├── .env.example              # 环境变量模板
├── .env                      # 实际环境变量（包含密码）
├── bootstrap-simple.sh       # 部署脚本
├── docker-compose/           # Docker Compose 配置
│   ├── database/
│   ├── cache/
│   ├── middleware/
│   └── web-server/
├── config/                   # 服务配置文件
│   ├── database/
│   ├── cache/
│   └── web-server/
├── logs/                     # 日志目录
│   ├── mysql/
│   ├── redis/
│   └── nginx/
└── volumes/                  # 数据卷目录
```

## 📝 配置说明

### 环境变量文件

所有服务的配置都集中在 `.env` 文件中：

```bash
# 复制模板
cp .env.example .env

# 编辑配置
vi .env
```

### 配置示例

```bash
# MySQL 配置
MYSQL_ROOT_PASSWORD=your_mysql_root_password
MYSQL_DATABASE=myapp
MYSQL_USER=appuser
MYSQL_PASSWORD=your_mysql_app_password
MYSQL_PORT=3306

# Redis 配置
REDIS_PASSWORD=your_redis_password
REDIS_PORT=6379

# PostgreSQL 配置
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_DB=myapp
POSTGRES_USER=appuser
POSTGRES_PORT=5432

# RabbitMQ 配置
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=your_rabbitmq_password
RABBITMQ_AMQP_PORT=5672
RABBITMQ_MGMT_PORT=15672

# Nacos 配置
NACOS_AUTH_ENABLE=true
NACOS_AUTH_TOKEN=SecretKey012345678901234567890123456789012345678901234567890123456789
NACOS_PORT=8848

# Nginx 配置
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
```

## 🐳 支持的服务

| 服务 | 版本 | 端口 | 说明 |
|------|------|------|------|
| MySQL | 8.0 | 3306 | 关系型数据库 |
| PostgreSQL | 15 | 5432 | 关系型数据库 |
| Redis | 7.0 | 6379 | 缓存数据库 |
| RabbitMQ | 3.12 | 5672, 15672 | 消息队列 |
| Nacos | 2.2 | 8848 | 服务注册与配置中心 |
| Nginx | latest | 80, 443 | Web 服务器 |

## 📦 部署命令

### 单个服务部署

```bash
# MySQL
docker-compose -f docker-compose/database/mysql.yml up -d

# Redis
docker-compose -f docker-compose/cache/redis.yml up -d

# PostgreSQL
docker-compose -f docker-compose/database/postgresql.yml up -d

# RabbitMQ
docker-compose -f docker-compose/middleware/rabbitmq.yml up -d

# Nacos
docker-compose -f docker-compose/middleware/nacos.yml up -d

# Nginx
docker-compose -f docker-compose/web-server/nginx.yml up -d
```

### 批量部署

```bash
# 使用 bootstrap-simple.sh
./bootstrap-simple.sh mysql redis nginx

# 或者使用 all-in-one.yml
docker-compose -f docker-compose/all-in-one.yml up -d
```

### 服务管理

```bash
# 查看服务状态
docker-compose -f docker-compose/database/mysql.yml ps

# 查看日志
docker logs mysql

# 停止服务
docker-compose -f docker-compose/database/mysql.yml down

# 停止并删除数据
docker-compose -f docker-compose/database/mysql.yml down -v
```

## 🔐 安全建议

1. **密码强度**: 至少 16 位，包含大小写字母、数字、特殊字符
2. **定期更新**: 建议每 3-6 个月更换一次密码
3. **环境隔离**: 不同环境使用不同的 `.env` 文件
4. **版本控制**: 将 `.env` 添加到 `.gitignore`，不要提交到仓库

## 📁 项目结构

```
/opt/docker-containers/
├── .env.example              # 环境变量模板（提交到 Git）
├── .env                      # 实际环境变量（不提交）
├── bootstrap-simple.sh       # 简化部署脚本
├── docker-compose/           # Docker Compose 配置
│   ├── database/
│   │   ├── mysql.yml
│   │   └── postgresql.yml
│   ├── cache/
│   │   └── redis.yml
│   ├── middleware/
│   │   ├── rabbitmq.yml
│   │   └── nacos.yml
│   └── web-server/
│       └── nginx.yml
├── config/                   # 服务配置文件
│   ├── database/mysql/
│   │   ├── conf.d/
│   │   └── init/
│   ├── cache/redis/
│   ├── web-server/nginx/
│   └── middleware/
├── logs/                     # 日志目录
│   ├── mysql/
│   ├── redis/
│   ├── postgresql/
│   ├── nginx/
│   ├── rabbitmq/
│   └── nacos/
└── volumes/                  # 数据持久化目录
```

## 🛠️ 高级用法

### 使用自定义环境变量文件

```bash
# 指定环境变量文件
docker-compose -f docker-compose/database/mysql.yml --env-file /path/to/.env up -d
```

### 覆盖默认配置

```bash
# 命令行覆盖环境变量
MYSQL_ROOT_PASSWORD=new_password docker-compose -f docker-compose/database/mysql.yml up -d
```

### 多环境管理

```bash
# 开发环境
cp .env.example .env.dev
vi .env.dev

# 生产环境
cp .env.example .env.prod
vi .env.prod

# 部署开发环境
docker-compose -f docker-compose/database/mysql.yml --env-file .env.dev up -d
```

## 🐛 故障排除

### 服务无法启动

```bash
# 进入部署目录
cd /opt/docker-containers

# 查看详细日志
docker-compose -f docker-compose/database/mysql.yml logs

# 检查端口占用
netstat -tunlp | grep 3306

# 检查环境变量
cat .env
```

### 密码错误

```bash
# 检查 .env 文件
cd /opt/docker-containers
cat .env | grep MYSQL_ROOT_PASSWORD

# 重新设置密码
sudo vi .env

# 重启服务
docker-compose -f docker-compose/database/mysql.yml restart
```

### 网络问题

```bash
# 检查 Docker 网络
docker network ls

# 重建网络
cd /opt/docker-containers
docker-compose -f docker-compose/database/mysql.yml down
docker-compose -f docker-compose/database/mysql.yml up -d
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License
