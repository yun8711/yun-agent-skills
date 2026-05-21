# 五种 Skill 内容设计模式

> 提炼自 Google Cloud Tech「5 Agent Skill design patterns」；与 Cursor 官方 `create-skill` 互补，解决 **SKILL.md 里面该怎么设计**。

## 模式一：Tool Wrapper（工具包装器）

**问题**：系统提示或 SKILL 正文塞满某库/团队规范，占 token、难维护。

**做法**：

- 详细规范 → `references/*.md`
- `SKILL.md` → 专家角色 + **何时加载** + **加载后动作**

**SKILL.md 必备节**：

- Core / When to load
- When reviewing / When writing（分场景指令）
- 输出：违规时引用规则编号或章节并给修复建议

**适用**：FastAPI 约定、公司内部 ESLint 规则、数据库命名规范等。

---

## 模式二：Generator（生成器）

**问题**：同类产出结构漂移（报告东一块西一块）。

**做法**：

- `assets/` → 输出结构模板（占位符）
- `references/` → 语气、格式、术语风格
- `SKILL.md` → 严格步骤：加载风格 → 加载模板 → 收集缺失信息 → 填空 → 交付

**设计原则**：**结构**（assets）与 **内容**（Agent 填）分离；换模板即可换产出类型。

**适用**：技术报告、RFC、commit message 批量规范、API 文档章节。

---

## 模式三：Reviewer（审查器）

**问题**：审查标准写死在 SKILL 正文，难以切换领域（风格 → 安全）。

**做法**：

- `references/review-checklist.md`（或按域拆分多个文件）→ **查什么**
- `SKILL.md` → **怎么查** + **输出结构**

**推荐输出结构**：

- Summary（整体评价）
- Findings（按 severity：error / warning / info，含行号、原因、修复）
- Score（可选 1–10 + 理由）
- Top N Recommendations

**适用**：Code review、安全审计、文档质量检查、PR 合规。

---

## 模式四：Inversion（反转 / 先问再做）

**问题**：Agent 爱猜、一次给答案，复杂需求易做错。

**做法**：

- 明确门禁：`在用户完成 Phase N 之前，不得开始实现/生成/修改代码`
- 分阶段提问；**每轮尽量只问一个问题**
- 全部信息收集完后，再加载模板或执行 Pipeline

**适用**：项目规划、架构选型、模糊需求的功能设计、学习路径定制（可与 `tech-mentor` 类似）。

---

## 模式五：Pipeline（流水线）

**问题**：多步任务被跳步，质量不可控。

**做法**：

- 编号步骤，写明 `按顺序执行，不得跳过`
- **钻石门禁**：`在用户确认 Step N 产出之前，不得进入 Step N+1`
- 末步可挂 Reviewer 清单做自检

**适用**：文档生成流水线、迁移 checklist、发布前检查、多文件代码生成。

---

## 组合示例

| 组合 | 行为 |
|------|------|
| Inversion → Generator | 先访谈收集字段，再填 `assets/template.md` |
| Pipeline → Reviewer | 每步产物 + 最终对照 `references/quality-checklist.md` |
| Tool Wrapper → Reviewer | 审查前加载 `references/conventions.md` |

## 对抗的 Agent「本能」

| 本能 | 模式约束 |
|------|----------|
| 爱猜 | Inversion |
| 爱跳步 | Pipeline |
| 爱一次吐完 | Generator / Pipeline 分步 |
| 爱堆上下文 | Tool Wrapper 按需 Read |
