---
name: llm-wiki-helper
description: 从 URL、文档、代码等提炼为 Markdown 笔记；首次使用需在 skill 目录写入 config.json 持久化 notesRoot 与 templatesDir（模板目录相对 notesRoot，默认 _templates）；成文前从笔记库该目录读取模板；仅写入 notesRoot 下既有分类，一级目录不可擅自改动；Obsidian MCP 优先。Use when 保存阅读笔记、总结文章、写入 raw/，或配合 yun-llm-wiki 做 Ingest。
---

# llm-wiki-helper

## 0. 配置持久化（必须先读）

**配置文件**（本 skill 目录内，与 `SKILL.md` 同级）：

`$HOME/.cursor/skills/llm-wiki-helper/config.json`

**字段**：

| 字段 | 含义 |
|------|------|
| `notesRoot` | **绝对路径**，本 skill 默认的笔记根目录；须为 vault 下的 **`raw` 目录**（即分类笔记只写在该路径之下）。 |
| `templatesDir` | **相对 `notesRoot` 的路径**，存放成文用 Markdown 模板（如 `_templates`）。解析为 **`{notesRoot}/{templatesDir}`**。缺省或未配置时按 **`_templates`** 处理；若该路径不存在，落盘前须询问用户是否更正或先创建目录。 |
| `configuredAt` | 可选，ISO8601，首次写入时填当前时间。 |

**首次使用（无 `config.json`、或缺少 `notesRoot`、或路径不存在）**：

1. **询问用户**指定 `notesRoot` 的绝对路径（说明：一般为 `OBSIDIAN_VAULT` 下的 `raw`，例如 `…/yun-notes2/raw`；若工作区即 yun-llm-wiki，则为仓库内 `raw` 的绝对路径）；并确认 **`templatesDir`**（相对 `notesRoot`，默认 `_templates`，即模板位于 `{notesRoot}/_templates`）。
2. 用户确认后，**写入** `config.json`（含 `notesRoot`、`templatesDir` 与可选 `configuredAt`；勿提交到公共仓库；仓库根 `.gitignore` 已忽略 `llm-wiki-helper/config.json`）。
3. **后续任务**：每次执行本 skill 相关落盘前 **Read** `config.json`，**默认**所有「笔记根」均指 `notesRoot`，模板根目录均指 **`{notesRoot}/{templatesDir}`**（见上表 `templatesDir`），不再重复询问，除非用户要求修改路径。

**变更路径**：用户可直接编辑 `config.json`，或口头要求更新后由 Agent 覆写同一文件。

**与 MCP**：`OBSIDIAN_VAULT` 仍由 Cursor MCP 配置；`notesRoot` 应通常为 `{OBSIDIAN_VAULT}/raw`。若二者不一致，落盘以 **`config.json` 的 `notesRoot` 为准**，并**提示用户**核对 vault 与笔记根是否一致。

---

## 1. 核心能力（优先）

**把可读输入变成高质量笔记**：在理解原文/原意的基础上做**提炼、分层摘要与归纳**（核心观点、论据结构、可复用结论、术语与边界条件；代码则抓意图、接口与约束），再落为结构化 Markdown。

**输入来源**（按任务选用）：

- **网页 / 长文**：WebFetch / MCP 拉正文；失败再用 `cursor-ide-browser`（navigate → lock → snapshot → unlock）。保留可复核的标题与 URL。
- **仓库内文档**：直接 Read；长文件可分段。
- **对话上下文**：只依据已出现陈述，不编造。
- **项目代码**：路径 + 短摘录 + 归纳，忌整文件堆砌。

**输出风格**：偏「教程式理解 + 可检索要点」；需要规范体裁时可对齐 Diátaxis（`documentation-writer`）与**笔记库模板**。

### 1.1 模板（必选：来自笔记仓库，非本 skill 目录）

- **本 skill 不再附带独立模板文件**；成文结构须以 **`config.json` 中的 `templatesDir`** 为准，从 **`{notesRoot}/{templatesDir}`** 选用已有 `.md` 模板。
- **落盘前**（写入或覆盖目标笔记之前）：
  1. 用 Obsidian MCP **`obsidian_files`** 列出模板目录（`folder` 为 **相对 vault 根** 的路径：由 `{notesRoot}/{templatesDir}` 去掉 vault 根前缀得到，常见为 `raw/_templates/`），或 **`obsidian_read`** 直接读取用户指定的模板文件；
  2. 若用户已点名模板文件名，则读取该文件全文并按其章节 / frontmatter 成文；
  3. 若用户未指定，则根据主题在列表中选最贴近的一类（如 issue / idea / learning-bundle），**征得用户确认**后再选用；
  4. 若目录为空或不存在，**不得**凭空虚构与仓库无关的版式；须说明情况并请用户补充模板或调整 `templatesDir`。
- **绝对路径备用**：`Read` 工具可读 `{notesRoot}/{templatesDir}/<文件名>.md`（当 MCP 不可用时）。

---

## 2. 目录、分类、索引与检索（Obsidian MCP）

**库内操作**（列文件、搜索、读/写笔记、标签、任务、属性、反链等）**一律通过 Obsidian MCP**，与工作区是否 yun-llm-wiki 无关；个人 vault 路径由 MCP 环境变量决定，**不要**用仓库内 grep 替代 Obsidian 的全文索引与链接解析来写「主路径」。

### 2.1 Cursor 中的典型配置（`mcp-obsidian-cli`）

- **MCP 服务名**（`call_mcp_tool` 的 `server`）：`obsidian`
- **启动**：`npx -y mcp-obsidian-cli`
- **环境**：`OBSIDIAN_VAULT` 指向 vault 根目录（可为 vault 名或绝对路径），以 Cursor MCP 配置为准。

### 2.2 运行前提

- Obsidian **桌面端已打开**，且已启用 **Obsidian CLI** 相关能力（该 MCP 通过 CLI 与运行中的 Obsidian 通信）。
- 系统可执行 `obsidian`（或按包文档设置 `OBSIDIAN_CLI_PATH`）。

### 2.3 工具（以 Cursor 内 MCP 描述为准；以下为 `mcp-obsidian-cli` 常见 surface）

| 用途 | 工具（名称以实际 schema 为准） |
|------|--------------------------------|
| 全文搜索 | `obsidian_search` |
| 列 vault 文件 | `obsidian_files` |
| 读笔记 | `obsidian_read` |
| 新建笔记 | `obsidian_create` |
| 标签 | `obsidian_tags` |
| 任务 | `obsidian_tasks` |
| frontmatter | `obsidian_properties`、`obsidian_property_set` |
| 反链 | `obsidian_backlinks` |
| 最近文件 | `obsidian_recents` |
| 日记 | `obsidian_daily_read`、`obsidian_daily_append` |
| 任意 CLI 子命令 | `obsidian`（透传） |

调用前**必须**读取对应 tool 的 JSON schema（若项目在 `mcps/obsidian/tools/` 下有缓存则读本地，否则以 Cursor 展示的 MCP 定义为准）。

### 2.4 无 Obsidian MCP 时

用工作区 **grep / 语义搜索 / Read** 定位；无法安全改 vault 时说明需启用 MCP 或用户在本机 Obsidian 中操作。

### 2.5 本 skill 新增笔记的落盘路径（硬性）

- **先读** `config.json` 得到 `notesRoot` 与 `templatesDir`（见 **§0**、**§1.1**）。未配置时不得默认落盘，须先完成首次配置。
- **仅允许**写入：`{notesRoot}/` 之下某条**已存在**的分类路径（可含多级子目录），**不得**写到 `notesRoot` 以外或未确认的任意路径（`notesRoot` 本身应对应 vault 的 `raw` 目录）。
- **落盘前**：用 MCP（如 `obsidian_files` 或等价）查看 `notesRoot` 下**现有一级目录与子目录**，按文章主题选最贴近的一类。
- **现有分类都不合适时**：**不得**擅自新建一级目录、不得擅自新建子目录；**必须先问用户**是否新建、以及新建在 `notesRoot` 下哪一级、建议名称是什么，**得到明确同意后再创建并写入**。
- **`notesRoot` 下的一级目录**（第一层文件夹）：**禁止**擅自重命名、删除、合并或改用途；确需调整须用户明确授权。
- 若 `notesRoot` 对应 **yun-llm-wiki** 内的 `raw/`，分工与 `schema.md` 一致，仍遵守上条。

---

## 3. yun-llm-wiki 仓库（与上并行）

当工作区是 **yun-llm-wiki** 且任务涉及知识库维护时，**另遵守** 仓库根 `AGENTS.md`、`schema.md`：

- 原始材料入 `raw/`（命名 `YYYYMMDD_主题_来源.md`）。
- **不直接改 `wiki/`**；变更通过 `diff/` 建议，用户审核后再应用；`wiki/index.md`、Dataview 等**以仓库内既有机制为准**。
- 摄入 / 查询 / Lint：`prompt/ingest.md`、`prompt/query.md`、`prompt/lint.md`。

---

## 4. 异常与边界

- 正文获取不全：在笔记中注明，并保留链接。
- 同时存在「个人 vault 笔记」与「wiki 入库」：先与用户确认是否重复维护；默认各走一条主路径。

参考：Diátaxis <https://diataxis.fr/>
