# 安全最佳实践

## 🔐 密码管理

### 密码强度要求

**最小要求:**
- 长度: 至少 16 个字符
- 复杂度: 包含大小写字母、数字、特殊字符
- 唯一性: 不同服务使用不同密码

**生成强密码示例:**

```bash
# 使用 openssl 生成 32 位随机密码
openssl rand -base64 32

# 使用 pwgen 工具
pwgen -s 32 1

# 使用 Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 密码存储安全

#### ✅ 推荐做法

1. **使用 Git Submodule 隔离**
   - 敏感信息存储在私有仓库
   - 主仓库只存储配置模板
   - 通过 submodule 引入

2. **环境变量注入**
   - 使用 `.env` 文件
   - Docker Compose 自动读取
   - 不在代码中硬编码

3. **定期轮换密码**
   - 建议每 90 天更换一次
   - 重要服务缩短周期

#### ❌ 禁止做法

1. **不要提交密码到公开仓库**
   ```bash
   # 错误示例
   git add secrets/.env.mysql  # ❌
   git commit -m "Add passwords" # ❌
   ```

2. **不要在日志中输出密码**
   ```bash
   # 错误示例
   echo "MySQL password: $MYSQL_ROOT_PASSWORD" # ❌
   ```

3. **不要使用弱密码**
   ```bash
   # 错误示例
   MYSQL_ROOT_PASSWORD=root     # ❌
   MYSQL_ROOT_PASSWORD=123456   # ❌
   MYSQL_ROOT_PASSWORD=password # ❌
   ```

---

## 🛡️ 网络安全

### 端口暴露原则

#### 开发环境

```yaml
# 允许本地访问
ports:
  - "127.0.0.1:3306:3306"  # ✅ 仅本地
```

#### 生产环境

```yaml
# 方案一: 不暴露端口,仅内部网络
# ports:
#   - "3306:3306"  # 注释掉

# 方案二: 使用防火墙限制
ports:
  - "3306:3306"
# 然后配置防火墙规则
```

### 网络隔离

```yaml
# 创建独立的网络
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # 内部网络,无法访问外网
  database:
    driver: bridge
    internal: true

services:
  nginx:
    networks:
      - frontend
      - backend
  
  app:
    networks:
      - backend
  
  mysql:
    networks:
      - database
```

### 防火墙配置

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 3306/tcp
sudo ufw enable

# iptables
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 3306 -j DROP
```

---

## 🔒 数据安全

### 数据加密

#### 传输加密

```yaml
# MySQL SSL
services:
  mysql:
    command:
      - --require-secure-transport=ON
    volumes:
      - ./ssl:/etc/mysql/ssl

# Redis TLS
services:
  redis:
    command: redis-server --tls-port 6379 --port 0 \
             --tls-cert-file /etc/redis/redis.crt \
             --tls-key-file /etc/redis/redis.key
```

#### 存储加密

```bash
# 使用加密卷 (Docker)
docker volume create --driver local \
  --opt type=tmpfs \
  --opt device=tmpfs \
  --opt o=size=1g,uid=1000 \
  encrypted_volume
```

### 数据备份安全

#### 加密备份

```bash
# 使用 GPG 加密备份
gpg --symmetric --cipher-algo AES256 \
    --output backup.sql.gz.gpg \
    backup.sql.gz

# 恢复时解密
gpg --decrypt backup.sql.gz.gpg > backup.sql.gz
```

#### 异地备份

```bash
# 同步到远程服务器
rsync -avz --delete \
  backup/ user@remote-server:/backup/docker-compose/

# 同步到云存储 (AWS S3)
aws s3 sync backup/ s3://my-bucket/docker-backup/ \
  --sse AES256  # 服务端加密
```

---

## 🚨 访问控制

### MySQL 用户权限

```sql
-- 创建应用用户 (最小权限原则)
CREATE USER 'appuser'@'%' IDENTIFIED BY 'strong_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON myapp.* TO 'appuser'@'%';
FLUSH PRIVILEGES;

-- 禁止 root 远程登录
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
FLUSH PRIVILEGES;
```

### Redis 访问控制

```conf
# redis.conf
# 重命名危险命令
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG ""
rename-command DEBUG ""
```

### Nginx 安全配置

```nginx
# 隐藏版本号
server_tokens off;

# 安全头
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Content-Security-Policy "default-src 'self'" always;

# 限制请求大小
client_max_body_size 10M;

# 限制连接速率
limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
limit_req zone=one burst=20 nodelay;
```

---

## 📝 审计与监控

### 日志管理

#### 集中日志

```yaml
# 使用 ELK 收集日志
services:
  filebeat:
    image: elastic/filebeat:8.0.0
    volumes:
      - ./logs:/var/log/docker:ro
      - ./config/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
```

#### 日志轮转

```yaml
services:
  mysql:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 安全审计

```bash
# 审计 Docker 容器
docker inspect mysql | grep -A 5 SecurityOpt

# 审计网络配置
docker network inspect bridge

# 审计权限
docker exec mysql whoami
docker exec mysql ps aux
```

---

## 🔄 更新与维护

### 定期更新

```bash
# 更新镜像
docker-compose pull
docker-compose up -d

# 清理旧镜像
docker image prune -a
```

### 安全扫描

```bash
# 使用 Trivy 扫描镜像漏洞
trivy image mysql:8.0

# 使用 Docker Scout
docker scout cves mysql:8.0
```

---

## ⚠️ 应急响应

### 密码泄露处理流程

1. **立即修改密码**
   ```bash
   # 停止服务
   docker-compose down
   
   # 修改 secrets 配置
   vi secrets/database/.env.mysql
   
   # 重新部署
   ./scripts/deploy.sh mysql
   ```

2. **更新所有相关服务**
   ```bash
   ./scripts/deploy.sh --restart all
   ```

3. **提交变更**
   ```bash
   cd secrets
   git add .
   git commit -m "Update compromised passwords"
   git push
   ```

4. **审查访问日志**
   ```bash
   # MySQL
   docker exec mysql cat /var/log/mysql/general.log
   
   # Redis
   docker exec redis cat /var/log/redis/redis.log
   ```

---

## 📋 安全检查清单

### 部署前检查

- [ ] 所有密码符合强度要求
- [ ] secrets 目录已添加到 .gitignore
- [ ] 私有仓库已正确配置
- [ ] 不必要的端口已关闭
- [ ] 防火墙规则已配置

### 定期检查 (每月)

- [ ] 审查用户权限
- [ ] 检查异常登录日志
- [ ] 更新安全补丁
- [ ] 验证备份可恢复性
- [ ] 扫描镜像漏洞

### 生产环境检查

- [ ] 所有服务已启用认证
- [ ] 网络隔离已配置
- [ ] 日志已集中收集
- [ ] 监控告警已配置
- [ ] 应急预案已准备

---

## 🔗 参考资料

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [MySQL Security](https://dev.mysql.com/doc/refman/8.0/en/security.html)
- [Redis Security](https://redis.io/topics/security)
- [Nginx Security](https://nginx.org/en/docs/security.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
