---
name: kd-api-generator
description: >-
  (Skill id: kd-api-generator.) From OpenAPI 3.x JSON, generates Vue 2 + axios
  API modules (import request from "@/utils/request", usually src/utils/request.js)
  and JSDoc @typedef under src/types/. Requires per-export JSDoc: summary line,
  @param where applicable, @returns (resPath-unwrapped data).
  @remarks only when differing from defaults (SSE, typo path, download, etc.).
  Uses per-file /** @typedef {import("@/types/...").X} X */ aliases. Follow
  src/api/_example.js when present; see reference.md for a compact pattern table.
  Use when the user invokes kd-api-generator or OpenAPI/Swagger/api-res.json sync.
metadata:
  version: "1.0.0"
---

# kd-api-generator

## 做什么

- **`src/types/*.js`**：`components.schemas` → `/** @typedef */`，末尾 `export {}`；主定义不放 api 里。简单映射：`integer`→`number`，`date-time`→`string`，`enum`→字面量联合，`array`→`T[]`，无结构 `object`→`Record<string,*>`；**请求侧 id 类字段按团队约定用 `string`**（可与 swagger 数值差异，优先在 typedef 的 `@property` 旁一行说明）。
- **`src/api/*.js`**：每个 path → `export function`；`import request from "@/utils/request"`（**实现读 `src/utils/request.js` + `vue.custom.js`**）；形态**优先抄仓库 `src/api/_example.js`**（最全长例），次查 [reference.md](reference.md) 速查表。
- **类型短名**：禁止只靠 `import "@/types/..."`；在 api 顶部写 `/** @typedef {import("@/types/...").X} X */`。

## 前置（30 秒）

读 `jsconfig`/`tsconfig` 的 `@` → `src`；默认 **仅写 `url` 即 GET**；成功体经 **`resPath`**（常 `data.data`）拆包；**`setAxios`** 改代理前缀；OpenAPI **`servers` 仅供参考**。

## 团队约定（KD 默认，生成代码须遵守）

- **不在单接口里拼 `tenantId` / `projectId` 等公共头**：一般由 **`src/utils/request.js`** 的 **`setHeaders`**（或等价逻辑）统一注入；勿在每个接口 JSDoc 里重复描述；仅当接口**必须**覆盖/补充 `headers` 时，再在实现处写明并在 `@remarks` 点明原因。
- **id 类入参统一为 `string`**：`@param {string} id`、path 用 `` `/.../${id}` ``；**不要**为「对齐 OpenAPI integer」在前端写 `Number(id)` / `parseInt`；`src/types` 里与**请求入参**相关的 id 字段宜与团队一致标为 `string`（与 swagger 数值差异写在 typedef `@property` 旁即可）。

## 导出函数 JSDoc（必填）

业务描述一行（对齐 OpenAPI `summary`/语义）；有入参则 **`@param`**；**`@returns`**（`Promise<业务类型>` 或 `[Promise, AbortController]` 等特例）。HTTP 方法与 path **不必写入 JSDoc**，以 `request({ url, method, … })` 为准。

**`@remarks`（按需）**：不写「成功体按 resPath 拆包」「tenantId 由 setHeaders 注入」等**全局默认**；仅在**与默认不一致**时补充，例如：`download` / `multipart` / `showError: false` / `errorPath` / `abort: true`、SSE / `responseType` 与文档 `text/event-stream` 的差异、**后端 path 笔误或与英文常规拼写不符**必须在备注中写明、占位接口说明等。`_example.js` 里对不同形态写了示范性的 `@remarks`，教学用意；量产业务接口以本节约束为准。

## 流程

0. 有则读 **`src/api/_example.js`**、**`src/utils/request.js`**。
1. 扫 OpenAPI `paths` + `components.schemas`。
2. 更新/新增 `src/types`，再按域写 `src/api`，顶部 typedef 别名块 + 上表 JSDoc。
3. OpenAPI 未含的接口：占位 + `@file` 说明，**不编 path**。
4. `eslint --fix`（含 prettier）。

## 坑

缺 JSDoc（描述 + `@returns`）；仅用 `import "@/types"` 无 typedef 别名；后端 path 笔误以前端真实为准并在**少量** `@remarks` 写明；为每个接口机械重复 `@remarks` 抄全局约定；`operationId` 冲突则前端改名；**重复注入**已在 `setHeaders` 中的 header；**多余**的 id 数字转换（除非后端明确要求数值形态）。
