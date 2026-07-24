---
name: yun-reqflow-e2e-verify
description: >-
  跑 pnpm test:e2e，据报告/api 录制判通过或回流；用户确认后标已归档。
  yun-reqflow 子环节。Use when user invokes yun-reqflow-e2e-verify, or asks to
  跑 e2e / 验收 / 归档前验证（显式触发）。
disable-model-invocation: true
---

# yun-reqflow-e2e-verify

跑测 → 通过/回流。不擅自 `已归档`。

## 门禁

1. 无脚手架 → 先 `yun-reqflow-e2e-author` Step 0。  
2. 提醒：主/子应用已起、`.env.e2e` 已填账号。  
3. 失败看终端、`midscene_run/report/`、`midscene_run/api/`。  
4. 中文；不提交密钥与 `storage-state`。

## Step

**1** 全量或当前需求对应 spec。  
**2** 核对 serve / 登录配置；缺则停。  
**3** 执行；保留退出码与关键日志。  
**4** 判读：

| 现象 | 回流 |
|------|------|
| 步骤/文案/断言与页不符 | → e2e-author |
| 功能错、接口 4xx/5xx | → implement（契约问题 → api） |
| 验收含糊或与预期冲突 | → clarify |
| 全部通过 | → 用户确认后 `已归档`（建议补 `测试环境`） |

**5** 短报告：通过/失败/下一 Skill + 报告路径。  
**6** 用户确认后回写 `已归档` + `updated`。`req_docs` 与 specs **保留**；可清 `midscene_run/`。

不借机大改业务（除非回流 implement 且用户授权）。
