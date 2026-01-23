# 前端部署自动化 (kd-fe-deploy)

一个完整的CI/CD自动化部署解决方案，专门为前端项目设计，支持通过堡垒机连接内网服务器的部署场景。

## 功能特性

- ✅ **自动化构建**：自动执行yk构建命令，生成部署产物
- ✅ **堡垒机连接**：支持密码认证，自动处理JumpServer交互
- ✅ **文件传输**：自动上传构建产物到服务器
- ✅ **部署执行**：自动解压、权限设置、启动服务
- ✅ **环境管理**：支持多环境部署（开发/测试/生产）
- ✅ **备份恢复**：自动备份旧版本，支持快速回滚
- ✅ **健康检查**：部署完成后自动验证服务状态
- ✅ **通知告警**：支持邮件、Slack等通知方式
- ✅ **配置验证**：自动检查配置和环境依赖

## 快速开始

### 1. 准备工作

确保系统已安装必需依赖：
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install jq expect openssh-client curl

# macOS
brew install jq expect openssh curl

# CentOS/RHEL
sudo yum install jq expect openssh-clients curl
```

### 2. 环境要求

- **操作系统**: Linux, macOS, WSL
- **Shell**: Bash 4.0+
- **网络**: 能够访问堡垒机
- **权限**: 本地用户有SSH访问权限

### 2. 配置架构说明

部署系统采用**分层配置架构**：

#### 本地配置（敏感信息）
存储在 `~/.kd-deploy/config.json`，包含堡垒机等敏感信息：
```bash
# 创建本地配置目录
mkdir -p ~/.kd-deploy

# 复制本地配置模板
cp kd-fe-deploy/config-template-local.json ~/.kd-deploy/config.json

# 编辑本地配置
vim ~/.kd-deploy/config.json
```

#### 项目配置（项目特定）
在项目的 `package.json` 中添加 `deploy` 字段：
```json
{
  "name": "my-frontend-project",
  "deploy": {
    "build": {
      "command": "yk zip-dist -b build"
    },
    "server": {
      "pattern": "12.168"
    },
    "target": {
      "path": "/data/app/my-project/"
    }
  }
}
```

### 3. 配置本地堡垒机信息

**创建本地配置（存储堡垒机等敏感信息）**
```bash
# 交互式配置（推荐）
./kd-fe-deploy/scripts/setup-local-config.sh --interactive

# 或手动创建
mkdir -p ~/.kd-deploy
cp kd-fe-deploy/config-template-local.json ~/.kd-deploy/config.json
vim ~/.kd-deploy/config.json
```

**设置堡垒机密码**
```bash
# 设置环境变量
export DEPLOY_PASSWORD="your_password"

# 或使用密码设置工具
./kd-fe-deploy/scripts/setup-password.sh --interactive
```

**注意**：本地配置包含敏感信息，不会提交到版本控制系统。

### 4. 验证配置

```bash
# 验证配置和环境
./kd-fe-deploy/scripts/validate-config.sh

# 测试堡垒机连接
./kd-fe-deploy/scripts/connect-server.sh your_project test
```

### 5. 执行部署

```bash
# 完整部署（自动读取package.json中的deploy配置）
./kd-fe-deploy/scripts/full-deploy.sh

# 指定环境部署
./kd-fe-deploy/scripts/full-deploy.sh --env prod

# 测试模式
./kd-fe-deploy/scripts/full-deploy.sh --test

# 仅构建
./kd-fe-deploy/scripts/full-deploy.sh --build-only

# 仅部署
./kd-fe-deploy/scripts/full-deploy.sh --deploy-only
```

## 配置详解

### 分层配置架构

#### 1. 本地配置 (~/.kd-deploy/config.json)
存储敏感信息，不应提交到版本控制：
```json
{
  "version": "1.0",
  "bastion": {
    "host": "192.168.12.100",        // 堡垒机IP地址
    "port": 2222,                     // 堡垒机SSH端口
    "user": "liuyun",                 // 堡垒机用户名
    "auth_method": "password",        // 认证方式（密码认证）
    "password_env_var": "DEPLOY_PASSWORD", // 密码环境变量名
    "connection_timeout": 30          // 连接超时时间（秒）
  },
  "defaults": {
    "backup_old_version": true,       // 默认备份设置
    "max_retries": 3,                 // 默认重试次数
    "timeout": 300,                   // 默认超时时间
    "log_level": "info"               // 默认日志级别
  }
}
```

#### 2. 项目配置 (package.json)
在项目的package.json中添加deploy字段：
```json
{
  "name": "my-frontend-project",
  "version": "1.0.0",
  "deploy": {
    "version": "1.0",
    "build": {
      "command": "yk zip-dist -b build",  // 构建命令
      "output_pattern": "*.zip"           // 输出文件模式
    },
    "server": {
      "pattern": "12.168",                // JumpServer服务器选择模式
      "description": "开发环境服务器"
    },
    "target": {
      "path": "/data/app/my-project/",    // 服务器部署路径
      "backup": true,                     // 是否备份旧版本
      "post_commands": [                  // 部署后执行的命令
        "ls -la",
        "echo 'Deploy completed successfully'"
      ]
    },
    "environments": {
      "dev": {
        "server_pattern": "12.168",
        "description": "开发环境"
      },
      "prod": {
        "server_pattern": "12.170",
        "description": "生产环境",
        "confirm_required": true
      }
    }
  }
}
```

## 脚本说明

| 脚本文件 | 功能说明 | 使用场景 |
|---------|---------|---------|
| `full-deploy.sh` | 完整部署流程 | 主要部署入口 |
| `deploy.sh` | 核心部署逻辑 | 高级用户使用 |
| `build.sh` | 构建脚本 | 单独构建需求 |
| `connect-server.sh` | 堡垒机连接 | 连接测试和调试 |
| `validate-config.sh` | 配置验证 | 环境检查 |
| `setup-local-config.sh` | 本地配置初始化 | 初始化堡垒机配置 |
| `setup-password.sh` | 密码设置工具 | 安全配置堡垒机密码 |

## 工作流程

### 正常部署流程

1. **配置验证**：检查配置文件和系统环境
2. **本地构建**：执行`yk zip-dist -b <param>`生成zip包
3. **连接堡垒机**：SSH连接并处理JumpServer交互
4. **服务器切换**：`sudo -i`切换到管理员权限
5. **目录进入**：进入项目部署目录
6. **文件上传**：使用trz/tsz上传构建产物
7. **解压部署**：解压文件到部署目录
8. **后处理**：执行自定义部署命令
9. **清理工作**：删除上传的zip文件
10. **健康检查**：验证部署结果

### 错误处理流程

- 构建失败：终止部署，显示错误信息
- 连接失败：重试连接，最多3次
- 上传失败：清理临时文件，终止部署
- 部署失败：自动回滚（如果启用）
- 健康检查失败：告警通知，不自动回滚

## 高级功能

### 备份和回滚

```bash
# 启用自动备份
{
  "projects": {
    "rhea": {
      "backup_old_version": true
    }
  }
}
```

### 通知配置

```json
{
  "notifications": {
    "enable": true,
    "type": "email",
    "recipients": ["dev-team@company.com"],
    "on_success": true,
    "on_failure": true
  }
}
```

### 自定义部署命令

```json
{
  "projects": {
    "rhea": {
      "post_deploy_commands": [
        "systemctl restart nginx",
        "echo 'Deploy completed'"
      ]
    }
  }
}
```

## 故障排除

### 常见问题

**Q: 连接堡垒机失败**
```bash
# 检查SSH配置
ssh -T bastion

# 测试连接
./kd-fe-deploy/scripts/connect-server.sh project test
```

**Q: 构建失败**
```bash
# 检查yk工具
which yk

# 检查Node.js环境
node --version && npm --version

# 手动测试构建
yk zip-dist -b build
```

**Q: 权限问题**
```bash
# 检查堡垒机密码设置
echo $DEPLOY_PASSWORD  # 应该有输出

# 如果没有设置密码环境变量
export DEPLOY_PASSWORD="your_actual_password"

# 测试密码认证
./kd-fe-deploy/scripts/connect-server.sh rhea test
```

**Q: JumpServer交互失败**
- 检查server_pattern配置是否正确
- 确认堡垒机账户有相应服务器权限
- 查看详细日志输出

### 调试模式

```bash
# 启用详细输出
./kd-fe-deploy/scripts/full-deploy.sh rhea --verbose

# 测试模式（不实际部署）
./kd-fe-deploy/scripts/full-deploy.sh rhea --test
```

### 日志查看

```bash
# 查看部署日志
tail -f /tmp/kd-deploy.log

# 查看系统日志
journalctl -u kd-deploy -f
```

## 安全注意事项

1. **密码管理**
   - 避免在配置文件中明文存储密码
   - 使用环境变量或密钥管理服务
   - 定期轮换密码和密钥

2. **密码安全**
   - 使用强密码（至少12位，包含大小写字母、数字、特殊字符）
   - 定期更换堡垒机密码
   - 使用环境变量而非配置文件存储密码
   - 不要在脚本中硬编码密码

3. **网络安全**
   - 仅允许必要的网络访问
   - 使用防火墙限制堡垒机访问
   - 启用审计日志

4. **部署安全**
   - 验证构建产物完整性
   - 使用最小权限原则
   - 实施变更审批流程

## 最佳实践

### 项目结构建议

```
your-project/
├── kd-fe-deploy/          # 部署工具
│   ├── config.json       # 项目配置
│   ├── scripts/          # 部署脚本
│   └── examples/         # 配置示例
├── src/                  # 源代码
├── package.json         # 项目配置
└── README.md           # 项目文档
```

### 配置管理

- 为不同环境维护独立配置
- 使用版本控制管理配置文件
- 敏感信息使用环境变量

### 部署策略

- 小步快跑，频繁部署
- 实施自动化测试
- 准备回滚方案
- 监控部署结果

### 团队协作

- 标准化部署流程
- 文档化部署步骤
- 培训团队成员
- 建立部署规范

## 扩展开发

### 添加新功能

1. **自定义构建器**
```bash
# 在build.sh中添加新的构建逻辑
case "$BUILD_TOOL" in
    "yk") yk zip-dist -b "$build_param" ;;
    "npm") npm run build ;;
    "yarn") yarn build ;;
esac
```

2. **新的通知方式**
```bash
# 在deploy.sh中添加通知逻辑
send_notification() {
    case "$NOTIFY_TYPE" in
        "email") send_email ;;
        "slack") send_slack ;;
        "webhook") send_webhook ;;
    esac
}
```

3. **集成其他工具**
- Docker容器化部署
- Kubernetes集群部署
- 云服务集成

### 贡献指南

欢迎提交Issue和Pull Request来改进这个工具！

## 许可证

MIT License

## 支持

如有问题，请：
1. 查看[故障排除](#故障排除)部分
2. 提交GitHub Issue
3. 联系运维团队