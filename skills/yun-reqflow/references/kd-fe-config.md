# KD 配置发现

有本仓 `vue.custom.js` 时按此取值。

| 来源 | 字段 / 变量 | 用途 |
|------|-------------|------|
| `vue.custom.js` | `name` | `activeRule` = `/{name}` |
| 同上 | `port` / `publicPath` | standalone |
| 同上 | `host` / `prefixArr` | 联调代理，非页面 baseURL |
| env | `E2E_HOST` / `E2E_HOST_PORT`（默认 `localhost`/`8001`） | 主应用 |
| env | `E2E_BASE_URL` | 整段覆盖 baseURL |
| env | `E2E_APP_PREFIX` | 覆盖 activeRule |

业务 URL：`http://localhost:{hostPort}/{name}#/{hash}`  
登录：`/login` → `/card` → `{activeRule}#/...`（`E2E_ENTRY=host`）

| 本仓 | 位置 |
|------|------|
| 请求 | 常见 `src/utils/request.js` |
| 接口 | `src/server/` 或 `src/api/` |
| 需求 | `req_docs/`（gitignore `/req_docs`） |
| e2e | `yun-reqflow-e2e-author` 的 assets + scaffold；`.env.e2e` / `e2e/midscene.config.ts` |

## 快照表（Step 0 必出）

| 项 | 值 | 来源 |
|----|-----|------|
| name / port / publicPath | | `vue.custom.js` |
| activeRule | `/{name}` | name 或 `E2E_APP_PREFIX` |
| 主应用 baseURL | | `E2E_BASE_URL` 或 host+port |
| 接口目录 | | Glob |
| req_docs ignore / e2e | | `.gitignore` / `e2e/`+`test:e2e` |
