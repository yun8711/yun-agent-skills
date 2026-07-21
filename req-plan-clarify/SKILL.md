---
name: req-plan-clarify
description: >-
  将项目需求文档收敛为可执行工作计划：对照代码现状、列出清单、澄清不确定项、
  经确认后回写结论到 req_docs（gitignore）。不主动改业务代码。
  Use when the user invokes req-plan-clarify, or asks to 梳理需求文档、出工作计划、
  澄清需求并回写、客户分支需求落地规划（显式触发；disable-model-invocation）。
disable-model-invocation: true
---

# req-plan-clarify

将「需求文档 → 对照现状 → 工作计划 → 澄清确认 → 回写结论」做成固定流水线。  
**主模式 Pipeline + 辅模式 Inversion + Generator（模板）**。

## 硬性门禁

1. **按 Step 顺序执行，不得跳过**（尤其不可跳过对照代码直接拍计划）。
2. **在用户确认工作计划与全部澄清答案之前，不得回写终稿，不得改业务代码**。
3. **用户未明确说「改代码 / 开始实现」时，流程止于文档回写**。
4. **回写只写结论性内容，不写讨论过程**。
5. 答复默认使用**中文**（用户另有说明除外）。

## 文档目录约定

| 项 | 约定 |
|----|------|
| 默认目录 | 项目根下 `req_docs/` |
| Git | 必须忽略；若不在 `.gitignore`，**先补上**再写文件 |
| 建议规则 | `/req_docs` 或 `req_docs/` |
| 路径 | 用户指定文件则用之；否则在 `req_docs/` 下读写 |

**Do NOT proceed past Step 0 until `req_docs` is gitignored (or user explicitly waives).**

## 执行步骤（不得跳过）

### Step 0 — 就绪检查

1. 确认目标需求文档路径（用户给出，或 `req_docs/` 下指定文件）。
2. 检查项目根 `.gitignore` 是否包含 `req_docs`；缺失则加入并告知用户。
3. 若目录不存在，创建 `req_docs/`（空目录可放 `.gitkeep` **仅当用户要求提交占位时**；默认整目录忽略则不必）。

### Step 1 — 阅读需求

Read 目标文档全文。摘出：范围、页面/路径、功能点、约束（mock、复用现有实现等）。

### Step 2 — 对照项目现状

用代码检索（优先 codegraph / Grep / Read）定位相关页面、组件、路由、已有交互。  
产出简要「现状映射」：需求条目 → 落点文件/符号（写入对话计划即可，不必另开文件）。

**Do NOT proceed to Step 3 until Step 2 has concrete file-level mapping.**

### Step 3 — 输出工作计划（对话）

Read [assets/work-plan-template.md](assets/work-plan-template.md)，按模板在对话中输出计划清单。  
标明：落点文件、任务拆分、建议开发顺序。  
**本步不改业务代码、不回写文档。**

### Step 4 — 澄清不确定项

Read [references/clarify-question-guide.md](references/clarify-question-guide.md)。  
凡影响实现结果的不确定点，向用户提问（可按模块分组一批问清）。  
给出「当前默认假设」便于用户改，但**不得把假设当终稿写入文档**。

**Do NOT proceed to Step 5 until the user has answered (or explicitly deferred) all blocking questions.**

### Step 5 — 回写文档

用户确认计划与答案后：

1. Read [assets/doc-writeback-template.md](assets/doc-writeback-template.md)。
2. 将**已确认结论**合并进 `req_docs/` 目标文档（更新需求条文 + 工作计划清单）。
3. Read [references/quality-checklist.md](references/quality-checklist.md) 自检；未通过则补全后再交付。
4. 向用户确认：是否开始改代码。未明确授权则**停止**。

## 渐进披露

| 何时 | 读取 |
|------|------|
| Step 3 出计划前 | [assets/work-plan-template.md](assets/work-plan-template.md) |
| Step 4 提问前 | [references/clarify-question-guide.md](references/clarify-question-guide.md) |
| Step 5 回写前 | [assets/doc-writeback-template.md](assets/doc-writeback-template.md) |
| Step 5 交付前 | [references/quality-checklist.md](references/quality-checklist.md) |
| 需要样例时 | [examples.md](examples.md) |

## 非目标

- 不替代详细设计评审或接口联调文档。
- 不在未授权时提交 git、推远程、改业务实现。
