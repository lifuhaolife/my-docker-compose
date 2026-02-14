#!/bin/bash

# ============================================
# 服务部署脚本
# ============================================
# 功能: 部署指定的服务或所有服务

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_DIR="${PROJECT_ROOT}/docker-compose"
SECRETS_DIR="${PROJECT_ROOT}/secrets"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 服务映射表
declare -A SERVICE_MAP=(
    ["mysql"]="database/mysql.yml"
    ["postgres"]="database/postgresql.yml"
    ["postgresql"]="database/postgresql.yml"
    ["redis"]="cache/redis.yml"
    ["nginx"]="web-server/nginx.yml"
    ["rabbitmq"]="middleware/rabbitmq.yml"
    ["nacos"]="middleware/nacos.yml"
)

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [选项] [服务名...]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -a, --all      部署所有基础服务"
    echo "  -l, --list     列出所有可用服务"
    echo "  -s, --status   显示服务状态"
    echo "  -d, --down     停止服务"
    echo "  -r, --restart  重启服务"
    echo ""
    echo "可用服务:"
    for service in "${!SERVICE_MAP[@]}"; do
        printf "  %-15s %s\n" "$service" "${SERVICE_MAP[$service]}"
    done | sort
    echo ""
    echo "示例:"
    echo "  $0 mysql              # 部署 MySQL"
    echo "  $0 redis nginx        # 部署 Redis 和 Nginx"
    echo "  $0 --all              # 部署所有基础服务"
    echo "  $0 --down mysql       # 停止 MySQL"
    echo "  $0 --status           # 查看服务状态"
}

# 列出所有服务
list_services() {
    echo "可用服务列表:"
    echo ""
    for service in "${!SERVICE_MAP[@]}"; do
        printf "  %-15s %s\n" "$service" "${SERVICE_MAP[$service]}"
    done | sort
}

# 检查服务配置
check_service_config() {
    local service=$1
    local compose_file="${COMPOSE_DIR}/${SERVICE_MAP[$service]}"
    
    if [ ! -f "$compose_file" ]; then
        log_error "配置文件不存在: $compose_file"
        return 1
    fi
    
    return 0
}

# 检查 secrets 配置
check_secrets() {
    if [ ! -d "${SECRETS_DIR}/.git" ] && [ ! -f "${SECRETS_DIR}/.git" ]; then
        log_error "Secrets submodule 未初始化,请先运行: ./scripts/setup.sh"
        return 1
    fi
}

# 部署服务
deploy_service() {
    local service=$1
    local compose_file="${COMPOSE_DIR}/${SERVICE_MAP[$service]}"
    
    log_info "部署服务: ${service}"
    
    if ! check_service_config "$service"; then
        return 1
    fi
    
    cd "${COMPOSE_DIR}"
    
    # 导出环境变量
    export SECRETS_DIR="${SECRETS_DIR}"
    
    # 加载通用环境变量
    if [ -f "${SECRETS_DIR}/.env.common" ]; then
        set -a
        source "${SECRETS_DIR}/.env.common"
        set +a
    fi
    
    # 启动服务
    docker-compose -f "$compose_file" up -d
    
    if [ $? -eq 0 ]; then
        log_success "${service} 部署成功"
        echo ""
        show_service_url "$service"
    else
        log_error "${service} 部署失败"
        return 1
    fi
}

# 停止服务
stop_service() {
    local service=$1
    local compose_file="${COMPOSE_DIR}/${SERVICE_MAP[$service]}"
    
    log_info "停止服务: ${service}"
    
    if ! check_service_config "$service"; then
        return 1
    fi
    
    cd "${COMPOSE_DIR}"
    docker-compose -f "$compose_file" down
    
    log_success "${service} 已停止"
}

# 重启服务
restart_service() {
    local service=$1
    local compose_file="${COMPOSE_DIR}/${SERVICE_MAP[$service]}"
    
    log_info "重启服务: ${service}"
    
    if ! check_service_config "$service"; then
        return 1
    fi
    
    cd "${COMPOSE_DIR}"
    
    export SECRETS_DIR="${SECRETS_DIR}"
    
    if [ -f "${SECRETS_DIR}/.env.common" ]; then
        set -a
        source "${SECRETS_DIR}/.env.common"
        set +a
    fi
    
    docker-compose -f "$compose_file" restart
    
    log_success "${service} 已重启"
}

# 显示服务状态
show_status() {
    log_info "服务状态:"
    echo ""
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# 显示服务访问地址
show_service_url() {
    local service=$1
    
    case $service in
        mysql)
            echo "访问地址: localhost:3306"
            echo "连接命令: mysql -h 127.0.0.1 -P 3306 -u root -p"
            ;;
        postgres|postgresql)
            echo "访问地址: localhost:5432"
            echo "连接命令: psql -h 127.0.0.1 -p 5432 -U postgres"
            ;;
        redis)
            echo "访问地址: localhost:6379"
            echo "连接命令: redis-cli -h 127.0.0.1 -p 6379 -a <password>"
            ;;
        nginx)
            echo "访问地址: http://localhost:80"
            ;;
        rabbitmq)
            echo "访问地址:"
            echo "  - AMQP: localhost:5672"
            echo "  - 管理界面: http://localhost:15672"
            ;;
        nacos)
            echo "访问地址: http://localhost:8848/nacos"
            echo "默认账号: nacos / nacos"
            ;;
    esac
    echo ""
}

# 部署所有基础服务
deploy_all() {
    log_info "部署所有基础服务..."
    
    local services=("mysql" "redis" "nginx")
    
    for service in "${services[@]}"; do
        deploy_service "$service"
        echo ""
    done
    
    log_success "所有基础服务部署完成"
    show_status
}

# 主函数
main() {
    local action="deploy"
    local services=()
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_services
                exit 0
                ;;
            -s|--status)
                show_status
                exit 0
                ;;
            -a|--all)
                check_secrets
                deploy_all
                exit 0
                ;;
            -d|--down)
                action="stop"
                shift
                ;;
            -r|--restart)
                action="restart"
                shift
                ;;
            *)
                services+=("$1")
                shift
                ;;
        esac
    done
    
    # 检查是否有服务参数
    if [ ${#services[@]} -eq 0 ]; then
        show_help
        exit 1
    fi
    
    # 检查 secrets
    if [ "$action" != "stop" ]; then
        check_secrets
    fi
    
    # 执行操作
    for service in "${services[@]}"; do
        if [ -n "${SERVICE_MAP[$service]}" ]; then
            case $action in
                deploy)
                    deploy_service "$service"
                    ;;
                stop)
                    stop_service "$service"
                    ;;
                restart)
                    restart_service "$service"
                    ;;
            esac
        else
            log_error "未知服务: $service"
        fi
    done
    
    echo ""
    show_status
}

# 执行主函数
main "$@"
