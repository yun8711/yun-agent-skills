# kd-api-generator · 速查与补充

**权威长例**：仓库内 **`src/api/_example.js`**（每种形态含完整 JSDoc）。本页为裁剪速查。

---

## 团队约定（与 SKILL 一致）

| 项 | 做法 |
|----|------|
| `tenantId` / `projectId` 等 | **`setHeaders` 统一处理**；单接口**不**默认传这些 `headers` |
| path / body 中的 **id** | **`string`**；**不**做 `Number(id)` 等转换（除非后端明确要求数值形态） |

---

## JSDoc 骨架

`@remarks` **按需**：不写 resPath / setHeaders 等全局约定；仅在例外项（download、multipart、`showError`、`errorPath`、`abort`、SSE、`responseType`、path 拼写特殊等）追加。

```javascript
/**
 * [业务描述，对齐 OpenAPI summary]
 *
 * @param {类型} x 含义（无参可省略整段）
 * @returns {Promise<类型>} resPath 拆包后的业务数据
 */
```

---

## request 形态速查（对齐 `@/utils/request`）

| 场景 | 配置要点 |
|------|-----------|
| GET，仅 path | `{ url: `/.../${id}` }`（不写 method） |
| GET + query | `{ url, params }` 或显式 `method: "get"` |
| POST JSON | `{ method: "post", url, data: body }` |
| POST，query only | `{ method: "post", url, params }` |
| PUT / PATCH / DELETE | 对应 `method` + `data`；path 用模板字符串 |
| 文件下载 | `download: true`（blob 由拦截器处理） |
| 上传 | `headers: { "content-type": "multipart/form-data" }`，`data: { file }` |
| 额外表单字段 | `data` 中 `JSON.stringify` 嵌套对象 |
| 静默错误 | `showError: false` |
| 单次错误路径 | `errorPath: "..."` |
| 可取消 | `abort: true` → 返回 **`[Promise, AbortController]`** |
| URL 简写 | `request("/api/v1/ping")` 等同 GET |

SSE / `text/event-stream`：`responseType: "text"` 仅兜底；真流式常用 `EventSource` / `fetch`；若响应非统一 `{ success, data }`，可能与拦截器冲突。

---

## 最小可读示例（完整 JSDoc + POST）

```javascript
/**
 * 创建示例
 *
 * @param {object} body 请求体
 * @returns {Promise<object>} 创建结果（拆包后）
 */
export function createExample(body) {
  return request({ url: "/api/v1/example", method: "post", data: body });
}
```

---

## 交付检查

- [ ] 每导出函数：描述 + `@param`（若有）+ `@returns`；`@remarks` 仅填例外项，不抄全局约定（不必在 JSDoc 重复 METHOD/path，`url`/`method` 即真相来源）
- [ ] **无**重复公共 header；**id 为 string**
- [ ] `src/types` ↔ `components.schemas`；api 顶部 `@typedef {import("@/types/...").X} X`
- [ ] request 形态与 `_example.js` 同类场景一致；已对照 `src/utils/request.js`
- [ ] ESLint/Prettier 通过
