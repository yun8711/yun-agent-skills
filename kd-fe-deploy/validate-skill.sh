#!/bin/bash
# validate-skill.sh - 快速验证 kd-fe-deploy skill

SKILL_FILE="kd-fe-deploy/SKILL.md"
ERRORS=0
WARNINGS=0

echo "=========================================="
echo "  kd-fe-deploy Skill 验证工具"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

# 1. 检查文件存在
echo "1. 文件结构检查"
echo "----------------"
if [ ! -f "$SKILL_FILE" ]; then
    check_fail "SKILL.md 不存在: $SKILL_FILE"
    exit 1
fi
check_pass "SKILL.md 存在"

# 2. 检查行数
LINES=$(wc -l < "$SKILL_FILE" 2>/dev/null || echo "0")
if [ "$LINES" -gt 500 ]; then
    check_warn "文件超过 500 行: $LINES (建议拆分内容)"
else
    check_pass "行数正常: $LINES"
fi

# 3. 检查 YAML frontmatter
echo ""
echo "2. YAML Frontmatter 检查"
echo "----------------"
if ! grep -q "^---$" "$SKILL_FILE"; then
    check_fail "缺少 YAML frontmatter 开始标记 (---)"
else
    check_pass "YAML frontmatter 开始标记存在"
fi

# 检查 name 字段
if grep -q "^name: kd-fe-deploy$" "$SKILL_FILE"; then
    check_pass "name 字段格式正确"
else
    NAME_LINE=$(grep "^name:" "$SKILL_FILE" | head -1)
    if [ -z "$NAME_LINE" ]; then
        check_fail "缺少 name 字段"
    else
        check_fail "name 字段格式错误: $NAME_LINE"
    fi
fi

# 检查 name 字段格式（小写、连字符）
NAME_VALUE=$(grep "^name:" "$SKILL_FILE" | head -1 | sed 's/name: //' | tr -d ' ')
if [[ "$NAME_VALUE" =~ ^[a-z0-9-]+$ ]]; then
    check_pass "name 字段符合规范（小写、数字、连字符）"
else
    check_fail "name 字段包含非法字符: $NAME_VALUE"
fi

# 检查 name 长度
NAME_LEN=${#NAME_VALUE}
if [ "$NAME_LEN" -le 64 ]; then
    check_pass "name 长度正常: $NAME_LEN 字符"
else
    check_fail "name 超过 64 字符: $NAME_LEN"
fi

# 检查 description 字段
DESC_LINE=$(grep "^description:" "$SKILL_FILE" | head -1)
if [ -z "$DESC_LINE" ]; then
    check_fail "缺少 description 字段"
else
    check_pass "description 字段存在"
    DESC_TEXT=$(echo "$DESC_LINE" | sed 's/description: //')
    DESC_LEN=${#DESC_TEXT}
    
    if [ "$DESC_LEN" -gt 1024 ]; then
        check_fail "description 超过 1024 字符: $DESC_LEN"
    else
        check_pass "description 长度正常: $DESC_LEN 字符"
    fi
    
    # 检查是否包含触发词
    TRIGGER_WORDS=("deploy" "Use when" "frontend" "package.json")
    HAS_TRIGGERS=false
    for word in "${TRIGGER_WORDS[@]}"; do
        if echo "$DESC_TEXT" | grep -qi "$word"; then
            HAS_TRIGGERS=true
            break
        fi
    done
    
    if [ "$HAS_TRIGGERS" = true ]; then
        check_pass "description 包含触发关键词"
    else
        check_warn "description 可能缺少明确的触发词（建议添加 'Use when...'）"
    fi
    
    # 检查是否使用第三人称
    if echo "$DESC_TEXT" | grep -qiE "^(I|You|We) "; then
        check_warn "description 可能使用了第一/二人称（建议使用第三人称）"
    else
        check_pass "description 使用第三人称"
    fi
fi

# 4. 检查脚本引用
echo ""
echo "3. 脚本引用检查"
echo "----------------"
SCRIPT_REFS=$(grep -o "\.\/kd-fe-deploy\/scripts\/[^ \`]*" "$SKILL_FILE" 2>/dev/null | sort -u || true)
if [ -z "$SCRIPT_REFS" ]; then
    check_warn "未找到脚本引用"
else
    for script in $SCRIPT_REFS; do
        # 移除可能的引号
        script=$(echo "$script" | tr -d '"' | tr -d "'")
        if [ -f "$script" ]; then
            check_pass "脚本存在: $script"
        else
            check_fail "脚本不存在: $script"
        fi
    done
fi

# 5. 检查路径格式
echo ""
echo "4. 路径格式检查"
echo "----------------"
if grep -q "\\\\" "$SKILL_FILE"; then
    check_fail "发现 Windows 反斜杠路径（应使用正斜杠）"
else
    check_pass "路径使用正斜杠格式"
fi

# 6. 检查代码块格式
echo ""
echo "5. 代码块格式检查"
echo "----------------"
CODE_BLOCKS=$(grep -c "^\`\`\`" "$SKILL_FILE" || echo "0")
if [ "$CODE_BLOCKS" -gt 0 ]; then
    check_pass "包含代码示例: $CODE_BLOCKS 个代码块"
else
    check_warn "未找到代码示例（建议添加使用示例）"
fi

# 7. 检查使用场景说明
echo ""
echo "6. 内容完整性检查"
echo "----------------"
if grep -qiE "(When to Use|使用场景|适用场景)" "$SKILL_FILE"; then
    check_pass "包含使用场景说明"
else
    check_warn "缺少明确的使用场景说明（建议添加 'When to Use' 部分）"
fi

# 8. 检查示例
if grep -qiE "(Example|示例|example)" "$SKILL_FILE"; then
    check_pass "包含示例说明"
else
    check_warn "缺少示例（建议添加实际使用示例）"
fi

# 总结
echo ""
echo "=========================================="
echo "  验证结果"
echo "=========================================="
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✅ 所有检查通过！${NC}"
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  发现 $WARNINGS 个警告，但无错误${NC}"
    exit 0
else
    echo -e "${RED}❌ 发现 $ERRORS 个错误，$WARNINGS 个警告${NC}"
    echo ""
    echo "请修复错误后重新验证"
    exit 1
fi
