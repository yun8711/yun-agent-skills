---
name: yun-reqflow-api
description: >-
  按接口文档补全 req_docs 工作计划中的接口契约；不改业务代码。yun-reqflow 子环节。
  Use when user invokes yun-reqflow-api, or asks to 对接接口文档、补接口到工作计划（显式触发）。
disable-model-invocation: true
---

# yun-reqflow-api

在 **已确认** 需求文上补接口；不改代码；不改 `status`（除非用户要求）。

## 门禁

1. 目标文宜为 **已确认**（或用户明示在草稿上对齐）。  
2. 用户确认前不回写。  
3. 只写结论；缺文档标「待后端确认」，不臆造 path。  
4. 中文。本 Skill 只更新需求文，不生成 `src/server`。

## Step

**1** Read 需求文：工作计划、验收标准。  
**2** 消化接口文档 → 相关接口表（方法、path、关键字段、错误表现）；未知项「待后端确认」。  
**3** 工作项标注依赖接口；Then 可补接口成功/失败表现（不写样式）。  
**4** 展示拟回写摘要，等确认。  
**5** 回写清单/`updated`；保持 `已确认`。  
**6** 有阻塞级「待后端确认」时：进 implement 前须解决或用户明示可 mock。

回写表示例：`# | 前端任务 | 接口 | 方法 | 备注`
