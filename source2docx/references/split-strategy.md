# 收录与拆分策略

## 原则：以 DOCX 行/页为准，不以源码行数拆文档

源码行数与 Word 排版行数常不一致。**分页与拆份必须基于同一份「排版行流」**，避免先按源码行拆 doc 再各自生成。

## 1. 三阶段流程

```text
收录源码（整文件） → 排版行流 → 分页 → master.docx → 按页切分多份 docx
```

| 阶段 | 说明 |
|------|------|
| 收录 | 从入口 BFS，**整文件**追加，直到排版行数 ≥ `target_pages × lines_per_page` |
| 排版行流 | 混淆后 flatten：每段 `===path===` 占 1 行 + 文件各行 |
| 分页 | 每 `lines_per_page` 行一页（docx 行单位），截断至恰好 `target_pages` 页 |
| master | 写入 `source-master.docx`（全量页） |
| 拆份 | 按页范围切 master 同等页组，写入 `source-doc-01.docx` … |

## 2. 源码收录（保持文件完整）

目标页数：`target_pages = total_pages ?? ceil(total_lines / lines_per_page)`。

按 BFS 顺序逐个**完整文件**追加，直到：

```text
len(排版行流) >= target_pages × lines_per_page
```

收录阶段**不从文件中间截取**。若遍历完仍不足，报错提示增加入口依赖或降低页数。

## 3. 截断至目标页数

排版行流生成后，取前 `target_pages × lines_per_page` 行，再按 `lines_per_page` 分页。

- 得到恰好 `target_pages` 页，每页满 `lines_per_page` 行（除策略要求末页满页外，中间页均满页）
- **截断可能落在某文件中间**——这是为保证总页数与 Word 一致的取舍；收录阶段仍保持整文件

## 4. 拆成 doc_count 份（按页，不按源码段）

在 **页** 边界切分，不再按 `===path===` 段切 doc：

```text
pages_per_doc = target_pages // doc_count  （余数分给前几份）
doc1: page 1 … page k
doc2: page k+1 … page m
…
```

每份子 docx 使用与 master **相同** 版面（宋体五号、段前段后 0、EXACTLY 行距），页数由 manifest 记录。

## 5. 段格式（不变）

```text
===src/main.js===
import App from './App.vue'
...
```

## 6. 默认字体

- **宋体（正文）**：`font_name = 宋体`
- **五号**：`10.5pt`
- 段前 / 段后：`0`

详见 [docx-layout.md](docx-layout.md)。
