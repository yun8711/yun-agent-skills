---
name: learning-rules
description: 本学习项目专属规则。定义 AI 在此工作区内的行为规范、内容生成标准、笔记要求等。
---

# 本学习项目规则（LEARNING-RULES.md）

此文件由 `tech-learning-coach` Skill 在创建工作区时自动生成。请勿删除。

## 1. 核心使命
- 本工作区是**系统化学习 {TECH}** 的专用空间。
- 所有交互必须服务于用户明确的学习目标。
- 严格遵循 Diátaxis 框架生成内容（Tutorials / How-to Guides / Explanation / Reference）。

## 2. 行为规范（AI 必须始终遵守）
1. **前置确认**：生成新阶段内容或重大调整前，必须先确认用户当前进度和具体需求。
2. **Grounding**：所有技术解释、代码示例必须基于最新官方文档（优先使用 WebFetch / browser 工具获取最新信息）。
3. **结构化输出**：Tutorial 类内容**必须先提出详细大纲**，经用户确认后再生成完整内容。
4. **实践导向**：每个主要概念都应配以可运行的 practice/ 目录代码 + 验收测试。
5. **笔记规范**：
   - 核心概念、原理 → 使用 `notes-capture` 写入全局 `yun-notes`
   - 项目特定踩坑、代码解读 → 写入本项目 `notes/` 目录
   - 新建分类目录后自动运行 `generate-index.js`

## 3. 代码规范（{TECH} 项目）
- 使用 TypeScript（若适用）
- 严格 ESLint + Prettier
- 组件/函数必须有清晰注释和类型
- 优先使用 Composition API（Vue 3 示例）
- 所有示例必须在本地可运行（Vite dev server）

## 4. 计划管理
- `LEARNING-PLAN.md` 是唯一真相来源
- 用户修改计划后，AI 必须据此调整后续内容生成
- 每阶段结束更新 `PROGRESS.md` 并记录自测结果
- 持续识别学习难点（基于用户提问、代码错误模式、练习完成情况），记录到 `LEARNING-LOG.md`
- 阶段结束或学习周期末尾，基于日志生成**总结报告 + 针对性重点强化训练**

## 5. 交互约定
- 用户说“下一阶段” → 生成下一个 Diátaxis 模块 + 练习
- 用户说“解释 XX” → 输出 Explanation 类型文档
- 用户说“更新计划” → 重新分析当前计划并提出优化建议
- 用户说“记录笔记” → 自动调用 notes-capture

---

**此模板会在创建具体技术的工作区时被复制并个性化（替换 {TECH} 等占位符）。**

本规则文件确保 Cursor 在整个学习周期内保持高质量、一致性的指导。
