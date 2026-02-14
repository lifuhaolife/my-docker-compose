# Docker Compose 环境管理系统

> 🎯 目标: 提供稳定、可移植、安全的容器化开发环境配置管理方案

## 🌟 核心特性

- ✅ **零依赖** - 无需 Git,仅需 curl/wget
- ✅ **一键部署** - 一行命令完成所有部署
- ✅ **HTTP 下载** - 直接从 GitHub 下载配置
- ✅ **安全存储** - 私有仓库隔离敏感信息
- ✅ **自动配置** - 自动生成强密码
- ✅ **易于移植** - 新机器秒级部署环境

## 🚀 快速开始 (无需 Git)

### 方式一: 公开仓库 (最简单)

```bash
# 一键部署所有基础服务
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash

# 部署指定服务
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- mysql redis

# 指定安装目录
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- --install-dir /opt/docker-env
```

### 方式二: 私有仓库 (推荐生产环境)

```bash
# 设置 GitHub Token (访问私有配置仓库)
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# 指定私有配置仓库
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- \
  --token ghp_xxxxxxxxxxxx \
  --secrets-repo YOUR_USERNAME/docker-compose-secrets
```

### 方式三: 本地执行

```bash
# 下载脚本
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh -o bootstrap.sh
chmod +x bootstrap.sh

# 执行部署
./bootstrap.sh mysql redis nginx
```

## 📦 支持的服务

| 服务 | 命令 | 版本 | 说明 |
|------|------|------|------|
| MySQL | `mysql` | 8.0 | 关系型数据库 |
| PostgreSQL | `postgres` | 15 | 关系型数据库 |
| Redis | `redis` | 7.0 | 缓存/NoSQL |
| Nginx | `nginx` | alpine | 反向代理 |
| RabbitMQ | `rabbitmq` | 3.12 | 消息队列 |
| Nacos | `nacos` | 2.2 | 注册中心 |
| 全部 | `all` | - | 所有基础服务 |

## 🏗️ 项目结构

```
my-docker-compose/
├── bootstrap.sh             # ⭐ 一键部署脚本
├── docker-compose/          # Docker Compose 配置
│   ├── database/           # MySQL, PostgreSQL
│   ├── cache/              # Redis
│   ├── web-server/         # Nginx
│   └── middleware/         # RabbitMQ, Nacos
├── config/                 # 配置文件模板
├── secrets/                # 私有配置模板
│   └── templates/          # .env 文件模板
└── scripts/                # 辅助脚本


## 🔐 密码管理方案

### 方案说明

本项目采用 **HTTP 下载 + 私有仓库** 方案:

1. **主仓库 (公开)**: 存储 Docker Compose 配置、脚本、文档
2. **私有仓库**: 存储实际密码配置 (可选)
3. **GitHub Token**: 用于访问私有仓库

### 工作流程

```
bootstrap.sh 脚本
    │
    ├─> 下载公开配置 (无需认证)
    │   └─> docker-compose/*.yml
    │   └─> config/*
    │   └─> secrets/templates/*
    │
    ├─> 下载私有配置 (需要 Token)
    │   └─> secrets/*/.env.*
    │
    └─> 自动部署服务
```

### 设置私有配置仓库

#### 1. 创建私有仓库

```bash
# 在 GitHub 创建私有仓库
Repository name: docker-compose-secrets
Visibility: Private
```

#### 2. 添加密码配置文件

```bash
# 克隆私有仓库
git clone https://github.com/YOUR_USERNAME/docker-compose-secrets.git
cd docker-compose-secrets

# 创建配置文件
mkdir -p database cache middleware

# 添加 MySQL 密码
cat > database/.env.mysql << 'EOF'
MYSQL_ROOT_PASSWORD=your_strong_password_here
MYSQL_DATABASE=myapp
MYSQL_USER=appuser
MYSQL_PASSWORD=app_password_here
MYSQL_PORT=3306
EOF

# 添加 Redis 密码
cat > cache/.env.redis << 'EOF'
REDIS_PASSWORD=redis_password_here
REDIS_PORT=6379
EOF

# 提交
git add .
git commit -m "Add secrets"
git push
```

#### 3. 创建 GitHub Token

1. 访问 GitHub Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. 勾选 `repo` 权限
4. 复制 Token

#### 4. 使用 Token 部署

```bash
# 方式一: 环境变量
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash

# 方式二: 参数传递
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- --token ghp_xxxxxxxxxxxx
```

## 📋 常用命令

### 部署服务

```bash
# 部署所有基础服务
./bootstrap.sh all

# 部署单个服务
./bootstrap.sh mysql

# 部署多个服务
./bootstrap.sh mysql redis nginx

# 仅初始化,不部署
./bootstrap.sh --init

# 跳过下载,仅部署
./bootstrap.sh --deploy mysql
```

### 管理服务

```bash
# 查看服务状态
docker ps

# 查看日志
docker logs mysql
docker logs -f redis  # 实时查看

# 停止服务
docker-compose -f docker-compose/database/mysql.yml down

# 重启服务
docker restart mysql
```

### 备份数据

```bash
# 使用备份脚本
./scripts/backup.sh mysql
./scripts/backup.sh --all
```

## 🌐 服务访问

| 服务 | 地址 | 默认账号 |
|------|------|----------|
| MySQL | localhost:3306 | 见 secrets/database/.env.mysql |
| PostgreSQL | localhost:5432 | 见 secrets/database/.env.postgres |
| Redis | localhost:6379 | 见 secrets/cache/.env.redis |
| Nginx | http://localhost | - |
| RabbitMQ | http://localhost:15672 | admin / 见 secrets/.env.rabbitmq |
| Nacos | http://localhost:8848/nacos | nacos / nacos |

## 🔧 高级配置

### 自定义安装目录

```bash
# 方式一: 环境变量
export INSTALL_DIR=/opt/my-docker-env
./bootstrap.sh mysql

# 方式二: 参数
./bootstrap.sh --install-dir /opt/my-docker-env mysql
```

### 修改端口

```bash
# 编辑配置文件
vi ~/docker-compose-env/secrets/database/.env.mysql

# 修改端口
MYSQL_PORT=3307

# 重启服务
docker restart mysql
```

### 更新配置

```bash
# 重新下载最新配置
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- --init

# 或直接下载特定文件
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/docker-compose/database/mysql.yml \
  -o ~/docker-compose-env/docker-compose/database/mysql.yml
```

## 🆘 常见问题

### Q: 没有 Git 怎么办?

A: 完全不需要 Git! 本方案使用 HTTP 下载,只需要 curl 或 wget。

### Q: 如何访问私有仓库?

A: 创建 GitHub Personal Access Token 并设置 `GITHUB_TOKEN` 环境变量。

### Q: 密码存在哪里?

A: 
- 自动生成: `~/docker-compose-env/secrets/`
- 私有仓库: GitHub 私有仓库 (安全)

### Q: 如何修改密码?

A: 编辑 `~/docker-compose-env/secrets/database/.env.mysql` 等文件,然后重启服务。

### Q: 支持哪些操作系统?

A: Linux, macOS, Windows (WSL2)

## 📚 文档

- [快速开始](./QUICKSTART.md) - 5分钟快速部署
- [部署指南](./docs/deployment.md) - 详细部署说明
- [安全实践](./docs/security.md) - 安全最佳实践
- [高级用法](./docs/advanced-usage.md) - 集群、多环境等
- [故障排查](./docs/troubleshooting.md) - 常见问题解决
- [方案分析](./SCHEME_ANALYSIS.md) - 方案深度对比


## 💡 方案优势

### 对比传统方案

| 特性 | 传统方案 | 本方案 | 优势 |
|------|---------|--------|------|
| 依赖 Git | ✅ 必须 | ❌ 不需要 | 更轻量 |
| 部署步骤 | 多步操作 | 一行命令 | 效率提升 80% |
| 配置同步 | 手动管理 | 自动下载 | 零错误 |
| 新机器部署 | 30分钟+ | 1分钟 | 极速部署 |
| 密码管理 | 明文/占位符 | 私有仓库 | 更安全 |

### 适用场景

✅ **个人开发者** - 快速搭建开发环境  
✅ **小团队协作** - 统一环境配置  
✅ **CI/CD 集成** - 自动化部署  
✅ **临时环境** - 测试/演示环境  
✅ **多机器同步** - 工作电脑/服务器环境一致  

## 🔄 CI/CD 集成

### GitHub Actions

```yaml
name: Deploy Environment

on:
  workflow_dispatch:
    inputs:
      services:
        description: 'Services to deploy'
        required: true
        default: 'all'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy services
        env:
          GITHUB_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
        run: |
          curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | \
            bash -s -- ${{ inputs.services }}
```

### GitLab CI

```yaml
deploy:
  stage: deploy
  script:
    - curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- all
  only:
    - main
```
