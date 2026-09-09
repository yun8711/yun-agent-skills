# Step 2 检查清单

对照当前画像。每条发现写：问题、位置、为什么、建议修法（供用户多选）。不改文件。

输出结构：

```markdown
### Summary
（空仓 / 有冲突 / 仅缺失卫星配置）

### Findings
- id / 问题 / 位置 / 为什么 / 建议修法
```

## 查什么

1. **未配置**：无格式化、无 JS 检查、无 CSS 检查（项目有样式文件时）、无 EditorConfig。
2. **双格式化器**：Prettier 与 oxfmt 同时作为默认格式化（脚本或 IDE）。
3. **规则重叠**：ESLint 仍开 `indent` / `quotes` / `semi` / `max-len` 且未关格式冲突；未使用与 Prettier 配套的关闭重叠规则方式。
4. **IDE 抢格式化**：Vue/React 文件默认格式化器不是用户的格式化工具（例如 Vue Official 与 Prettier 并存）。
5. **ignore 缺失**：会对 `dist`、`node_modules`、`coverage`、构建产物跑 lint。
6. **链路残缺**：有 lint 脚本但无 lint-staged / husky；有 husky 无 `commit-msg`（仅当用户关心提交信息时作为 info）。
7. **栈与配置格式**：Vue CLI 项目却是 ESLint flat（或相反）——只报告风险，不自动升级。
8. **oxlint-only + Vue/React 模板**：说明模板/框架规则可能不足。
9. **同风格不一致**：prettier 单引号、eslint 双引号等。
10. **`.npmrc` / `tsconfig`**：仅当文件明显与已探测包管理器或 `moduleResolution` 和构建器矛盾时列为 info，不把风格偏好当错误。

空仓：一条发现「未配置」，建议进入完整配置。
