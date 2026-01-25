---
name: kd-fe-deploy
description: 自动化前端项目构建和部署到内网服务器，支持通过 JumpServer 堡垒机连接。当用户需要部署前端应用、在 package.json 中配置部署路径、通过堡垒机连接内网服务器、或设置前端 CI/CD 时使用此技能。
---

# 前端部署自动化 (kd-fe-deploy)

自动化前端代码构建和部署到内网服务器，支持通过 JumpServer 堡垒机连接。

## 使用场景

在以下情况下应用此技能：
- 部署前端应用到内网服务器
- 在 package.json 中配置部署路径
- 通过 JumpServer 堡垒机连接服务器
- 设置前端项目的自动化 CI/CD
- 管理内网环境的部署任务

## 配置说明

### 团队级配置 (~/.kd-deploy/config.json)

创建本地配置文件，包含你的凭证和环境设置：

```json
{
  "user": "your_username",
  "password": "your_password",
  "env_list": [
    {
      "alias": "12,12环境,内网",
      "host": "192.168.12.100",
      "port": 2222
    }
  ]
}
```

**安全提示**：此文件包含敏感信息，不应提交到版本控制系统。

### 项目配置 (package.json)

在项目的 package.json 中添加部署配置：

```json
{
  "name": "my-project",
  "deploy-path": "/data/application/qiankun/subapp/rhea/"
}
```

## 部署流程

### 快速部署

执行完整的部署流程：

```bash
# 默认部署（构建并部署到默认环境）
./kd-fe-deploy/scripts/full-deploy.sh

# 部署到指定环境
./kd-fe-deploy/scripts/full-deploy.sh --env 12
```

### 手动步骤（如需要）

1. **验证配置**：确保 ~/.kd-deploy/config.json 存在
2. **构建项目**：运行 `npm run build`（自动执行）
3. **打包构建产物**：压缩 dist 目录（自动处理）
4. **通过 JumpServer 连接**：建立堡垒机连接
5. **上传和部署**：传输文件并解压到目标目录

## 前置要求

确保已安装以下工具：
- jq（JSON 处理）
- expect（自动化脚本）
- openssh-client（SSH 连接）
- zip（文件压缩）

## 故障排除

### 常见问题

- **配置文件缺失**：创建 ~/.kd-deploy/config.json 并填入正确的凭证
- **环境未找到**：检查 env_list 数组中的 alias 是否匹配
- **构建失败**：确保 npm run build 生成 dist/ 目录
- **连接问题**：检查 JumpServer 凭证和网络访问权限

### 验证步骤

运行配置验证：

```bash
./kd-fe-deploy/scripts/validate-config.sh
```

## 使用示例

### 基础部署

```bash
# 进入项目目录
cd my-frontend-project

# 确保 package.json 中配置了 deploy-path
# 确保 ~/.kd-deploy/config.json 存在并包含凭证

# 执行部署
../kd-fe-deploy/scripts/full-deploy.sh
```

### 多环境配置

在 ~/.kd-deploy/config.json 中配置多个环境：

```json
{
  "user": "developer",
  "password": "secure_password",
  "env_list": [
    {
      "alias": "dev",
      "host": "192.168.1.100",
      "port": 2222
    },
    {
      "alias": "staging",
      "host": "192.168.2.100",
      "port": 2222
    },
    {
      "alias": "prod",
      "host": "192.168.3.100",
      "port": 2222
    }
  ]
}
```

部署到指定环境：
```bash
./kd-fe-deploy/scripts/full-deploy.sh --env staging
```
