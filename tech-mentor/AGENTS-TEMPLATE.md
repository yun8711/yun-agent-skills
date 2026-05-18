# Agents 说明 — {TECH} 学习工作区

本仓库由 **Tech Mentor（`tech-mentor`）** 初始化，是**系统化课程练习项目**（默认非生产业务代码；`workspaceMode` 见 `resources/tech-profile.json`）。

## 如何运行

根据实际技术栈填写下列命令（在 `practice/` 下已创建对应工程后，应与该工程根目录的 `package.json` / `pyproject.toml` / `Cargo.toml` 等保持一致；**搭架子阶段**若尚未创建练习工程，可先填「待定」或占位，首次在 `practice/` 内 scaffold 后再更新本节）。

- **包管理器**：{PACKAGE_MANAGER}
- **安装依赖**：`{INSTALL_CMD}`
- **启动开发/调试**：`{DEV_CMD}`
- **运行测试（若有）**：`{TEST_CMD}`
- **其他常用命令**：{OTHER_CMDS}

版本、工作区模式与生态以 `resources/tech-profile.json` 为准（`version`、`relatedEcosystem`、`workspaceMode`、`learningRoot` 等）。

## AI 交互快捷指令

| 用户说法（示例） | AI 行为摘要 |
| ---------------- | ----------- |
| 下一阶段 / 继续 | 按 `LEARNING-PLAN.md` 与 `chapterStructure` 生成下一模块 + 练习 |
| 给我一个练习 | 针对当前章节生成练习与验收 |
| 批改练习 | 批改并更新 `LEARNING-LOG.md`、`PROGRESS.md` |
| 解释 XX | 输出 Explanation 型内容（须符合官方文档） |
| 更新计划 | 修订 `LEARNING-PLAN.md` 并展示待确认 |
| 记录笔记 | 默认写入本项目 `notes/`；项目外个人笔记由用户自定，不强制 |
| 快速开始 / 跳过 | 按 `SKILL.md` 快速启动与默认规则处理 |

## 目录与单一真相来源

| 路径 | 说明 |
| ---- | ---- |
| `resources/tech-profile.json` | 学习目标、章节、`workspaceMode`、`prerequisites`、`skipChapters`、`codeStyle` 等；**生成或修改练习前应先阅读** |
| `LEARNING-PLAN.md` | 用户确认过的章节式学习计划 |
| `RESOURCES.md` | 官方文档索引、精选文章与视频（避免与 `notes/` 混用） |
| `practice/` | 章节练习与示例代码、本地实验工程的**根目录**（见下节「`practice/` 目录约定」） |
| `notes/` | 与本项目相关的笔记与踩坑 |
| `LEARNING-LOG.md` | 学习日志：重点、难点、疑问点、证据与建议动作 |
| `PROGRESS.md` | 章节/阶段进度与里程碑状态 |
| `LEARNING-EVALUATION.md` | 阶段评价、趋势评价与分级强化计划 |
| `.cursor/rules/LEARNING-RULES.md`（或项目内等价规则文件） | Cursor 中 AI 的行为与内容规范 |

## `practice/` 目录约定

搭架子时仅初始化**空的** `practice/`。学习过程中创建的练习工程、可运行示例与沙盒项目**一律放在 `practice/` 下**，不在仓库其它位置随意新建工程根。

**子目录如何组织不在初始化时固定**。进入各章节或具体练习前，由**用户与 AI 商定**一种或多种方式，例如：**每一学习章节一个子目录**（如 `practice/ch03-forms/`），或在 `practice/` 下**由用户指定路径**（如 `practice/my-lab/`）。商定后可在当章 `LEARNING-PLAN.md` 小节、`LEARNING-LOG.md` 或 `notes/` 中简要记录，便于后续会话对齐。若 `workspaceMode` 为 `in_place`，仍须遵守 `tech-profile` 中声明的可写范围。

## 给 AI 的简要约定

1. **先读配置再行动**：生成或修改练习、教程与说明前，以 `tech-profile.json` 与 `LEARNING-PLAN.md` 为准，遵守 `learningScope`、`chapterStructure`、`relatedEcosystem`、`learningPace`、`workspaceMode`；代码风格以 `codeStyle` 与 LEARNING-RULES 为准（官方推荐实践）。**新建或移动任何练习/示例代码前**，确认落在 **`practice/`** 下并与用户对齐当章子目录或用户指定路径（见上节）。
2. **运行方式**：以本节「如何运行」为准；若与用户指令冲突，先核对 `tech-profile.json` 与本文件后执行。
3. **学习跟踪与评价**：练习批改或关键提问后更新 `LEARNING-LOG.md`；章/阶段结束更新 `PROGRESS.md` 与 `LEARNING-EVALUATION.md`（含**元认知自检**三问、强化项含难度与预计耗时）。
4. **行为规范与输出格式**：详见 `.cursor/rules/` 下的学习项目规则；本文件不重复展开。

---

*本文件在创建工作区时由 **Tech Mentor（`tech-mentor`）** 根据所选技术栈与章节结构个性化填写占位符。*
