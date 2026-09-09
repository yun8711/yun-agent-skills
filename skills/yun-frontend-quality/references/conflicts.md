# 冲突与禁止组合

写入前与 Step 2 共用。用选项让用户改选或接受缺口，禁止静默替换工具。

## 硬冲突（写入时不可并存为默认）

| 组合 | 原因 |
|------|------|
| Prettier + oxfmt 都当默认格式化器 | 保存/提交会互相改写 |
| ESLint 风格规则与格式化器同时生效且未关闭重叠 | 同一文件两种缩进/引号 |
| 两个 IDE 默认格式化器 | formatOnSave 结果不稳定 |

## 能力缺口（可选，须说明）

| 组合 | 说明 |
|------|------|
| 仅 oxlint、项目为 Vue/React | 主要检查脚本；SFC/JSX 框架规则通常仍要 ESLint 插件 |
| 无 Stylelint、项目有大量 SCSS/Vue `<style>` | 格式化器管折行，不管属性顺序与 CSS 语义 |
| ESLint 8 eslintrc 用在全新 Vite 绿场 | 能跑；生态文档以 flat 居多 |
| ESLint 9+ flat 用在 Vue CLI 5 | 插件与 CLI 链路可能不齐，须用户接受风险 |

## 写入时自动处理（仍须在汇总里列出）

- 选了 Prettier：JS 检查侧关闭与 Prettier 重叠的格式规则（eslint-config-prettier 或等价）。
- 选了 oxlint + ESLint：关掉两边重复的规则（如 eslint-plugin-oxlint 或文档推荐方式）。
- lint 脚本顺序：JS/CSS `--fix` 之后，**格式化工具最后执行**。
- Vue/React 文件：IDE 默认格式化器与所选格式化工具一致。
