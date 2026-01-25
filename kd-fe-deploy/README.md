# 前端部署自动化 (kd-fe-deploy)

一个完整的CI/CD自动化部署解决方案，专门为前端项目设计，支持通过堡垒机连接内网服务器的部署场景。

## 功能特性

- 自动化构建：默认执行 `npm run build` 并自动压缩 `dist` 目录
- 堡垒机连接：支持明文密码认证，自动处理 JumpServer 交互
- 文件传输：自动上传构建产物到服务器
- 部署执行：自动解压到目标目录
- 环境管理：支持通过 `--env` 切换堡垒机环境

## 快速开始

### 1. 准备工作

确保系统已安装必需依赖：
- **Linux/macOS**: `jq`, `expect`, `openssh-client`, `zip`
- **Windows (Git Bash/WSL)**: `jq`, `expect`, `openssh` (Windows 10/11 原生支持 PowerShell 压缩，无需安装 `zip`)

### 2. 配置架构说明

#### 团队级配置（用户本地敏感信息）
存储在开发者本地的用户目录下：`~/.kd-deploy/config.json`。

**配置示例 (`~/.kd-deploy/config.json`)：**
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

#### 项目级配置（项目特定）
在项目的 `package.json` 中配置部署目标路径：
```json
{
  "name": "my-frontend-project",
  "deploy-path": "/data/application/qiankun/subapp/rhea/"
}
```

### 3. 执行部署

```bash
# 完整部署（默认执行 npm run build）
./kd-fe-deploy/scripts/full-deploy.sh

# 指定环境部署
./kd-fe-deploy/scripts/full-deploy.sh --env 12
```

## 安全建议

1. **本地配置安全**：建议设置本地配置文件权限：`chmod 600 ~/.kd-deploy/config.json`。
2. **明文密码**：请确保你的本地开发环境安全。

## 故障排除

- **找不到环境配置**：检查 `~/.kd-deploy/config.json` 中的 `alias` 是否匹配。
- **部署路径错误**：检查 `package.json` 中的 `deploy-path` 是否正确。
- **构建失败**：默认执行 `npm run build` 并压缩 `dist` 目录，请确保构建产物在 `dist` 文件夹中。

## 许可证

MIT License
