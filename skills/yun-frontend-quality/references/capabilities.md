# 能力面与卫星问卷

## 3.1 能力面（可多选，不预选）

出题时带说明 + 有共识则写「行业常见做法」+ 选项。

| id | 能力 | 说明（题干可用） |
|----|------|------------------|
| format | 格式化 | 管折行、引号、分号等最终样子 |
| js | JS/TS 检查 | 管质量规则，不管最后怎么折行 |
| css | CSS 检查 | 样式语义与属性顺序；无样式文件可跳过 |
| integrate | 编辑器与提交 | EditorConfig、VSCode/Cursor、husky、lint-staged |
| commitlint | 提交说明规范 | 与 husky `commit-msg` 一起；未勾 integrate 时说明 hooks 依赖 |
| npmrc | 包管理器配置 | 不管代码样子；registry 有仓则保留，不问口令 |
| tsconfig | TypeScript 编译 | 不管格式；无 TS 则不要勾 |

**行业常见做法（3.1 题干可用）：**

- 多数前端会同时要格式化 + JS 检查。
- 有独立 CSS/SCSS/Vue style 时再上 CSS 检查。
- 团队用 git 时，提交前跑 lint-staged 很常见。
- `tsconfig` / `.npmrc` 与 lint 不同域，需要时再勾。

派生、不单独占 3.1：`.prettierignore` 等 ignore、`.editorconfig`、`.gitattributes`、`.vscode/extensions.json`。出现在 Step 4 汇总，随覆盖策略。

## 3.2 工具选项（每能力一题，不预选）

**格式化：** Prettier / oxfmt / 本轮不配。  
说明：二者都面向「最终折行」；不要两个都当默认。  
常见做法：长期主流是 Prettier；oxfmt 走 Prettier 兼容、偏速度。

**JS/TS：** ESLint / oxlint / 两者都要 / 本轮不配。  
常见做法：多数项目用 ESLint（插件和框架规则最全）。追求速度时用 oxlint，或 oxlint 打头、ESLint 只留框架规则。不要重复开同一条规则。

**CSS：** Stylelint / 本轮不配。  
常见做法：有 SCSS 或组件内样式时用 Stylelint；纯 Tailwind/原子类且无手写 CSS 可以不配。

**集成：** 生成 EditorConfig + IDE settings + husky/lint-staged / 只 IDE / 只 hooks / 本轮不配。  
常见做法：formatOnSave 与提交前 lint-staged 一起用，本地和 CI 更一致。

## 卫星短问卷（勾了才问，与风格题分开）

**commitlint：** 用好/坏 commit 例句（见 questions.md）选 conventional 类型风格；仓内已有 `commitlint.config.*` 则选项含「保持现有」。

**`.npmrc`：** 是否限制只能一种包管理器；是否需要提升依赖（旧 Vue CLI 常见 hoist）。**不问 registry 账号。** 已有 `.npmrc` 选项含「保持现有」。

**`tsconfig`：** 三档对照（见 questions.md）：松 / 常用 / 严。已有文件选项含「保持现有」。不要展开全部 compilerOptions。
