# ⚡ 快速测试步骤 (3分钟)

## 🎯 测试目标

验证项目是否可行,能否正常工作。

---

## 📋 快速测试清单

### ✅ 步骤 1: 本地自动化测试 (推荐)

```bash
# 进入项目目录
cd c:/Users/lenovo/CodeBuddy/my-docker-compose

# 给测试脚本执行权限
chmod +x test-local.sh

# 运行自动化测试
./test-local.sh
```

**预期结果:**
- ✅ 所有依赖检查通过
- ✅ 文件完整性检查通过
- ✅ Docker Compose 语法正确
- ✅ 密码生成功能正常
- ✅ 单个服务可以部署

---

### ✅ 步骤 2: 手动验证核心功能

#### 2.1 验证文件存在

```bash
# 检查核心文件
ls -lh bootstrap.sh
ls -lh docker-compose/database/mysql.yml
ls -lh secrets/templates/database/.env.mysql.example
```

**预期结果:** 所有文件都存在

#### 2.2 验证 Docker Compose 配置

```bash
# 验证 MySQL 配置
docker-compose -f docker-compose/database/mysql.yml config
```

**预期结果:** 无错误输出,显示完整配置

#### 2.3 测试密码生成

```bash
# 生成随机密码
openssl rand -base64 24
openssl rand -base64 32
```

**预期结果:** 每次生成不同的随机字符串

#### 2.4 测试单个服务部署

```bash
# 创建临时测试目录
mkdir -p /tmp/test-deploy/secrets/database
mkdir -p /tmp/test-deploy/logs/mysql

# 创建测试配置
cat > /tmp/test-deploy/secrets/database/.env.mysql << 'EOF'
MYSQL_ROOT_PASSWORD=testpassword123
MYSQL_DATABASE=testdb
MYSQL_USER=testuser
MYSQL_PASSWORD=testuserpass123
MYSQL_PORT=3306
EOF

# 部署 MySQL
export SECRETS_DIR=/tmp/test-deploy/secrets
docker-compose -f docker-compose/database/mysql.yml up -d

# 等待启动
sleep 10

# 检查状态
docker ps | grep mysql
docker logs mysql

# 测试连接
docker exec mysql mysql -u root -ptestpassword123 -e "SELECT VERSION();"

# 清理
docker-compose -f docker-compose/database/mysql.yml down -v
rm -rf /tmp/test-deploy
```

**预期结果:** MySQL 成功启动并可以连接

---

### ✅ 步骤 3: GitHub 集成测试

#### 3.1 推送到 GitHub

```bash
# 初始化 Git (如果还没有)
git init
git add .
git commit -m "Test: Initial commit"

# 推送到 GitHub (替换为你的用户名)
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/my-docker-compose-test.git
git push -u origin main
```

**预期结果:** 文件成功推送

#### 3.2 测试 HTTP 下载

```bash
# 测试下载 bootstrap.sh (替换用户名)
curl -I https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/bootstrap.sh

# 下载并查看
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/bootstrap.sh | head -20
```

**预期结果:** HTTP 200 响应,文件内容正确

#### 3.3 测试一键部署

```bash
# 修改 bootstrap.sh 中的用户名
# GITHUB_USER="YOUR_USERNAME"

# 提交修改
git add bootstrap.sh
git commit -m "Update GitHub username"
git push

# 测试部署 (在新机器或清理后)
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/my-docker-compose-test/main/bootstrap.sh | bash -s -- --init
```

**预期结果:** 配置文件成功下载到本地

---

## 🎯 成功标准

### 基础测试通过标志

- [✅] Docker 和 Docker Compose 已安装
- [✅] 所有必需文件存在
- [✅] Docker Compose 配置语法正确
- [✅] 密码生成功能正常
- [✅] 单个服务可以成功部署
- [✅] 可以连接到部署的服务

### 完整测试通过标志

- [✅] 文件已推送到 GitHub
- [✅] HTTP 下载功能正常
- [✅] 一键部署脚本可以执行
- [✅] 多个服务可以同时运行
- [✅] 服务之间可以互相通信

---

## 🐛 常见问题快速修复

### 问题 1: Docker 未安装

```bash
# Linux
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER

# macOS/Windows
# 下载 Docker Desktop
```

### 问题 2: 端口冲突

```bash
# 查看端口占用
netstat -tulpn | grep :3306

# 修改端口
vi secrets/database/.env.mysql
# MYSQL_PORT=3307
```

### 问题 3: 权限问题

```bash
# 给脚本执行权限
chmod +x *.sh
chmod +x scripts/*.sh
```

### 问题 4: curl 下载失败

```bash
# 检查网络
ping github.com

# 使用代理 (如果需要)
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
```

---

## 📊 测试结果记录

### 本地测试

| 测试项 | 状态 | 备注 |
|--------|------|------|
| Docker 安装 | ⬜ | |
| 文件完整性 | ⬜ | |
| Compose 语法 | ⬜ | |
| 密码生成 | ⬜ | |
| 单服务部署 | ⬜ | |

### GitHub 测试

| 测试项 | 状态 | 备注 |
|--------|------|------|
| 文件推送 | ⬜ | |
| HTTP 下载 | ⬜ | |
| 一键部署 | ⬜ | |

---

## 🎉 下一步

测试通过后:

1. **优化配置** - 根据需求调整服务配置
2. **创建私有仓库** - 存储敏感密码
3. **正式使用** - 推送到正式仓库
4. **文档完善** - 记录自定义配置

---

## 📚 详细测试文档

- 🧪 [TESTING.md](./TESTING.md) - 完整测试指南
- 📖 [README.md](./README.md) - 项目说明
- ⚡ [QUICKSTART.md](./QUICKSTART.md) - 快速开始

---

**开始测试吧!** 🚀

```bash
# 一键运行所有测试
./test-local.sh
```
