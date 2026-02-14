# 高级用法

## 🔄 多环境管理

### 环境配置结构

```
secrets/
├── .env.common           # 通用配置
├── .env.common.dev       # 开发环境通用配置
├── .env.common.prod      # 生产环境通用配置
├── database/
│   ├── .env.mysql.dev
│   └── .env.mysql.prod
├── cache/
│   ├── .env.redis.dev
│   └── .env.redis.prod
└── middleware/
    ├── .env.rabbitmq.dev
    └── .env.rabbitmq.prod
```

### 切换环境

#### 方式一: 使用脚本参数

```bash
# 部署开发环境
./scripts/deploy.sh --env dev mysql redis

# 部署生产环境
./scripts/deploy.sh --env prod mysql redis
```

#### 方式二: 使用符号链接

```bash
# 切换到开发环境
ln -sf secrets/database/.env.mysql.dev secrets/database/.env.mysql
ln -sf secrets/cache/.env.redis.dev secrets/cache/.env.redis

# 切换到生产环境
ln -sf secrets/database/.env.mysql.prod secrets/database/.env.mysql
ln -sf secrets/cache/.env.redis.prod secrets/cache/.env.redis
```

#### 方式三: 使用环境变量

```bash
# 设置环境
export DEPLOY_ENV=prod

# 部署脚本自动加载对应配置
./scripts/deploy.sh mysql
```

---

## 🌐 集群部署

### Redis 集群

```yaml
# docker-compose/cache/redis-cluster.yml
version: '3.8'

services:
  redis-node-1:
    image: redis:7.0-alpine
    container_name: redis-node-1
    command: redis-server --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes
    ports:
      - "7000:6379"
    volumes:
      - redis_node_1:/data
    networks:
      - redis_cluster

  redis-node-2:
    image: redis:7.0-alpine
    container_name: redis-node-2
    command: redis-server --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes
    ports:
      - "7001:6379"
    volumes:
      - redis_node_2:/data
    networks:
      - redis_cluster

  redis-node-3:
    image: redis:7.0-alpine
    container_name: redis-node-3
    command: redis-server --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes
    ports:
      - "7002:6379"
    volumes:
      - redis_node_3:/data
    networks:
      - redis_cluster

  redis-cluster-init:
    image: redis:7.0-alpine
    depends_on:
      - redis-node-1
      - redis-node-2
      - redis-node-3
    command: >
      sh -c "redis-cli --cluster create 
      redis-node-1:6379 redis-node-2:6379 redis-node-3:6379 
      --cluster-replicas 0 --cluster-yes"
    networks:
      - redis_cluster

volumes:
  redis_node_1:
  redis_node_2:
  redis_node_3:

networks:
  redis_cluster:
    driver: bridge
```

**部署集群:**

```bash
# 部署 Redis 集群
docker-compose -f docker-compose/cache/redis-cluster.yml up -d

# 验证集群状态
docker exec redis-node-1 redis-cli cluster info
docker exec redis-node-1 redis-cli cluster nodes
```

### MySQL 主从复制

```yaml
# docker-compose/database/mysql-replication.yml
version: '3.8'

services:
  mysql-master:
    image: mysql:8.0
    container_name: mysql-master
    env_file:
      - ${SECRETS_DIR:-../secrets}/database/.env.mysql
    ports:
      - "3306:3306"
    volumes:
      - mysql_master_data:/var/lib/mysql
      - ../config/database/mysql/master.cnf:/etc/mysql/conf.d/master.cnf
    command:
      - --server-id=1
      - --log-bin=mysql-bin
      - --binlog-format=ROW
    networks:
      - mysql_replication

  mysql-slave:
    image: mysql:8.0
    container_name: mysql-slave
    env_file:
      - ${SECRETS_DIR:-../secrets}/database/.env.mysql
    ports:
      - "3307:3306"
    volumes:
      - mysql_slave_data:/var/lib/mysql
      - ../config/database/mysql/slave.cnf:/etc/mysql/conf.d/slave.cnf
    command:
      - --server-id=2
      - --relay-log=relay-bin
    depends_on:
      - mysql-master
    networks:
      - mysql_replication

volumes:
  mysql_master_data:
  mysql_slave_data:

networks:
  mysql_replication:
    driver: bridge
```

**配置主从复制:**

```bash
# 1. 在主库创建复制用户
docker exec mysql-master mysql -u root -p -e "
CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
"

# 2. 获取主库状态
docker exec mysql-master mysql -u root -p -e "SHOW MASTER STATUS\G"

# 3. 配置从库
docker exec mysql-slave mysql -u root -p -e "
CHANGE MASTER TO 
  MASTER_HOST='mysql-master',
  MASTER_USER='repl',
  MASTER_PASSWORD='repl_password',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=0;
START SLAVE;
"

# 4. 验证主从状态
docker exec mysql-slave mysql -u root -p -e "SHOW SLAVE STATUS\G"
```

---

## 🔌 服务扩展

### 添加新服务

#### 1. 创建 Docker Compose 配置

```yaml
# docker-compose/mongodb/mongodb.yml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: mongodb
    restart: unless-stopped
    env_file:
      - ${SECRETS_DIR:-../secrets}/database/.env.mongodb
    ports:
      - "${MONGODB_PORT:-27017}:27017"
    volumes:
      - mongodb_data:/data/db
      - mongodb_config:/data/configdb
    networks:
      - db_network

volumes:
  mongodb_data:
  mongodb_config:

networks:
  db_network:
    driver: bridge
```

#### 2. 创建 Secrets 配置

```bash
# secrets/templates/database/.env.mongodb.example
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=CHANGE_ME_MONGODB_PASSWORD!
MONGODB_PORT=27017
```

#### 3. 更新部署脚本

编辑 `scripts/deploy.sh`,添加:

```bash
declare -A SERVICE_MAP=(
    # ... 现有服务
    ["mongodb"]="database/mongodb.yml"
    ["mongo"]="database/mongodb.yml"
)
```

#### 4. 创建配置文件

```bash
# config/database/mongodb/mongod.conf
storage:
  dbPath: /data/db
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

security:
  authorization: enabled
```

---

## 🔧 自定义网络

### 多层网络架构

```yaml
# docker-compose/networks.yml
version: '3.8'

networks:
  frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

  backend:
    driver: bridge
    internal: true  # 无法访问外网
    ipam:
      config:
        - subnet: 172.21.0.0/16

  database:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.22.0.0/16
```

### 服务网络配置

```yaml
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
  
  redis:
    networks:
      - database
```

---

## 📊 监控集成

### Prometheus + Grafana

```yaml
# docker-compose/monitoring/prometheus.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ../config/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-admin}
    depends_on:
      - prometheus
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
```

**Prometheus 配置:**

```yaml
# config/monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql-exporter:9104']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx-exporter:9113']
```

---

## 🔄 CI/CD 集成

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy Services

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
      with:
        submodules: true
        token: ${{ secrets.PRIVATE_REPO_TOKEN }}
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Deploy services
      run: |
        ./scripts/deploy.sh mysql redis nginx
      env:
        SECRETS_DIR: ./secrets
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - deploy

deploy_services:
  stage: deploy
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - git submodule update --init --recursive
    - ./scripts/deploy.sh mysql redis nginx
  only:
    - main
```

---

## 🐛 调试技巧

### 进入容器调试

```bash
# 使用 bash
docker exec -it mysql bash

# 使用 sh (如果没有 bash)
docker exec -it mysql sh

# 以 root 用户进入
docker exec -it -u root mysql bash
```

### 导出容器配置

```bash
# 导出容器配置
docker inspect mysql > mysql-config.json

# 导出镜像
docker save mysql:8.0 > mysql-8.0.tar

# 导入镜像
docker load < mysql-8.0.tar
```

### 调试网络

```bash
# 查看网络详情
docker network inspect bridge

# 测试容器间连接
docker run --rm -it --network bridge alpine ping mysql

# 抓包分析
docker run --rm -it --net container:mysql nicolaka/netshoot tcpdump -i eth0
```

---

## 📦 数据迁移

### 迁移到新服务器

```bash
# 1. 备份数据
./scripts/backup.sh --all

# 2. 打包配置和数据
tar -czf docker-compose-backup.tar.gz \
  docker-compose/ \
  config/ \
  backup/ \
  scripts/

# 3. 传输到新服务器
scp docker-compose-backup.tar.gz user@new-server:/opt/

# 4. 在新服务器解压
ssh user@new-server
cd /opt
tar -xzf docker-compose-backup.tar.gz

# 5. 克隆主项目
git clone --recursive https://github.com/yourusername/my-docker-compose.git
cd my-docker-compose

# 6. 恢复数据
# (复制备份文件到对应位置)

# 7. 部署服务
./scripts/deploy.sh --all
```

---

## 🔐 安全增强

### 使用 Docker Secrets

```yaml
# docker-compose/database/mysql.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    secrets:
      - mysql_root_password
      - mysql_password
    environment:
      - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password
      - MYSQL_PASSWORD_FILE=/run/secrets/mysql_password

secrets:
  mysql_root_password:
    file: ${SECRETS_DIR:-../secrets}/database/mysql_root_password.txt
  mysql_password:
    file: ${SECRETS_DIR:-../secrets}/database/mysql_password.txt
```

### 启用 TLS

```yaml
# MySQL TLS
services:
  mysql:
    command:
      - --require-secure-transport=ON
      - --ssl-ca=/etc/mysql/ssl/ca.pem
      - --ssl-cert=/etc/mysql/ssl/server-cert.pem
      - --ssl-key=/etc/mysql/ssl/server-key.pem
    volumes:
      - ./ssl:/etc/mysql/ssl:ro
```

---

## 📝 最佳实践总结

1. **环境隔离**: 为不同环境使用不同的配置文件
2. **网络安全**: 使用 internal 网络隔离数据库
3. **资源限制**: 为每个容器设置内存和 CPU 限制
4. **日志管理**: 集中收集和轮转日志
5. **监控告警**: 部署 Prometheus + Grafana
6. **定期备份**: 自动化备份并异地存储
7. **安全扫描**: 定期扫描镜像漏洞
8. **版本控制**: 所有配置文件纳入 Git 管理
9. **文档维护**: 及时更新文档和注释
10. **测试验证**: 在生产部署前进行充分测试
