# E2E

| 项 | 来源 |
|----|------|
| appPrefix | `vue.custom.js` `name` → `/{name}`；或 `E2E_APP_PREFIX` |
| baseURL | `E2E_BASE_URL` 或 `E2E_HOST`+`E2E_HOST_PORT`（默认 `localhost:8001`） |
| 账号 | `.env.e2e` |
| 路由 | `e2e/midscene.config.ts` → `routes.*` |

登录：`/login` → `/card` → `{appPrefix}#/...`

主应用 + 本仓 serve 后：`pnpm test:e2e`（无头 `E2E_HEADLESS=1`）。  
登录态：`e2e/.auth/storage-state.json`；重登 `E2E_FORCE_LOGIN=1`。  
录制：`midscene_run/api/`；关 `E2E_API_RECORD=0`。
