---
name: notes-directory
description: 本地笔记目录（分类树与路径）的索引与配置：维护 _index.json、排除规则、按描述搜索笔记、目录变更后刷新索引；提供 note-template 路径供 notes-capture 落盘时遵循。Use when 用户要查找已有笔记、整理笔记库目录结构、更新索引、配置 notesPath，或需要「笔记应归入哪条分类路径」所依赖的索引与规则（不负责把对话/链接/代码写成正文）。
---

# 本地笔记目录

**路径写法**：笔记库根目录用 `{notesPath}`；本 skill 与脚本位于 `$HOME/.cursor/skills/notes-directory/`（与 `~/.cursor/skills/notes-directory/` 同义）。

本 skill 管**分类树、`_index.json`、检索与模板路径**；**notes-capture** 负责把多来源内容写成 `.md` 并**在新建/移动分类目录后自动跑索引脚本**（见该 skill）。

## 零、与 notes-capture 的分工

| 本 skill（notes-directory）          | notes-capture                               |
| ------------------------------------ | ------------------------------------------- |
| `config.json`、`notesPath`、排除目录 | 抓取 / 对话与代码提炼、Diátaxis、落盘       |
| 索引规则与 `generate-index.js`       | 选路径、新建/追加 `.md`，**并自动刷新索引** |
| 按描述**搜索**已有 `.md`             | 读 `note-template.md` 决定条目形态          |

## 一、前置检查

1. 读取 `$HOME/.cursor/skills/notes-directory/config.json` 获取 `notesPath`、`excludeDirs`
2. **若 config 不存在或 notesPath 未配置**：提示用户配置，例如 `{ "notesPath": "/绝对路径/yun-notes", "excludeDirs": [] }`
3. **若 `{notesPath}` 目录不存在**：提示检查路径
4. 通过后再执行后续操作

## 二、分类索引

- **位置**：`{notesPath}/_index.json`
- **结构**：递归树形，例如：

  ```json
  {
    "notesRoot": "绝对路径",
    "updatedAt": "ISO8601",
    "excludeDirs": [".git", "assets"],
    "tree": { "一级目录": { "children": { "二级目录": { "children": {} } } } },
    "paths": ["一级目录", "一级目录/二级目录"]
  }
  ```

- **生成**：`node $HOME/.cursor/skills/notes-directory/scripts/generate-index.js`（在已配置 `notesPath` 前提下）
- **排除**：脚本默认跳过 `.git`、`.obsidian`、`assets`、`node_modules`、`__pycache__` 等；`config.json` 的 `excludeDirs` 可追加；被排除目录不参与索引与搜索
- **刷新时机**：凡**创建/移动/重命名**会改变分类树的目录后都必须运行上述命令；日常由 **notes-capture** 在新建目录后自动执行，你手动整理目录后也须执行一次

## 三、搜索笔记

- **触发**：用户要在已有笔记里查主题、问题或关键词
- **流程**：
  1. 读 `_index.json`，用 `paths` 缩小目录范围
  2. **先 grep**：固定词、报错片段、文件名、标识符等字面匹配；`excludeDirs` 用 `--exclude-dir` 排除
  3. **再 SemanticSearch**：grep 无有效结果、或用户只有模糊描述（「讲过 Vue 列表动画那类」）时用语义搜索；依赖 **Cursor 内置语义检索**，无需自建向量库
  4. 返回摘录；若无结果且用户要收录新内容，引导 **notes-capture**

## 四、目录与模板

- **新建分类目录**：在 `{notesPath}` 下创建后运行 `generate-index.js`（或由 notes-capture 自动运行）
- **完整模板**：`$HOME/.cursor/skills/notes-directory/note-template.md`
- **`---` 约定**：仅用于**相邻独立条目**之间；**单独一行** `---`，上下各一空行。同一条目内只用 `##` / `###` 分级，**不在小节之间插** `---`。
- **与 note-template 对齐的摘录示例**（字段可按需增减，不必死板列表）：

```markdown
## 知识点示例标题

**原文**：[页面标题](https://example.com) ← 有外链时保留

### 核心

要点……

### 适用场景 / 注意

……

---

### 问题示例标题

表现：……  
原因：……  
解决方案：……

---

### 备忘示例标题

2025-03-25T12:00:00+08:00 一句或一段自由正文
```

类型：**问题**、**知识点**（外链归此）、**备忘**；细节以 `note-template.md` 为准。

## 五、本地多媒体

图片等到笔记文件同级 `assets/`，命名 `年月日_时间戳`；`assets` 不进分类索引。

## 六、异常与兜底

- **`_index.json` 生成失败**（权限、路径非法等）：输出终端错误；提示检查 `{notesPath}` 写入权限与路径；建议用户本地执行 `node $HOME/.cursor/skills/notes-directory/scripts/generate-index.js` 并处理报错
- **`note-template.md` 缺失或无法解析**：notes-capture 仍按 Diátaxis 写结构化 Markdown，条首可注「模板暂不可用」；事后补齐模板再人工整理
- **用户指定路径或分类**：notes-capture 落盘时优先服从

## 七、注意事项

- `{notesPath}` 使用绝对路径
- 手动改动分类树后**务必**跑一次 `generate-index.js`（若未交给 notes-capture 自动跑）
