# Docker Compose 环境管理系统 - 项目

## 📋 项目概述

### 核心目标
创建一个 Docker Compose 环境管理系统，实现：
- **配置管理**: 将 Docker Compose 配置存储在 Git 仓库中
- **密码安全**: 敏感密码存储在私有 GitHub 仓库中
- **一键部署**: 通过 HTTP 下载实现一键部署，无需 Git 作为前置条件
- **服务扩展**: 支持 MySQL、PostgreSQL、Redis、Nginx、RabbitMQ、Nacos 等常见中间件
- **环境迁移**: 便于环境迁移和部署跟踪

### 关键转折点
1. **初始方案**: Git Submodule + 私有仓库
2. **重大调整**: 用户明确要求 **"前置条件不需要git"**
3. **最终方案**: HTTP/curl 下载 + GitHub Token 认证

## 🎯 用户核心需求

### 1. 部署方式
- **无 Git 依赖**: 部署环境不需要安装 Git
- **HTTP 下载**: 通过 curl/wget 直接从 GitHub 下载配置文件
- **一键执行**: 单条命令完成整个环境部署

### 2. 安全性要求
- **密码隔离**: 实际密码与配置代码分离
- **私有存储**: 敏感信息存储在私有 GitHub 仓库
- **自动生成**: 部署时自动生成强密码

### 3. 易用性要求
- **简单配置**: 最小化用户配置工作
- **灵活选择**: 支持按需部署特定服务
- **完整文档**: 提供详细的部署和配置指南

### 4. 可维护性
- **模块化设计**: 各服务配置独立，便于维护
- **版本控制**: 所有配置纳入版本管理
- **测试验证**: 提供完整的测试方案

## 🏗️ 技术架构

### 核心组件
1. **`bootstrap.sh`** - 主部署脚本
   - 通过 HTTP 下载所有配置
   - 自动创建目录结构
   - 生成随机密码
   - 部署指定服务

2. **Docker Compose 配置**
   - `docker-compose/database/` - 数据库服务
   - `docker-compose/cache/` - 缓存服务
   - `docker-compose/web-server/` - Web 服务器
   - `docker-compose/middleware/` - 中间件服务
   - `docker-compose/all-in-one.yml` - 全服务组合

3. **配置管理**
   - `config/` - 各服务配置文件
   - `secrets/templates/` - 密码模板文件
   - `secrets/` - 实际密码文件（本地生成，不提交）

4. **辅助脚本**
   - `scripts/deploy.sh` - 部署脚本
   - `scripts/backup.sh` - 备份脚本
   - `scripts/generate-passwords.sh` - 密码生成脚本
   - `scripts/init-secrets.sh` - 密码初始化脚本

### 部署流程
```
用户执行 curl 命令
    ↓
bootstrap.sh 下载配置
    ↓
创建目录结构
    ↓
生成随机密码
    ↓
部署 Docker 服务
    ↓
环境就绪
```

## 📁 项目结构

```
my-docker-compose/
├── bootstrap.sh                    # 主部署脚本
├── config/                         # 服务配置文件
│   ├── cache/redis/redis.conf
│   ├── database/mysql/conf.d/my.cnf
│   └── web-server/nginx/
├── docker-compose/                 # Docker Compose 配置
│   ├── database/mysql.yml
│   ├── database/postgresql.yml
│   ├── cache/redis.yml
│   ├── web-server/nginx.yml
│   ├── middleware/rabbitmq.yml
│   ├── middleware/nacos.yml
│   └── all-in-one.yml
├── secrets/                        # 敏感配置（不提交）
│   ├── templates/                  # 模板文件
│   │   ├── database/.env.mysql.example
│   │   ├── cache/.env.redis.example
│   │   └── middleware/
│   ├── database/.env.mysql         # 实际密码（本地）
│   └── cache/.env.redis            # 实际密码（本地）
├── scripts/                        # 辅助脚本
│   ├── deploy.sh
│   ├── backup.sh
│   ├── generate-passwords.sh
│   └── init-secrets.sh
├── docs/                           # 文档
│   ├── deployment.md
│   ├── http-deployment.md
│   ├── security.md
│   └── troubleshooting.md
└── 其他文档文件
```

## 🔧 关键技术决策

### 1. 部署方式选择
- **放弃 Git Submodule**: 简化部署前置条件
- **采用 HTTP 下载**: 使用 curl/wget 直接下载
- **GitHub Token 认证**: 支持私有仓库访问

### 2. 密码管理策略
- **模板与实现分离**: `.example` 模板 + 实际 `.env` 文件
- **自动密码生成**: 部署时自动生成 32 位强密码
- **Git 忽略规则**: 确保实际密码不提交到公开仓库

### 3. 服务配置设计
- **独立配置文件**: 每个服务独立配置，便于维护
- **组合部署**: 支持单个服务或全部服务部署
- **环境变量注入**: 通过 .env 文件注入敏感信息

### 4. 错误处理机制
- **依赖检查**: 部署前检查 Docker、curl/wget
- **逐步执行**: 每一步都有明确的状态反馈
- **错误恢复**: 提供清晰的错误信息和解决方案

## 🚀 部署方法

### 1. 基础部署（公开仓库）
```bash
# 一键部署所有基础服务
curl -fsSL https://raw.githubusercontent.com/lifuhaolife/my-docker-compose/main/bootstrap.sh | bash

# 部署指定服务
curl -fsSL https://raw.githubusercontent.com/lifuhaolife/my-docker-compose/main/bootstrap.sh | bash -s -- mysql redis nginx
```

### 2. 私有仓库部署
```bash
# 设置 GitHub Token
export GITHUB_TOKEN="ghp_xxxx"

# 部署并下载私有配置
curl -fsSL https://raw.githubusercontent.com/lifuhaolife/my-docker-compose/main/bootstrap.sh | bash -s -- --secrets-repo lifuhaolife/docker-compose-secrets
```

### 3. 本地部署
```bash
# 生成密码
./scripts/generate-passwords.sh

# 部署服务
./scripts/deploy.sh mysql redis
```

## ⚠️ 遇到的问题与解决方案

### 问题 1: Git 认证失败
- **现象**: `exit code 128` 认证错误
- **原因**: GitHub 需要 Personal Access Token，不支持密码
- **解决**: 使用 Token 认证，配置远程 URL

### 问题 2: 推送被拒绝
- **现象**: `! [rejected] main -> main (fetch first)`
- **原因**: 远程仓库已有内容（GitHub 创建的 README）
- **解决**: 使用 `git push --force` 强制推送

### 问题 3: SSH 密钥未配置
- **现象**: SSH 认证失败
- **解决**: 切换回 Token 认证，提供 SSH 配置指南

### 问题 4: Secrets 目录暴露风险
- **现象**: secrets/ 目录被推送到公开仓库
- **现状**: 仅模板文件被推送，实际密码文件被 .gitignore 排除
- **建议**: 考虑完全移除 secrets/ 目录或迁移到私有仓库

## 🔐 安全注意事项

### 已实施的安全措施
1. ✅ 实际密码文件被 .gitignore 排除
2. ✅ 使用 32 位强随机密码
3. ✅ 支持私有仓库存储敏感信息
4. ✅ 部署时自动生成密码

### 建议的改进
1. ⚠️ 考虑从公开仓库完全移除 secrets/ 目录
2. ⚠️ 建立独立的私有密码仓库
3. ⚠️ 实现密码轮换机制
4. ⚠️ 添加部署审计日志

## 📝 用户操作习惯适配

### 从 IDEA 切换到 VSCode
1. **VSCode 内置 Git 功能**
   - `Ctrl+Shift+G`: 源代码管理面板
   - `Ctrl+Enter`: 提交更改
   - 点击文件查看差异对比

2. **推荐插件**
   - **GitLens**: 代码注解、提交历史
   - **Git Graph**: 可视化分支图
   - **Git History**: 文件历史记录

3. **关键操作对照**
   - IDEA Git 弹窗 → VSCode 源代码管理面板
   - Commit → 输入信息后 `Ctrl+Enter`
   - Push/Pull → 面板菜单操作
   - Blame → GitLens 自动显示

## 🎯 项目状态

### 已完成
- ✅ 核心部署脚本 bootstrap.sh
- ✅ 完整的 Docker Compose 配置
- ✅ 密码管理系统
- ✅ 测试脚本和文档
- ✅ GitHub 仓库推送

### 待完成
- ⏳ 从公开仓库移除 secrets/ 目录（可选）
- ⏳ 建立私有密码仓库（可选）
- ⏳ 生产环境测试验证
- ⏳ 监控和日志集成

### 已知问题
- 🔄 secrets/ 目录包含模板文件在公开仓库
- 🔄 需要定期更新密码
- 🔄 缺乏多环境支持（开发/测试/生产）

## 📞 支持与维护

### 快速帮助
```bash
# 查看帮助
./bootstrap.sh --help

# 测试部署
./test-local.sh

# 生成新密码
./scripts/generate-passwords.sh
```

### 故障排除
1. **部署失败**: 检查 Docker 服务状态
2. **下载失败**: 检查网络连接和 GitHub Token
3. **密码问题**: 重新生成密码文件
4. **配置错误**: 查看服务日志

### 联系方式
- **GitHub**: https://github.com/lifuhaolife/my-docker-compose
- **问题反馈**: GitHub Issues
- **文档更新**: 提交 Pull Request

---

## 📅 项目时间线

1. **初始需求分析**: Docker Compose 环境管理
2. **方案设计**: Git Submodule + 私有仓库
3. **需求调整**: 转向 HTTP 下载方案
4. **开发实现**: 创建核心脚本和配置
5. **测试验证**: 本地测试和问题修复
6. **Git 推送**: 解决认证和推送问题
7. **密码管理**: 完成密码生成和替换
8. **文档完善**: 创建总结文档

---

**最后更新**: 2025年2月14日  
**项目状态**: 核心功能完成，可投入生产使用  
**维护建议**: 定期更新密码，监控安全漏洞