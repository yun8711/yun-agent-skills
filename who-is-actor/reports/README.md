# 报告输出目录

who-is-actor **默认**将 HTML 报告写入此目录（不写入被分析仓库）。

## 命名规则

```
<repo_basename>-collaboration-report-<YYYY-MM-DD-HHmm>.html
```

示例：`rhea-fe-collaboration-report-2026-06-04-1304.html`（2026-06-04 13:04 生成）

同一分钟同仓库再次生成时，追加序号：`…-1304-2.html`
- 由 `assets/report-template.html` + 聚合指标 JSON 生成。
