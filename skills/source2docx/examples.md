# 示例

## 输入

- 文档份数：2
- 每页行数：50
- 总页数：60
- 入口：`src/main.js`

## 命令

```bash
python 本 Skill 目录/scripts/export_source_docx.py \
  --project-root /path/to/project \
  --entry src/main.js \
  --doc-count 2 \
  --lines-per-page 50 \
  --total-pages 60 \
  --obfuscation medium \
  --output-dir soft-copyright-output
```

## 产出

```
soft-copyright-output/
├── source-master.docx    # 60 页 × 50 行
├── source-doc-01.docx    # 30 页（page 1–30）
├── source-doc-02.docx    # 30 页（page 31–60）
└── manifest.json
```

## manifest.json 摘要

```json
{
  "master": "source-master.docx",
  "total_pages": 60,
  "documents": [
    { "file": "source-doc-01.docx", "page_start": 1, "page_end": 30, "page_count": 30 },
    { "file": "source-doc-02.docx", "page_start": 31, "page_end": 60, "page_count": 30 }
  ],
  "params": {
    "layout": {
      "font_name": "宋体",
      "font_size_pt": 10.5,
      "lines_per_page": 50
    }
  }
}
```

## 流程说明

1. 从入口 BFS 收录**整文件**，直到排版行 ≥ 3000
2. 取前 3000 行 → 60 页（每页 50 行）
3. 写 master → 按页拆 2 份

默认 **宋体五号**，段前段后 0。
