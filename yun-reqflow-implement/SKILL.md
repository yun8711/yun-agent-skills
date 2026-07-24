---
name: yun-reqflow-implement
description: >-
  按已确认 req_docs 实现前端，最小 diff；用户确认后标已处理。不写/不跑 e2e。
  yun-reqflow 子环节。Use when user invokes yun-reqflow-implement, or says
  开始实现 / 改代码（显式触发）。
disable-model-invocation: true
---

# yun-reqflow-implement

按 **已确认** 文改业务代码。e2e 交给 author / verify。

## 门禁

1. `status` 为 **已确认**（或用户明示在此文开发）。  
2. 未说「改代码 / 开始实现」：只列拟改文件。  
3. 阻塞级「待后端确认」：先问 mock / 延期。  
4. 最小 diff；中文。  
5. 用户确认后才改 `已处理`；不擅自 `已归档`。

## Step

**1** Read：工作计划、验收标准、接口表。  
**2** 核对落点仍有效。  
**3** 短列表拟改文件；等确认开写（本会话已说「开始实现」可直接写）。  
**4** 按开发顺序实现；接口风格对齐 `src/server` 或 `src/api`；允许时用空函数 + mock。  
**5** 对照验收标准做代码侧覆盖自检（不做 e2e）。  
**6** 用户确认功能后：`已处理` + `updated`；问是否进 `yun-reqflow-e2e-author`。
