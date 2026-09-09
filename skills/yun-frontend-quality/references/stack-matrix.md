# 栈与配置格式

用于 3.2 说明与过滤，**不是**默认勾选表。绿场工具选项仍全空。

## ESLint 配置格式

仅当用户选了 ESLint，且探测无法唯一确定时再问 8+eslintrc 还是 9+flat。

| 探测信号 | 写入时说明 |
|----------|------------|
| 已有 `.eslintrc*` 或 eslint 8 | 保持 eslintrc，除非用户在 3.2 明确改 flat |
| 已有 `eslint.config.*` | 保持 flat |
| 绿场 + Vite / Next | 文档与脚手架以 flat 居多（写进「行业常见做法」，不预选） |
| Vue CLI 5 / webpack 4 类 | 插件与 CLI 仍常见 eslintrc（写进说明，不预选） |

问版本时说明：格式（eslintrc vs flat）比「8 还是 9」数字更影响文件形态。按已装 `eslint` 大版本对齐；绿场让用户选，再按所选格式写对应配置文件。

## 框架插件（用户选了 ESLint 时）

| 框架 | 常见配套（说明用） |
|------|-------------------|
| Vue 2 | `eslint-plugin-vue` 的 Vue 2 配置 |
| Vue 3 | `eslint-plugin-vue` 的 Vue 3 / flat 配置 |
| React | `eslint-plugin-react` + `eslint-plugin-react-hooks` |
| Next | 仓内常有 `eslint-config-next`；已有则选项含保持 |

oxlint：Vue/React 文件往往只深入 script/JSX 一部分；模板/框架规则不足时在说明里写出，选项允许「oxlint + ESLint」。

## 包与文件（按用户选择生成，不写死版本号）

- 用项目包管理器安装；版本取当时 npm 上与所选大版本线兼容的范围，**不要在 Skill 正文写具体年月或补丁号**。
- 配置文件名随工具：`prettier.config.*` 或 oxfmt 当前文档中的配置文件；`eslint.config.*` 或 `.eslintrc.*`；`stylelint.config.*`；`.oxlintrc.json` 等以该工具文档为准。
- 第一期不做 Biome。
