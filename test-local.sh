#!/bin/bash

# ============================================
# 项目可行性快速测试脚本
# ============================================
# 功能: 自动化测试项目的各项功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试计数器
TEST_PASSED=0
TEST_FAILED=0
TEST_TOTAL=0

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; ((TEST_PASSED++)); ((TEST_TOTAL++)); }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; ((TEST_FAILED++)); ((TEST_TOTAL++)); }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# 分隔线
separator() {
    echo "============================================"
}

# 测试 1: 检查依赖
test_dependencies() {
    log_info "测试 1: 检查依赖..."
    
    # Docker
    if command -v docker &> /dev/null; then
        log_success "Docker 已安装: $(docker --version)"
    else
        log_error "Docker 未安装"
    fi
    
    # Docker Compose
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose 已安装: $(docker-compose --version)"
    else
        log_error "Docker Compose 未安装"
    fi
    
    # curl/wget
    if command -v curl &> /dev/null; then
        log_success "curl 已安装"
    elif command -v wget &> /dev/null; then
        log_success "wget 已安装"
    else
        log_error "curl 和 wget 都未安装"
    fi
    
    echo ""
}

# 测试 2: 文件完整性
test_files() {
    log_info "测试 2: 检查文件完整性..."
    
    local files=(
        "bootstrap.sh"
        "docker-compose/database/mysql.yml"
        "docker-compose/cache/redis.yml"
        "docker-compose/web-server/nginx.yml"
        "config/database/mysql/conf.d/my.cnf"
        "config/cache/redis/redis.conf"
        "secrets/templates/database/.env.mysql.example"
        "secrets/templates/cache/.env.redis.example"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            log_success "文件存在: $file"
        else
            log_error "文件缺失: $file"
        fi
    done
    
    echo ""
}

# 测试 3: Docker Compose 语法
test_compose_syntax() {
    log_info "测试 3: 验证 Docker Compose 语法..."
    
    local compose_files=(
        "docker-compose/database/mysql.yml"
        "docker-compose/cache/redis.yml"
        "docker-compose/web-server/nginx.yml"
    )
    
    for file in "${compose_files[@]}"; do
        if docker-compose -f "$file" config &> /dev/null; then
            log_success "语法正确: $file"
        else
            log_error "语法错误: $file"
        fi
    done
    
    echo ""
}

# 测试 4: 密码生成功能
test_password_generation() {
    log_info "测试 4: 测试密码生成功能..."
    
    generate_password() {
        local length=${1:-32}
        openssl rand -base64 48 | cut -c1-${length}
    }
    
    local pass1=$(generate_password 32)
    local pass2=$(generate_password 32)
    local pass3=$(generate_password 16)
    
    if [ ${#pass1} -eq 32 ] && [ ${#pass3} -eq 16 ]; then
        log_success "密码长度正确"
    else
        log_error "密码长度不正确"
    fi
    
    if [ "$pass1" != "$pass2" ]; then
        log_success "每次生成不同密码"
    else
        log_error "密码生成重复"
    fi
    
    echo ""
}

# 测试 5: 配置文件生成
test_config_generation() {
    log_info "测试 5: 测试配置文件生成..."
    
    local test_dir="/tmp/test-config-$$"
    mkdir -p "$test_dir"
    
    # 复制模板
    if cp secrets/templates/database/.env.mysql.example "$test_dir/.env.mysql"; then
        log_success "模板复制成功"
    else
        log_error "模板复制失败"
    fi
    
    # 替换密码
    sed -i "s/CHANGE_ME_TO_STRONG_PASSWORD_123!/$(openssl rand -base64 24)/g" "$test_dir/.env.mysql"
    
    # 验证替换
    if grep -q "CHANGE_ME" "$test_dir/.env.mysql"; then
        log_error "密码替换失败"
    else
        log_success "密码替换成功"
    fi
    
    # 清理
    rm -rf "$test_dir"
    
    echo ""
}

# 测试 6: Docker 网络功能
test_docker_network() {
    log_info "测试 6: 测试 Docker 网络..."
    
    # 测试网络创建
    if docker network create test-network-$$. &> /dev/null; then
        log_success "Docker 网络创建成功"
        docker network rm test-network-$$ &> /dev/null || true
    else
        log_error "Docker 网络创建失败"
    fi
    
    # 测试 Docker 卷创建
    if docker volume create test-volume-$$ &> /dev/null; then
        log_success "Docker 卷创建成功"
        docker volume rm test-volume-$$ &> /dev/null || true
    else
        log_error "Docker 卷创建失败"
    fi
    
    echo ""
}

# 测试 7: 单个服务部署
test_single_service() {
    log_info "测试 7: 测试单个服务部署..."
    
    local test_dir="/tmp/test-deploy-$$"
    mkdir -p "$test_dir/secrets/database"
    mkdir -p "$test_dir/logs/mysql"
    
    # 创建测试配置
    cat > "$test_dir/secrets/database/.env.mysql" << 'EOF'
MYSQL_ROOT_PASSWORD=testpassword123
MYSQL_DATABASE=testdb
MYSQL_USER=testuser
MYSQL_PASSWORD=testuserpass123
MYSQL_PORT=3306
EOF
    
    # 测试部署
    export SECRETS_DIR="$test_dir/secrets"
    
    if timeout 60 docker-compose -f docker-compose/database/mysql.yml up -d 2>/dev/null; then
        sleep 10
        
        if docker ps | grep -q mysql; then
            log_success "MySQL 容器启动成功"
            
            # 测试连接
            if docker exec mysql mysql -u root -ptestpassword123 -e "SELECT 1;" &>/dev/null; then
                log_success "MySQL 连接成功"
            else
                log_warning "MySQL 连接失败 (可能还在初始化)"
            fi
            
            # 清理
            docker-compose -f docker-compose/database/mysql.yml down -v &>/dev/null || true
        else
            log_error "MySQL 容器未运行"
        fi
    else
        log_error "MySQL 部署失败"
    fi
    
    # 清理
    rm -rf "$test_dir"
    unset SECRETS_DIR
    
    echo ""
}

# 测试 8: HTTP 下载 (如果有网络)
test_http_download() {
    log_info "测试 8: 测试 HTTP 下载 (可选)..."
    
    # 测试网络连接
    if curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        log_success "网络连接正常"
        
        # 测试下载 (如果已推送到 GitHub)
        read -p "是否已推送到 GitHub? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "请输入 GitHub 用户名: " github_user
            read -p "请输入仓库名 (默认 my-docker-compose): " github_repo
            github_repo=${github_repo:-my-docker-compose}
            
            if curl -fsSL "https://raw.githubusercontent.com/${github_user}/${github_repo}/main/bootstrap.sh" -o /tmp/test-bootstrap.sh 2>/dev/null; then
                log_success "bootstrap.sh 下载成功"
                rm -f /tmp/test-bootstrap.sh
            else
                log_error "bootstrap.sh 下载失败"
            fi
        else
            log_warning "跳过 GitHub 下载测试"
        fi
    else
        log_warning "网络连接失败,跳过 HTTP 下载测试"
    fi
    
    echo ""
}

# 显示测试报告
show_report() {
    separator
    echo -e "${BLUE}测试报告${NC}"
    separator
    echo ""
    echo "总测试数: $TEST_TOTAL"
    echo -e "通过: ${GREEN}$TEST_PASSED${NC}"
    echo -e "失败: ${RED}$TEST_FAILED${NC}"
    
    if [ $TEST_FAILED -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 所有测试通过!项目可行!${NC}"
    else
        echo ""
        echo -e "${RED}❌ 部分测试失败,请检查配置${NC}"
    fi
    
    separator
}

# 主函数
main() {
    clear
    separator
    echo -e "${BLUE}   Docker Compose 项目可行性测试${NC}"
    separator
    echo ""
    
    # 执行测试
    test_dependencies
    test_files
    test_compose_syntax
    test_password_generation
    test_config_generation
    test_docker_network
    test_single_service
    test_http_download
    
    # 显示报告
    show_report
}

# 执行主函数
main
