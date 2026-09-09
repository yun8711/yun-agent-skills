# 源码混淆规则

目的：**软著材料可读、可审，但不暴露密钥、算法细节与生产配置**。混淆后须保持原行数与基本结构（括号配对、缩进层级）。

## 级别

| 级别 | 适用 |
|------|------|
| `light` | 仅脱敏凭证与连接串 |
| `medium`（默认） | light + 核心业务函数体简化 |
| `strict` | medium + 常量/配置占位 + 复杂逻辑块替换 |

## 必做（所有级别）

1. **密钥与凭证**：匹配 `apiKey`、`secret`、`password`、`token`、`private_key`、`access_key` 等赋值右侧 → `"***"`
2. **连接串**：`mongodb://`、`redis://`、`mysql://`、`postgres://` URL → `"<connection-redacted>"`
3. **`.env` 取值**：不收录 `.env` 文件；若其他文件硬编码 env 值，同上做占位
4. **长 Base64 / JWT 字面量** → `"<redacted>"`

## medium 追加

5. **加密/签名核心**：`encrypt`、`decrypt`、`sign`、`verify`、`hash`、`hmac` 等命名的函数 **函数体**（花括号内）替换为 `{ /* core logic omitted for copyright submission */ return input; }` 或语言等价单行占位，**保留函数签名与 export**
6. **授权/计费/DRM 相关模块**：同上，仅保留接口形状

## strict 追加

7. **大段数值/配置常量**（>32 字符的字符串或数组字面量）→ 短占位
8. **嵌套 ≥4 层的复杂表达式**：改为简单变量名 + 注释 `// simplified`
9. **正则含敏感业务规则**：改为 `/.../`

## 不做

- 不改变文件名、路径 header
- 不删除 import/export 结构（npm 包名可保留）
- 不引入语法错误
- 不混淆第三方库拷贝进 repo 的 vendor（应排除不收录）

## 手动标记

用户可指定：

- `obfuscate_files`：强制混淆的文件 glob
- `skip_obfuscate_files`：永不混淆（如纯 UI 组件）

Agent 在提取计划中列出将混淆的文件与规则命中项，供用户确认。
