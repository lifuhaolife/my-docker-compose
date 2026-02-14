# HTTP 下载部署方案详解

## 📋 概述

本文档详细说明如何通过 HTTP 下载方式实现零 Git 依赖的一键部署方案。

---

## 🏗️ 架构设计

### 整体架构

```
┌─────────────────┐
│   用户机器       │
│                 │
│  curl/wget      │
│     ↓           │
│ bootstrap.sh    │
│     ↓           │
│ Docker Compose  │
└─────────────────┘
        │
        │ HTTP 下载
        ↓
┌─────────────────┐         ┌─────────────────┐
│ GitHub 公开仓库  │         │ GitHub 私有仓库  │
│                 │         │                 │
│ • docker-compose│         │ • .env.mysql    │
│ • config        │         │ • .env.redis    │
│ • templates     │         │ • .env.*        │
│ • bootstrap.sh  │         │                 │
└─────────────────┘         └─────────────────┘
        │                           │
        │ 公开访问                   │ Token 认证
        ↓                           ↓
    无需认证                  需要设置 Token
```

### 文件组织

```
GitHub 公开仓库:
├── bootstrap.sh              # 一键部署脚本
├── docker-compose/           # Docker Compose 配置
│   ├── database/
│   │   ├── mysql.yml
│   │   └── postgresql.yml
│   ├── cache/
│   │   └── redis.yml
│   └── all-in-one.yml
├── config/                   # 服务配置文件
│   ├── database/mysql/conf.d/my.cnf
│   └── cache/redis/redis.conf
└── secrets/                  # 配置模板
    └── templates/
        ├── database/.env.mysql.example
        └── cache/.env.redis.example

GitHub 私有仓库:
├── database/
│   ├── .env.mysql           # MySQL 实际密码
│   └── .env.postgres        # PostgreSQL 实际密码
├── cache/
│   └── .env.redis           # Redis 实际密码
└── middleware/
    ├── .env.rabbitmq        # RabbitMQ 实际密码
    └── .env.nacos           # Nacos 实际密码
```

---

## 🔧 技术实现

### 1. 文件下载

#### 公开文件下载

```bash
# 使用 curl
curl -fsSL https://raw.githubusercontent.com/USER/REPO/BRANCH/FILE -o OUTPUT

# 使用 wget
wget -q https://raw.githubusercontent.com/USER/REPO/BRANCH/FILE -O OUTPUT

# 参数说明
# -f: 失败时不输出错误
# -s: 静默模式
# -S: 显示错误信息
# -L: 跟随重定向
# -o/-O: 输出文件
```

#### 私有文件下载 (需要认证)

```bash
# 使用 curl + Token
curl -fsSL \
  -H "Authorization: token ghp_xxxxxxxxxxxx" \
  https://raw.githubusercontent.com/USER/PRIVATE-REPO/BRANCH/FILE \
  -o OUTPUT

# 使用 wget + Token
wget -q \
  --header="Authorization: token ghp_xxxxxxxxxxxx" \
  https://raw.githubusercontent.com/USER/PRIVATE-REPO/BRANCH/FILE \
  -O OUTPUT
```

### 2. GitHub API 访问

#### 获取文件内容

```bash
# API 端点
# GET https://api.github.com/repos/:owner/:repo/contents/:path

# 示例: 获取文件
curl -H "Authorization: token ghp_xxx" \
  https://api.github.com/repos/user/repo/contents/secrets/database/.env.mysql

# 返回 JSON,需要解码 base64
```

#### 使用 Raw 文件 (推荐)

```bash
# Raw 文件更简单,直接返回内容
curl -H "Authorization: token ghp_xxx" \
  https://raw.githubusercontent.com/user/repo/main/secrets/database/.env.mysql
```

### 3. 密码自动生成

```bash
# 生成强密码 (32位)
generate_password() {
    local length=${1:-32}
    openssl rand -base64 48 | cut -c1-${length}
}

# 使用
password=$(generate_password)
echo "Generated password: $password"
```

---

## 🚀 部署流程

### 标准流程

```bash
# 1. 检查依赖
check_dependencies() {
    # 检查 curl/wget
    # 检查 Docker
    # 检查 Docker Compose
}

# 2. 创建目录
create_directories() {
    mkdir -p ~/docker-compose-env/{docker-compose,config,secrets,logs,volumes}
}

# 3. 下载公开配置
download_public_configs() {
    # 下载 docker-compose/*.yml
    # 下载 config/*
    # 下载 secrets/templates/*
}

# 4. 下载私有配置 (可选)
download_private_secrets() {
    if [ -n "$GITHUB_TOKEN" ]; then
        # 下载 secrets/*/.env.*
    else
        # 使用模板 + 自动生成密码
    fi
}

# 5. 部署服务
deploy_services() {
    docker-compose -f docker-compose/database/mysql.yml up -d
}
```

### 完整示例

```bash
#!/bin/bash
# 一键部署脚本

# 配置
GITHUB_USER="yourusername"
GITHUB_REPO="my-docker-compose"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main"

# 安装目录
INSTALL_DIR="${INSTALL_DIR:-$HOME/docker-compose-env}"

# 下载文件函数
download() {
    local url=$1
    local output=$2
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget &> /dev/null; then
        wget -q "$url" -O "$output"
    fi
}

# 主流程
main() {
    # 1. 创建目录
    mkdir -p "$INSTALL_DIR"
    
    # 2. 下载配置
    download "${BASE_URL}/docker-compose/database/mysql.yml" \
             "${INSTALL_DIR}/docker-compose/database/mysql.yml"
    
    # 3. 部署
    cd "$INSTALL_DIR"
    docker-compose -f docker-compose/database/mysql.yml up -d
}

main
```

---

## 🔐 安全最佳实践

### 1. Token 管理

```bash
# ❌ 不要硬编码 Token
GITHUB_TOKEN="ghp_xxx"  # 错误!

# ✅ 使用环境变量
export GITHUB_TOKEN="ghp_xxx"

# ✅ 使用参数传递
./bootstrap.sh --token ghp_xxx

# ✅ 存储在配置文件 (权限 600)
echo "GITHUB_TOKEN=ghp_xxx" > ~/.docker-compose-token
chmod 600 ~/.docker-compose-token
source ~/.docker-compose-token
```

### 2. Token 权限

创建 Token 时仅需最小权限:

```
✅ repo - 访问私有仓库
❌ 其他权限不需要勾选
```

### 3. 密码强度

```bash
# ✅ 强密码示例
MYSQL_ROOT_PASSWORD=Xk9#mP2$vL7@nQ4!wR8%

# ❌ 弱密码示例
MYSQL_ROOT_PASSWORD=root
MYSQL_ROOT_PASSWORD=123456
MYSQL_ROOT_PASSWORD=password
```

### 4. 网络安全

```yaml
# docker-compose.yml
services:
  mysql:
    ports:
      # ✅ 仅本地访问 (生产环境)
      - "127.0.0.1:3306:3306"
      
      # ❌ 所有接口访问 (仅开发环境)
      # - "3306:3306"
```

---

## 📊 性能优化

### 1. 并行下载

```bash
# 使用后台进程并行下载
download_parallel() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        (
            url="${BASE_URL}/${file}"
            output="${INSTALL_DIR}/${file}"
            download "$url" "$output"
        ) &
    done
    
    wait  # 等待所有下载完成
}
```

### 2. 缓存机制

```bash
# 检查文件是否已存在且未过期
download_with_cache() {
    local url=$1
    local output=$2
    local cache_time=${3:-86400}  # 默认缓存1天
    
    if [ -f "$output" ]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$output" 2>/dev/null || echo 0)))
        
        if [ $file_age -lt $cache_time ]; then
            echo "使用缓存: $output"
            return 0
        fi
    fi
    
    download "$url" "$output"
}
```

### 3. 断点续传

```bash
# 使用 wget 的断点续传
wget -c "$url" -O "$output"

# 使用 curl 的断点续传
curl -C - -o "$output" "$url"
```

---

## 🔄 更新策略

### 1. 全量更新

```bash
# 重新下载所有配置
./bootstrap.sh --init
```

### 2. 增量更新

```bash
# 仅更新特定服务
curl -fsSL ${BASE_URL}/docker-compose/database/mysql.yml \
  -o ~/docker-compose-env/docker-compose/database/mysql.yml
docker restart mysql
```

### 3. 版本管理

```bash
# 使用 Git 管理本地配置
cd ~/docker-compose-env
git init
git add .
git commit -m "Update configs"

# 更新前备份
git stash
./bootstrap.sh --init
git stash pop
```

---

## 🐛 故障排查

### 下载失败

```bash
# 测试网络连接
curl -I https://raw.githubusercontent.com

# 测试文件是否存在
curl -I ${BASE_URL}/docker-compose/database/mysql.yml

# 使用详细模式
curl -v ${BASE_URL}/docker-compose/database/mysql.yml -o mysql.yml
```

### Token 无效

```bash
# 验证 Token
curl -H "Authorization: token ghp_xxx" \
  https://api.github.com/user

# 检查 Token 权限
curl -H "Authorization: token ghp_xxx" \
  https://api.github.com/user/repos
```

### 权限问题

```bash
# 检查目录权限
ls -la ~/docker-compose-env

# 修复权限
chmod 755 ~/docker-compose-env
chmod 600 ~/docker-compose-env/secrets/*/.env.*
```

---

## 📚 相关文档

- [快速开始](../QUICKSTART.md)
- [部署指南](../docs/deployment.md)
- [安全实践](../docs/security.md)
- [方案分析](../SCHEME_ANALYSIS.md)
