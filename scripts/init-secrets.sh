#!/bin/bash

# ============================================
# Secrets 初始化脚本
# ============================================
# 功能: 从模板创建 secrets 配置文件

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
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 生成随机密码
generate_password() {
    local length=${1:-32}
    openssl rand -base64 48 | cut -c1-${length}
}

# 创建配置文件
create_config() {
    local template_file=$1
    local target_file=$2
    
    if [ -f "$target_file" ]; then
        log_warning "${target_file} 已存在,跳过"
        return 0
    fi
    
    if [ ! -f "$template_file" ]; then
        log_error "模板文件不存在: $template_file"
        return 1
    fi
    
    mkdir -p "$(dirname "$target_file")"
    cp "$template_file" "$target_file"
    
    log_success "创建配置文件: $target_file"
}

# 自动填充密码
auto_fill_passwords() {
    local target_file=$1
    
    log_info "自动生成密码..."
    
    # 替换所有 CHANGE_ME_... 为随机密码
    sed -i.bak "s/CHANGE_ME_TO_STRONG_PASSWORD_123!/$(generate_password)/g" "$target_file"
    sed -i.bak "s/CHANGE_ME_APP_PASSWORD_456!/$(generate_password)/g" "$target_file"
    sed -i.bak "s/CHANGE_ME_APP_PASSWORD!/$(generate_password)/g" "$target_file"
    sed -i.bak "s/CHANGE_ME_POSTGRES_PASSWORD!/$(generate_password)/g" "$target_file"
    sed -i.bak "s/CHANGE_ME_REDIS_PASSWORD!/$(generate_password)/g" "$target_file"
    sed -i.bak "s/CHANGE_ME_RABBITMQ_PASSWORD!/$(generate_password)/g" "$target_file"
    
    # 删除备份文件
    rm -f "${target_file}.bak"
    
    log_success "密码生成完成"
}

# 初始化所有配置
init_all_configs() {
    log_info "初始化所有 secrets 配置..."
    
    # 通用配置
    create_config "${TEMPLATES_DIR}/.env.common.example" "${SECRETS_DIR}/.env.common"
    
    # MySQL
    create_config "${TEMPLATES_DIR}/database/.env.mysql.example" "${SECRETS_DIR}/database/.env.mysql"
    auto_fill_passwords "${SECRETS_DIR}/database/.env.mysql"
    
    # PostgreSQL
    create_config "${TEMPLATES_DIR}/database/.env.postgres.example" "${SECRETS_DIR}/database/.env.postgres"
    auto_fill_passwords "${SECRETS_DIR}/database/.env.postgres"
    
    # Redis
    create_config "${TEMPLATES_DIR}/cache/.env.redis.example" "${SECRETS_DIR}/cache/.env.redis"
    auto_fill_passwords "${SECRETS_DIR}/cache/.env.redis"
    
    # RabbitMQ
    create_config "${TEMPLATES_DIR}/middleware/.env.rabbitmq.example" "${SECRETS_DIR}/middleware/.env.rabbitmq"
    auto_fill_passwords "${SECRETS_DIR}/middleware/.env.rabbitmq"
    
    # Nacos
    create_config "${TEMPLATES_DIR}/middleware/.env.nacos.example" "${SECRETS_DIR}/middleware/.env.nacos"
    
    log_success "所有配置初始化完成"
}

# 显示下一步操作
show_next_steps() {
    echo ""
    echo "============================================"
    echo "🎉 Secrets 配置初始化完成!"
    echo "============================================"
    echo ""
    echo "📋 下一步操作:"
    echo ""
    echo "1. 查看生成的配置文件:"
    echo "   cd ${SECRETS_DIR}"
    echo "   ls -R"
    echo ""
    echo "2. 可选: 编辑配置文件修改密码"
    echo "   vi database/.env.mysql"
    echo ""
    echo "3. 将 secrets 目录推送到私有仓库:"
    echo "   cd ${SECRETS_DIR}"
    echo "   git add ."
    echo "   git commit -m 'Initialize secrets'"
    echo "   git push"
    echo ""
    echo "4. 部署服务:"
    echo "   ./scripts/deploy.sh mysql redis"
    echo ""
    echo "⚠️  注意: 请妥善保管这些配置文件,不要提交到公开仓库!"
    echo "============================================"
}

# 主函数
main() {
    echo ""
    echo "============================================"
    echo "   初始化 Secrets 配置"
    echo "============================================"
    echo ""
    
    # 检查模板目录
    if [ ! -d "$TEMPLATES_DIR" ]; then
        log_error "模板目录不存在: $TEMPLATES_DIR"
        exit 1
    fi
    
    read -p "是否自动生成所有配置文件并填充随机密码? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        init_all_configs
        show_next_steps
    else
        log_info "请手动复制模板文件并填入密码"
        echo "模板目录: ${TEMPLATES_DIR}"
        echo "目标目录: ${SECRETS_DIR}"
    fi
}

# 执行主函数
main "$@"
