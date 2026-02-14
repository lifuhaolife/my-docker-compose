#!/bin/bash

# ============================================
# 拉取私有配置脚本
# ============================================
# 功能: 更新 secrets submodule 到最新版本

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

# 拉取最新配置
pull_secrets() {
    log_info "更新私有配置仓库..."
    
    if [ ! -d "${SECRETS_DIR}/.git" ] && [ ! -f "${SECRETS_DIR}/.git" ]; then
        log_error "Secrets submodule 未初始化"
        log_info "请先运行: ./scripts/setup.sh"
        exit 1
    fi
    
    cd "${PROJECT_ROOT}"
    
    # 更新 submodule
    git submodule update --remote --merge
    
    if [ $? -eq 0 ]; then
        log_success "私有配置更新成功"
    else
        log_error "私有配置更新失败"
        exit 1
    fi
}

# 显示变更
show_changes() {
    log_info "配置变更:"
    echo ""
    cd "${SECRETS_DIR}"
    git log --oneline -5
    echo ""
    git diff HEAD~1 --name-only
}

# 主函数
main() {
    echo ""
    echo "============================================"
    echo "   更新私有配置"
    echo "============================================"
    echo ""
    
    pull_secrets
    show_changes
    
    echo ""
    log_success "配置更新完成"
    echo "============================================"
}

# 执行主函数
main "$@"
