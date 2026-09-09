# 官方 create-skill 基线速查

完整条文以 **`~/.cursor/skills-cursor/create-skill/SKILL.md`** 为准；实现前 Agent 应 Read 该文件。

## 元数据

| 字段 | 要求 |
|------|------|
| `name` | ≤64 字符，小写字母数字连字符 |
| `description` | 非空，≤1024 字符，第三人称，WHAT + WHEN + 触发词 |
| `disable-model-invocation` | 默认 `true`；仅环境自动挂载时省略 |

## 存放

| 类型 | 路径 |
|------|------|
| 本仓发布 | `skills/<name>/`（push 后 `npx skills add yun8711/yun-agent-skills`） |
| 个人（不进本仓） | `~/.cursor/skills/<skill-name>/` |
| 项目 | `.cursor/skills/<skill-name>/` |
| **禁止** | `~/.cursor/skills-cursor/` |

## 篇幅与结构

- 主文件 `SKILL.md` 建议 **&lt; 500 行**
- 渐进披露：细节放 `reference.md` / `references/` / `examples.md`
- 引用深度：**一层**（从 SKILL.md 直链到支持文件）
- 默认假设 Agent 已足够聪明，只写其缺少的上下文

## 自由度

| 级别 | 场景 |
|------|------|
| High | 文本指引、多种合理做法 |
| Medium | 伪代码 / 模板 |
| Low | `scripts/` 确定性脚本 |

## 官方 Common Patterns（与 yun 模式映射）

| 官方 | 常对应 yun 模式 |
|------|-----------------|
| Template Pattern | Generator |
| Workflow Pattern | Pipeline |
| Feedback Loop Pattern | Pipeline / Reviewer |
| Conditional Workflow | Pipeline 分支或 Inversion 分支 |
| Examples Pattern | 任意模式的可选增强 |

## 反模式（必须避免）

- Windows 反斜杠路径
- 过多等价选项（应给默认 + 例外）
- 无维护计划的时效性说明
- 术语混用（endpoint / route / path 择一）
- 含糊 Skill 名（`helper`、`utils`）

## yun-create-skill 追加项

在通过上表后，再执行 `yun-create-skill` SKILL.md **§6.2 模式清单**。
