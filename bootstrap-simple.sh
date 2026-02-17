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

# 覆盖选项
FORCE_ALL=false
FORCE_SERVICE=""

# 下载统计
DOWNLOAD_SUCCESS=0
DOWNLOAD_FAILED=0
DOWNLOAD_EMPTY=0

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
    
    export COMPOSE_CMD
    
    # 检查 /opt 目录写权限
    if [ ! -w "/opt" ] && [ "$EUID" -ne 0 ]; then
        log_error "需要 root 权限或使用 sudo 执行脚本"
        log_info "使用方法: curl -fsSL https://... | sudo bash"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 下载文件（带校验）
download_file() {
    local url=$1
    local output=$2
    local force=$3
    
    # 检查文件是否存在且不强制覆盖
    if [ -f "$output" ] && [ "$force" != "true" ]; then
        log_warning "已存在（跳过）: $output"
        return 0
    fi
    
    # 创建父目录
    mkdir -p "$(dirname "$output")"
    
    # 下载文件
    local tmp_file="${output}.tmp"
    if command -v curl &> /dev/null; then
        curl -fsSL --connect-timeout 10 --max-time 30 "$url" -o "$tmp_file" 2>/dev/null
    else
        wget -q --timeout=10 "$url" -O "$tmp_file" 2>/dev/null
    fi
    
    # 校验文件是否为空
    if [ ! -f "$tmp_file" ]; then
        log_error "下载失败: $url"
        DOWNLOAD_FAILED=$((DOWNLOAD_FAILED + 1))
        return 1
    fi
    
    if [ ! -s "$tmp_file" ]; then
        log_error "文件为空: $url"
        rm -f "$tmp_file"
        DOWNLOAD_EMPTY=$((DOWNLOAD_EMPTY + 1))
        return 1
    fi
    
    # 移动到目标位置
    mv "$tmp_file" "$output"
    DOWNLOAD_SUCCESS=$((DOWNLOAD_SUCCESS + 1))
    return 0
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

# 服务对应的文件映射
declare -A SERVICE_FILES=(
    ["mysql"]="docker-compose/database/mysql.yml config/database/mysql/conf.d/my.cnf"
    ["postgresql"]="docker-compose/database/postgresql.yml config/database/postgresql/init"
    ["redis"]="docker-compose/cache/redis.yml config/cache/redis/redis.conf"
    ["nginx"]="docker-compose/web-server/nginx.yml config/web-server/nginx/nginx.conf config/web-server/nginx/conf.d/default.conf"
    ["rabbitmq"]="docker-compose/middleware/rabbitmq.yml config/middleware/rabbitmq"
    ["nacos"]="docker-compose/middleware/nacos.yml config/middleware/nacos/application.properties"
)

# 下载 Docker Compose 配置
download_configs() {
    log_info "下载配置文件..."
    
    # 重置统计
    DOWNLOAD_SUCCESS=0
    DOWNLOAD_FAILED=0
    DOWNLOAD_EMPTY=0
    
    # 判断是否只下载指定服务的配置
    if [ -n "$FORCE_SERVICE" ]; then
        download_service_configs "$FORCE_SERVICE"
    else
        download_all_configs
    fi
    
    # 输出统计
    echo ""
    log_info "下载统计: 成功=$DOWNLOAD_SUCCESS, 失败=$DOWNLOAD_FAILED, 空文件=$DOWNLOAD_EMPTY"
    
    if [ $DOWNLOAD_FAILED -gt 0 ] || [ $DOWNLOAD_EMPTY -gt 0 ]; then
        log_warning "部分文件下载失败，请检查网络连接"
        log_info "可以尝试: 1) 使用 --force 重新下载  2) 手动上传文件"
    fi
}

# 下载所有配置
download_all_configs() {
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
    
    log_info "下载 Docker Compose 文件..."
    for file in "${compose_files[@]}"; do
        local url="${BASE_URL}/${file}"
        local output="${INSTALL_DIR}/${file}"
        
        if download_file "$url" "$output" "$FORCE_ALL"; then
            log_success "下载: $file"
        fi
    done
    
    # 配置文件
    local config_files=(
        "config/database/mysql/conf.d/my.cnf"
        "config/cache/redis/redis.conf"
        "config/web-server/nginx/nginx.conf"
        "config/web-server/nginx/conf.d/default.conf"
        "config/middleware/nacos/application.properties"
        ".env.example"
    )
    
    log_info "下载服务配置文件..."
    for file in "${config_files[@]}"; do
        local url="${BASE_URL}/${file}"
        local output="${INSTALL_DIR}/${file}"
        
        if download_file "$url" "$output" "$FORCE_ALL"; then
            log_success "下载: $file"
        fi
    done
}

# 下载指定服务的配置
download_service_configs() {
    local service=$1
    
    if [ -z "${SERVICE_FILES[$service]}" ]; then
        log_error "未知服务: $service"
        log_info "支持的服务: mysql, postgresql, redis, nginx, rabbitmq, nacos"
        return 1
    fi
    
    log_info "下载 $service 相关配置..."
    
    # 下载 compose 文件
    local compose_file="docker-compose"
    case $service in
        mysql|postgresql) compose_file="docker-compose/database/${service}.yml" ;;
        redis) compose_file="docker-compose/cache/redis.yml" ;;
        nginx) compose_file="docker-compose/web-server/nginx.yml" ;;
        rabbitmq|nacos) compose_file="docker-compose/middleware/${service}.yml" ;;
    esac
    
    local url="${BASE_URL}/${compose_file}"
    local output="${INSTALL_DIR}/${compose_file}"
    
    if download_file "$url" "$output" "true"; then
        log_success "下载: $compose_file"
    fi
    
    # 下载配置文件
    for file in ${SERVICE_FILES[$service]}; do
        if [[ "$file" != docker-compose* ]]; then
            url="${BASE_URL}/${file}"
            output="${INSTALL_DIR}/${file}"
            
            if download_file "$url" "$output" "true"; then
                log_success "下载: $file"
            fi
        fi
    done
}

# 检查文件完整性
check_files() {
    log_info "检查文件完整性..."
    
    local empty_files=()
    local missing_files=()
    
    # 检查关键文件
    local check_files=(
        "docker-compose/database/mysql.yml"
        "docker-compose/cache/redis.yml"
        "config/cache/redis/redis.conf"
        ".env.example"
    )
    
    for file in "${check_files[@]}"; do
        local path="${INSTALL_DIR}/${file}"
        if [ ! -f "$path" ]; then
            missing_files+=("$file")
        elif [ ! -s "$path" ]; then
            empty_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        log_warning "缺失文件: ${missing_files[*]}"
    fi
    
    if [ ${#empty_files[@]} -gt 0 ]; then
        log_warning "空文件: ${empty_files[*]}"
    fi
    
    if [ ${#missing_files[@]} -eq 0 ] && [ ${#empty_files[@]} -eq 0 ]; then
        log_success "文件完整性检查通过"
        return 0
    else
        return 1
    fi
}

# 初始化环境变量
init_env() {
    log_info "初始化环境变量..."
    
    cd "$INSTALL_DIR"
    
    # 检查 .env.example 是否存在且不为空
    if [ ! -f ".env.example" ] || [ ! -s ".env.example" ]; then
        log_error ".env.example 文件不存在或为空"
        log_info "正在创建默认 .env.example ..."
        create_default_env_example
    fi
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        log_success "已创建 .env 文件"
        log_warning "请编辑 .env 文件设置密码: vi .env"
    else
        log_warning ".env 文件已存在，跳过创建"
        log_info "如需重置，请执行: cp .env.example .env"
    fi
}

# 创建默认 .env.example
create_default_env_example() {
    cat > "${INSTALL_DIR}/.env.example" << 'ENVEOF'
# ============================================
# MySQL 8.0 配置
# ============================================
MYSQL_ROOT_PASSWORD=your_mysql_root_password_here
MYSQL_DATABASE=myapp
MYSQL_USER=appuser
MYSQL_PASSWORD=your_mysql_app_password_here
MYSQL_PORT=3306

# ============================================
# PostgreSQL 15 配置
# ============================================
POSTGRES_PASSWORD=your_postgres_password_here
POSTGRES_DB=myapp
POSTGRES_USER=appuser
POSTGRES_PORT=5432

# ============================================
# Redis 7.0 配置
# ============================================
REDIS_PASSWORD=your_redis_password_here
REDIS_PORT=6379

# ============================================
# RabbitMQ 3.12 配置
# ============================================
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=your_rabbitmq_password_here
RABBITMQ_AMQP_PORT=5672
RABBITMQ_MGMT_PORT=15672

# ============================================
# Nacos 2.2 配置
# ============================================
NACOS_AUTH_ENABLE=true
NACOS_AUTH_TOKEN=SecretKey012345678901234567890123456789012345678901234567890123456789
NACOS_AUTH_IDENTITY_KEY=serverIdentity
NACOS_AUTH_IDENTITY_VALUE=security
NACOS_PORT=8848

# ============================================
# Nginx 配置
# ============================================
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

# ============================================
# 通用配置
# ============================================
TZ=Asia/Shanghai
ENVEOF
    
    log_success "已创建默认 .env.example"
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
    
    # 检查 .env 文件是否已修改
    if grep -q "your_mysql_root_password_here" .env 2>/dev/null; then
        log_warning ".env 文件包含默认密码，请先修改: vi .env"
        read -p "是否继续部署? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # 加载环境变量
    set -a
    source .env
    set +a
    
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
            # 检查文件是否为空
            if [ ! -s "$compose_file" ]; then
                log_error "配置文件为空: $compose_file"
                log_info "请使用 --force-service $service 重新下载"
                continue
            fi
            
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
    --force                 强制覆盖所有已存在的配置文件
    --force-service NAME    强制重新下载指定服务的配置 (mysql/redis/nginx/rabbitmq/nacos/postgresql)
    --check                 检查文件完整性

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

    # 强制重新下载所有配置
    curl -fsSL https://cdn.jsdelivr.net/gh/lifuhaolife/my-docker-compose@main/bootstrap-simple.sh | sudo bash -s -- --force

    # 只重新下载 MySQL 配置
    curl -fsSL https://cdn.jsdelivr.net/gh/lifuhaolife/my-docker-compose@main/bootstrap-simple.sh | sudo bash -s -- --force-service mysql

    # 检查文件完整性
    curl -fsSL https://cdn.jsdelivr.net/gh/lifuhaolife/my-docker-compose@main/bootstrap-simple.sh | sudo bash -s -- --check

    # 本地执行
    ./bootstrap-simple.sh mysql redis nginx
EOF
}

# 主函数
main() {
    local install_only=false
    local deploy_only=false
    local check_only=false
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
            --force)
                FORCE_ALL=true
                shift
                ;;
            --force-service)
                FORCE_SERVICE="$2"
                shift 2
                ;;
            --check)
                check_only=true
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
    
    # 仅检查文件
    if [ "$check_only" = true ]; then
        check_files
        exit $?
    fi
    
    if [ "$deploy_only" = false ]; then
        create_directories
        download_configs
        check_files || true
        init_env
    fi
    
    if [ "$install_only" = false ] && [ "$check_only" = false ]; then
        echo ""
        # 如果指定了服务参数，直接部署（适用于管道模式）
        if [ ${#services[@]} -gt 0 ]; then
            log_info "检测到服务参数，自动部署: ${services[*]}"
            deploy_services "${services[@]}"
        else
            # 交互模式，询问用户
            if [ -t 0 ]; then
                read -p "是否立即部署服务? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    deploy_services "mysql" "redis"
                else
                    log_info "稍后可以手动部署: cd $INSTALL_DIR && docker compose -f docker-compose/database/mysql.yml up -d"
                fi
            else
                log_info "管道模式未指定服务，跳过自动部署"
                log_info "手动部署命令: cd $INSTALL_DIR && docker compose -f docker-compose/database/mysql.yml up -d"
            fi
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
    echo "  2. 部署服务: docker compose -f docker-compose/database/mysql.yml up -d"
    echo "  3. 查看状态: docker ps"
    echo ""
    echo "故障排除:"
    echo "  - 重新下载配置: ./bootstrap-simple.sh --force"
    echo "  - 重置 .env: cp .env.example .env"
    echo "  - 检查文件: ./bootstrap-simple.sh --check"
    echo ""
    echo "============================================"
}

# 执行主函数
main "$@"
