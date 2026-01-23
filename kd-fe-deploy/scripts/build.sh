#!/bin/bash

# 前端构建脚本
# 用于自动化执行yk zip-dist构建命令

set -e  # 遇到错误立即退出

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.json"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
    exit 1
}

success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"
}

# 检查依赖
check_dependencies() {
    log "检查构建依赖..."

    if ! command -v yk &> /dev/null; then
        error "yk 命令未找到，请确保已安装yk工具"
    fi

    if ! command -v node &> /dev/null; then
        error "Node.js 未找到，请确保已安装Node.js"
    fi

    log "依赖检查完成"
}

# 验证配置
validate_config() {
    local project_name="$1"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "配置文件不存在: $CONFIG_FILE"
    fi

    # 检查项目配置是否存在
    if ! jq -e ".projects.\"$project_name\"" "$CONFIG_FILE" &>/dev/null; then
        error "项目 '$project_name' 在配置文件中未找到"
    fi

    # 获取构建参数
    BUILD_PARAM=$(jq -r ".projects.\"$project_name\".build_param // \"build\"" "$CONFIG_FILE")
    if [[ "$BUILD_PARAM" == "null" ]]; then
        BUILD_PARAM="build"
    fi

    log "项目 '$project_name' 的构建参数: $BUILD_PARAM"
}

# 执行构建
execute_build() {
    local project_name="$1"
    local build_param="$BUILD_PARAM"

    log "开始构建项目: $project_name"
    log "构建参数: $build_param"

    # 切换到项目根目录
    cd "$PROJECT_ROOT"

    # 检查是否存在package.json
    if [[ ! -f "package.json" ]]; then
        error "未找到package.json文件，请确保在正确的项目目录中"
    fi

    # 清理旧的构建产物
    log "清理旧的构建产物..."
    rm -f *.zip

    # 执行构建
    log "执行构建命令: $build_param"
    if ! eval "$build_param"; then
        error "构建失败"
    fi

    # 查找生成的zip文件
    ZIP_FILE=$(ls -t *.zip 2>/dev/null | head -n1)
    if [[ -z "$ZIP_FILE" ]]; then
        error "未找到构建生成的zip文件"
    fi

    # 验证zip文件
    if [[ ! -f "$ZIP_FILE" ]]; then
        error "zip文件不存在: $ZIP_FILE"
    fi

    local file_size=$(stat -f%z "$ZIP_FILE" 2>/dev/null || stat -c%s "$ZIP_FILE" 2>/dev/null)
    if [[ $file_size -lt 1024 ]]; then
        error "zip文件过小，可能构建失败: ${file_size} bytes"
    fi

    success "构建完成，生成文件: $ZIP_FILE (${file_size} bytes)"
    echo "$ZIP_FILE"
}

# 显示构建信息
show_build_info() {
    local zip_file="$1"

    log "构建产物信息:"
    echo "  文件: $zip_file"
    echo "  大小: $(ls -lh "$zip_file" | awk '{print $5}')"
    echo "  修改时间: $(stat -c%y "$zip_file" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$zip_file")"

    # 显示文件内容（如果有）
    if command -v unzip &> /dev/null; then
        log "zip文件内容预览:"
        unzip -l "$zip_file" | head -20
    fi
}

# 主函数
main() {
    local project_name="$1"

    if [[ -z "$project_name" ]]; then
        error "请指定项目名称"
    fi

    log "开始构建流程 for project: $project_name"

    check_dependencies
    validate_config "$project_name"
    local zip_file=$(execute_build "$project_name")
    show_build_info "$zip_file"

    success "构建流程完成"
    echo "$zip_file"
}

# 参数处理
if [[ $# -eq 0 ]]; then
    echo "用法: $0 <project_name>"
    echo "示例: $0 rhea"
    exit 1
fi

main "$@"