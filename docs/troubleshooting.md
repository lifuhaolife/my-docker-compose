# 故障排查指南

## 🔍 诊断工具

### Docker 诊断命令

```bash
# 查看容器状态
docker ps -a

# 查看容器详细信息
docker inspect mysql

# 查看容器日志
docker logs mysql
docker logs --tail 100 mysql
docker logs -f mysql  # 实时跟踪

# 查看容器资源使用
docker stats mysql

# 进入容器
docker exec -it mysql bash

# 查看网络
docker network ls
docker network inspect bridge

# 查看卷
docker volume ls
docker volume inspect mysql_data
```

### 系统诊断

```bash
# 查看端口占用
netstat -tulpn | grep :3306
lsof -i :3306

# 查看磁盘空间
df -h

# 查看内存
free -h

# 查看进程
ps aux | grep mysql
```

---

## ❌ 常见问题

### 1. 容器无法启动

#### 问题: 容器启动后立即退出

```bash
# 查看退出代码
docker ps -a | grep mysql

# 查看错误日志
docker logs mysql
```

**可能原因与解决方案:**

##### 1.1 配置文件错误

```bash
# 检查配置文件语法
docker-compose -f docker-compose/database/mysql.yml config

# 验证环境变量
docker-compose -f docker-compose/database/mysql.yml config | grep -A 5 environment
```

**解决:**
```bash
# 修正配置文件
vi docker-compose/database/mysql.yml
```

##### 1.2 密码配置错误

```bash
# 检查 secrets 文件
cat secrets/database/.env.mysql

# 确保密码不为空
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "密码未设置"
fi
```

**解决:**
```bash
# 重新生成密码
./scripts/init-secrets.sh
```

##### 1.3 卷权限问题

```bash
# 检查卷权限
ls -la volumes/mysql

# 修复权限
sudo chown -R 999:999 volumes/mysql
```

---

### 2. 端口冲突

#### 问题: 端口已被占用

```bash
# 错误信息
Error starting userland proxy: listen tcp4 0.0.0.0:3306: bind: address already in use
```

**诊断:**

```bash
# 查看端口占用
netstat -tulpn | grep :3306
# 或
lsof -i :3306
# 或
ss -tulpn | grep :3306
```

**解决方案:**

##### 方案一: 停止占用端口的服务

```bash
# 查找并停止服务
sudo systemctl stop mysql
# 或
sudo kill -9 <PID>
```

##### 方案二: 修改端口

```bash
# 修改 secrets 配置
vi secrets/database/.env.mysql

# 修改端口
MYSQL_PORT=3307

# 重新部署
./scripts/deploy.sh mysql
```

##### 方案三: 仅绑定本地

```yaml
# 修改 docker-compose 文件
ports:
  - "127.0.0.1:3306:3306"  # 仅本地访问
```

---

### 3. 网络连接问题

#### 问题: 容器间无法通信

**诊断:**

```bash
# 检查网络
docker network inspect db_network

# 进入容器测试连接
docker exec mysql ping redis
docker exec mysql telnet redis 6379
```

**解决方案:**

##### 3.1 确保在同一网络

```yaml
# docker-compose.yml
services:
  mysql:
    networks:
      - db_network
  
  redis:
    networks:
      - db_network

networks:
  db_network:
    driver: bridge
```

##### 3.2 使用服务名访问

```bash
# 正确方式: 使用服务名
mysql -h mysql -P 3306 -u root -p

# 错误方式: 使用 localhost
mysql -h localhost -P 3306 -u root -p  # 在容器内部
```

---

### 4. 数据卷问题

#### 问题: 数据丢失

**可能原因:**
- 未正确挂载卷
- 容器删除时卷被删除
- 权限问题

**诊断:**

```bash
# 查看卷挂载
docker inspect mysql | grep -A 10 Mounts

# 查看卷内容
ls -la volumes/mysql

# 检查卷类型
docker volume ls
docker volume inspect mysql_data
```

**解决方案:**

##### 4.1 使用命名卷

```yaml
volumes:
  mysql_data:  # 命名卷,持久化

services:
  mysql:
    volumes:
      - mysql_data:/var/lib/mysql
```

##### 4.2 备份数据

```bash
# 定期备份
./scripts/backup.sh mysql

# 恢复数据
docker exec -i mysql mysql -u root -p < backup.sql
```

---

### 5. 内存不足

#### 问题: 容器被 OOM Killed

```bash
# 查看容器退出代码
docker ps -a | grep mysql
# Exit Code: 137 (OOM Killed)

# 查看内存使用
docker stats --no-stream
```

**解决方案:**

##### 5.1 限制容器内存

```yaml
services:
  mysql:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

##### 5.2 调整服务配置

```ini
# MySQL my.cnf
[mysqld]
innodb_buffer_pool_size = 1G  # 根据可用内存调整
max_connections = 500
```

```conf
# Redis redis.conf
maxmemory 1gb
maxmemory-policy allkeys-lru
```

---

### 6. 权限问题

#### 问题: Permission denied

```bash
# 错误信息
ERROR: for mysql  Cannot start service mysql: error while creating mount source path
```

**诊断:**

```bash
# 查看权限
ls -la volumes/
ls -la logs/

# 查看容器用户
docker exec mysql whoami
docker exec mysql id
```

**解决方案:**

##### 6.1 修复目录权限

```bash
# MySQL (通常 UID 999)
sudo chown -R 999:999 volumes/mysql logs/mysql

# PostgreSQL (通常 UID 999)
sudo chown -R 999:999 volumes/postgresql

# Redis (通常 UID 999)
sudo chown -R 999:999 volumes/redis

# Nginx (通常 UID 101)
sudo chown -R 101:101 volumes/nginx logs/nginx
```

##### 6.2 使用 ACL

```bash
# 设置 ACL
setfacl -R -m u:999:rwx volumes/mysql
setfacl -R -d -m u:999:rwx volumes/mysql
```

---

### 7. Submodule 问题

#### 问题: Secrets submodule 未初始化

```bash
# 错误信息
ERROR: Couldn't find env file: secrets/database/.env.mysql
```

**解决方案:**

```bash
# 初始化 submodule
git submodule update --init --recursive

# 或重新克隆
git clone --recursive https://github.com/yourusername/my-docker-compose.git
```

#### 问题: Submodule 更新冲突

```bash
# 查看状态
cd secrets
git status

# 拉取更新
git pull origin main

# 如果有冲突
git stash
git pull origin main
git stash pop
```

---

### 8. Docker Compose 版本问题

#### 问题: 版本不兼容

```bash
# 错误信息
ERROR: Version in "./docker-compose.yml" is unsupported.
```

**解决方案:**

```bash
# 检查 Docker Compose 版本
docker-compose --version

# 更新 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

---

## 🚨 紧急恢复

### 完全重置服务

```bash
# 停止所有容器
docker-compose -f docker-compose/database/mysql.yml down

# 删除卷 (警告: 数据将丢失)
docker-compose -f docker-compose/database/mysql.yml down -v

# 删除镜像
docker rmi mysql:8.0

# 重新部署
./scripts/deploy.sh mysql
```

### 从备份恢复

```bash
# 1. 停止服务
docker stop mysql

# 2. 恢复数据
gunzip backup/20240101_120000/mysql_all_databases.sql.gz
docker cp backup/20240101_120000/mysql_all_databases.sql mysql:/tmp/

# 3. 导入数据
docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/mysql_all_databases.sql

# 4. 重启服务
docker start mysql
```

---

## 📊 性能问题

### 慢查询分析

```sql
-- MySQL
SHOW VARIABLES LIKE 'slow_query_log';
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- 查看慢查询
SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;
```

### 连接池问题

```bash
# 查看当前连接数
docker exec mysql mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"
docker exec mysql mysql -u root -p -e "SHOW PROCESSLIST;"

# 修改最大连接数
vi config/database/mysql/conf.d/my.cnf
# max_connections = 1000
```

### Redis 性能

```bash
# 查看内存使用
docker exec redis redis-cli INFO memory

# 查看慢日志
docker exec redis redis-cli SLOWLOG GET 10

# 实时监控
docker exec redis redis-cli MONITOR
```

---

## 📝 日志分析

### 关键日志文件

```bash
# MySQL
logs/mysql/error.log
logs/mysql/slow.log

# Redis
logs/redis/redis.log

# Nginx
logs/nginx/access.log
logs/nginx/error.log

# Docker
/var/log/docker.log  # Linux
~/Library/Containers/com.docker.docker/Data/log/vm/dockerd.log  # macOS
```

### 日志分析命令

```bash
# 搜索错误
grep -i error logs/mysql/error.log

# 统计错误类型
grep -i error logs/mysql/error.log | awk '{print $1, $2}' | sort | uniq -c

# 实时监控
tail -f logs/mysql/error.log
```

---

## 🔗 获取帮助

### 查看文档

```bash
# 查看服务文档
docker exec mysql mysql --help
docker exec redis redis-cli --help

# 查看 Docker 文档
docker --help
docker-compose --help
```

### 社区资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Forums](https://forums.docker.com/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/docker)
- GitHub Issues: 在项目仓库提交 issue
