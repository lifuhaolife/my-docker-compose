#!/bin/bash

# ============================================
# Docker Compose 简化部署脚本
# ============================================
# 功能: 通过 HTTP 下载配置文件并部署
# 使用: curl -fsSL https://cdn.jsdelivr.net/gh/USER/REPO@main/bootstrap-simple.sh | bash

set -e

# 配置
GITHUB_USER="lifuhaolife"
GITHUB_REPO="my-docker-compose"
GITHUB_BRANCH="main"
BASE_URL="https://cdn.jsdelivr.net/gh/${GITHUB_USER}/${GITHUB_REPO}@${GITHUB_BRANCH}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 安装目录（统一部署到 /opt/docker-containers）
INSTALL_DIR="${INSTALL_DIR:-/opt/docker-containers}"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        log_error "需要 curl 或 wget"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    # 检查 Docker Compose（支持 V1 和 V2）
    COMPOSE_CMD=""
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
        log_success "检测到 Docker Compose V2"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
        log_success "检测到 Docker Compose V1"
    else
        log_error "Docker Compose 未安装"
        log_info "安装方法:"
        log_info "  V2: curl -fsSL https://get.docker.com | bash"
        log_info "  V1: sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose"
        exit 1
    fi
    
    # 导出 COMPOSE_CMD 供其他函数使用
    export COMPOSE_CMD
    
    # 检查 /opt 目录写权限
    if [ ! -w "/opt" ] && [ "$EUID" -ne 0 ]; then
        log_error "需要 root 权限或使用 sudo 执行脚本"
        log_info "使用方法: curl -fsSL https://... | sudo bash"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 下载文件
download_file() {
    local url=$1
    local output=$2
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$output" 2>/dev/null
    else
        wget -q "$url" -O "$output" 2>/dev/null
    fi
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
    mkdir -p "${INSTALL_DIR}/config/database/mysql/init"
    mkdir -p "${INSTALL_DIR}/config/database/postgresql/init"
    mkdir -p "${INSTALL_DIR}/config/cache/redis"
    mkdir -p "${INSTALL_DIR}/config/web-server/nginx/conf.d"
    mkdir -p "${INSTALL_DIR}/config/web-server/nginx/ssl"
    mkdir -p "${INSTALL_DIR}/config/middleware/rabbitmq"
    mkdir -p "${INSTALL_DIR}/config/middleware/nacos"
    mkdir -p "${INSTALL_DIR}/logs/mysql"
    mkdir -p "${INSTALL_DIR}/logs/redis"
    mkdir -p "${INSTALL_DIR}/logs/postgresql"
    mkdir -p "${INSTALL_DIR}/logs/nginx"
    mkdir -p "${INSTALL_DIR}/logs/rabbitmq"
    mkdir -p "${INSTALL_DIR}/logs/nacos"
    mkdir -p "${INSTALL_DIR}/volumes"
    
    log_success "目录创建完成: $INSTALL_DIR"
}

# 下载 Docker Compose 配置
download_configs() {
    log_info "下载配置文件..."
    
    # Docker Compose 文件
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
    
    # 配置文件
    local config_files=(
        "config/database/mysql/conf.d/my.cnf"
        "config/cache/redis/redis.conf"
        "config/web-server/nginx/nginx.conf"
        "config/web-server/nginx/conf.d/default.conf"
        ".env.example"
    )
    
    for file in "${config_files[@]}"; do
        local url="${BASE_URL}/${file}"
        local output="${INSTALL_DIR}/${file}"
        
        if download_file "$url" "$output"; then
            log_success "下载: $file"
        fi
    done
}

# 初始化环境变量
init_env() {
    log_info "初始化环境变量..."
    
    cd "$INSTALL_DIR"
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            log_success "已创建 .env 文件"
            log_warning "请编辑 .env 文件设置密码: vi .env"
        else
            log_error ".env.example 不存在"
            exit 1
        fi
    else
        log_warning ".env 文件已存在，跳过创建"
    fi
}

# 部署服务
deploy_services() {
    local services=("$@")
    
    log_info "部署服务: ${services[*]}"
    
    cd "$INSTALL_DIR"
    
    # 检查 .env 文件
    if [ ! -f ".env" ]; then
        log_error ".env 文件不存在，请先运行: cp .env.example .env"
        exit 1
    fi
    
    # 加载环境变量
    export $(cat .env | grep -v '^#' | xargs)
    
    if [ ${#services[@]} -eq 0 ]; then
        services=("mysql" "redis")
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
            $COMPOSE_CMD -f "$compose_file" up -d
            
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
    -i, --install-dir DIR   指定安装目录 (默认: /opt/docker-containers)
    --init                  仅初始化，不部署
    --deploy                跳过下载，仅部署

服务:
    mysql       MySQL 8.0
    postgres    PostgreSQL 15
    redis       Redis 7.0
    nginx       Nginx
    rabbitmq    RabbitMQ
    nacos       Nacos
    all         部署所有服务

示例:
    # 一键部署
    curl -fsSL https://cdn.jsdelivr.net/gh/lifuhaolife/my-docker-compose@main/bootstrap-simple.sh | sudo bash

    # 部署指定服务
    curl -fsSL https://cdn.jsdelivr.net/gh/lifuhaolife/my-docker-compose@main/bootstrap-simple.sh | sudo bash -s -- mysql redis

    # 本地执行
    ./bootstrap-simple.sh mysql redis nginx
EOF
}

# 主函数
main() {
    local install_only=false
    local deploy_only=false
    local services=()
    
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
    echo "   Docker Compose 简化部署"
    echo "============================================"
    echo ""
    
    check_dependencies
    
    if [ "$deploy_only" = false ]; then
        create_directories
        download_configs
        init_env
    fi
    
    if [ "$install_only" = false ]; then
        echo ""
        read -p "是否立即部署服务? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            deploy_services "${services[@]}"
        else
            log_info "稍后可以手动部署: cd $INSTALL_DIR && docker-compose -f docker-compose/database/mysql.yml up -d"
        fi
    fi
    
    echo ""
    echo "============================================"
    echo "🎉 初始化完成!"
    echo "============================================"
    echo ""
    echo "📁 安装目录: $INSTALL_DIR"
    echo "📝 配置文件: $INSTALL_DIR/.env"
    echo ""
    echo "下一步操作:"
    echo "  1. 编辑环境变量: cd $INSTALL_DIR && vi .env"
    echo "  2. 部署服务: docker-compose -f docker-compose/database/mysql.yml up -d"
    echo "  3. 查看状态: docker ps"
    echo ""
    echo "============================================"
}

# 执行主函数
main "$@"
