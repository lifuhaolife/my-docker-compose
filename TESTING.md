# 🧪 项目测试指南

## 📋 测试概览

本指南将帮助你逐步验证项目的可行性,从本地测试到完整部署。

---

## ✅ 测试清单

### 阶段一: 本地基础测试
- [ ] 测试目录结构完整性
- [ ] 测试 Docker Compose 文件语法
- [ ] 测试配置文件生成
- [ ] 测试单个服务部署

### 阶段二: GitHub 集成测试
- [ ] 推送到 GitHub
- [ ] 测试 HTTP 下载
- [ ] 测试 bootstrap.sh 执行

### 阶段三: 完整流程测试
- [ ] 新环境部署测试
- [ ] 多服务部署测试
- [ ] 服务连接性测试

### 阶段四: 私有仓库测试
- [ ] 创建私有配置仓库
- [ ] Token 认证测试
- [ ] 私有配置下载测试

---

## 🔬 阶段一: 本地基础测试

### 测试 1: 验证文件完整性

```bash
# 进入项目目录
cd c:/Users/lenovo/CodeBuddy/my-docker-compose

# 检查核心文件是否存在
echo "检查核心文件..."
ls -lh bootstrap.sh
ls -lh docker-compose/database/mysql.yml
ls -lh docker-compose/cache/redis.yml
ls -lh config/database/mysql/conf.d/my.cnf
ls -lh secrets/templates/database/.env.mysql.example

# 预期结果: 所有文件都存在
```

### 测试 2: 验证 Docker Compose 语法

```bash
# 测试 MySQL 配置
echo "验证 MySQL Docker Compose..."
docker-compose -f docker-compose/database/mysql.yml config

# 测试 Redis 配置
echo "验证 Redis Docker Compose..."
docker-compose -f docker-compose/cache/redis.yml config

# 测试 All-in-one 配置
echo "验证 All-in-one Docker Compose..."
docker-compose -f docker-compose/all-in-one.yml config

# 预期结果: 无错误输出,显示完整配置
```

### 测试 3: 测试密码生成

```bash
# 测试密码生成函数
generate_password() {
    local length=${1:-32}
    openssl rand -base64 48 | cut -c1-${length}
}

echo "生成测试密码..."
echo "密码1: $(generate_password 32)"
echo "密码2: $(generate_password 16)"
echo "密码3: $(generate_password 24)"

# 预期结果: 每次生成不同的随机密码
```

### 测试 4: 测试配置文件创建

```bash
# 创建测试目录
mkdir -p /tmp/test-secrets/database
mkdir -p /tmp/test-secrets/cache

# 从模板创建配置
cp secrets/templates/database/.env.mysql.example /tmp/test-secrets/database/.env.mysql
cp secrets/templates/cache/.env.redis.example /tmp/test-secrets/cache/.env.redis

# 自动填充密码
sed -i "s/CHANGE_ME_TO_STRONG_PASSWORD_123!/$(openssl rand -base64 24)/g" /tmp/test-secrets/database/.env.mysql
sed -i "s/CHANGE_ME_REDIS_PASSWORD!/$(openssl rand -base64 24)/g" /tmp/test-secrets/cache/.env.redis

# 验证配置文件
echo "MySQL 配置:"
cat /tmp/test-secrets/database/.env.mysql
echo ""
echo "Redis 配置:"
cat /tmp/test-secrets/cache/.env.redis

# 预期结果: 配置文件中的 CHANGE_ME 被替换为随机密码
```

### 测试 5: 测试单个服务部署

```bash
# 设置环境变量
export SECRETS_DIR=/tmp/test-secrets
export INSTALL_DIR=/tmp/test-docker-env

# 创建必要的目录
mkdir -p $INSTALL_DIR/logs/mysql
mkdir -p $INSTALL_DIR/volumes

# 部署 MySQL (测试模式)
echo "测试部署 MySQL..."
docker-compose -f docker-compose/database/mysql.yml up -d

# 检查容器状态
sleep 5
docker ps | grep mysql

# 查看日志
docker logs mysql

# 停止并清理
docker-compose -f docker-compose/database/mysql.yml down -v

# 预期结果: MySQL 容器成功启动并运行
```

---

## 🌐 阶段二: GitHub 集成测试

### 测试 6: 推送到 GitHub

```bash
# 1. 初始化 Git 仓库 (如果还没有)
cd c:/Users/lenovo/CodeBuddy/my-docker-compose
git init

# 2. 添加所有文件
git add .

# 3. 提交
git commit -m "Test: Initial commit for testing"

# 4. 在 GitHub 创建仓库
# 访问 https://github.com/new
# Repository name: my-docker-compose-test
# 设置为 Public (用于测试)

# 5. 推送到 GitHub
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/my-docker-compose-test.git
git push -u origin main

# 预期结果: 文件成功推送到 GitHub
```

### 测试 7: 测试 HTTP 下载

```bash
# 测试下载 bootstrap.sh
echo "测试下载 bootstrap.sh..."
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/bootstrap.sh -o /tmp/test-bootstrap.sh
ls -lh /tmp/test-bootstrap.sh

# 测试下载 Docker Compose 文件
echo "测试下载 MySQL 配置..."
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/docker-compose/database/mysql.yml -o /tmp/test-mysql.yml
ls -lh /tmp/test-mysql.yml

# 测试下载配置文件
echo "测试下载 MySQL 配置模板..."
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/secrets/templates/database/.env.mysql.example -o /tmp/test-mysql-env
ls -lh /tmp/test-mysql-env

# 预期结果: 所有文件成功下载
```

### 测试 8: 测试 bootstrap.sh 执行

```bash
# 方式一: 修改下载的脚本测试
vi /tmp/test-bootstrap.sh
# 修改:
# GITHUB_USER="YOUR_USERNAME"  # 你的用户名
# GITHUB_REPO="my-docker-compose-test"
# INSTALL_DIR="/tmp/test-deploy"

# 执行脚本
chmod +x /tmp/test-bootstrap.sh
/tmp/test-bootstrap.sh --init

# 检查结果
ls -la /tmp/test-deploy/
ls -la /tmp/test-deploy/docker-compose/
ls -la /tmp/test-deploy/secrets/

# 预期结果: 目录结构正确,配置文件已下载
```

---

## 🚀 阶段三: 完整流程测试

### 测试 9: 新环境模拟测试

```bash
# 模拟全新环境
rm -rf ~/docker-compose-env-test

# 执行一键部署 (仅初始化)
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/bootstrap.sh | \
  bash -s -- --install-dir ~/docker-compose-env-test --init

# 验证目录结构
echo "验证目录结构..."
ls -la ~/docker-compose-env-test/
ls -la ~/docker-compose-env-test/docker-compose/
ls -la ~/docker-compose-env-test/config/
ls -la ~/docker-compose-env-test/secrets/

# 预期结果: 所有目录和文件都正确创建
```

### 测试 10: 单服务部署测试

```bash
# 部署 MySQL
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/bootstrap.sh | \
  bash -s -- --install-dir ~/docker-compose-env-test --deploy mysql

# 等待容器启动
sleep 10

# 检查容器状态
docker ps | grep mysql

# 检查日志
docker logs mysql

# 测试连接
docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD:-root}" -e "SELECT VERSION();"

# 预期结果: MySQL 成功运行,可以连接
```

### 测试 11: 多服务部署测试

```bash
# 清理之前的服务
docker stop $(docker ps -aq) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null

# 部署多个服务
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/bootstrap.sh | \
  bash -s -- --install-dir ~/docker-compose-env-test mysql redis nginx

# 等待服务启动
sleep 15

# 检查所有服务
docker ps

# 测试 MySQL
docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" 2>/dev/null && echo "✅ MySQL OK"

# 测试 Redis
docker exec redis redis-cli ping 2>/dev/null && echo "✅ Redis OK"

# 测试 Nginx
curl -s http://localhost/nginx-health 2>/dev/null && echo "✅ Nginx OK"

# 预期结果: 所有服务都正常运行
```

### 测试 12: 服务连接性测试

```bash
# 测试容器间网络
echo "测试容器间网络连接..."

# 从 MySQL 连接 Redis
docker exec mysql ping -c 2 redis 2>/dev/null && echo "✅ MySQL -> Redis OK"

# 从 Nginx 连接 MySQL
docker exec nginx ping -c 2 mysql 2>/dev/null && echo "✅ Nginx -> MySQL OK"

# 预期结果: 容器间可以互相通信
```

---

## 🔐 阶段四: 私有仓库测试

### 测试 13: 创建私有配置仓库

```bash
# 1. 创建私有仓库
# 访问 https://github.com/new
# Repository name: docker-compose-secrets-test
# Visibility: Private

# 2. 克隆并添加配置
git clone https://github.com/YOUR_USERNAME/docker-compose-secrets-test.git
cd docker-compose-secrets-test

# 3. 创建测试配置
mkdir -p database cache

# MySQL 配置
cat > database/.env.mysql << 'EOF'
MYSQL_ROOT_PASSWORD=TestPassword123!@#
MYSQL_DATABASE=testdb
MYSQL_USER=testuser
MYSQL_PASSWORD=TestUserPass456!@#
MYSQL_PORT=3306
EOF

# Redis 配置
cat > cache/.env.redis << 'EOF'
REDIS_PASSWORD=TestRedisPass789!@#
REDIS_PORT=6379
EOF

# 4. 提交
git add .
git commit -m "Add test secrets"
git push origin main

# 预期结果: 私有仓库创建成功,配置文件已上传
```

### 测试 14: 创建 GitHub Token

```bash
# 1. 访问 GitHub Token 页面
# https://github.com/settings/tokens

# 2. Generate new token (classic)
# 勾选权限: repo

# 3. 复制生成的 Token
# 格式: ghp_xxxxxxxxxxxxxxxxxxxx

# 4. 测试 Token
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# 测试 Token 是否有效
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user

# 预期结果: 返回你的用户信息
```

### 测试 15: 私有配置下载测试

```bash
# 使用 Token 下载私有配置
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# 测试下载
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/YOUR_USERNAME/docker-compose-secrets-test/main/database/.env.mysql \
  -o /tmp/private-mysql-env

# 查看内容
cat /tmp/private-mysql-env

# 预期结果: 成功下载私有配置文件
```

### 测试 16: 完整私有部署测试

```bash
# 清理测试环境
docker stop $(docker ps -aq) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null
rm -rf ~/docker-compose-env-test

# 使用私有配置部署
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/bootstrap.sh | \
  bash -s -- \
    --token ghp_xxxxxxxxxxxx \
    --secrets-repo YOUR_USERNAME/docker-compose-secrets-test \
    --install-dir ~/docker-compose-env-test \
    mysql redis

# 验证配置来源
echo "验证私有配置是否生效..."
cat ~/docker-compose-env-test/secrets/database/.env.mysql | grep "TestPassword123"

# 测试服务
docker exec mysql mysql -u root -p"TestPassword123!@#" -e "SELECT VERSION();"

# 预期结果: 使用私有配置成功部署
```

---

## 🎯 测试结果验证

### 成功标准

#### 阶段一 (本地测试)
✅ 所有文件存在  
✅ Docker Compose 语法正确  
✅ 密码生成功能正常  
✅ 单个服务可以部署  

#### 阶段二 (GitHub 集成)
✅ 文件成功推送到 GitHub  
✅ HTTP 下载功能正常  
✅ bootstrap.sh 可以执行  

#### 阶段三 (完整流程)
✅ 新环境可以一键部署  
✅ 多个服务同时运行  
✅ 容器间网络互通  

#### 阶段四 (私有仓库)
✅ 私有仓库创建成功  
✅ Token 认证通过  
✅ 私有配置可以下载  
✅ 使用私有配置部署成功  

---

## 📊 测试报告模板

```markdown
# 测试报告

## 测试环境
- 操作系统: [填写]
- Docker 版本: [填写]
- Docker Compose 版本: [填写]
- 测试时间: [填写]

## 测试结果

### 阶段一: 本地基础测试
- [ ] 文件完整性: PASS/FAIL
- [ ] Docker Compose 语法: PASS/FAIL
- [ ] 密码生成: PASS/FAIL
- [ ] 单服务部署: PASS/FAIL

### 阶段二: GitHub 集成测试
- [ ] 文件推送: PASS/FAIL
- [ ] HTTP 下载: PASS/FAIL
- [ ] bootstrap.sh 执行: PASS/FAIL

### 阶段三: 完整流程测试
- [ ] 新环境部署: PASS/FAIL
- [ ] 多服务部署: PASS/FAIL
- [ ] 服务连接性: PASS/FAIL

### 阶段四: 私有仓库测试
- [ ] 私有仓库创建: PASS/FAIL
- [ ] Token 认证: PASS/FAIL
- [ ] 私有配置下载: PASS/FAIL
- [ ] 私有配置部署: PASS/FAIL

## 问题记录
[记录遇到的问题和解决方案]

## 总结
[项目可行性评估]
```

---

## 🐛 常见测试问题

### 问题 1: curl 下载失败

```bash
# 检查网络
curl -I https://raw.githubusercontent.com

# 检查 URL 是否正确
curl -I https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/bootstrap.sh

# 解决: 确保 URL 正确,检查仓库是否为 Public
```

### 问题 2: Docker Compose 语法错误

```bash
# 验证语法
docker-compose -f file.yml config

# 查看 YAML 格式
cat file.yml | grep -n "  "  # 检查缩进

# 解决: 修正 YAML 缩进 (使用空格,不要用 Tab)
```

### 问题 3: 端口冲突

```bash
# 查看端口占用
netstat -tulpn | grep :3306

# 修改端口
vi secrets/database/.env.mysql
# MYSQL_PORT=3307

# 重启服务
docker restart mysql
```

### 问题 4: Token 认证失败

```bash
# 验证 Token
curl -H "Authorization: token ghp_xxx" https://api.github.com/user

# 检查权限
curl -H "Authorization: token ghp_xxx" \
  https://api.github.com/repos/YOUR_USERNAME/PRIVATE_REPO

# 解决: 重新创建 Token,确保勾选 repo 权限
```

---

## 🎉 测试成功后的下一步

1. **优化配置** - 根据测试结果调整配置
2. **完善文档** - 更新 README 和文档
3. **正式使用** - 推送到正式仓库
4. **团队推广** - 分享给团队成员

---

**开始测试吧!** 🚀
