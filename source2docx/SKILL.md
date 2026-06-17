---
name: source2docx
description: >-
  Extracts project source code from an entry file into multiple .docx documents
  for software copyright (软著) registration, with master-first pagination and
  optional obfuscation. Use when the user invokes source2docx, or mentions 软著、
  软件著作权、源码文档、source code docx, copyright submission materials, or asks
  to export project source into Word documents with line/page limits.
disable-model-invocation: true
---

# source2docx — 源码导出 DOCX

将项目源码从入口文件起按依赖顺序提取、混淆后，**先统一分页生成 master.docx，再按页切分**为多份 `.docx`。分页以 Word 排版行为准，不以源码行数直接拆文档。

**在用户确认 Step 2 提取计划之前，不得生成 docx 或写入最终产物。**

按顺序执行，**不得跳过**任何步骤。

## 关联 Skill

生成 docx 时 Read [docx skill](../docx/SKILL.md) 的「Creating New Documents」；版面见 [references/docx-layout.md](references/docx-layout.md)。优先用 `scripts/export_source_docx.py`。

## Step 1 — 收集参数（Inversion）

| 参数 | 必填 | 说明 |
|------|------|------|
| `doc_count` | 是 | 生成文档份数 |
| `lines_per_page` | 是 | 每页行数 |
| `total_lines` 或 `total_pages` | 二选一 | 总页数优先；或由总行数推算页数 |
| `entry_file` | 否 | 入口文件；未提供则 Read [references/entry-discovery.md](references/entry-discovery.md) |
| `output_dir` | 否 | 默认 `soft-copyright-output/` |
| `obfuscation_level` | 否 | `light` / `medium` / `strict` |
| `exclude_patterns` | 否 | 额外排除 glob |

确认换算：`target_pages = total_pages ?? ceil(total_lines / lines_per_page)`。**分页与拆份以 DOCX 页为准**。默认字体：**宋体五号（10.5pt）**，段前段后 0。

## Step 2 — 提取计划（门禁）

1. Read [references/split-strategy.md](references/split-strategy.md)
2. Read [references/obfuscation-rules.md](references/obfuscation-rules.md)
3. BFS 收录整文件，段格式：

```text
===relative/path/to/file.ext===
<file content after obfuscation>
```

4. 用 [assets/extraction-plan-template.md](assets/extraction-plan-template.md) 展示：
   - `target_pages`、`lines_per_page`
   - 拟收录文件列表（整文件，累计 **排版行数** ≥ `target_pages × lines_per_page`）
   - master 页数与各 `source-doc-NN.docx` 的 **页范围**（非源码段边界）
   - 混淆摘要

**在用户确认该计划之前，不得进入 Step 3。**

## Step 3 — 生成 docx

### 首选：脚本

依赖：`pip install -r scripts/requirements.txt`

```bash
python scripts/export_source_docx.py \
  --project-root . \
  --entry src/main.js \
  --doc-count 2 \
  --lines-per-page 50 \
  --total-pages 60 \
  --obfuscation medium \
  --output-dir soft-copyright-output
```

流程（脚本内置）：

1. 收录源码 → 排版行流
2. 截断至 `target_pages × lines_per_page` 行并分页
3. 写 **`source-master.docx`**
4. 按页范围拆 **`source-doc-01.docx`** …

默认 **宋体、五号（10.5pt）、段前段后 0**。可选 `--margin-cm`、`--font-name`、`--font-size`。

### 备选：手动

同 [references/docx-layout.md](references/docx-layout.md)：先 master 全页，再按页切分。

## Step 4 — 质量自检

Read [references/quality-checklist.md](references/quality-checklist.md)。

交付物：

- `source-master.docx`
- `source-doc-01.docx` …（页数见 manifest）
- `manifest.json`

## 附加资源

- [examples.md](examples.md)

## 用户要求（原文，执行时 verbatim 遵守）

1. 用户需要提供生成文档数量，每页多少行，总行数或总页数
2. 提取源码时，从入口文件开始，逐个文件提取转换，每一段要用`===xxx===`这种形式标明文件相对路径，后跟文件内容
3. 首先按要求的总数提取足够行数的内容，然后根据需要分隔为几个文档再分隔，要避免把完整的文件从中间截断，尽量保持文件完整性
4. 提取源码时，要避免暴露一些核心代码，可以进行一定程度的混淆

**策略补充（页数准确）**：收录阶段保持文件完整；生成阶段先出 master.docx 再按页拆份。为凑足总页数，排版行流截断处可能落在文件中间。
