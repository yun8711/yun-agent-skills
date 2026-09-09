# 交付前自检

## 参数与页数

- [ ] master 页数 = `target_pages`
- [ ] 各 `source-doc-NN.docx` 页数之和 = `target_pages`
- [ ] 每页（中间页）= `lines_per_page` 行
- [ ] `manifest.json` 中 `page_start` / `page_end` 正确

## 格式

- [ ] 字体：宋体，五号（10.5pt）
- [ ] 段前、段后 = 0
- [ ] 每段以 `===相对路径===` 开头

## 收录

- [ ] 收录阶段为整文件（未在收录时从文件中间截取）
- [ ] 无 API key、密码、`.env` 明文

## 产物

- [ ] `source-master.docx` 存在
- [ ] `source-doc-01.docx` … 连续编号
