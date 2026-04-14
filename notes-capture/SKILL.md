---
name: notes-capture
description: 从多来源（技术文章链接、对话上下文、项目代码等）捕获并整理为本地 Markdown 笔记：按 Diátaxis 与技术文档原则，结合 notes-directory 的索引与模板落盘；新建分类目录后自动刷新 _index.json。Use when 用户要保存链接为笔记、从聊天记录提炼笔记、从代码库摘录要点进笔记、合并到已有笔记，或任何需按模板写成文档的收录需求。
---

# 笔记收录（notes-capture）

**路径**：`$HOME/.cursor/skills/...` 与 `~/.cursor/skills/...` 同义；笔记库根目录为 `{notesPath}`（见 notes-directory 的 `config.json`）。

把多来源材料写成**可长期查阅**的技术笔记：遵循 **documentation-writer**（Diátaxis 等）与 **`$HOME/.cursor/skills/notes-directory/note-template.md`**。索引规则由 **notes-directory** 定义；**你只要在因本任务新建或移动了分类目录后，自动执行一次**下面的 `node ... generate-index.js`（勿只提示用户手动跑）。

## 零、与 notes-directory 的分工

| notes-capture                             | notes-directory                                     |
| ----------------------------------------- | --------------------------------------------------- |
| 写什么、怎么提炼、选路径、新建/追加 `.md` | `config`、`notesPath`、`_index.json` 结构、搜索策略 |
| **自动刷新索引**（见下）                  | 提供 `generate-index.js` 与模板路径                 |

## 一、执行顺序（摘录）

1. 按 notes-directory「一、前置检查」确认 `{notesPath}` 可用。
2. **Read** `$HOME/.cursor/skills/notes-directory/note-template.md`；读 `{notesPath}/_index.json`，若无则先执行一次 `node $HOME/.cursor/skills/notes-directory/scripts/generate-index.js` 再读。
3. 录入或合并 `.md`：**独立条目之间**用单独一行 `---`，上下各一空行；同一条目内只用标题层级，**不用** `---` 切小节（与 notes-directory「四、目录与模板」一致）。
4. **若本次新建或移动了 `{notesPath}` 下的分类目录**：在写回完成后**立即**执行：  
   `node $HOME/.cursor/skills/notes-directory/scripts/generate-index.js`  
   若失败，走「五、异常与兜底」。

## 二、输入来源

1. **URL**：走「三、获取页面内容」。
2. **对话**：仅依据已出现陈述，不编造。
3. **代码**：路径 + 短摘录，忌整文件粘贴。
4. **混合**：分段标出来源（链接 / 对话 / 路径）。

## 三、获取页面内容（URL；fetch 优先，浏览器兜底）

1. WebFetch / MCP 等拉正文；失败或正文空再 **cursor-ide-browser**（navigate → lock → snapshot → unlock）。
2. 来自网页的条目须在笔记中保留**可点击**标题与 URL（知识点用 **原文** 行，见模板）。

## 四、提炼（documentation-writer）

读取 `$HOME/.cursor/skills/documentation-writer/SKILL.md`，内化 Diátaxis 与 Clarity 等；不确定处不臆造 API/版本。

## 五、分类、条目形态与自检

1. 用 `_index.json` 的 `tree` / `paths` 选相对路径；**用户指定路径/文件名时优先**。
2. 形态与模板一致：概念/原理/API、外链收藏 → **知识点**（有链则 **原文**）；排错 → **问题**；速记 → **备忘**。
3. 自检：链接可点、结构符合模板与 `---` 约定。
4. **正文获取不全**：注明「正文获取不完整，建议本地打开」，并保留 URL。
5. **fetch 与浏览器均无法得到可用正文**：仍可落一条**知识点/备忘**条目，仅含 **原文** 与短说明「正文无法获取」。

## 六、异常与兜底

- **`generate-index.js` 报错**（权限、路径等）：向用户展示错误；说明须可写 `{notesPath}`；可建议其在终端自行重跑脚本。
- **`note-template.md` 无法读取**：按 Diátaxis 写 Markdown，条首可加一行「模板未读入」；事后对照 notes-directory 模板整理。
- **`_index.json` 缺失且脚本失败**：仍可按用户指定路径写 `.md`，并提示索引未更新、需排错后补跑脚本。

## 七、延伸阅读

- Diátaxis：<https://diataxis.fr/>
