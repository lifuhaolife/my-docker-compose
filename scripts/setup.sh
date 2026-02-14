#!/bin/bash

# ============================================
# 项目初始化脚本
# ============================================
# 功能: 初始化项目环境,创建必要目录,拉取私有配置

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="${PROJECT_ROOT}/secrets"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 创建必要的目录
create_directories() {
    log_info "创建项目目录..."
    
    # 数据持久化目录
    mkdir -p "${PROJECT_ROOT}/volumes"
    mkdir -p "${PROJECT_ROOT}/logs"
    
    # 各服务日志目录
    mkdir -p "${PROJECT_ROOT}/logs/mysql"
    mkdir -p "${PROJECT_ROOT}/logs/postgresql"
    mkdir -p "${PROJECT_ROOT}/logs/redis"
    mkdir -p "${PROJECT_ROOT}/logs/nginx"
    mkdir -p "${PROJECT_ROOT}/logs/rabbitmq"
    mkdir -p "${PROJECT_ROOT}/logs/nacos"
    
    log_success "目录创建完成"
}

# 初始化 Git 仓库
init_git() {
    if [ ! -d "${PROJECT_ROOT}/.git" ]; then
        log_info "初始化 Git 仓库..."
        cd "${PROJECT_ROOT}"
        git init
        log_success "Git 仓库初始化完成"
    else
        log_info "Git 仓库已存在"
    fi
}

# 检查并初始化 Submodule
init_submodule() {
    log_info "检查 Secrets Submodule..."
    
    if [ -f "${SECRETS_DIR}/.git" ]; then
        log_success "Submodule 已存在"
        return 0
    fi
    
    if [ -f "${PROJECT_ROOT}/.gitmodules" ]; then
        log_info "发现 .gitmodules 配置,初始化 submodule..."
        cd "${PROJECT_ROOT}"
        git submodule update --init --recursive
        log_success "Submodule 初始化完成"
    else
        log_warning "未配置 submodule"
        echo ""
        echo "请按照以下步骤添加私有配置仓库:"
        echo "1. 在 GitHub 创建私有仓库: docker-compose-secrets"
        echo "2. 运行命令:"
        echo "   git submodule add https://github.com/YOUR_USERNAME/docker-compose-secrets.git secrets"
        echo "3. 在 secrets 目录中创建配置文件"
        echo ""
        read -p "是否现在添加 submodule? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "请输入私有仓库 URL: " repo_url
            if [ -n "$repo_url" ]; then
                cd "${PROJECT_ROOT}"
                git submodule add "$repo_url" secrets
                log_success "Submodule 添加成功"
            else
                log_error "仓库 URL 不能为空"
                exit 1
            fi
        fi
    fi
}

# 初始化 Secrets 配置
init_secrets_config() {
    log_info "检查 Secrets 配置..."
    
    if [ ! -f "${SECRETS_DIR}/.env.common" ]; then
        log_warning "未找到 .env.common,从模板创建..."
        if [ -f "${SECRETS_DIR}/templates/.env.common.example" ]; then
            cp "${SECRETS_DIR}/templates/.env.common.example" "${SECRETS_DIR}/.env.common"
            log_success ".env.common 创建成功"
        fi
    fi
    
    # 检查其他必要的配置文件
    local config_files=(
        "database/.env.mysql"
        "database/.env.postgres"
        "cache/.env.redis"
        "middleware/.env.rabbitmq"
        "middleware/.env.nacos"
    )
    
    for config_file in "${config_files[@]}"; do
        local target_file="${SECRETS_DIR}/${config_file}"
        local template_file="${SECRETS_DIR}/templates/${config_file}.example"
        
        if [ ! -f "$target_file" ]; then
            log_warning "未找到 ${config_file}"
            if [ -f "$template_file" ]; then
                read -p "是否从模板创建 ${config_file}? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    mkdir -p "$(dirname "$target_file")"
                    cp "$template_file" "$target_file"
                    log_success "${config_file} 创建成功,请编辑并填入实际密码"
                fi
            fi
        fi
    done
}

# 检查 Docker 环境
check_docker() {
    log_info "检查 Docker 环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装,请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装,请先安装 Docker Compose"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker 未运行,请启动 Docker"
        exit 1
    fi
    
    log_success "Docker 环境检查通过"
}

# 设置脚本权限
set_permissions() {
    log_info "设置脚本执行权限..."
    chmod +x "${PROJECT_ROOT}/scripts/"*.sh
    log_success "权限设置完成"
}

# 显示项目信息
show_info() {
    echo ""
    echo "============================================"
    echo "🎉 项目初始化完成!"
    echo "============================================"
    echo ""
    echo "📁 项目结构:"
    echo "   ${PROJECT_ROOT}"
    echo ""
    echo "🔐 下一步操作:"
    echo ""
    echo "1. 编辑 secrets 目录中的配置文件,填入实际密码"
    echo "   cd ${SECRETS_DIR}"
    echo "   vi database/.env.mysql"
    echo ""
    echo "2. 部署服务:"
    echo "   ./scripts/deploy.sh mysql"
    echo "   ./scripts/deploy.sh redis nginx"
    echo ""
    echo "3. 更新私有配置:"
    echo "   ./scripts/pull-secrets.sh"
    echo ""
    echo "📖 更多信息请查看 README.md"
    echo "============================================"
}

# 主函数
main() {
    echo ""
    echo "============================================"
    echo "   Docker Compose 环境管理系统 - 初始化"
    echo "============================================"
    echo ""
    
    create_directories
    init_git
    init_submodule
    init_secrets_config
    check_docker
    set_permissions
    show_info
}

# 执行主函数
main "$@"
