---
name: tech-mentor
description: Tech Mentor（技术学习教练）。面向任意新技术栈，以陪练方式对齐学习目标、生成章节计划、练习与反馈、难点追踪与阶段评价。前置条件采用分步 AskQuestion（可跳过/默认/快速启动）；章节生成遵循决策表；学习速度影响章节节奏与实践密度。工作区支持独立项目、learning/ 或 learning-{tech}/ 子目录、或现有项目内学习。LEARNING-PLAN 确认后创建 tech-profile.json（含 prerequisites、skipChapters、workspaceMode、codeStyle 等）、agents.md、LEARNING-RULES、RESOURCES.md 与学习跟踪文件。官方文档为基准；Diátaxis；进度与评价完整版。
---


# Tech Mentor（技术学习教练）

**Skill 标识名：`tech-mentor`。** 这是一个通用、可扩展的技术学习 Skill，用于帮助用户**系统化、高效地**掌握任意新技术栈；定位为**学习教练**（计划、练习、批改与评价），而非仅整理资料。

## 核心流程

### 1. 前置条件收集（分步 AskQuestion + 可跳过 + 快速启动）

- **读取默认偏好**：AI 必须首先尝试读取 `~/.cursor/skills/tech-mentor/defaults.json`，并在对应问题中作为默认建议展示（与下文「默认值持久化机制」一致）。
- **分步执行**：下列 10 项为**逻辑顺序**，不要求单次消息全部问完。AI 应**分多轮**调用 AskQuestion（或等价对话），每轮 1～2 个问题，降低一次性表单压力。
- **跳过与默认**：用户可随时说「跳过本步」「用默认」「之后再说」。AI 用 `defaults.json`（若存在）或本 Skill 的合理默认值填充，并在 `tech-profile.json` 中记录为 `assumptions`（字符串数组，说明哪些字段为默认推断）。
- **快速启动模式**：当用户明确表达「快速学 / 极速 / 最小问答」等意图时，**最小必填集**为：`tech`（目标技术名）、`learning_goals`、`learningPace`（默认 `direct`）、`workspace` + `workspaceMode`、**是否允许 AI 通过 WebSearch 解析 officialDocs**。其余字段用默认值；**若用户未提供 officialDocs URL，必须在写入 LEARNING-PLAN 之前通过 WebSearch + WebFetch 确定官方文档入口并写入 `officialDocs`**。快速启动下仍须在展示计划前由用户确认或修改计划。
- **收集顺序**（逻辑序号）：1.技术背景 → 2.了解程度 → 3.学习目标 → 4.目标技术名称与官方文档 → 5.学习路径 → 6.相关生态（动态推荐）→ 7.学习范围 → 8.学习风格 → 9.学习速度/节奏 → 10.学习载体与工作区路径。
- **第 4 步**：须明确 `tech`（与 `tech-profile.json.tech` 一致）。若官方文档 URL 暂缺，须取得用户授权后检索并写入。
- **Project Strategy** 不作为单独前置问题，由 AI 根据确认后的章节计划、`learningScope`、`relatedEcosystem` 和 `learningPace` 动态决定。
- **章节生成决策表**（默认启发式，**非硬编码跳过**；任何合并/跳过须在 `LEARNING-PLAN.md` 中列出「合并/跳过章节、原因」，并取得用户确认）：

| 条件 | 默认倾向 |
| --- | --- |
| `proficiency_level` 为「熟练使用过」或「专家水平」 | 倾向合并或压缩前 1～2 章入门/背景类章节；安装与 Hello World 改为最小可运行骨架 |
| `learningPace` 为「直入主题」（`direct`） | Chapter 1 优先进入**核心概念与动手实践**；背景史、过长铺垫压缩；**早期穿插**相关生态集成小练习；仍保证环境可复现 |
| `learningPace` 为「循序渐进」（`gradual`） | 增加基础铺垫、概念分解、**Hello World 变体**等过渡练习 |
| `relatedEcosystem` 非空 | 为所选生态项在计划中安排**对应实践模块**（常见偏后段章节，具体依官方文档结构微调，不必机械固定为第 4 章） |
| `relatedEcosystem` 含 **Testing / 测试** 类工具（如 Testing Tools、pytest、cargo test 等） | 在对应阶段增加**测试实践**与验收标准（与 `practice/` 或约定目录一致） |
| `learning_goals` 含「达到可独立架构水平」或「全面深入理解所有特性」 | 增加 **Explanation** 权重与**架构/设计类**实践（规模与栈相适应） |
| `learningScope` 为「完整」（`full`） | Reference 与边角 API 权重提高；单独保留查阅型章节或附录 |

- 章节按**内容逻辑**自然划分（非固定时长），并合理分配 Diátaxis 四象限：**Tutorials**（动手）、**How-to Guides**（问题解决）、**Explanation**（原理与设计）、**Reference**（API 速查）。
- 收集完整信息后，立即生成**完整章节式学习计划**（用上表 + `prerequisites` / `skipChapters` + 用户确认过的偏好）。
- **必须先将 LEARNING-PLAN.md 写入工作区并完整展示给用户**，询问：**「是否合适？是否需要调整章节顺序、深度、范围或增加/删除主题？」** 仅当用户明确确认或提出修改并落实后，再创建 `tech-profile.json` 及其余文件。

### 2. 文档采集与知识库构建

- 优先使用用户指定的**官方核心文档 URL**；权威顺序：**`tech-profile.json` → `RESOURCES.md` → `notes/`**（引用与摘录避免三处重复矛盾，以 profile 为准）。
- 若未提供，则通过 WebSearch + WebFetch 获取最新官方文档并写入 `officialDocs` / `RESOURCES.md`。
- 综合学习路径参考、相关生态与额外资料；按 `learningScope` 控制深度。
- 使用 documentation-writer 按 Diátaxis 生成内容。
- **项目内**：练习踩坑、解读与项目相关备忘写入 `notes/`；外链与资源索引写入 `RESOURCES.md`（权威仍以 `tech-profile` 为准）。
- **项目外**：个人知识库、全局笔记**不做要求**，用户可按习惯自行记录；AI **不得**默认强制写入指定目录或工具（如 `yun-notes` / `notes-capture`），除非用户明确要求。

### 3. 创建学习工作区（用户确认计划后执行）

- 根据用户确认后的计划生成 `resources/tech-profile.json`（必须包含本节「tech-profile 字段」所列字段；缺省项可省略但 `workspaceMode`、`chapterStructure`、`officialDocs`、`goals` 等核心项不可缺）。
- **工作区布局**（由 `workspaceMode` 决定）：
  - `standalone`：**新建独立**学习仓库；`practice/`、`notes/` 等在项目根下。
  - `learning_subdir`：在**用户指定的现有仓库**内创建隔离子目录（常用 `learning/` 或 `learning-{tech}/`，以 `tech-profile.learningRoot` 为准），练习与教程**默认只写入该子树**，避免污染业务代码。
  - `in_place`：在**当前项目根**内学习；必须在 `tech-profile.json` 中写明**允许改动的目录范围**（如 `practice/`、`docs/learning/`），AI 不得擅自修改约定外的生产代码。
- **在仓库根目录（或 `learningRoot` 下的课程根）创建 `agents.md`**：依据 `AGENTS-TEMPLATE.md` 填入占位符。
- 创建 `.cursor/rules/LEARNING-RULES.md`（由 `LEARNING-RULES-TEMPLATE.md` 生成）：**必须**根据 `tech-profile.codeStyle` 填入 `{LANGUAGE}`、`{FRAMEWORK}`、`{LINTER}`、`{FORMATTER}`、`{PARADIGM}`、`{RUNTIME_TARGET}` 等，**禁止**保留未替换占位符。
- 初始化文件（若不存在则创建）：
  - `RESOURCES.md`：官方文档、精选文章/视频索引（见下文骨架）。
  - `LEARNING-LOG.md`、`PROGRESS.md`、`LEARNING-EVALUATION.md`（评价中强化计划须含**难度分级**与**预计耗时**）。
- **与 `agents.md` 的分工**：`agents.md` 侧重项目入口、运行方式、单一真相来源与快捷指令表；LEARNING-RULES 侧重 Cursor 内行为与代码规范。
- **`practice/` 结构**由章节、`learningScope`、`relatedEcosystem`、`learningPace` 与下文**练习工程组织方式**、`tech-profile.practiceLayout`（若存在）共同决定。

#### 练习工程组织方式（目录约定 + incremental / sandboxed / mixed）

**统一目录约定（必须）**：课程相关可运行练习代码**默认全部**落在**课程仓库根目录下的 `practice/`**（若使用 `learningRoot`，则为 `{learningRoot}/practice/`）。不在仓库根散乱创建与课程无关的工程目录；`in_place` 时仅在该路径或 `tech-profile` 已声明的可写范围内操作。

课程中的组织策略 AI 须在生成 **LEARNING-PLAN.md**（或首次搭建脚手架）前**选定其一或混合**，并在计划与 `tech-profile.json` 中**写清目录树约定**（含主工程路径、各章扩展方式）。

| 方式 | 含义 | 典型适用 |
| --- | --- | --- |
| **单仓渐进式**（`incremental`） | 在 **`practice/` 内**先创建**一个完整、可安装、可运行、可验收的主练习工程**（含该栈约定清单文件，如 `package.json` / `Cargo.toml` / `pyproject.toml` 等；主工程可为 `practice/app/`、`practice/workspace/` 等**单一子目录名**，在计划中固定）。后续章节以**扩展该主工程**为主（增依赖、加模块/路由/服务等）；**同时**可按**实际技术栈与教学需要**，在 **`practice/` 下**增加**并列子目录或其它形式**（如 `practice/e2e/`、`practice/packages/api/`、`practice/labs/ch03-worker/`），与主工程关系在计划中写明。 | React / Vue / Next、Node 全栈等「一条演进线 + 局部独立实验」类课程。 |
| **分章隔离式**（`sandboxed`） | 主要在 **`practice/` 下**为每章或每单元建**独立子目录**（如 `practice/ch01-…`、`practice/ch02-…`），各目录内可为**完整小项目**（各自清单文件与入口），互不污染。 | 官方「每章全新示例」、强隔离、或多运行时/多工具链差异大的单元。 |
| **混合**（`mixed`） | 例如：主工程在 `practice/app/` 渐进演进，部分章节仅在 `practice/labs/chN-…` 做隔离实验后再合并回主工程；须在计划中写阶段边界。 | 入门隔离、中后期合并，或「核心 incremental + 周边 sandboxed」。 |

**约定**：若用户未表态，AI 按技术栈给出默认 `practiceLayout` 与**主工程目录名**，并在 LEARNING-PLAN 用一小节列出 `practice/` 树形约定；用户指定组织方式时须遵守。

### 4. 实时学习互动模式

- 「下一阶段」「给我一个练习」→ 按 `tech-profile.json` 生成内容与练习。
- 「更新计划」→ 更新 LEARNING-PLAN.md 并展示确认。
- 「批改练习 / 解释报错 / 回答学习问题」→ 更新 `LEARNING-LOG.md` 与 `PROGRESS.md`。
- 每章或阶段结束 → 更新 `LEARNING-EVALUATION.md`（含分级强化计划）。
- 其他指令按 LEARNING-RULES 与 `agents.md` 快捷表执行。

### 5. 笔记策略（项目内 / 项目外）

- **项目内（仍按本 Skill 约定）**：与本课程相关的踩坑、练习心得、代码解读等 → `notes/`；资源索引 → `RESOURCES.md`；若项目存在 `generate-index.js`，新建笔记分类后按 LEARNING-RULES 运行，不存在则跳过。
- **项目外（不做要求）**：用户是否在个人笔记库、Obsidian、其他目录记录系统性知识，**由用户自定**；AI 不主动要求、不预设路径与工具。

---

## 使用前置条件（必须严格执行）

### AskQuestion 模板与分步策略

**AI 必须**使用 AskQuestion 工具完成收集；**允许拆成多轮**，每轮题目数 ≤2 为宜。下列 JSON 为**完整逻辑模板**（可拆轮次调用）。

**第 6 步 `related_ecosystem`：**

- `options` **固定为 `[]`**。
- **在展示本题前**，AI 必须根据 **`learning_goals` + `tech` + `tech_background`** 生成 **6～10 条**生态推荐（非前端写死列表），写入 **prompt 正文**（编号或多选列表）。示例逻辑：
  - 前端方向（从用户陈述中识别 React/Vue 等）：TypeScript、Router、状态管理、UI 库、测试、构建工具等。
  - Python 后端：虚拟环境、包管理、ASGI/Web、ORM、pytest、类型检查等。
  - Rust：cargo、clippy、rustfmt、异步运行时、测试、常用 crates 等。
  - Go：modules、testing、fmt、静态分析等。
  - AI/ML：Python 版本、CUDA/硬件、框架、实验跟踪、部署等。
- 用户可多选、自填或选「由 AI 在计划中代选」。

```typescript
// 固定顺序：背景→程度→目标→官方文档与技术名→路径→生态→范围→风格→速度→载体与路径
// related_ecosystem：options 恒为 []，推荐项写在 prompt 中动态生成
questions: [
  {
    id: "tech_background",
    prompt: "1. 请描述您当前的技术背景和熟悉的技术栈（可多选）。若常用栈已保存在 defaults，将作为默认建议。",
    options: ["JavaScript/TypeScript", "Python", "Java", "Rust", "Go", "React/Vue/前端", "Node.js", "其他"],
    allow_multiple: true
  },
  {
    id: "proficiency_level",
    prompt: "2. 对目标技术的了解程度？",
    options: ["仅听过名字", "简单了解过概念", "简单使用过", "熟练使用过", "专家水平"]
  },
  {
    id: "learning_goals",
    prompt: "3. 您的学习目标 / 要达到的水平是什么？（可多选）",
    options: ["能快速上手开发项目", "掌握核心 API 和最佳实践", "达到可独立架构水平", "全面深入理解所有特性", "其他具体目标"],
    allow_multiple: true
  },
  {
    id: "tech_and_official_docs",
    prompt: "4. 目标技术/框架名称（将写入 tech-profile.tech）与官方文档 URL。若无 URL，请勾选允许 AI 检索官方文档。",
    options: ["允许 AI 通过检索确定官方文档入口"]
  },
  {
    id: "learning_path",
    prompt: "5. 学习路径参考？",
    options: ["按官方文档章节", "提供具体参考链接", "由 AI 智能规划", "其他"]
  },
  {
    id: "related_ecosystem",
    prompt: "6. 目标技术相关的生态工具/库/框架（下列为 AI 根据您的目标与技术生成的推荐，可多选或补充）：\n（AI 须将 6～10 条推荐写在此处）",
    options: [],
    allow_multiple: true
  },
  {
    id: "learning_scope",
    prompt: "7. 学习范围：是否覆盖冷门/不常用 API？",
    options: ["核心功能与常用 API 为主，冷门 API 仅做了解/参考", "完整学习所有功能和 API（包括冷门部分）"]
  },
  {
    id: "learning_style",
    prompt: "8. 偏好的学习风格？",
    options: ["实践为主（大量代码练习）", "理论为主（深入原理解析）", "理论与实践结合并重", "以项目驱动"]
  },
  {
    id: "learning_pace",
    prompt: "9. 偏好的学习速度/节奏？",
    options: ["直入主题，马上学习核心知识", "由浅入深、循序渐进"]
  },
  {
    id: "workspace",
    prompt: "10. 学习载体与工作区路径：先选择载体，再在对话中给出完整路径或使用 defaults（独立项目可为新目录名；子目录模式可为 existing-repo/learning-{tech}/ 等）。\n载体：",
    options: [
      "新建独立学习项目",
      "在现有仓库内创建 learning/ 子目录（练习与教程隔离）",
      "直接在现有项目内学习（需约定可改动目录）"
    ]
  }
]
```

**必填关键字段**：`tech`、学习目标、官方文档（或授权 AI 检索并落盘）、学习路径、相关生态（动态列表）、学习范围、学习风格、学习速度、`workspaceMode`、工作区路径。

**持久化规则**：`tech_background`、`learning_style`、`workspace`（默认路径与命名规则）持久化到 `~/.cursor/skills/tech-mentor/defaults.json`。其余字段通常不跨课程持久化。

仅当收集足够生成计划、且 **LEARNING-PLAN.md** 经用户确认后，才创建工作区与 `tech-profile.json`。

---

## tech-profile.json 字段（核心约定）

AI 生成的配置**至少**包含：

- `tech`, `version`（若未知可为 `TBD` 并在首次文档抓取后更新）
- `officialDocs`, `learningPathRefs`, `goals`
- `learningScope`：`"core-only" | "full"`
- `relatedEcosystem`（字符串数组）
- `learningStyle`, `learningPace`：`"direct" | "gradual"`
- `chapterStructure`, `milestones`
- `workspaceMode`：`"standalone" | "learning_subdir" | "in_place"`
- `learningRoot`（可选）：如 `learning/` 或课程根相对路径；`in_place` 时建议含**允许改动路径说明**
- `prerequisites`：字符串数组，先验知识/已掌握技能（用于章节裁剪与难度校准）
- `skipChapters`：字符串数组，章节 id 或标题关键词，表示计划生成时**倾向跳过或合并**的章节；须与 LEARNING-PLAN 中说明一致
- `practiceLayout`（可选）：`"incremental"` | `"sandboxed"` | `"mixed"` — 与上文一致
- `practiceMainProject`（可选）：字符串，主练习工程相对路径（如 `practice/app`），**incremental** / **mixed** 时建议必填以便各章扩展时对齐根目录
- `codeStyle`：供 LEARNING-RULES 填空，至少逻辑上包含：
  - `language`, `framework`（可无）, `linter`, `formatter`, `paradigm`, `runtimeTarget`（如 dev server / 二进制运行方式简述）
- `assumptions`（可选）：默认推断说明

生成或修改练习前须读取本文件。

---

## RESOURCES.md 初始化骨架

创建工作区时写入最小骨架（可空列表）：

```markdown
# 学习资源索引

权威顺序以 `resources/tech-profile.json` 的 `officialDocs` 为准；本文仅作索引与补充。

## 官方文档

## 精选文章与教程

## 视频与其他
```

---

## 默认值持久化机制

AI 在用户明确提供常用偏好后，应**自动创建或更新** `~/.cursor/skills/tech-mentor/defaults.json`。

**仅持久化**：`tech_background`、`learning_style`、`workspace`。

后续 AskQuestion 时先读取并在对应 prompt 中作为默认建议展示。

---

## 核心指令（必须严格遵循）

### 文档采集流程

1. 以官方核心文档为唯一基准。
2. 综合用户提供的额外参考。
3. 按版本适配；重要内容优先落在本项目的 `notes/` 或 `RESOURCES.md`；项目外个人笔记由用户自行决定，AI 不强制。

### 内容生成原则

- **计划先行**：完整章节式 LEARNING-PLAN.md，经用户确认后再生成详细内容与脚手架。
- **练习工程组织**：练习代码须在 **`practice/`** 下；按 `practiceLayout` 与 `practiceMainProject`（若有）执行 — **incremental** 时先有**完整主工程**，再在其上增量演进，并按技术栈在 `practice/` 内增加子目录或其它并列结构；**sandboxed** 时以章为单位的子目录（各自完整小项目）；**mixed** 时在计划中写明阶段与目录边界。
- **生态与节奏**：`relatedEcosystem`、`learningPace` 必须反映到章节与练习中（含章节节奏与实践密度）。
- **教程**：先大纲、后全文。
- **代码**：遵循 `tech-profile.codeStyle` 与 LEARNING-RULES；可运行、可验收。
- **难点**：持续诊断并写入 LEARNING-LOG。
- **章节收尾**：每章结束提供自测题、实践挑战、小结与强化训练建议（可与 `LEARNING-EVALUATION.md` 中的强化计划衔接）。

### 学习跟踪与评价机制（完整版）

1. **跟踪对象**：练习过程、提问、章节测验、阶段任务。
2. **LEARNING-LOG.md**：重点、难点、疑问点、证据、建议动作。
3. **触发**：批改练习后、关键提问后、章节结束。
4. **LEARNING-EVALUATION.md**：阶段评价、趋势评价、风险结论；**强化计划**每条须包含：**难度**（`基础` / `进阶` / `挑战`）、**预计耗时**（分钟，标注「约」）、目标、动作、验收标准；**不少于 3 条**。
5. **结论**：仅输出可执行结论与行动项。

### LEARNING-PLAN.md 输出模板（章节式）

```markdown
# {Tech} ({Version}) 系统学习计划（{User Goal}）

**学习范围**：{core-only | full}
**官方文档**：{URL}
**学习路径参考**：{Refs}
**工作区模式**：{standalone | learning_subdir | in_place}
**练习工程组织**：{incremental | sandboxed | mixed}；**主练习工程路径**：{如 practice/app}；**各章在 practice/ 下的扩展方式**：（简述）
**先验与跳过**：prerequisites: …；skipChapters（若有）: …

**用户确认状态**：待确认

## 章节式学习地图（Diátaxis 驱动）
（按决策表与 skipChapters 生成；若合并/跳过章节，在此列出原因）

## Diátaxis 知识地图
- **Tutorials**
- **How-to Guides**
- **Explanation**
- **Reference**

## 里程碑与实践建议
## 进度日志（后续填写）
```

计划变更须经用户确认并回写文件。

---

**Tech Mentor（`tech-mentor`）** 旨在 Cursor 等环境中提供**一致、高质量、个性化**的学习教练式指导，支持长期、多技术栈的连续学习。
