# yun-agent-skills

自研 Agent Skill 源仓库。安装与更新统一走 [`npx skills`](https://skills.sh/)（Vercel Labs Skills CLI），本仓不 vendor 第三方。

开发自研：改 `skills/<name>/` → commit / push → `npx skills update -g`。

## 安装

全局安装到 `~/.agents/skills/`，CLI 再按 Agent 挂 symlink（Cursor / Claude Code / Codex 等）。

```bash
# 自研（本仓）
npx skills add yun8711/yun-agent-skills -g --skill '*' \
  -a cursor -a claude-code -a codex -y

# 常用第三方（远程标准版，不进本仓）
npx skills add anthropics/skills --skill docx -g \
  -a cursor -a claude-code -a codex -y
npx skills add Leonxlnx/taste-skill -g \
  -a cursor -a claude-code -a codex -y
npx skills add dominikmartn/nothing-design-skill -g \
  -a cursor -a claude-code -a codex -y
npx skills add galaxy-dawn/claude-scholar --skill ui-ux-pro-max -g \
  -a cursor -a claude-code -a codex -y
```

查看与更新：

```bash
npx skills list -g
npx skills update -g
```

锁文件在 `~/.agents/.skill-lock.json`（全局），不提交本仓。

## 自研索引

| Skill | 用途 |
|-------|------|
| `yun-create-skill` | 在官方 `create-skill` 之上，用五种内容设计模式创建/重构 Agent Skill |
| `yun-frontend-quality` | 前端格式化/lint/编辑器/hooks 配置向导（选项+说明，不预选工具） |
| `yun-reqflow` | 需求开发闭环编排（澄清→接口→实现→e2e→归档） |
| `yun-reqflow-clarify` | 需求澄清与工作计划（含验收标准） |
| `yun-reqflow-api` | 按接口文档补全工作计划契约 |
| `yun-reqflow-implement` | 按已确认需求改业务代码 |
| `yun-reqflow-e2e-author` | 按验收标准 + 真实 UI 写 Midscene e2e |
| `yun-reqflow-e2e-verify` | 跑 e2e、判读回流或归档 |
| `kd-i18n-*` | Vue 2 标品 VoerkaI18n 全流程（setup / marking / translation / workflow） |
| `kd-api-generator` | OpenAPI → `src/api` + `src/types` |
| `llm-wiki-helper` | URL/文档 → yun-llm-wiki 笔记 |
| `tech-mentor` | 新技术栈结构化学习 |
| `source2docx` | 软著源码导出 Word（依赖已安装的 `docx` Skill） |
