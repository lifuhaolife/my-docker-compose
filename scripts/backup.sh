#!/bin/bash

# ============================================
# 数据备份脚本
# ============================================
# 功能: 备份数据库和重要配置

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backup"
DATE=$(date +%Y%m%d_%H%M%S)

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

# 创建备份目录
create_backup_dir() {
    mkdir -p "${BACKUP_DIR}/${DATE}"
    log_info "备份目录: ${BACKUP_DIR}/${DATE}"
}

# 备份 MySQL
backup_mysql() {
    log_info "备份 MySQL 数据库..."
    
    if ! docker ps | grep -q mysql; then
        log_error "MySQL 容器未运行"
        return 1
    fi
    
    # 读取密码
    if [ -f "${PROJECT_ROOT}/secrets/database/.env.mysql" ]; then
        source "${PROJECT_ROOT}/secrets/database/.env.mysql"
    else
        log_error "未找到 MySQL 配置文件"
        return 1
    fi
    
    # 执行备份
    docker exec mysql mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" --all-databases > \
        "${BACKUP_DIR}/${DATE}/mysql_all_databases.sql"
    
    if [ $? -eq 0 ]; then
        # 压缩备份文件
        gzip "${BACKUP_DIR}/${DATE}/mysql_all_databases.sql"
        log_success "MySQL 备份完成: mysql_all_databases.sql.gz"
    else
        log_error "MySQL 备份失败"
    fi
}

# 备份 PostgreSQL
backup_postgres() {
    log_info "备份 PostgreSQL 数据库..."
    
    if ! docker ps | grep -q postgres; then
        log_error "PostgreSQL 容器未运行"
        return 1
    fi
    
    # 读取密码
    if [ -f "${PROJECT_ROOT}/secrets/database/.env.postgres" ]; then
        source "${PROJECT_ROOT}/secrets/database/.env.postgres"
    else
        log_error "未找到 PostgreSQL 配置文件"
        return 1
    fi
    
    # 执行备份
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" postgres pg_dumpall -U postgres > \
        "${BACKUP_DIR}/${DATE}/postgres_all_databases.sql"
    
    if [ $? -eq 0 ]; then
        gzip "${BACKUP_DIR}/${DATE}/postgres_all_databases.sql"
        log_success "PostgreSQL 备份完成: postgres_all_databases.sql.gz"
    else
        log_error "PostgreSQL 备份失败"
    fi
}

# 备份 Redis
backup_redis() {
    log_info "备份 Redis 数据..."
    
    if ! docker ps | grep -q redis; then
        log_error "Redis 容器未运行"
        return 1
    fi
    
    # 触发 RDB 快照
    docker exec redis redis-cli BGSAVE
    
    # 等待快照完成
    sleep 2
    
    # 复制备份文件
    docker cp redis:/data/dump.rdb "${BACKUP_DIR}/${DATE}/redis_dump.rdb"
    
    if [ $? -eq 0 ]; then
        gzip "${BACKUP_DIR}/${DATE}/redis_dump.rdb"
        log_success "Redis 备份完成: redis_dump.rdb.gz"
    else
        log_error "Redis 备份失败"
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理旧备份文件 (保留最近7天)..."
    
    find "${BACKUP_DIR}" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
    
    log_success "清理完成"
}

# 显示备份列表
show_backup_list() {
    log_info "备份文件列表:"
    echo ""
    
    if [ -d "${BACKUP_DIR}" ]; then
        ls -lh "${BACKUP_DIR}" | tail -n +2
    else
        echo "暂无备份文件"
    fi
}

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [选项] [服务名...]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -a, --all      备份所有数据库"
    echo "  -l, --list     显示备份列表"
    echo "  -c, --clean    清理旧备份"
    echo ""
    echo "示例:"
    echo "  $0 mysql              # 备份 MySQL"
    echo "  $0 redis postgres     # 备份 Redis 和 PostgreSQL"
    echo "  $0 --all              # 备份所有数据库"
    echo "  $0 --list             # 显示备份列表"
}

# 主函数
main() {
    local backup_all=false
    local services=()
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                show_backup_list
                exit 0
                ;;
            -c|--clean)
                cleanup_old_backups
                exit 0
                ;;
            -a|--all)
                backup_all=true
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
    echo "   数据备份"
    echo "============================================"
    echo ""
    
    create_backup_dir
    
    # 如果指定了 --all,备份所有数据库
    if [ "$backup_all" = true ]; then
        backup_mysql || true
        backup_postgres || true
        backup_redis || true
    else
        # 备份指定的服务
        for service in "${services[@]}"; do
            case $service in
                mysql)
                    backup_mysql || true
                    ;;
                postgres|postgresql)
                    backup_postgres || true
                    ;;
                redis)
                    backup_redis || true
                    ;;
                *)
                    log_error "不支持的服务: $service"
                    ;;
            esac
        done
    fi
    
    echo ""
    log_success "备份完成"
    echo "备份位置: ${BACKUP_DIR}/${DATE}"
    echo "============================================"
}

# 执行主函数
main "$@"
