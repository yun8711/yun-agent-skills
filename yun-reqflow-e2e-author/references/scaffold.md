# E2E 脚手架

无 `e2e/` + `test:e2e` 时，Agent **直接执行**（模板：本 Skill [`assets/`](../assets/)）。

| Agent | 用户 |
|-------|------|
| 依赖、文件、scripts、gitignore、routes、specs | `.env.e2e` 账号；起主/子应用 |

**跳过条件**：已有 `playwright.config.ts`、`e2e/midscene.config.ts`、`test:e2e`。

## 1. 依赖

```bash
pnpm add -D @playwright/test playwright @midscene/web dotenv typescript @types/node
npx playwright install chrome
```

（已有 typescript 可跳过对应包；`@midscene/web` ^1.10、`@playwright/test` ^1.61。）

## 2. 拷贝

| 模板 | 目标 |
|------|------|
| `assets/playwright.config.ts` | `playwright.config.ts` |
| `assets/env.e2e.example` | `.env.e2e.example` |
| `assets/e2e/**` | `e2e/**` |

不覆盖已有业务 specs；不问则不覆盖已有脚手架文件。

## 3. scripts

```json
"test:e2e": "playwright test e2e/specs",
"test:e2e:save-auth": "E2E_AUTH_MODE=none playwright test e2e/scripts/save-auth.spec.ts --headed",
"test:e2e:ui": "playwright test --ui",
"test:e2e:report": "playwright show-report"
```

## 4. gitignore

`.env.e2e`、`/playwright-report`、`/midscene_run`、`/playwright/.cache`、`/e2e/.auth`

## 5. 配置

- `appPrefix`：本仓 `vue.custom.js.name` → `/{name}`（代码已推导）  
- 无 `.env.e2e`：从 example 复制，提醒用户改账号  
- `routes.*`：写用例时再补  

跑测前用户：账号、主应用 8001（或 `E2E_HOST_PORT`）、子应用 port、Chrome、Codex/模型。

自检：`pnpm test:e2e --list`；`baseURL`/`appPrefix` 合理；密钥未提交。
