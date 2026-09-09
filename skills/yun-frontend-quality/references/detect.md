# Step 1 探测清单

只读。产出项目画像，交给用户确认。

## 必须采集

| 项 | 怎么看 |
|----|--------|
| 是否前端项目 | 根目录 `package.json`；没有则不要猜栈 |
| 包管理器 | `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json` / `bun.lockb`；多个则列入画像并在确认后提问 |
| 框架 | 依赖 `vue`（2 vs 3 看版本）、`react`、`next`、无框架 |
| 构建器 | `vite`、`vue-cli-service` / `@vue/cli-service`、`webpack`、`next` |
| 语言 | `typescript`、`.ts`/`.tsx` 数量 |
| CSS | `sass`/`scss`、`less`、`postcss`、Tailwind、UnoCSS、CSS-in-JS |
| 已有格式化 | `prettier` 配置文件或 `package.json.prettier`；`oxfmt` / `.oxfmtrc*` |
| 已有 JS 检查 | `eslint` 版本；`.eslintrc*` vs `eslint.config.*`；`.oxlintrc*` / `oxlint` |
| 已有 CSS 检查 | `stylelint` 与配置文件 |
| 其它 | `.editorconfig`、`.vscode/settings.json`、`extensions.json`、husky、lint-staged、commitlint、`.npmrc`、`tsconfig*.json`、ignore 文件 |
| 脚本 | `lint` / `format` / `fmt` 等 |
| 已有风格 | 从已有配置翻译成人话（引号、分号、行宽、缩进、尾逗号）。读不出则写「未知」 |

## 画像字段（出示给用户）

- 框架 / 构建器 / 语言 / CSS
- 包管理器
- 已有工具与配置格式（eslint 8 eslintrc / 9+ flat 等）
- 已有风格（人话）
- 空仓：写明「未检测到质量工具配置」

## 第一期范围

- 只描述 **仓库根**；monorepo 子包不自动铺，画像可一句提到存在 `packages/`。
- 探测到 Biome：记入「已有工具」，不进入迁入/迁出选项。
