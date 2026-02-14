#!/bin/bash

# ============================================
# Docker Compose 环境一键部署脚本
# ============================================
# 功能: 无需 Git,通过 HTTP 下载配置文件并部署
# 使用: curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/bootstrap.sh | bash

set -e

# 配置
GITHUB_USER="lifuhaolife"  # 替换为你的 GitHub 用户名
GITHUB_REPO="my-docker-compose"
GITHUB_BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

# 私有仓库配置 (使用 GitHub Personal Access Token)
# 方式1: 通过环境变量
# export GITHUB_TOKEN="ghp_xxxx"
# 方式2: 通过参数
# ./bootstrap.sh --token ghp_xxxx

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 安装目录
INSTALL_DIR="${INSTALL_DIR:-$HOME/docker-compose-env}"
SECRETS_DIR="${INSTALL_DIR}/secrets"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    # 检查 curl 或 wget
    if command -v curl &> /dev/null; then
        DOWNLOADER="curl"
    elif command -v wget &> /dev/null; then
        DOWNLOADER="wget"
    else
        log_error "需要 curl 或 wget,请先安装"
        exit 1
    fi
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    # 检查 Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 下载文件
download_file() {
    local url=$1
    local output=$2
    
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$url" -o "$output" 2>/dev/null
    else
        wget -q "$url" -O "$output" 2>/dev/null
    fi
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    return 0
}

# 下载文件 (支持私有仓库)
download_file_with_auth() {
    local url=$1
    local output=$2
    
    if [ -n "$GITHUB_TOKEN" ]; then
        # 私有仓库使用认证
        if [ "$DOWNLOADER" = "curl" ]; then
            curl -fsSL -H "Authorization: token ${GITHUB_TOKEN}" "$url" -o "$output" 2>/dev/null
        else
            wget -q --header "Authorization: token ${GITHUB_TOKEN}" "$url" -O "$output" 2>/dev/null
        fi
    else
        # 公开仓库
        download_file "$url" "$output"
    fi
    
    return $?
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "${INSTALL_DIR}/docker-compose/database"
    mkdir -p "${INSTALL_DIR}/docker-compose/cache"
    mkdir -p "${INSTALL_DIR}/docker-compose/web-server"
    mkdir -p "${INSTALL_DIR}/docker-compose/middleware"
    mkdir -p "${INSTALL_DIR}/config/database/mysql/conf.d"
    mkdir -p "${INSTALL_DIR}/config/database/postgresql"
    mkdir -p "${INSTALL_DIR}/config/cache/redis"
    mkdir -p "${INSTALL_DIR}/config/web-server/nginx/conf.d"
    mkdir -p "${INSTALL_DIR}/config/middleware"
    mkdir -p "${INSTALL_DIR}/secrets/database"
    mkdir -p "${INSTALL_DIR}/secrets/cache"
    mkdir -p "${INSTALL_DIR}/secrets/middleware"
    mkdir -p "${INSTALL_DIR}/logs"
    mkdir -p "${INSTALL_DIR}/volumes"
    
    log_success "目录创建完成: $INSTALL_DIR"
}

# 下载 Docker Compose 配置
download_compose_files() {
    log_info "下载 Docker Compose 配置..."
    
    local compose_files=(
        "docker-compose/database/mysql.yml"
        "docker-compose/database/postgresql.yml"
        "docker-compose/cache/redis.yml"
        "docker-compose/web-server/nginx.yml"
        "docker-compose/middleware/rabbitmq.yml"
        "docker-compose/middleware/nacos.yml"
        "docker-compose/all-in-one.yml"
    )
    
    for file in "${compose_files[@]}"; do
        local url="${BASE_URL}/${file}"
        local output="${INSTALL_DIR}/${file}"
        
        if download_file "$url" "$output"; then
            log_success "下载: $file"
        else
            log_warning "跳过: $file"
        fi
    done
}

# 下载配置文件
download_config_files() {
    log_info "下载配置文件..."
    
    local config_files=(
        "config/database/mysql/conf.d/my.cnf"
        "config/cache/redis/redis.conf"
        "config/web-server/nginx/nginx.conf"
        "config/web-server/nginx/conf.d/default.conf"
    )
    
    for file in "${config_files[@]}"; do
        local url="${BASE_URL}/${file}"
        local output="${INSTALL_DIR}/${file}"
        
        if download_file "$url" "$output"; then
            log_success "下载: $file"
        else
            log_warning "跳过: $file"
        fi
    done
}

# 下载 Secrets 模板
download_secrets_templates() {
    log_info "下载 Secrets 模板..."
    
    local template_files=(
        "secrets/templates/.env.common.example"
        "secrets/templates/database/.env.mysql.example"
        "secrets/templates/database/.env.postgres.example"
        "secrets/templates/cache/.env.redis.example"
        "secrets/templates/middleware/.env.rabbitmq.example"
        "secrets/templates/middleware/.env.nacos.example"
    )
    
    # 如果提供了 GitHub Token,尝试从私有仓库下载
    if [ -n "$GITHUB_TOKEN" ]; then
        log_info "检测到 GitHub Token,尝试从私有仓库下载 secrets..."
        
        local secrets_repo="${SECRETS_REPO:-${GITHUB_USER}/docker-compose-secrets}"
        local secrets_branch="${SECRETS_BRANCH:-main}"
        local secrets_base="https://raw.githubusercontent.com/${secrets_repo}/${secrets_branch}"
        
        # 尝试下载实际的 secrets 文件
        local secrets_files=(
            "database/.env.mysql"
            "database/.env.postgres"
            "cache/.env.redis"
            "middleware/.env.rabbitmq"
            "middleware/.env.nacos"
        )
        
        for file in "${secrets_files[@]}"; do
            local url="${secrets_base}/${file}"
            local output="${SECRETS_DIR}/${file}"
            
            if download_file_with_auth "$url" "$output"; then
                log_success "下载 secrets: $file"
            else
                log_warning "使用模板: $file"
            fi
        done
    fi
    
    # 始终下载模板
    for file in "${template_files[@]}"; do
        local url="${BASE_URL}/${file}"
        local output="${INSTALL_DIR}/${file}"
        
        if download_file "$url" "$output"; then
            log_success "下载模板: $file"
        fi
    done
}

# 生成随机密码
generate_password() {
    local length=${1:-32}
    openssl rand -base64 48 | cut -c1-${length}
}

# 初始化 Secrets 配置
init_secrets() {
    log_info "初始化 Secrets 配置..."
    
    # 复制模板到实际配置文件
    if [ ! -f "${SECRETS_DIR}/database/.env.mysql" ]; then
        if [ -f "${INSTALL_DIR}/secrets/templates/database/.env.mysql.example" ]; then
            cp "${INSTALL_DIR}/secrets/templates/database/.env.mysql.example" \
               "${SECRETS_DIR}/database/.env.mysql"
            
            # 自动生成密码
            sed -i "s/CHANGE_ME_TO_STRONG_PASSWORD_123!/$(generate_password)/g" \
                "${SECRETS_DIR}/database/.env.mysql"
            sed -i "s/CHANGE_ME_APP_PASSWORD_456!/$(generate_password)/g" \
                "${SECRETS_DIR}/database/.env.mysql"
            
            log_success "MySQL 配置初始化完成"
        fi
    fi
    
    if [ ! -f "${SECRETS_DIR}/database/.env.postgres" ]; then
        if [ -f "${INSTALL_DIR}/secrets/templates/database/.env.postgres.example" ]; then
            cp "${INSTALL_DIR}/secrets/templates/database/.env.postgres.example" \
               "${SECRETS_DIR}/database/.env.postgres"
            sed -i "s/CHANGE_ME_POSTGRES_PASSWORD!/$(generate_password)/g" \
                "${SECRETS_DIR}/database/.env.postgres"
            log_success "PostgreSQL 配置初始化完成"
        fi
    fi
    
    if [ ! -f "${SECRETS_DIR}/cache/.env.redis" ]; then
        if [ -f "${INSTALL_DIR}/secrets/templates/cache/.env.redis.example" ]; then
            cp "${INSTALL_DIR}/secrets/templates/cache/.env.redis.example" \
               "${SECRETS_DIR}/cache/.env.redis"
            sed -i "s/CHANGE_ME_REDIS_PASSWORD!/$(generate_password)/g" \
                "${SECRETS_DIR}/cache/.env.redis"
            log_success "Redis 配置初始化完成"
        fi
    fi
    
    # 其他服务...
    
    log_success "Secrets 配置初始化完成"
}

# 下载部署脚本
download_scripts() {
    log_info "下载部署脚本..."
    
    local scripts=(
        "scripts/deploy.sh"
        "scripts/backup.sh"
    )
    
    for file in "${scripts[@]}"; do
        local url="${BASE_URL}/${file}"
        local output="${INSTALL_DIR}/${file}"
        
        if download_file "$url" "$output"; then
            chmod +x "$output"
            log_success "下载脚本: $file"
        fi
    done
}

# 部署服务
deploy_services() {
    local services=("$@")
    
    log_info "部署服务: ${services[*]}"
    
    cd "$INSTALL_DIR"
    
    # 导出环境变量
    export SECRETS_DIR="${SECRETS_DIR}"
    export INSTALL_DIR="${INSTALL_DIR}"
    
    if [ ${#services[@]} -eq 0 ]; then
        # 默认部署基础服务
        services=("mysql" "redis" "nginx")
    fi
    
    for service in "${services[@]}"; do
        local compose_file=""
        
        case $service in
            mysql)
                compose_file="docker-compose/database/mysql.yml"
                ;;
            postgres|postgresql)
                compose_file="docker-compose/database/postgresql.yml"
                ;;
            redis)
                compose_file="docker-compose/cache/redis.yml"
                ;;
            nginx)
                compose_file="docker-compose/web-server/nginx.yml"
                ;;
            rabbitmq)
                compose_file="docker-compose/middleware/rabbitmq.yml"
                ;;
            nacos)
                compose_file="docker-compose/middleware/nacos.yml"
                ;;
            all)
                compose_file="docker-compose/all-in-one.yml"
                ;;
            *)
                log_error "未知服务: $service"
                continue
                ;;
        esac
        
        if [ -f "$compose_file" ]; then
            log_info "部署 $service..."
            docker-compose -f "$compose_file" up -d
            
            if [ $? -eq 0 ]; then
                log_success "$service 部署成功"
            else
                log_error "$service 部署失败"
            fi
        else
            log_error "配置文件不存在: $compose_file"
        fi
    done
}

# 显示帮助
show_help() {
    cat << EOF
使用方法:
    $0 [选项] [服务...]

选项:
    -h, --help              显示帮助信息
    -i, --install-dir DIR   指定安装目录 (默认: ~/docker-compose-env)
    -t, --token TOKEN       GitHub Personal Access Token (用于私有仓库)
    -s, --secrets-repo REPO 私有配置仓库 (格式: user/repo)
    --init                  仅初始化,不部署
    --deploy                跳过下载,仅部署

服务:
    mysql       MySQL 8.0
    postgres    PostgreSQL 15
    redis       Redis 7.0
    nginx       Nginx
    rabbitmq    RabbitMQ
    nacos       Nacos
    all         部署所有基础服务

示例:
    # 一键部署所有服务
    curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/bootstrap.sh | bash

    # 部署指定服务
    curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/bootstrap.sh | bash -s -- mysql redis

    # 使用私有仓库
    export GITHUB_TOKEN="ghp_xxxx"
    curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/bootstrap.sh | bash -s -- --secrets-repo USER/docker-compose-secrets

    # 指定安装目录
    ./bootstrap.sh --install-dir /opt/docker-env mysql redis

    # 仅初始化,不部署
    ./bootstrap.sh --init

    # 跳过下载,仅部署 (适合已下载的情况)
    ./bootstrap.sh --deploy mysql redis
EOF
}

# 主函数
main() {
    local install_only=false
    local deploy_only=false
    local services=()
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -t|--token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            -s|--secrets-repo)
                SECRETS_REPO="$2"
                shift 2
                ;;
            --init)
                install_only=true
                shift
                ;;
            --deploy)
                deploy_only=true
                shift
                ;;
            *)
                services+=("$1")
                shift
                ;;
        esac
    done
    
    echo ""
    echo "============================================"
    echo "   Docker Compose 环境一键部署"
    echo "============================================"
    echo ""
    
    check_dependencies
    
    if [ "$deploy_only" = false ]; then
        create_directories
        download_compose_files
        download_config_files
        download_secrets_templates
        download_scripts
        init_secrets
    fi
    
    if [ "$install_only" = false ]; then
        deploy_services "${services[@]}"
    fi
    
    echo ""
    echo "============================================"
    echo "🎉 部署完成!"
    echo "============================================"
    echo ""
    echo "📁 安装目录: $INSTALL_DIR"
    echo "🔐 配置目录: $SECRETS_DIR"
    echo ""
    echo "查看服务状态:"
    echo "  cd $INSTALL_DIR"
    echo "  docker-compose -f docker-compose/all-in-one.yml ps"
    echo ""
    echo "查看日志:"
    echo "  docker logs mysql"
    echo "  docker logs redis"
    echo ""
    echo "停止服务:"
    echo "  docker-compose -f docker-compose/all-in-one.yml down"
    echo "============================================"
}

# 执行主函数
main "$@"
