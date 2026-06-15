# HTML 报告生成（默认）

## 默认产出

分析完成后，**默认**生成本地可打开的**单文件 HTML**（非 Markdown），除非用户明确要求「仅 Markdown」或「不要写文件」。

## 模板与输出路径

1. **读取模板**：`<skill_root>/assets/report-template.html`（`skill_root` = 本 skill 目录，即含 `SKILL.md` 的 `who-is-actor/` 文件夹）
2. **写入位置**（默认，**不写入被分析仓库**）：
   ```
   <skill_root>/reports/<repo_basename>-collaboration-report-<YYYY-MM-DD-HHmm>.html
   ```
   - `repo_basename`：`basename $(git -C <repo_path> rev-parse --show-toplevel)`（如 `rhea-fe`）
   - `<YYYY-MM-DD-HHmm>`：报告生成时刻，本地时区（如 `2026-06-04-1304` 表示 13:04）
   - 示例：`~/.cursor/skills/who-is-actor/reports/rhea-fe-collaboration-report-2026-06-04-1304.html`
   - `meta.generatedAt` 建议人类可读格式：`2026-06-04 13:04`（与文件名时刻一致）
   - 若同一分钟同仓库文件已存在，在末尾追加 `-2`、`-3`…（如 `…-1304-2.html`）
   - 若 `reports/` 不存在，创建该目录（仅 skill 目录内）
3. **告知用户**：输出绝对路径，并执行 `open <path>`（macOS）或提示在浏览器中打开

用户可说「写到仓库里」「输出到桌面」「只要 Markdown」覆盖默认行为。

## 生成步骤

1. 完成步骤 2 数据采集与本地聚合（遵守敏感数据规则）
2. 按下方 schema 构建 **纯 JSON** 对象（仅聚合指标与仓库级文案，无原始 commit 主题、无完整路径列表）
3. 读取 `assets/report-template.html`，将占位符 `__REPORT_DATA_JSON__` **整段替换**为 `JSON.stringify(data)` 结果（UTF-8，确保合法 JSON）
4. 可选：将 `<title>` 中的 `__REPO_NAME__` 替换为仓库目录名
5. 写入输出文件；在对话中附 3–5 条仓库级要点摘要（不替代 HTML）

## JSON Schema（`REPORT_DATA`）

```json
{
  "meta": {
    "repoName": "rhea-fe",
    "repoPath": "/abs/path/to/repo",
    "generatedAt": "2026-06-04 13:04",
    "scopeLabel": "git log --all · 2022-08-09 → 2026-05-28",
    "badges": ["18 位贡献者（仅计数）", "分支: main"]
  },
  "summary": {
    "repoName": "rhea-fe",
    "totalCommits": "2,323",
    "linesDisplay": "+1.21M / −665K",
    "commitsPerDay": "1.67",
    "activeDayPct": "49.3%",
    "weekendPct": "10.1%",
    "lateNightPct": "9.4%",
    "bugFixPct": "40.2%",
    "churnPct": "54.8%",
    "activityBand": "0–20（较高可见活动）",
    "activityNote": "可见活动指数分数越低 = Git 写入越频繁；本仓库约 10–15 分。",
    "activityScorePct": 12
  },
  "kpis": [
    { "label": "总提交数", "value": "2,323", "highlight": true },
    { "label": "贡献者数量", "value": "18", "unit": "仅计数" }
  ],
  "charts": {
    "hours": { "labels": ["00","01", "..."], "data": [0, 1, "..."] },
    "weekday": { "labels": ["周一","周二","周三","周四","周五","周六","周日"], "data": [441, 464, 444, 379, 137, 51, 98] },
    "extensions": { "labels": [".vue",".js"], "data": [6676, 3135] },
    "rates": {
      "labels": ["约定式提交%","Bug修复%","周末%","深夜%","流失率%","净增长%"],
      "data": [93.2, 40.2, 10.1, 9.4, 54.8, 45.2]
    }
  },
  "insights": [
    { "title": "⏰ 提交时间", "text": "仓库级描述，多重解读，不评判个人。" }
  ],
  "discussion": ["团队回顾问题 1", "问题 2"],
  "busFactor": {
    "singleAuthorFilePct": "52.7%",
    "filesTracked": 1006,
    "items": [
      { "file": "src/views/Foo.vue", "author": "Display Name" }
    ]
  }
}
```

### 字段约束

| 字段 | 规则 |
|------|------|
| `charts.hours` | 必须 24 个 label（`00`–`23`）与 24 个 data（无数据填 0） |
| `charts.weekday` | 7 个 label（周一至周日）与 7 个 data |
| `charts.extensions` | Top 8，仅扩展名字符串 |
| `charts.rates` | 仅仓库级比率，**禁止**按贡献者序列 |
| `busFactor.items` | 可选，最多 **10** 条；仅步骤 4.3 巴士因子披露；路径须脱敏敏感段；**不得**与评分/排名并列 |
| 所有字符串 | 写入 JSON 前做密钥模式脱敏（见 SKILL 敏感数据过滤规则） |

## 图表说明

- **雷达图**：仅展示仓库级比率（约定式提交%、Bug 修复% 等），**不是**个人多维画像。
- **Chart.js**：通过 CDN 加载；离线打开时图表可能空白，需联网。

## Markdown 回退

用户明确说「Markdown」「不要 HTML」「纯文本报告」时：

- 跳过 HTML 写入，按 SKILL 步骤 4 输出 Markdown 结构
- 仍遵守仓库级、非人事、无按人表格等全部约束

## 禁止项（HTML 同样适用）

- 按贡献者表格、排名、个人评分、个人雷达图
- 在 KPI/图表/insights 中嵌入贡献者对比
- 将原始 commit message 批量写入 HTML（用户主动要求的脱敏样例 ≤3 条且 ≤120 字符除外）
