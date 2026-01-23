# 使用示例

## 基本部署流程

### 1. 首次配置

```bash
# 进入项目目录
cd your-frontend-project/

# 复制配置模板
cp kd-fe-deploy/config-template.json kd-fe-deploy/config.json

# 编辑配置
vim kd-fe-deploy/config.json
```

### 2. 验证配置

```bash
# 验证配置
./kd-fe-deploy/scripts/validate-config.sh

# 测试堡垒机连接
./kd-fe-deploy/scripts/connect-server.sh rhea test
```

### 3. 执行部署

```bash
# 完整部署到开发环境
./kd-fe-deploy/scripts/full-deploy.sh rhea

# 部署到生产环境
./kd-fe-deploy/scripts/full-deploy.sh rhea --env prod
```

## 高级用法

### 仅构建

```bash
# 只执行构建，不部署
./kd-fe-deploy/scripts/full-deploy.sh rhea --build-only

# 查看生成的构建产物
ls -la *.zip
```

### 仅部署

```bash
# 跳过构建，直接部署现有产物
./kd-fe-deploy/scripts/full-deploy.sh rhea --deploy-only
```

### 详细输出

```bash
# 启用详细日志输出
./kd-fe-deploy/scripts/full-deploy.sh rhea --verbose
```

### 测试模式

```bash
# 测试模式，不会实际部署
./kd-fe-deploy/scripts/full-deploy.sh rhea --test
```

## 配置示例

### 简单配置（密码认证）

```json
{
  "version": "1.0",
  "bastion": {
    "host": "192.168.12.100",
    "port": 2222,
    "user": "liuyun",
    "auth_method": "password",
    "password_env_var": "DEPLOY_PASSWORD"
  },
  "projects": {
    "rhea": {
      "build_param": "build",
      "deploy_path": "/data/application/qiankun/subapp/rhea/",
      "server_pattern": "12.168"
    }
  }
}
```

### 完整配置（密码认证 + 多环境）

```json
{
  "version": "1.0",
  "bastion": {
    "host": "192.168.12.100",
    "port": 2222,
    "user": "liuyun",
    "auth_method": "password",
    "password": null
  },
  "projects": {
    "rhea": {
      "build_param": "build",
      "deploy_path": "/data/application/qiankun/subapp/rhea/",
      "server_pattern": "12.168",
      "backup_old_version": true,
      "post_deploy_commands": [
        "ls -la",
        "echo 'Rhea部署完成'"
      ]
    },
    "admin": {
      "build_param": "prod",
      "deploy_path": "/data/application/admin/",
      "server_pattern": "12.169",
      "post_deploy_commands": [
        "chown -R www-data:www-data .",
        "systemctl reload apache2"
      ]
    }
  },
  "environments": {
    "dev": {
      "server_pattern": "12.168"
    },
    "test": {
      "server_pattern": "12.169"
    },
    "prod": {
      "server_pattern": "12.170"
    }
  },
  "deployment": {
    "max_retries": 3,
    "timeout": 300,
    "log_level": "info"
  }
}
```

## 实际场景示例

### 场景1：日常开发部署

```bash
# 开发环境快速部署
./kd-fe-deploy/scripts/full-deploy.sh rhea --env dev

# 检查部署结果
curl http://dev-server/health
```

### 场景2：生产环境部署

```bash
# 生产环境完整部署
./kd-fe-deploy/scripts/full-deploy.sh rhea --env prod --verbose

# 验证生产环境
curl https://production-server/health
```

### 场景3：紧急回滚

```bash
# 如果部署出现问题，快速回滚
./kd-fe-deploy/scripts/rollback.sh rhea prod
```

### 场景4：批量部署

```bash
# 部署多个项目
for project in rhea qiankun admin; do
    ./kd-fe-deploy/scripts/full-deploy.sh $project --env prod
done
```

## 故障排除示例

### 问题1：SSH连接失败

```bash
# 检查SSH配置
ssh -T bastion

# 测试密钥
ssh -i ~/.ssh/id_rsa -p 2222 liuyun@192.168.12.100 "echo 'test'"

# 检查DNS解析
nslookup 192.168.12.100
```

### 问题2：构建失败

```bash
# 检查依赖
which yk
yk --version

# 检查Node.js
node --version
npm --version

# 手动测试构建
cd your-project/
yk zip-dist -b build
```

### 问题3：部署权限问题

```bash
# 检查SSH密钥权限
ls -la ~/.ssh/id_rsa
# 应该显示: -rw-------

# 修复权限
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### 问题4：JumpServer选择失败

```bash
# 检查服务器模式配置
grep "server_pattern" kd-fe-deploy/config.json

# 手动测试连接
./kd-fe-deploy/scripts/connect-server.sh rhea

# 在JumpServer界面输入正确的服务器标识
```

## 脚本组合使用

### CI/CD集成

```bash
#!/bin/bash
# ci-deploy.sh

PROJECT=$1
ENV=${2:-dev}

echo "开始CI/CD部署: $PROJECT -> $ENV"

# 1. 验证配置
./kd-fe-deploy/scripts/validate-config.sh

# 2. 构建
./kd-fe-deploy/scripts/full-deploy.sh $PROJECT --build-only

# 3. 部署到测试环境
./kd-fe-deploy/scripts/full-deploy.sh $PROJECT --env test --deploy-only

# 4. 运行自动化测试
npm test

# 5. 部署到生产环境
if [[ "$ENV" == "prod" ]]; then
    ./kd-fe-deploy/scripts/full-deploy.sh $PROJECT --env prod --deploy-only
fi

echo "CI/CD部署完成"
```

### 定时备份脚本

```bash
#!/bin/bash
# backup-deploy.sh

PROJECTS=("rhea" "qiankun" "admin")
BACKUP_DIR="/data/backups/$(date +%Y%m%d)"

mkdir -p "$BACKUP_DIR"

for project in "${PROJECTS[@]}"; do
    echo "备份项目: $project"

    # 连接服务器并创建备份
    ./kd-fe-deploy/scripts/connect-server.sh $project << EOF
cd /data/application/
tar czf "$BACKUP_DIR/${project}-$(date +%H%M%S).tar.gz" $project/
echo "备份完成: $project"
EOF

done

echo "所有项目备份完成"
```

### 监控脚本

```bash
#!/bin/bash
# monitor-deploy.sh

PROJECTS=("rhea" "qiankun")
HEALTH_ENDPOINTS=(
    "http://dev-server:8080/health"
    "http://prod-server/health"
)

# 检查应用健康状态
check_health() {
    local url=$1
    local timeout=10

    if curl -f -s --max-time $timeout "$url" > /dev/null; then
        echo "✅ $url - 正常"
        return 0
    else
        echo "❌ $url - 异常"
        return 1
    fi
}

echo "=== 部署监控检查 ==="
echo "时间: $(date)"

# 检查每个项目的健康状态
failed_count=0
for url in "${HEALTH_ENDPOINTS[@]}"; do
    if ! check_health "$url"; then
        ((failed_count++))
    fi
done

# 检查磁盘使用率
echo ""
echo "磁盘使用率:"
df -h /data

# 检查最近的部署日志
echo ""
echo "最近部署日志:"
tail -10 /tmp/kd-deploy.log

if [[ $failed_count -gt 0 ]]; then
    echo ""
    echo "⚠️  发现 $failed_count 个异常，建议检查"
    exit 1
else
    echo ""
    echo "✅ 所有检查正常"
fi
```