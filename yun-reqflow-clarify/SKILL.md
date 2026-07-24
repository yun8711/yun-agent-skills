---
name: yun-reqflow-clarify
description: >-
  需求对照代码、出工作计划、澄清后回写 req_docs（含验收标准 Given/When/Then）。
  不改业务代码。yun-reqflow 子环节。
  Use when user invokes yun-reqflow-clarify, or asks to
  梳理需求、出工作计划、澄清并回写（显式触发）。
disable-model-invocation: true
---

# yun-reqflow-clarify

一文一条。模板：`templates/req.md`、`templates/work-plan.md`。

## 门禁

1. Step 不得跳过（尤其不可跳过对照代码）。  
2. 计划与澄清未确认前：不回写终稿、不改业务代码。  
3. 未说「改代码 / 开始实现」：止于文档。  
4. 回写只写结论；中文。  
5. 未 gitignore `/req_docs` 不得进 Step 1（用户明示放弃除外）。  
6. 不擅自 `已处理` / `已归档`；已归档文档保留。

## 文档约定

| 项 | 约定 |
|----|------|
| 目录 | `req_docs/`，gitignore `/req_docs` |
| 粒度 | 一需求一文 |
| 命名 | `{客户}_{版本}_{短主题}.md` |
| 路径 | 用户指定优先，否则按命名新建 |

版本：frontmatter `branch` 或当前分支中的 `vX.X.X.X`。客户名对齐 `release/project/{客户}/…`。

| frontmatter | 必填 | 说明 |
|-------------|------|------|
| `title` `status` `created` `updated` | 是 | `status`：草稿/已确认/已处理/已归档 |
| `branch` | 客户分支需求必填 | |
| `发起人` `后端人员` `测试环境` | 否 | 已知则写；归档前建议有 `测试环境` |

正文：页面 / 路径 / 落点 / 需求条文。日期与发起人只放 frontmatter。

## Step

**0** 定目标文；gitignore；必要时落盘 `templates/req.md`（`草稿`）。作用域默认整篇。  
**1** 读全文，摘范围/约束。  
**2** codegraph / Grep / Read → 落点映射；无文件级映射不进 3。  
**3** 按 `templates/work-plan.md` 出计划；不改代码、不回写。  
**4** 问清影响实现的点（分支、契约、状态机、组件、口径/单位等）；编号 + 选项；可附「默认假设（待确认）」。勿问：已写死、纯样式对齐、本期无关项。答完（或延期）前不进 5。  
**5** 回写终稿：结论覆盖模糊句；`status`→**已确认**；`updated` 当日；落点 + 需求条文 + 工作计划清单 + **验收标准表**（Given/When/Then，只功能）；多模块仍一文。自检后问是否改代码。

状态后续（用户指令）：实现完成→`已处理`；测试通过→`已归档`。闭环见 [yun-reqflow](../yun-reqflow/)。
