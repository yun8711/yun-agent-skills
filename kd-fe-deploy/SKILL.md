---
name: kd-fe-deploy
description: 自动化前端代码构建和部署到内网服务器。使用SSH密钥或密码认证连接堡垒机，自动处理JumpServer交互，实现完整的CI/CD部署流程。适用于前端项目部署、微服务更新、自动化发布等场景。
---

# 前端部署自动化 (kd-fe-deploy)

这个skill实现了完整的前端代码构建和部署自动化流程，包括本地构建、堡垒机连接、服务器选择、文件上传和部署等步骤。

## 快速开始

### 1. 配置项目
```bash
# 复制配置模板
cp kd-fe-deploy/config-template.json kd-fe-deploy/config.json

# 编辑配置文件，设置您的堡垒机和项目信息
vim kd-fe-deploy/config.json
```

### 2. 部署项目
```bash
# 部署指定项目
./kd-fe-deploy/scripts/deploy.sh rhea

# 或使用完整部署流程
./kd-fe-deploy/scripts/full-deploy.sh rhea
```

## 工作流程

### 完整部署流程
1. **本地构建**：运行 `yk zip-dist -b <build_param>` 生成zip包
2. **堡垒机连接**：自动SSH连接到堡垒机并认证
3. **服务器选择**：自动选择目标服务器（通过IP模式匹配）
4. **权限切换**：执行 `sudo -i` 切换到管理员权限
5. **目录切换**：进入项目部署目录
6. **文件上传**：使用trz/tsz命令上传构建产物
7. **解压部署**：解压文件到部署目录
8. **清理工作**：删除上传的zip文件

## 配置说明

### 分层配置架构

#### 1. 本地配置 (~/.kd-deploy/config.json)
存储堡垒机等敏感信息：
```json
{
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
    "timeout": 300
  }
}
```

#### 2. 项目配置 (package.json)
在项目的package.json中添加deploy字段：
```json
{
  "name": "my-frontend-project",
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
    }
  }
}
```

## 认证方式

### 密码认证（堡垒机专用）

由于堡垒机不支持SSH密钥认证，我们使用密码认证：

#### 方法1：环境变量（推荐）
```bash
# 设置环境变量
export DEPLOY_PASSWORD="your_password_here"

# 配置文件中设置
{
  "bastion": {
    "auth_method": "password",
    "password": null,
    "password_env_var": "DEPLOY_PASSWORD"
  }
}
```

#### 方法2：配置文件直接设置（不推荐）
```json
{
  "bastion": {
    "auth_method": "password",
    "password": "your_password_here",
    "password_env_var": null
  }
}
```

**安全提醒**：
- 优先使用环境变量，避免密码明文存储
- 不要将包含密码的配置文件提交到版本控制
- 定期更换堡垒机密码

## 使用场景

### 开发环境部署
```bash
./kd-fe-deploy/scripts/deploy.sh rhea dev
```

### 生产环境部署
```bash
./kd-fe-deploy/scripts/deploy.sh rhea prod
```

### 批量部署
```bash
./kd-fe-deploy/scripts/deploy-multiple.sh rhea qiankun
```

## 脚本说明

### 核心脚本
- `build.sh`：本地构建脚本
- `connect-server.sh`：堡垒机连接和服务器选择
- `deploy.sh`：完整部署流程
- `upload-file.sh`：文件上传脚本

### 工具脚本
- `validate-config.sh`：配置验证
- `check-dependencies.sh`：依赖检查
- `cleanup.sh`：清理脚本

## 安全注意事项

1. **密码存储**：避免在配置文件中明文存储密码，使用环境变量或密钥管理
2. **SSH密钥**：使用带密码保护的SSH密钥对
3. **权限控制**：部署脚本只执行必要的操作
4. **日志记录**：敏感信息不会记录到日志中

## 故障排除

### 连接问题
```bash
# 测试堡垒机连接
./kd-fe-deploy/scripts/test-connection.sh

# 检查SSH配置
ssh -T bastion
```

### 构建问题
```bash
# 检查构建环境
./kd-fe-deploy/scripts/check-build-env.sh

# 手动构建测试
yk zip-dist -b build
```

### 部署问题
```bash
# 检查部署目录权限
./kd-fe-deploy/scripts/check-deploy-perms.sh rhea

# 查看部署日志
tail -f /tmp/kd-deploy.log
```

## 扩展功能

### 自定义构建
修改 `scripts/build.sh` 以支持不同的构建工具：
- npm/yarn
- webpack
- vite
- 其他构建系统

### 多环境支持
在配置中添加环境特定设置：
```json
{
  "environments": {
    "dev": {"server_pattern": "12.168"},
    "test": {"server_pattern": "12.169"},
    "prod": {"server_pattern": "12.170"}
  }
}
```

### 部署验证
添加部署后验证步骤：
- 健康检查
- 版本验证
- 回滚机制

## 最佳实践

1. **配置管理**：每个项目单独维护配置
2. **版本控制**：将配置文件纳入版本控制（敏感信息除外）
3. **测试验证**：在部署前进行充分测试
4. **回滚准备**：准备回滚方案以应对部署失败
5. **监控告警**：监控部署状态和系统健康

## 相关文件

- [config-template.json](config-template.json)：配置模板
- [examples/project-config.json](examples/project-config.json)：完整配置示例
- scripts/ 目录：所有自动化脚本
- README.md：详细使用说明