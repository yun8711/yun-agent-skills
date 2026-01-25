# Skill 调试指南

本文档帮助你调试和验证 `kd-fe-deploy` skill 是否正常工作。

## 1. 基础验证

### 1.1 检查文件结构

确保 skill 目录结构正确：

```bash
kd-fe-deploy/
├── SKILL.md              # ✅ 必须存在
├── README.md             # ✅ 文档文件
├── scripts/              # ✅ 脚本目录
│   ├── full-deploy.sh
│   ├── deploy.sh
│   └── ...
└── config-template-local.json
```

### 1.2 验证 YAML Frontmatter

检查 `SKILL.md` 的前置元数据格式：

```bash
# 使用 grep 检查格式
grep -A 2 "^---$" kd-fe-deploy/SKILL.md
```

应该看到：
```yaml
---
name: kd-fe-deploy
description: Automates frontend project builds...
---
```

**常见问题**：
- ❌ 缺少 `---` 分隔符
- ❌ `name` 字段包含大写字母或特殊字符（应使用小写和连字符）
- ❌ `description` 超过 1024 字符
- ❌ `description` 使用第一人称（应使用第三人称）

### 1.3 验证描述触发词

检查 description 是否包含足够的触发关键词：

```bash
# 查看 description
grep "description:" kd-fe-deploy/SKILL.md
```

**应该包含的触发词**：
- ✅ "deploy" / "deployment"
- ✅ "frontend"
- ✅ "package.json"
- ✅ "JumpServer" / "bastion"
- ✅ "Use when..." 明确使用场景

## 2. Skill 发现测试

### 2.1 测试 Skill 是否被加载

在 Cursor 中测试以下场景，观察 AI 是否自动应用此 skill：

**测试场景 1：部署相关查询**
```
用户: "帮我部署前端项目到内网服务器"
预期: AI 应该识别并应用 kd-fe-deploy skill
```

**测试场景 2：配置相关查询**
```
用户: "如何在 package.json 中配置部署路径？"
预期: AI 应该引用 skill 中的配置说明
```

**测试场景 3：JumpServer 相关**
```
用户: "我需要通过 JumpServer 连接服务器部署"
预期: AI 应该应用 skill 并指导使用相关脚本
```

### 2.2 手动触发测试

如果自动触发失败，尝试明确提及：

```
用户: "使用 kd-fe-deploy skill 帮我部署项目"
```

## 3. 内容验证

### 3.1 检查文件路径引用

验证所有脚本路径是否正确：

```bash
# 检查 SKILL.md 中引用的脚本是否存在
grep -o "\.\/kd-fe-deploy\/scripts\/[^ ]*" kd-fe-deploy/SKILL.md | sort -u

# 验证这些文件是否存在
for script in $(grep -o "\.\/kd-fe-deploy\/scripts\/[^ ]*" kd-fe-deploy/SKILL.md | sort -u); do
    if [ -f "$script" ]; then
        echo "✅ $script"
    else
        echo "❌ 缺失: $script"
    fi
done
```

### 3.2 验证代码示例

检查所有 JSON 和 bash 代码块是否格式正确：

```bash
# 检查 JSON 示例是否有效
grep -A 10 "```json" kd-fe-deploy/SKILL.md | grep -A 10 "```" | head -20

# 可以使用 jq 验证 JSON 格式（如果安装了 jq）
```

### 3.3 检查行数限制

确保 SKILL.md 不超过 500 行：

```bash
wc -l kd-fe-deploy/SKILL.md
# 应该显示少于 500 行
```

## 4. 功能测试

### 4.1 测试配置验证脚本

```bash
# 测试配置验证功能
cd kd-fe-deploy
./scripts/validate-config.sh

# 应该显示配置验证结果
```

### 4.2 测试脚本可执行性

```bash
# 检查所有脚本是否有执行权限
find kd-fe-deploy/scripts -name "*.sh" -exec ls -l {} \;

# 如果没有权限，添加执行权限
chmod +x kd-fe-deploy/scripts/*.sh
```

### 4.3 测试路径解析

验证相对路径在不同工作目录下是否正确：

```bash
# 从项目根目录测试
cd /path/to/your/project
./kd-fe-deploy/scripts/full-deploy.sh --help

# 从 kd-fe-deploy 目录测试
cd kd-fe-deploy
./scripts/full-deploy.sh --help
```

## 5. 实际使用测试

### 5.1 创建测试项目

创建一个最小测试项目来验证 skill：

```bash
# 创建测试目录
mkdir test-deploy-project
cd test-deploy-project

# 创建 package.json
cat > package.json << EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "deploy-path": "/tmp/test-deploy"
}
EOF

# 创建简单的构建脚本
cat > package.json << EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "deploy-path": "/tmp/test-deploy",
  "scripts": {
    "build": "mkdir -p dist && echo 'test' > dist/index.html"
  }
}
EOF
```

### 5.2 测试 AI 响应

在 Cursor 中询问：

```
"我有一个前端项目，package.json 中已经配置了 deploy-path，如何部署？"
```

**预期响应应该包括**：
- ✅ 提到使用 `full-deploy.sh` 脚本
- ✅ 说明需要 `~/.kd-deploy/config.json` 配置
- ✅ 提供具体的执行命令
- ✅ 说明环境切换选项

## 6. 常见问题排查

### 问题 1: Skill 未被识别

**症状**: AI 没有自动应用 skill

**排查步骤**:
1. 检查 skill 位置是否正确（项目级应在 `.cursor/skills/` 或项目根目录）
2. 验证 `description` 是否包含足够的触发词
3. 重启 Cursor 让 skill 重新加载
4. 检查 `name` 字段是否符合规范（小写、连字符）

### 问题 2: 路径引用错误

**症状**: AI 引用的脚本路径不存在

**排查步骤**:
1. 验证所有脚本路径使用正斜杠 `/`（不是反斜杠 `\`）
2. 检查路径是否相对于项目根目录
3. 确认脚本文件确实存在

### 问题 3: 描述不够具体

**症状**: Skill 被误触发或不被触发

**解决方案**:
- 在 description 中添加更多特定关键词
- 明确说明 "Use when..." 场景
- 避免过于宽泛的描述

### 问题 4: 内容过长

**症状**: Skill 文件超过 500 行

**解决方案**:
- 将详细文档移到 `README.md` 或 `reference.md`
- 在 SKILL.md 中使用链接引用
- 保持 SKILL.md 简洁，只包含核心指导

## 7. 调试检查清单

使用以下清单系统化验证：

- [ ] SKILL.md 文件存在且格式正确
- [ ] YAML frontmatter 格式正确（name, description）
- [ ] name 字段：小写、连字符、不超过 64 字符
- [ ] description 字段：第三人称、包含触发词、不超过 1024 字符
- [ ] SKILL.md 内容不超过 500 行
- [ ] 所有脚本路径引用正确且文件存在
- [ ] 代码示例格式正确（JSON、bash）
- [ ] 使用正斜杠路径（不是 Windows 反斜杠）
- [ ] 术语使用一致
- [ ] 包含 "When to Use" 或类似的使用场景说明
- [ ] 包含实际可执行的示例

## 8. 性能优化建议

### 8.1 减少 Token 使用

- ✅ 使用链接引用详细文档，而不是内联所有内容
- ✅ 保持示例简洁
- ✅ 移除冗余说明

### 8.2 提高可发现性

- ✅ 在 description 中包含常见同义词
- ✅ 明确列出触发场景
- ✅ 使用领域特定术语

## 9. 验证脚本

创建一个快速验证脚本：

```bash
#!/bin/bash
# validate-skill.sh

SKILL_FILE="kd-fe-deploy/SKILL.md"

echo "=== Skill 验证 ==="

# 检查文件存在
if [ ! -f "$SKILL_FILE" ]; then
    echo "❌ SKILL.md 不存在"
    exit 1
fi
echo "✅ SKILL.md 存在"

# 检查行数
LINES=$(wc -l < "$SKILL_FILE")
if [ "$LINES" -gt 500 ]; then
    echo "⚠️  文件超过 500 行: $LINES"
else
    echo "✅ 行数正常: $LINES"
fi

# 检查 YAML frontmatter
if grep -q "^---$" "$SKILL_FILE"; then
    echo "✅ YAML frontmatter 存在"
else
    echo "❌ 缺少 YAML frontmatter"
fi

# 检查 name 字段
if grep -q "^name: kd-fe-deploy$" "$SKILL_FILE"; then
    echo "✅ name 字段正确"
else
    echo "❌ name 字段格式错误"
fi

# 检查 description 字段
DESC_LEN=$(grep "^description:" "$SKILL_FILE" | cut -d: -f2- | wc -c)
if [ "$DESC_LEN" -gt 1024 ]; then
    echo "⚠️  description 可能过长"
else
    echo "✅ description 长度正常"
fi

# 检查脚本引用
echo ""
echo "=== 脚本引用检查 ==="
for script in $(grep -o "\.\/kd-fe-deploy\/scripts\/[^ ]*" "$SKILL_FILE" | sort -u); do
    if [ -f "$script" ]; then
        echo "✅ $script"
    else
        echo "❌ 缺失: $script"
    fi
done

echo ""
echo "=== 验证完成 ==="
```

保存为 `validate-skill.sh` 并运行：

```bash
chmod +x validate-skill.sh
./validate-skill.sh
```

## 10. 持续改进

调试 skill 是一个迭代过程：

1. **测试** → 在实际场景中使用
2. **观察** → 记录 AI 的响应和行为
3. **调整** → 根据反馈优化 description 和内容
4. **验证** → 再次测试确保改进有效

记住：skill 的目标是让 AI 在正确的时机自动应用正确的知识，而不是包含所有可能的文档。
