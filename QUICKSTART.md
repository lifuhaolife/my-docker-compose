# ⚡ 快速开始指南 (无需 Git)

> 1 分钟完成开发环境部署,无需安装 Git!

## 📋 前置条件

- ✅ Docker 已安装并运行
- ✅ Docker Compose 已安装
- ✅ curl 或 wget 可用
- ✅ (可选) GitHub Personal Access Token (用于私有仓库)

---

## 🚀 一键部署 (最简单)

### 部署所有基础服务

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash
```

就这么简单!脚本会自动:
1. ✅ 创建目录结构
2. ✅ 下载所有配置文件
3. ✅ 生成随机密码
4. ✅ 部署 MySQL + Redis + Nginx

---

## 🎯 指定服务部署

### 部署单个服务

```bash
# MySQL
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- mysql

# Redis
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- redis

# Nginx
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- nginx
```

### 部署多个服务

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- mysql redis nginx
```

---

## 🔐 使用私有配置 (生产环境推荐)

### 步骤 1: 创建私有仓库

1. 访问 GitHub → New repository
2. Repository name: `docker-compose-secrets`
3. Visibility: **Private**
4. 不要勾选 README

### 步骤 2: 添加配置文件

```bash
# 克隆私有仓库
git clone https://github.com/YOUR_USERNAME/docker-compose-secrets.git
cd docker-compose-secrets

# 创建 MySQL 配置
mkdir -p database
cat > database/.env.mysql << 'EOF'
MYSQL_ROOT_PASSWORD=your_strong_password_here
MYSQL_DATABASE=myapp
MYSQL_USER=appuser
MYSQL_PASSWORD=app_password_here
MYSQL_PORT=3306
EOF

# 创建 Redis 配置
mkdir -p cache
cat > cache/.env.redis << 'EOF'
REDIS_PASSWORD=redis_password_here
REDIS_PORT=6379
EOF

# 提交
git add .
git commit -m "Add secrets"
git push
```

### 步骤 3: 创建 GitHub Token

1. GitHub Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. 勾选 `repo` 权限
4. 复制生成的 Token

### 步骤 4: 使用 Token 部署

```bash
# 方式一: 环境变量
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash

# 方式二: 参数传递
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | \
  bash -s -- --token ghp_xxxxxxxxxxxx --secrets-repo YOUR_USERNAME/docker-compose-secrets
```

---

## 📁 安装目录

默认安装到 `~/docker-compose-env/`,可以自定义:

```bash
# 自定义安装目录
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | \
  bash -s -- --install-dir /opt/my-env mysql redis
```

### 目录结构

```
~/docker-compose-env/
├── docker-compose/       # Docker Compose 配置
│   ├── database/        # MySQL, PostgreSQL
│   ├── cache/           # Redis
│   ├── web-server/      # Nginx
│   └── middleware/      # RabbitMQ, Nacos
├── config/              # 服务配置文件
├── secrets/             # 密码配置
│   ├── database/       # 数据库密码
│   ├── cache/          # 缓存密码
│   └── middleware/     # 中间件密码
├── logs/                # 日志目录
└── volumes/             # 数据持久化
```

---

## ✅ 验证部署

### 查看服务状态

```bash
docker ps
```

输出示例:
```
CONTAINER ID   IMAGE          STATUS          PORTS                    NAMES
abc123         mysql:8.0      Up 2 minutes    0.0.0.0:3306->3306/tcp   mysql
def456         redis:7.0      Up 2 minutes    0.0.0.0:6379->6379/tcp   redis
ghi789         nginx:alpine   Up 2 minutes    0.0.0.0:80->80/tcp       nginx
```

### 测试连接

#### MySQL

```bash
# 查看密码
cat ~/docker-compose-env/secrets/database/.env.mysql

# 连接测试
docker exec mysql mysql -u root -p -e "SELECT VERSION();"
```

#### Redis

```bash
# 查看密码
cat ~/docker-compose-env/secrets/cache/.env.redis

# 连接测试
docker exec redis redis-cli -a YOUR_PASSWORD ping
```

#### Nginx

```bash
# 访问测试
curl http://localhost

# 或浏览器访问
open http://localhost  # macOS
xdg-open http://localhost  # Linux
```

---

## 🔧 管理服务

### 查看日志

```bash
# 查看所有日志
docker logs mysql

# 实时查看
docker logs -f redis

# 查看最近 100 行
docker logs --tail 100 nginx
```

### 停止服务

```bash
# 停止单个服务
docker stop mysql

# 停止所有服务
cd ~/docker-compose-env
docker-compose -f docker-compose/all-in-one.yml down
```

### 重启服务

```bash
# 重启单个服务
docker restart mysql

# 重启多个服务
docker restart mysql redis nginx
```

### 删除服务 (数据保留)

```bash
docker rm -f mysql redis nginx
```

---

## 🔄 更新配置

### 从 GitHub 更新

```bash
# 重新下载最新配置
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | \
  bash -s -- --init
```

### 从私有仓库更新

```bash
# 使用 Token 更新私有配置
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | \
  bash -s -- --token ghp_xxxxxxxxxxxx --secrets-repo YOUR_USERNAME/docker-compose-secrets
```

### 手动修改配置

```bash
# 编辑配置文件
vi ~/docker-compose-env/secrets/database/.env.mysql

# 重启服务使配置生效
docker restart mysql
```

---

## 💾 数据备份

### 自动备份

```bash
cd ~/docker-compose-env
./scripts/backup.sh mysql
./scripts/backup.sh --all
```

### 手动备份

```bash
# MySQL
docker exec mysql mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" --all-databases > backup.sql

# Redis
docker exec redis redis-cli BGSAVE
docker cp redis:/data/dump.rdb backup.rdb
```

---

## 🆘 常见问题

### Q: 提示 "curl: command not found"?

A: 安装 curl:
```bash
# Ubuntu/Debian
sudo apt-get install curl

# CentOS/RHEL
sudo yum install curl

# macOS (通常已安装)
brew install curl
```

### Q: Docker 未安装?

A: 安装 Docker:
```bash
# Linux
curl -fsSL https://get.docker.com | bash

# macOS/Windows
# 下载安装 Docker Desktop
```

### Q: 端口被占用?

A: 修改配置中的端口:
```bash
vi ~/docker-compose-env/secrets/database/.env.mysql
# 修改 MYSQL_PORT=3307
docker restart mysql
```

### Q: 忘记密码?

A: 查看配置文件:
```bash
cat ~/docker-compose-env/secrets/database/.env.mysql
cat ~/docker-compose-env/secrets/cache/.env.redis
```

### Q: 如何完全卸载?

A: 删除安装目录和容器:
```bash
# 停止并删除容器
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# 删除安装目录
rm -rf ~/docker-compose-env
```

---

## 📚 下一步

- 📖 查看 [完整文档](./README.md)
- 🔐 了解 [安全最佳实践](./docs/security.md)
- 🚀 探索 [高级用法](./docs/advanced-usage.md)
- 🐛 [故障排查](./docs/troubleshooting.md)

---

## 💡 提示

### 开发环境

当前配置适用于开发环境,服务绑定到 `0.0.0.0`,可以从任何地方访问。

### 生产环境

对于生产环境,建议:
1. ✅ 使用私有仓库存储密码
2. ✅ 修改端口绑定到 `127.0.0.1`
3. ✅ 配置防火墙规则
4. ✅ 使用强密码

---

**🎉 开始享受一键部署的便捷吧!**
