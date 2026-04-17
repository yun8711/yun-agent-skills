# Agents 说明 — {TECH} 学习工作区

本仓库由 **Tech Mentor（`tech-mentor`）** 初始化，是**系统化课程练习项目**（默认非生产业务代码；`workspaceMode` 见 `resources/tech-profile.json`）。

## 如何运行

根据实际技术栈填写下列命令（初始化时应与 `package.json` / `pyproject.toml` / `Cargo.toml` 等保持一致）。

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
| `resources/tech-profile.json` | 学习目标、章节、`workspaceMode`、`practiceLayout`、`practiceMainProject`（主练习工程路径）、`prerequisites`、`skipChapters`、`codeStyle`；**生成或修改练习前应先阅读** |
| `LEARNING-PLAN.md` | 用户确认过的章节式学习计划 |
| `RESOURCES.md` | 官方文档索引、精选文章与视频（避免与 `notes/` 混用） |
| `practice/` | 章节练习与示例代码 |
| `notes/` | 与本项目相关的笔记与踩坑 |
| `LEARNING-LOG.md` | 学习日志：重点、难点、疑问点、证据与建议动作 |
| `PROGRESS.md` | 章节/阶段进度与里程碑状态 |
| `LEARNING-EVALUATION.md` | 阶段评价、趋势评价与分级强化计划 |
| `.cursor/rules/LEARNING-RULES.md`（或项目内等价规则文件） | Cursor 中 AI 的行为与内容规范 |

## 给 AI 的简要约定

1. **先读配置再行动**：生成或修改练习、教程与说明前，以 `tech-profile.json` 与 `LEARNING-PLAN.md` 为准，遵守 `learningScope`、`chapterStructure`、`relatedEcosystem`、`learningPace`、`workspaceMode`；代码风格以 `codeStyle` 与 LEARNING-RULES 为准（官方推荐实践）。
2. **运行方式**：以本节「如何运行」为准；若与用户指令冲突，先核对 `tech-profile.json` 与本文件后执行。
3. **学习跟踪与评价**：练习批改或关键提问后更新 `LEARNING-LOG.md`；章/阶段结束更新 `PROGRESS.md` 与 `LEARNING-EVALUATION.md`（强化项含难度与预计耗时）。
4. **行为规范与输出格式**：详见 `.cursor/rules/` 下的学习项目规则；本文件不重复展开。

---

*本文件在创建工作区时由 **Tech Mentor（`tech-mentor`）** 根据所选技术栈与章节结构个性化填写占位符。*
