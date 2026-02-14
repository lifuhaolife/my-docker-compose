#!/bin/bash

# ============================================
# 密码生成脚本
# ============================================
# 功能: 为所有服务生成随机密码并替换占位符
# 使用: ./scripts/generate-passwords.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="${PROJECT_ROOT}/secrets"
TEMPLATES_DIR="${SECRETS_DIR}/templates"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# 生成随机密码
generate_password() {
    local length=${1:-32}
    # 生成强密码: 大小写字母+数字+特殊字符
    openssl rand -base64 48 | cut -c1-${length}
}

# 创建并填充密码
create_and_fill() {
    local template=$1
    local target=$2
    local service_name=$3
    
    if [ -f "$target" ]; then
        log_warning "$service_name 配置已存在: $target"
        read -p "是否覆盖? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    if [ ! -f "$template" ]; then
        log_error "模板不存在: $template"
        return 1
    fi
    
    # 复制模板
    cp "$template" "$target"
    
    # 替换密码占位符
    log_info "生成 $service_name 密码..."
    
    # 根据不同服务替换对应的占位符
    case $service_name in
        MySQL)
            sed -i.bak "s/CHANGE_ME_TO_STRONG_PASSWORD_123!/$(generate_password)/g" "$target"
            sed -i.bak "s/CHANGE_ME_APP_PASSWORD_456!/$(generate_password)/g" "$target"
            ;;
        PostgreSQL)
            sed -i.bak "s/CHANGE_ME_POSTGRES_PASSWORD!/$(generate_password)/g" "$target"
            sed -i.bak "s/CHANGE_ME_APP_PASSWORD!/$(generate_password)/g" "$target"
            ;;
        Redis)
            sed -i.bak "s/CHANGE_ME_REDIS_PASSWORD!/$(generate_password)/g" "$target"
            ;;
        RabbitMQ)
            sed -i.bak "s/CHANGE_ME_RABBITMQ_PASSWORD!/$(generate_password)/g" "$target"
            ;;
        Nacos)
            # Nacos 不需要随机密码,使用默认配置
            log_info "Nacos 使用默认配置"
            ;;
        *)
            log_warning "未知服务: $service_name"
            ;;
    esac
    
    # 删除备份文件
    rm -f "${target}.bak"
    
    log_success "$service_name 配置生成完成"
}

# 显示生成的密码信息
show_passwords() {
    echo ""
    echo "============================================"
    echo "🔐 生成的密码信息"
    echo "============================================"
    echo ""
    
    if [ -f "${SECRETS_DIR}/database/.env.mysql" ]; then
        echo "MySQL:"
        echo "  Root 密码: $(grep MYSQL_ROOT_PASSWORD ${SECRETS_DIR}/database/.env.mysql | cut -d'=' -f2)"
        echo "  App 密码:  $(grep '^MYSQL_PASSWORD=' ${SECRETS_DIR}/database/.env.mysql | cut -d'=' -f2)"
        echo ""
    fi
    
    if [ -f "${SECRETS_DIR}/database/.env.postgres" ]; then
        echo "PostgreSQL:"
        echo "  Root 密码: $(grep '^POSTGRES_PASSWORD=' ${SECRETS_DIR}/database/.env.postgres | cut -d'=' -f2)"
        echo "  App 密码:  $(grep 'POSTGRES_PASSWORD' ${SECRETS_DIR}/database/.env.postgres | tail -1 | cut -d'=' -f2)"
        echo ""
    fi
    
    if [ -f "${SECRETS_DIR}/cache/.env.redis" ]; then
        echo "Redis:"
        echo "  密码: $(grep REDIS_PASSWORD ${SECRETS_DIR}/cache/.env.redis | cut -d'=' -f2)"
        echo ""
    fi
    
    if [ -f "${SECRETS_DIR}/middleware/.env.rabbitmq" ]; then
        echo "RabbitMQ:"
        echo "  密码: $(grep RABBITMQ_DEFAULT_PASS ${SECRETS_DIR}/middleware/.env.rabbitmq | cut -d'=' -f2)"
        echo ""
    fi
    
    echo "============================================"
}

# 主函数
main() {
    echo ""
    echo "============================================"
    echo "   密码生成工具"
    echo "============================================"
    echo ""
    
    # 检查模板目录
    if [ ! -d "$TEMPLATES_DIR" ]; then
        log_error "模板目录不存在: $TEMPLATES_DIR"
        exit 1
    fi
    
    # 创建目标目录
    mkdir -p "${SECRETS_DIR}/database"
    mkdir -p "${SECRETS_DIR}/cache"
    mkdir -p "${SECRETS_DIR}/middleware"
    
    # 生成各服务密码
    create_and_fill "${TEMPLATES_DIR}/database/.env.mysql.example" \
                    "${SECRETS_DIR}/database/.env.mysql" "MySQL"
    
    create_and_fill "${TEMPLATES_DIR}/database/.env.postgres.example" \
                    "${SECRETS_DIR}/database/.env.postgres" "PostgreSQL"
    
    create_and_fill "${TEMPLATES_DIR}/cache/.env.redis.example" \
                    "${SECRETS_DIR}/cache/.env.redis" "Redis"
    
    create_and_fill "${TEMPLATES_DIR}/middleware/.env.rabbitmq.example" \
                    "${SECRETS_DIR}/middleware/.env.rabbitmq" "RabbitMQ"
    
    create_and_fill "${TEMPLATES_DIR}/middleware/.env.nacos.example" \
                    "${SECRETS_DIR}/middleware/.env.nacos" "Nacos"
    
    create_and_fill "${TEMPLATES_DIR}/.env.common.example" \
                    "${SECRETS_DIR}/.env.common" "Common"
    
    # 显示密码
    show_passwords
    
    echo ""
    log_success "所有密码生成完成!"
    echo ""
    echo "📁 配置文件位置: ${SECRETS_DIR}"
    echo ""
    echo "⚠️  重要提示:"
    echo "   1. 请妥善保管这些密码"
    echo "   2. 不要将 secrets/ 提交到公开仓库"
    echo "   3. 可以将 secrets/ 推送到私有仓库备份"
    echo ""
}

# 执行主函数
main "$@"
