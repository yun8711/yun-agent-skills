# 配置架构说明

## 概述

kd-fe-deploy 采用**分层配置架构**，将敏感信息与项目配置分离，确保安全性和灵活性。

## 配置层次

### 1. 本地配置层 (~/.kd-deploy/config.json)
**位置**: 用户本地目录（不会提交到版本控制）
**用途**: 存储敏感信息和全局配置
**内容**:
- 堡垒机连接信息（IP、端口、用户名）
- 认证信息（密码环境变量名）
- 默认部署参数

```json
{
  "version": "1.0",
  "bastion": {
    "host": "192.168.12.100",
    "port": 2222,
    "user": "liuyun",
    "auth_method": "password",
    "password_env_var": "DEPLOY_PASSWORD",
    "connection_timeout": 30
  },
  "defaults": {
    "backup_old_version": true,
    "max_retries": 3,
    "timeout": 300,
    "log_level": "info"
  }
}
```

### 2. 项目配置层 (package.json)
**位置**: 项目根目录的package.json文件
**用途**: 定义项目特定的部署配置
**内容**:
- 构建命令和参数
- 服务器选择模式
- 部署路径和后处理命令
- 环境特定配置

```json
{
  "name": "my-frontend-project",
  "version": "1.0.0",
  "deploy": {
    "build": {
      "command": "yk zip-dist -b build",
      "output_pattern": "*.zip"
    },
    "server": {
      "pattern": "12.168"
    },
    "target": {
      "path": "/data/app/my-project/",
      "backup": true,
      "post_commands": [
        "ls -la",
        "echo 'Deploy completed successfully'"
      ]
    },
    "environments": {
      "prod": {
        "server_pattern": "12.170",
        "confirm_required": true
      }
    }
  }
}
```

## 配置合并逻辑

部署脚本运行时会按以下优先级合并配置：

1. **本地配置** (~/.kd-deploy/config.json) - 基础设置
2. **项目配置** (package.json:deploy) - 项目特定设置
3. **环境变量** - 运行时覆盖
4. **命令行参数** - 最高优先级

## 安全性设计

### 敏感信息隔离
- 堡垒机IP、端口、用户名等敏感信息存储在本地
- 项目代码库不包含任何敏感信息
- 支持多套本地配置（不同环境）

### 密码管理
- 密码通过环境变量传递
- 支持密码环境变量名配置
- 避免在配置文件中明文存储密码

### 权限控制
- 本地配置文件权限检查
- 环境变量访问控制
- 配置验证和完整性检查

## 初始化流程

### 首次使用
```bash
# 1. 初始化本地配置
./kd-fe-deploy/scripts/setup-local-config.sh --interactive

# 2. 设置密码环境变量
export DEPLOY_PASSWORD="your_password"

# 3. 在项目中添加deploy配置
# 编辑 package.json 添加 deploy 字段

# 4. 验证配置
./kd-fe-deploy/scripts/validate-config.sh

# 5. 执行部署
./kd-fe-deploy/scripts/full-deploy.sh
```

### 配置检查
```bash
# 检查本地配置
./kd-fe-deploy/scripts/setup-local-config.sh --check

# 验证项目配置
./kd-fe-deploy/scripts/validate-config.sh
```

## 环境适配

### 多环境支持
项目可以为不同环境定义特定的配置：

```json
{
  "deploy": {
    "environments": {
      "dev": {
        "server_pattern": "12.168",
        "backup": false
      },
      "test": {
        "server_pattern": "12.169",
        "backup": true
      },
      "prod": {
        "server_pattern": "12.170",
        "backup": true,
        "confirm_required": true
      }
    }
  }
}
```

### 运行时环境选择
```bash
# 部署到开发环境
./kd-fe-deploy/scripts/full-deploy.sh --env dev

# 部署到生产环境（需要确认）
./kd-fe-deploy/scripts/full-deploy.sh --env prod
```

## 扩展性

### 自定义构建
支持任意构建命令：
```json
{
  "deploy": {
    "build": {
      "command": "npm run build && tar czf dist.tar.gz dist/",
      "output_pattern": "*.tar.gz"
    }
  }
}
```

### 自定义部署步骤
支持部署前后自定义命令：
```json
{
  "deploy": {
    "target": {
      "pre_commands": [
        "systemctl stop my-app"
      ],
      "post_commands": [
        "systemctl start my-app",
        "systemctl status my-app"
      ]
    }
  }
}
```

## 故障排除

### 配置问题
```bash
# 检查本地配置
./kd-fe-deploy/scripts/setup-local-config.sh --check

# 验证项目配置
./kd-fe-deploy/scripts/validate-config.sh

# 查看配置文件位置
echo $HOME/.kd-deploy/config.json
```

### 权限问题
```bash
# 检查配置文件权限
ls -la ~/.kd-deploy/config.json

# 检查环境变量
echo $DEPLOY_PASSWORD
```

### 配置覆盖
```bash
# 查看当前生效的配置
./kd-fe-deploy/scripts/full-deploy.sh --test --verbose
```

这个分层架构确保了安全性、灵活性和可维护性，使得部署系统既安全又易于使用。