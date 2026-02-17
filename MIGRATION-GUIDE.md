# 架构迁移指南

## 📋 架构变更说明

### 旧架构（已废弃）

```
❌ secrets/
   ❌ templates/          # 多个分散的 .env 模板
   ❌ database/.env.mysql # 多个独立的密码文件
   ❌ cache/.env.redis
   ❌ middleware/.env.rabbitmq
```

**问题**:
- 配置分散，维护复杂
- 需要管理多个 .env 文件
- secrets 目录暴露在公开仓库（即使是模板）

### 新架构（推荐）

```
✅ .env.example        # 统一的环境变量模板
✅ .env                # 实际环境变量（本地）
```

**优势**:
- ✅ 配置集中，一目了然
- ✅ 只需修改一个文件
- ✅ 符合 Docker Compose 标准实践
- ✅ 更安全、更简洁

## 🔄 迁移步骤

### 1. 提取现有密码

```bash
# 查看现有密码
cat secrets/database/.env.mysql
cat secrets/cache/.env.redis
cat secrets/middleware/.env.rabbitmq
```

### 2. 创建新的 .env 文件

```bash
# 复制模板
cp .env.example .env

# 编辑并填入现有密码
vi .env
```

### 3. 迁移密码配置

将旧配置文件中的密码复制到新的 `.env` 文件：

```bash
# 从 secrets/database/.env.mysql 提取
MYSQL_ROOT_PASSWORD=your_existing_password
MYSQL_DATABASE=myapp
MYSQL_USER=appuser
MYSQL_PASSWORD=your_existing_password

# 从 secrets/cache/.env.redis 提取
REDIS_PASSWORD=your_existing_password

# 从 secrets/middleware/.env.rabbitmq 提取
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=your_existing_password
```

### 4. 停止旧服务

```bash
# 停止所有服务
docker-compose -f docker-compose/database/mysql.yml down
docker-compose -f docker-compose/cache/redis.yml down
docker-compose -f docker-compose/middleware/rabbitmq.yml down
```

### 5. 启动新服务

```bash
# 使用新的配置启动
docker-compose -f docker-compose/database/mysql.yml up -d
docker-compose -f docker-compose/cache/redis.yml up -d
docker-compose -f docker-compose/middleware/rabbitmq.yml up -d
```

### 6. 验证服务

```bash
# 检查服务状态
docker ps

# 测试连接
docker exec -it mysql mysql -uroot -p
docker exec -it redis redis-cli -a your_redis_password
```

### 7. 清理旧文件（可选）

```bash
# 备份旧密码文件（以防万一）
cp -r secrets secrets.backup

# 或者直接删除（建议先备份）
# rm -rf secrets/
```

## ⚠️ 注意事项

### 数据卷保留

迁移过程中，Docker 数据卷不会丢失：

```bash
# 查看数据卷
docker volume ls

# 数据卷位置
mysql_data    # MySQL 数据
redis_data    # Redis 数据
postgres_data # PostgreSQL 数据
```

### 密码一致性

确保 `.env` 中的密码与旧密码完全一致，否则服务可能无法启动。

### 环境变量优先级

Docker Compose 读取环境变量的顺序：

1. 命令行参数（最高优先级）
2. `.env` 文件
3. Shell 环境变量
4. Docker Compose 文件中的默认值

## 🔧 快速迁移脚本

```bash
#!/bin/bash
# 自动迁移脚本

# 1. 创建新的 .env 文件
cp .env.example .env

# 2. 从旧文件提取密码并填充
if [ -f "secrets/database/.env.mysql" ]; then
    grep MYSQL_ROOT_PASSWORD secrets/database/.env.mysql >> .env
    grep MYSQL_DATABASE secrets/database/.env.mysql >> .env
    grep MYSQL_USER secrets/database/.env.mysql >> .env
    grep '^MYSQL_PASSWORD=' secrets/database/.env.mysql >> .env
fi

if [ -f "secrets/cache/.env.redis" ]; then
    grep REDIS_PASSWORD secrets/cache/.env.redis >> .env
fi

if [ -f "secrets/middleware/.env.rabbitmq" ]; then
    grep RABBITMQ_DEFAULT_USER secrets/middleware/.env.rabbitmq >> .env
    grep RABBITMQ_DEFAULT_PASS secrets/middleware/.env.rabbitmq >> .env
fi

echo "迁移完成！请检查 .env 文件"
```

## 📊 架构对比

| 特性 | 旧架构 | 新架构 |
|------|--------|--------|
| 配置文件数量 | 6+ 个 .env 文件 | 1 个 .env 文件 |
| 维护复杂度 | 高 | 低 |
| 密码查找 | 需要打开多个文件 | 集中在一个文件 |
| Docker Compose 标准 | ❌ 自定义方式 | ✅ 标准方式 |
| 迁移便利性 | ❌ 分散配置 | ✅ 单文件复制 |

## 🆘 常见问题

### Q: 迁移后服务无法启动？

A: 检查 `.env` 文件中的密码是否正确，确保与旧密码一致。

### Q: 数据会丢失吗？

A: 不会。Docker 数据卷独立于配置文件，迁移不会影响数据。

### Q: 可以保留旧架构吗？

A: 可以，但建议迁移到新架构。新架构更简洁、更符合标准。

### Q: 如何回滚到旧架构？

A: 保留 `secrets.backup` 目录，随时可以恢复。

## 📝 迁移检查清单

- [ ] 备份现有密码文件
- [ ] 创建新的 `.env` 文件
- [ ] 复制所有密码到 `.env`
- [ ] 停止所有服务
- [ ] 使用新配置启动服务
- [ ] 验证服务正常运行
- [ ] 测试应用连接
- [ ] 删除旧的 `secrets/` 目录（可选）

---

**推荐**: 新项目直接使用新架构，旧项目按需迁移。
