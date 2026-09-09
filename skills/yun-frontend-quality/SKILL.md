---
name: yun-frontend-quality
description: >-
  Guides setup and review of frontend format/lint/editor/git-hook config
  (Prettier or oxfmt, ESLint or oxlint, Stylelint, EditorConfig, husky,
  lint-staged, commitlint; optional npmrc and tsconfig) via an options-only
  wizard. Use when the user asks to configure prettier, eslint, stylelint,
  oxlint, oxfmt, editorconfig, husky, commitlint, formatOnSave, or to review
  and fix lint config conflicts in Vue, React, or JS/TS projects.
metadata:
  version: "1.0.0"
---

# yun-frontend-quality

独立向导：阅读项目 → 检查配置 → 按选择写入。覆盖 Vue / React / 纯 JS·TS（Vite、Next、Vue CLI 等）。

**主模式 Pipeline。** ② 用 Reviewer；③ 选题用 Inversion；汇总与落盘用 Generator。

执行步骤 **按顺序，不得跳过**。Biome 不在范围内；探测到仅作「已有工具」报告，不提供迁入向导。

## 交互契约

每一步只提供 **选项** 和 **说明**。如果有行业最佳实践，也可以列出（单独一节「行业常见做法」，有共识才写；**不**打在选项上、**不**预选、**不**替用户勾）。

- 有 AskQuestion 时优先用；否则对话里编号选项。
- 一次只问一个问题（能力面、只修项、覆盖策略可为多选/单次三选）。
- 说明写清：本步决定什么、影响后面哪一步；每个选项一句「会得到什么 / 代价」。
- 无 `package.json`：选项为停 / 确认这不是前端项目。第一期只配 **仓库根目录**。

完整提问格式见 [references/turn-protocol.md](references/turn-protocol.md)。

## 门禁

- 在用户 **确认项目画像** 之前，不得进入 Step 2。
- 在用户 **选择检查后的处理** 之前，不得改任何文件。
- 在用户 **确认汇总** 之前，不得安装依赖、不得写盘。
- 未完成当前 Step 的必答题，不得进入下一步。
- 绿场 **不预选任何工具**。推荐只来自探测信号（过滤非法组合），不是某套仓库习惯。

## 何时加载

| 时机 | Read |
|------|------|
| 每次提问前 | [references/turn-protocol.md](references/turn-protocol.md) |
| Step 1 | [references/detect.md](references/detect.md) |
| Step 2 | [references/review-checklist.md](references/review-checklist.md)、[references/conflicts.md](references/conflicts.md) |
| Step 3.1～3.2 | [references/capabilities.md](references/capabilities.md)、[references/stack-matrix.md](references/stack-matrix.md) |
| Step 3.3 | [references/questions.md](references/questions.md)、[references/option-map.md](references/option-map.md) |
| Step 4 | [assets/summary-template.md](assets/summary-template.md) |
| Step 5 写入前 | [references/quality-checklist.md](references/quality-checklist.md) |

规范在 references；主文件只调度。查什么在 checklist；怎么问在 turn-protocol；怎么写文件在 option-map + summary。

---

## Step 1 — 阅读项目

按 detect.md 采集（只读，不改文件）。无配置则画像记「空」。

出示 **项目画像**（框架、构建器、包管理器、已有配置与版本、已有风格的人话）。

选项：确认 / 我来改几项 / 停。  
改几项：用户纠正后再确认。停则结束。

**在用户确认画像之前，不得进入 Step 2。**

---

## Step 2 — 检查配置

按 review-checklist 与 conflicts 列出发现。每条：问题、位置、为什么、建议修法。空仓的发现就是「未配置」。

**先提示，再问。** 不得在此步改文件。

选项：

- 不改 → 结束
- 只修这些问题 → 展示发现列表，**可多选**；只修勾上的；**跳过 Step 3**，进入 Step 4（清单仅含勾选项）
- 进入完整配置 → Step 3

空仓选项：进入配置 / 这次不配。

---

## Step 3 — 配置

仅当用户选择完整配置。按序，**不得跳过**子步。未答完不得进入 Step 4。

### 3.1 选要哪些能力

可多选。未勾的域：本轮不问、不写（② 已提示的仍可只在「只修」路径处理）。

能力面与题干说明见 capabilities.md。

### 3.2 对每种已选能力选工具

每种能力 **单独一题**，选项不预选。约束与冲突见 stack-matrix.md：冲突项用说明警告，用选项让用户改选或接受缺口，**禁止默默改掉**。

ESLint 8 eslintrc vs 9+ flat：仅当选了 ESLint **且**探测无法唯一确定时再问。

### 3.3 用案例选同一套风格

**只访谈一次**，映射到所有已选格式化/编辑器工具。对照代码见 questions.md；键名见 option-map.md。

- 一次一题。
- 未探测到 Vue/React 则跳过对应模板题。
- 无行业唯一答案则省略「行业常见做法」。
- commitlint / `.npmrc` / `tsconfig` 用各自短问卷（见 capabilities.md），**不与引号行宽混题**。

「只修」路径跳过 3.1～3.3，沿用现状风格。

---

## Step 4 — 汇总

按 summary-template 列出：能力面、工具与版本、风格表、将改文件、将装依赖、将加 scripts、派生文件（ignore、editorconfig、gitattributes、extensions.json）。

已有文件覆盖策略 **问一次**：

- 全部覆盖
- 已有的跳过
- 改为逐文件再问

选项：确认写入 / 返回修改 / 取消。

**在用户确认汇总之前，不得安装依赖、不得写盘。**

---

## Step 5 — 安装、写入、验证

1. 用探测到的包管理器安装依赖（多个 lockfile 时 Step 1 已问清）。
2. 按汇总与覆盖策略写文件、scripts、hooks、IDE。
3. 对照 quality-checklist 自检。
4. **烟雾验证**：配置能加载；对 1～2 个样例文件跑对应命令（lint/format **dry-run 或不改源码**）。失败则报告哪一步、哪条规则。
5. **不对全仓 `--fix`。** 验证选项：开始验证 / 跳过验证。

路径示例见 [examples.md](examples.md)。
