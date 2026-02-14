#!/bin/bash

# ============================================
# bootstrap.sh 配置示例
# ============================================
# 请根据你的实际情况修改以下配置

# ============================================
# 必填配置
# ============================================

# 你的 GitHub 用户名
GITHUB_USER="yourusername"

# 你的 GitHub 仓库名
GITHUB_REPO="my-docker-compose"

# 分支名称 (默认 main)
GITHUB_BRANCH="main"

# ============================================
# 可选配置
# ============================================

# 私有配置仓库 (如果使用私有仓库)
# 格式: username/repo
# SECRETS_REPO="yourusername/docker-compose-secrets"
# SECRETS_BRANCH="main"

# 安装目录 (默认 ~/docker-compose-env)
# INSTALL_DIR="$HOME/docker-compose-env"

# GitHub Token (用于访问私有仓库)
# 方式一: 环境变量
# export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
#
# 方式二: 参数传递
# ./bootstrap.sh --token ghp_xxxxxxxxxxxx

# ============================================
# 如何获取 GitHub Token
# ============================================
# 1. 访问 https://github.com/settings/tokens
# 2. Generate new token (classic)
# 3. 勾选权限:
#    - repo (Full control of private repositories)
# 4. 复制生成的 Token
# 5. 设置环境变量:
#    export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# ============================================
# 如何创建私有配置仓库
# ============================================
# 1. 创建私有仓库
#    - 访问 https://github.com/new
#    - Repository name: docker-compose-secrets
#    - Description: Docker Compose secrets storage
#    - Visibility: Private
#    - 不要勾选 README、.gitignore、license
#
# 2. 添加配置文件
#    git clone https://github.com/YOUR_USERNAME/docker-compose-secrets.git
#    cd docker-compose-secrets
#
#    # MySQL 配置
#    mkdir -p database
#    cat > database/.env.mysql << 'EOF'
#    MYSQL_ROOT_PASSWORD=your_strong_password_here
#    MYSQL_DATABASE=myapp
#    MYSQL_USER=appuser
#    MYSQL_PASSWORD=app_password_here
#    MYSQL_PORT=3306
#    EOF
#
#    # Redis 配置
#    mkdir -p cache
#    cat > cache/.env.redis << 'EOF'
#    REDIS_PASSWORD=redis_password_here
#    REDIS_PORT=6379
#    EOF
#
#    # 提交
#    git add .
#    git commit -m "Add secrets configuration"
#    git push origin main

# ============================================
# 使用示例
# ============================================

# 示例 1: 一键部署所有服务 (公开配置)
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash

# 示例 2: 部署指定服务
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- mysql redis

# 示例 3: 使用私有配置
# export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash

# 示例 4: 指定安装目录
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- --install-dir /opt/docker-env

# 示例 5: 仅初始化,不部署
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- --init

# 示例 6: 跳过下载,仅部署
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose/main/bootstrap.sh | bash -s -- --deploy mysql redis
