---
name: yun-create-skill
description: >-
  在 Cursor 官方 create-skill 规范之上，用五种内容设计模式（Tool Wrapper、Generator、
  Reviewer、Inversion、Pipeline）规划并落地 Agent Skill。创建或重构 Skill、选型模式、
  设计 references/assets 结构时使用。优先于单独使用 create-skill。
metadata:
  version: "1.0.0"
---

# yun-create-skill

在 **Cursor 官方 `create-skill`**（格式、元数据、篇幅、渐进披露）之上，增加 **内容设计模式**（源自 Google ADK / Cloud Tech 实践），使产出的 Skill **可发现、省 token、流程可控**。

## 0. 前置：必读官方基线

每次执行本 Skill 时，**先 Read**：

`$HOME/.cursor/skills-cursor/create-skill/SKILL.md`

以下事项以官方为准，本 Skill **不重复展开**，仅做设计层补充：

- `name` / `description`（第三人称、WHAT + WHEN）
- 存放位置：纳入本仓则写 `skills/<name>/`（push 后 `npx skills add/update`）；否则个人 `~/.cursor/skills/` 或项目 `.cursor/skills/`。**禁止**写入 `~/.cursor/skills-cursor/`
- `SKILL.md` 建议 &lt; 500 行、渐进披露、引用深度一层
- 反模式（Windows 路径、选项过多、时效性表述等）

详细对照表见 [references/official-baseline.md](references/official-baseline.md)。

## 1. 工作流总览

```text
Discovery → Pattern 选型 → Design → Implementation → Verification
```

| 阶段 | 目标 | 主要产出 |
|------|------|----------|
| Discovery | 弄清用途、触发、约束 | 需求摘要 |
| Pattern 选型 | 选定主模式，必要时组合 | 模式说明 + 目录草图 |
| Design | 定目录、门禁、引用关系 | 文件清单 |
| Implementation | 写 SKILL.md 与支持文件 | 可安装目录 |
| Verification | 官方 + 模式双清单 | 通过 / 待改项 |

用户提供的 Skill 正文措辞须 **verbatim** 写入（与官方 create-skill 一致，不得擅自改写）。

## 2. Phase 1 — Discovery

用 AskQuestion（可用时）或对话收集：

1. **Purpose**：解决什么任务？一次性还是反复用？
2. **Location**：本仓 `skills/<name>/`、个人 `~/.cursor/skills/`，还是项目 `.cursor/skills/`？
3. **Triggers**：用户说什么话、做什么操作时应加载？
4. **Domain**：Agent 默认不知道的团队规范、API、流程？
5. **Output**：固定版式、检查报告、多步产物？
6. **Risk**：猜错代价高吗？能否跳步？是否需要人工卡点？

根据答案进入 **§3 模式选型**（详见 [references/patterns.md](references/patterns.md)）。

## 3. Phase 2 — Pattern 选型

**必须先完成选型再写 SKILL.md 正文。**

### 3.1 决策树（简版）

| 若主要需求是… | 首选模式 |
|---------------|----------|
| 让 Agent 掌握某库/团队规范，按需加载 | **Tool Wrapper** |
| 输出结构固定（报告、文档、消息格式） | **Generator** |
| 对照清单审查/审计 | **Reviewer** |
| 需求复杂、易误解，须先澄清 | **Inversion** |
| 多步骤、不可跳步、须确认 | **Pipeline** |

### 3.2 组合（常见）

- **Generator + Inversion**：先问清缺失字段，再填模板
- **Pipeline + Reviewer**：流水线末步对照质量清单
- **Tool Wrapper + Reviewer**：先加载规范，再按规范审查

在 Design 笔记中写明：**主模式**、**辅模式**（若有）、**为何组合**。

### 3.3 目录约定（与模式对齐）

在官方 `reference.md` / `examples.md` / `scripts/` 之外，按模式扩展：

```text
skill-name/
├── SKILL.md                 # 编排：何时加载何文件、步骤与门禁
├── references/              # Tool Wrapper / Reviewer / Generator 风格指南
│   └── *.md
├── assets/                  # Generator / Pipeline / Inversion 终稿模板
│   └── *.md
├── examples.md              # 可选：输入输出样例
└── scripts/                 # 可选：确定性步骤（官方 Low freedom）
```

单文件 `reference.md` 仍允许；**多份规范**时用 `references/` 更清晰。

## 4. Phase 3 — Design

1. **命名**：`name` 小写连字符，≤64 字符，语义明确（忌 `helper` / `utils`）。
2. **description**：第三人称；写清 WHAT + WHEN；含触发关键词。
3. **SKILL.md 角色**：
   - Tool Wrapper / Reviewer：**协议**（何时读哪份 reference、输出结构）
   - Generator：**项目经理**（逐步加载 assets + references）
   - Inversion：**面试官**（分阶段问题 + 门禁）
   - Pipeline：**调度器**（有序步骤 + 不可跳过 + 确认点）
4. **门禁话术**（Inversion / Pipeline 必填其一或组合）：
   - `在用户确认 X 之前，不得开始 Y`
   - `不得跳过 Step N`
   - `每阶段一次只问一个问题`（Inversion 推荐）
5. 从 [assets/skeletons.md](assets/skeletons.md) 选取最接近的骨架，再裁剪。

向用户展示：**模式选择 + 目录树 + 门禁摘要**，确认后再实现。

## 5. Phase 4 — Implementation

1. 创建目录（个人或项目路径）。
2. 写 `SKILL.md` frontmatter + 正文（按选定模式组织章节）。
3. 创建 `references/*`、`assets/*`、`scripts/*`（按需）。
4. 在 SKILL.md 中 **显式写出**：
   - 何时 `Read` 哪个文件（渐进披露）
   - 步骤顺序与停止条件
   - 结构化输出格式（Reviewer / Generator）
5. 默认 `disable-model-invocation: true`（与官方一致）；仅当需要环境自动挂载时省略。

## 6. Phase 5 — Verification

### 6.1 官方清单（摘自 create-skill）

- [ ] description 具体、第三人称、含触发词
- [ ] SKILL.md &lt; 500 行
- [ ] 引用仅一层深度
- [ ] 术语一致；无 Windows 路径
- [ ] 无未请求的时间敏感表述

### 6.2 模式清单

- [ ] 已记录主模式（及组合理由）
- [ ] SKILL.md 含清晰的 **加载指令**（何时读 references/assets）
- [ ] Tool Wrapper：规范在 references，主文件不堆砌长规范
- [ ] Generator：assets 管结构，references 管风格，步骤可执行
- [ ] Reviewer：查什么在 references，怎么查在 SKILL.md
- [ ] Inversion：存在「未答完不得开工」类门禁
- [ ] Pipeline：步骤编号、禁止跳步、关键步有人工确认
- [ ] 组合模式时无步骤/门禁冲突

## 7. 与 create-skill 的分工

| 使用场景 | 调用 |
|----------|------|
| 只问 YAML / 路径 / 通用写法 | 官方 `create-skill` |
| **新建或重构 Skill、要模式化、要团队一致质量** | **`yun-create-skill`**（本 Skill 会拉取官方基线） |

## 8. 附加资源

- 五种模式详解与示例：[references/patterns.md](references/patterns.md)
- 官方要求速查：[references/official-baseline.md](references/official-baseline.md)
- 五种骨架模板：[assets/skeletons.md](assets/skeletons.md)
