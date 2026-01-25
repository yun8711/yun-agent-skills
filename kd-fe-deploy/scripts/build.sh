#!/bin/bash

# 前端构建脚本
# 用于自动化执行构建命令并压缩 dist 目录

set -e  # 遇到错误立即退出

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 加载配置库
source "${SCRIPT_DIR}/lib/config-loader.sh" 2>/dev/null || true

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

    if ! command -v node &> /dev/null; then
        error "Node.js 未找到，请确保已安装 Node.js"
    fi

    # 检查压缩工具：优先检查 zip，Windows 环境下检查 powershell.exe
    if ! command -v zip &> /dev/null; then
        if ! command -v powershell.exe &> /dev/null; then
            error "未找到压缩工具 (zip 或 PowerShell)。请安装 zip 工具或确保在 Windows 环境下可以使用 PowerShell。"
        fi
    fi

    log "依赖检查完成"
}

# 压缩函数：支持跨平台
compress_dist() {
    local source_dir="dist"
    local target_zip="$1"
    
    log "正在压缩 $source_dir 目录..."
    
    if command -v zip &> /dev/null; then
        # Linux/macOS/WSL 使用标准 zip
        (cd "$source_dir" && zip -rq "../$target_zip" .)
    elif command -v powershell.exe &> /dev/null; then
        # Windows 环境使用 PowerShell 原生命令
        # 注意：Compress-Archive 需要绝对路径或相对于当前目录的路径
        local abs_source_dir="$(cd "$source_dir" && pwd)"
        local abs_target_zip="$(pwd)/$target_zip"
        
        # 将路径转换为 Windows 格式（如果是 Git Bash/MSYS2）
        if command -v cygpath &> /dev/null; then
            abs_source_dir=$(cygpath -w "$abs_source_dir")
            abs_target_zip=$(cygpath -w "$abs_target_zip")
        fi
        
        powershell.exe -Command "Compress-Archive -Path '$abs_source_dir\*' -DestinationPath '$abs_target_zip' -Force"
    else
        error "无法执行压缩：未找到支持的压缩工具"
    fi
}

# 显示构建信息
show_build_info() {
    local zip_file="$1"

    log "构建产物信息:"
    echo "  文件: $zip_file"
    
    if [[ -f "$zip_file" ]]; then
        local size=$(ls -lh "$zip_file" | awk '{print $5}')
        echo "  大小: $size"
    fi
}

# 主函数
main() {
    local build_cmd="${1:-$BUILD_COMMAND}"

    log "开始构建流程"
    check_dependencies

    cd "$PROJECT_ROOT"

    if [[ ! -f "package.json" ]]; then
        error "未找到 package.json 文件"
    fi

    # 1. 执行构建命令
    log "执行构建命令: $build_cmd"
    if ! eval "$build_cmd"; then
        error "构建失败"
    fi

    # 2. 检查 dist 目录
    if [[ ! -d "dist" ]]; then
        error "未找到 dist 目录"
    fi

    # 3. 压缩 dist 目录
    local project_name=$(jq -r '.name // "project"' package.json)
    local zip_file="${project_name}.zip"
    rm -f "$zip_file"
    
    compress_dist "$zip_file"

    # 4. 验证生成的 zip 文件
    if [[ ! -f "$zip_file" ]]; then
        error "压缩失败，未生成 $zip_file"
    fi

    success "构建并压缩完成: $zip_file"
    show_build_info "$zip_file"
    
    echo "$zip_file"
}

main "$@"
