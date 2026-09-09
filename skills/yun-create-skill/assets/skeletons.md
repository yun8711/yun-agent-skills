# Skill 骨架模板（按模式）

复制到目标 Skill 后替换占位符，并删除未用模式块。

---

## Tool Wrapper

```markdown
---
name: {skill-name}
description: {Expert in X}. Use when {building|reviewing|debugging} {X applications}.
---

You are an expert in {X}.

## When to load references

- Before **reviewing** or **writing** {X} code, Read [references/conventions.md](references/conventions.md).

## When reviewing

1. Load conventions
2. Check each rule; for violations: cite rule, severity, fix

## When writing

1. Load conventions
2. Follow every rule exactly
```

---

## Generator

```markdown
---
name: {skill-name}
description: Generates {artifact type} in {format}. Use when {user asks for ...}.
---

You generate {artifact type}. Execute in order:

**Step 1** — Read [references/style-guide.md](references/style-guide.md)

**Step 2** — Read [assets/output-template.md](assets/output-template.md)

**Step 3** — Collect missing fields from user:
- {field-a}
- {field-b}

**Step 4** — Fill template per style guide

**Step 5** — Deliver final artifact
```

---

## Reviewer

```markdown
---
name: {skill-name}
description: Reviews {subject} for {criteria}. Use when {PR review|audit|...}.
---

## Protocol

1. Read [references/review-checklist.md](references/review-checklist.md)
2. Read user-provided {code|doc|...}
3. For each rule violation: line, severity (error|warning|info), why, fix

## Output format

### Summary
### Findings (by severity)
### Score (1-10, justified)
### Top 3 Recommendations
```

---

## Inversion

```markdown
---
name: {skill-name}
description: Gathers requirements via structured questions before {plan|build|...}. Use when {ambiguous scope|greenfield|...}.
---

**DO NOT** {start building|generate output|edit files} until all phases below are complete.

## Phase 1 — {name}

Ask **one question at a time**, in order:
1. {Q1}
2. {Q2}

## Phase 2 — {name} (only after Phase 1 complete)

1. {Q3}
...

## Phase 3 — Synthesis

1. Read [assets/plan-template.md](assets/plan-template.md)
2. Fill from gathered answers
3. Present plan; ask: "Does this match your intent?"
4. Iterate until user confirms
```

---

## Pipeline

```markdown
---
name: {skill-name}
description: Runs {workflow} in strict order. Use when {multi-step|quality-critical|...}.
---

Execute steps **in order**. **Do NOT skip** any step.

## Step 1 — {name}

{actions}
Ask: "{confirmation question}?"

## Step 2 — {name}

{actions}
**Do NOT proceed to Step 3 until user confirms Step 2.**

## Step 3 — {name}

Read [assets/{template}.md](assets/{template}.md); assemble output.

## Step 4 — Quality check

Read [references/quality-checklist.md](references/quality-checklist.md); fix before delivery.
```

---

## 组合示例（Pipeline + Reviewer 末步）

在 Pipeline 最后一步写入：

```markdown
## Step N — Self-review

Apply [references/quality-checklist.md](references/quality-checklist.md).
Report pass/fail per item before final delivery.
```
