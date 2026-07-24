# 项目就绪检查

## KD（有本仓 `vue.custom.js`）

1. Read [kd-fe-config.md](kd-fe-config.md) → 输出快照表。  
2. 问当前阶段。

| 阶段 | 必查 |
|------|------|
| clarify | 快照、`req_docs`、gitignore、分支 |
| implement | `已确认`；强依赖接口已对齐或可 mock |
| e2e-* | 无脚手架则 author Step 0 安装；用户填账号、起服务 |

## 非 KD

问 baseURL、登录、是否有 e2e；另查 `req_docs` ignore、分支。
