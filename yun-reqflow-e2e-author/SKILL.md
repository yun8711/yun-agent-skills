---
name: yun-reqflow-e2e-author
description: >-
  按验收标准 + 真实 UI 写 Midscene/Playwright 功能用例；无脚手架时按 assets 安装落盘。
  不擅自已归档。yun-reqflow 子环节。
  Use when user invokes yun-reqflow-e2e-author, or asks to 写 e2e / 初始化 e2e（显式触发）。
disable-model-invocation: true
---

# yun-reqflow-e2e-author

验收标准定目标；真实 UI 定步骤与文案。不测样式。  
脚手架：[references/scaffold.md](references/scaffold.md)、[assets/](assets/)。

## 门禁

1. 宜为 **已处理**（或用户明示已实现）。仅初始化脚手架可跳过验收标准。  
2. 无脚手架 → 先执行 scaffold。  
3. 只断言功能/业务结果；不跑全量除非用户要求。  
4. 不改 `已归档`；密钥不上仓。  
5. Agent：依赖/脚手架/routes/specs。用户：`.env.e2e` 账号、起主/子应用。

## Step

**0** 缺 `e2e/` 或 `test:e2e` → 按 scaffold 执行；已有跳过。  
**1** 抽出验收标准 Given/When/Then。  
**2** 对照 Vue/路由：文案、路径、成功提示。  
**3** 用例提纲（路径、步骤、断言）→ 用户确认后落盘。  
**4** 写 `e2e/specs/{主题}.smoke.spec.ts`；必要时补 `routes`。登录：`loginViaHost`；进页：`gotoAppPage`。  
**5** 问是否进 `yun-reqflow-e2e-verify`。

验收与实现冲突先问用户；不判定归档。
