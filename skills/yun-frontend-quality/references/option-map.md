# 风格表 → 配置键

3.3 只收一份风格表，再写入所有已选工具。某工具没有对应键则跳过并在汇总注明。

## 格式化（Prettier；oxfmt 用其 Prettier 兼容键，文件名以 oxfmt 文档为准）

| 风格表字段 | 键 |
|------------|-----|
| 引号 单/双 | `singleQuote` true/false |
| 分号 有/无 | `semi` |
| 尾逗号 无/多行/全有 | `trailingComma`: none / es5 / all |
| 行宽 80/100/120 | `printWidth` |
| 缩进 2 空格 / 4 空格 / Tab | `tabWidth` + `useTabs` |
| 多行 JSX/HTML 的 `>` 单独一行 | `bracketSameLine: false`（跟在末属性后则为 true） |
| 属性超宽才拆行 | `singleAttributePerLine: false`（强制每行一属性则为 true） |
| 箭头函数参数括号 | `arrowParens`: avoid / always（仅当问了此题） |

EditorConfig 派生：`indent_style` / `indent_size`、`max_line_length` ← 行宽、`end_of_line = lf`、`charset = utf-8`、`trim_trailing_whitespace`、`insert_final_newline`。

`.gitattributes` 派生：文本 `eol=lf`（与 EditorConfig 一致即可）。

## ESLint

- **不要**再设 `indent` / `quotes` / `semi` / `max-len` 与格式化器对着干。
- Vue：`vue/html-closing-bracket-newline`、`vue/max-attributes-per-line` 与 `bracketSameLine`、`singleAttributePerLine` **对齐**，不要把 Prettier 的 `singleAttributePerLine: false` 配成 ESLint 强制每行一属性。
- 质量规则用该框架的 recommended；放宽项仅当用户在卫星题里选了再改。

## Stylelint

- extends 用 standard（有 SCSS 再加 scss；有 Vue SFC style 再加 vue）。
- 属性顺序：用户未问则汇总里列为将使用常见 order 插件或省略，**写入前在汇总展示**，覆盖策略那次一并确认。
- 不与格式化器抢引号/缩进类格式。

## IDE

- `editor.formatOnSave`: true
- `editor.defaultFormatter`：Prettier 扩展或 Oxc/oxfmt 扩展（随 3.2）
- `[vue]` / `[javascriptreact]` / `[typescriptreact]`：同一格式化器，不要用框架语言扩展做格式化
- `extensions.json`：按已选工具列推荐扩展 ID

## 提交

lint-staged：对已暂存文件跑 JS 检查 `--fix` → CSS `--fix`（若启用）→ **格式化最后**。
