# yun-agent-skills

Personal collection of agent skills covering modern development technologies and best practices.

安装位置：`~/.agents/skills/`（symlink 到本仓库各 Skill 目录）。部分文档仍写 `~/.cursor/skills/`，以本机实际加载目录为准。

## Skill 索引

| Skill | 用途 | 来源 |
|-------|------|------|
| `ui-ux-pro-max` | UI/UX 设计系统选型、配色排版、可访问性与前端落地指导 | [galaxy-dawn/claude-scholar](https://github.com/galaxy-dawn/claude-scholar) |
| `nothing-design` | Nothing 工业风单色设计系统（显式触发，不自动用于泛 UI 任务） | [dominikmartn/nothing-design-skill](https://github.com/dominikmartn/nothing-design-skill) |
| `yun-create-skill` | 在官方 `create-skill` 之上，用五种内容设计模式创建/重构 Agent Skill | 自研 |
| `yun-reqflow` | 需求开发闭环编排（澄清→接口→实现→e2e→归档） | 自研 |
| `yun-reqflow-clarify` | 需求澄清与工作计划（含验收标准） | 自研 |
| `yun-reqflow-api` | 按接口文档补全工作计划契约 | 自研 |
| `yun-reqflow-implement` | 按已确认需求改业务代码 | 自研 |
| `yun-reqflow-e2e-author` | 按验收标准 + 真实 UI 写 Midscene e2e | 自研 |
| `yun-reqflow-e2e-verify` | 跑 e2e、判读回流或归档 | 自研 |
| `who-is-actor` | Git 仓库协作模式分析；默认 HTML 写入 `who-is-actor/reports/` | 自研 |
| `kd-i18n-*` | 公司 Vue 2 标品 VoerkaI18n 全流程 | 自研 |
| `kd-api-generator` | OpenAPI → `src/api` + `src/types` | 自研 |
| `llm-wiki-helper` | URL/文档 → yun-llm-wiki 笔记 | 自研 |
| `personal-ledger` | 个人 SQLite 记账 | 自研 |
| `tech-mentor` | 新技术栈结构化学习 | 自研 |
| `documentation-writer` | Diátaxis 技术文档 | 自研 |
| `find-skills` | 从 skills.sh 发现与安装 Skill | 上游 |
| `docx` | Word 文档读写 | 上游 |

## 安装第三方 Skill

```bash
npx skills add https://github.com/<owner>/<repo> --skill <skill-name> -y
# 若安装到 .agents/skills/ 子目录，移到仓库根目录以与本仓库结构一致
mv ~/.cursor/skills/.agents/skills/<skill-name> ~/.cursor/skills/
```

安装后更新 `skills-lock.json`（`npx skills add` 会自动写入）。

## 同步到 Claude Code（可选）

部分环境仍从 `~/.claude/skills/` 加载，可与本仓库保持一致：

```bash
rsync -a --delete ~/.cursor/skills/<skill-name>/ ~/.claude/skills/<skill-name>/
```
