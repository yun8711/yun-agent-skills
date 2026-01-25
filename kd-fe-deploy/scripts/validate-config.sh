#!/bin/bash

# 配置验证脚本
# 验证配置文件和部署环境

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOCAL_CONFIG="${HOME}/.kd-deploy/config.json"
PACKAGE_JSON="${PROJECT_ROOT}/package.json"

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

warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >&2
}

# 检查本地配置
check_local_config() {
    log "检查本地配置 (~/.kd-deploy/config.json)..."

    if [[ ! -f "$LOCAL_CONFIG" ]]; then
        error "本地配置文件不存在: $LOCAL_CONFIG"
        echo ""
        echo "请运行以下命令创建本地配置:"
        echo "  mkdir -p ~/.kd-deploy"
        echo "  cp kd-fe-deploy/config-template-local.json ~/.kd-deploy/config.json"
        echo "  vim ~/.kd-deploy/config.json"
        return 1
    fi

    # 验证JSON语法
    if ! jq empty "$LOCAL_CONFIG" 2>/dev/null; then
        error "本地配置文件JSON语法错误"
        return 1
    fi

    # 检查必需字段
    local required_fields=("host" "port" "user" "auth_method")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".bastion.$field" "$LOCAL_CONFIG" &>/dev/null; then
            error "堡垒机配置缺少必需字段: $field"
            return 1
        fi
    done

    # 验证主机格式
    local host=$(jq -r '.bastion.host' "$LOCAL_CONFIG")
    if [[ ! "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ ! "$host" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        warning "堡垒机主机格式可能不正确: $host"
    fi

    # 验证端口
    local port=$(jq -r '.bastion.port' "$LOCAL_CONFIG")
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        error "堡垒机端口无效: $port"
        return 1
    fi

    # 验证认证方式
    local auth_method=$(jq -r '.bastion.auth_method' "$LOCAL_CONFIG")
    if [[ "$auth_method" != "password" ]]; then
        warning "认证方式应该是password: $auth_method"
    fi

    # 检查密码设置
    local password_env_var=$(jq -r '.bastion.password_env_var // "DEPLOY_PASSWORD"' "$LOCAL_CONFIG")
    if [[ -z "${!password_env_var:-}" ]]; then
        warning "环境变量 $password_env_var 未设置，请运行: export $password_env_var='your_password'"
    else
        log "环境变量 $password_env_var 已设置"
    fi

    success "本地配置验证通过"
}

# 检查项目配置
check_project_config() {
    log "检查项目配置 (package.json)..."

    if [[ ! -f "$PACKAGE_JSON" ]]; then
        error "package.json不存在: $PACKAGE_JSON"
        return 1
    fi

    # 验证JSON语法
    if ! jq empty "$PACKAGE_JSON" 2>/dev/null; then
        error "package.json JSON语法错误"
        return 1
    fi

    # 检查deploy配置
    if ! jq -e '.deploy' "$PACKAGE_JSON" &>/dev/null; then
        error "package.json中缺少deploy配置"
        echo ""
        echo "请在package.json中添加deploy字段，参考:"
        echo "  kd-fe-deploy/examples/package.json-deploy-config.json"
        return 1
    fi

    # 检查必需的deploy字段
    local project_name=$(jq -r '.name // "unknown"' "$PACKAGE_JSON")
    local deploy_path=$(jq -r '.deploy.target.path // ""' "$PACKAGE_JSON")
    local build_command=$(jq -r '.deploy.build.command // ""' "$PACKAGE_JSON")

    log "项目名称: $project_name"

    if [[ -z "$deploy_path" ]]; then
        warning "deploy.target.path 未配置"
    else
        log "部署路径: $deploy_path"
    fi

    if [[ -z "$build_command" ]]; then
        warning "deploy.build.command 未配置"
    else
        log "构建命令: $build_command"
    fi

    success "项目配置验证通过"
}

# 检查系统依赖
check_system_dependencies() {
    log "检查系统依赖..."

    local missing_deps=()
    local optional_deps=()

    # 必需依赖
    local required_deps=("jq" "expect" "ssh" "scp")
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    # 可选依赖
    local optional_list=("curl" "wget" "rsync" "zip" "unzip")
    for dep in "${optional_list[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            optional_deps+=("$dep")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "缺少必需依赖: ${missing_deps[*]}"
    fi

    if [[ ${#optional_deps[@]} -gt 0 ]]; then
        warning "缺少可选依赖: ${optional_deps[*]} (某些功能可能受限)"
    fi

    success "系统依赖检查完成"
}

# 检查网络连接
check_network_connectivity() {
    log "检查网络连接..."

    local bastion_host=$(jq -r '.bastion.host' "$CONFIG_FILE")
    local bastion_port=$(jq -r '.bastion.port // 22' "$CONFIG_FILE")

    if command -v nc &> /dev/null; then
        if nc -z -w5 "$bastion_host" "$bastion_port" 2>/dev/null; then
            success "堡垒机网络连接正常"
        else
            warning "无法连接到堡垒机: $bastion_host:$bastion_port"
        fi
    elif command -v telnet &> /dev/null; then
        if timeout 5 telnet "$bastion_host" "$bastion_port" </dev/null &>/dev/null; then
            success "堡垒机网络连接正常"
        else
            warning "无法连接到堡垒机: $bastion_host:$bastion_port"
        fi
    else
        log "无合适的网络检查工具，跳过网络连接测试"
    fi
}

# 生成配置报告
generate_report() {
    log "生成配置验证报告..."

    echo "=========================================="
    echo "前端部署自动化配置验证报告"
    echo "=========================================="
    echo "验证时间: $(date)"
    echo "配置文件: $CONFIG_FILE"
    echo ""

    echo "堡垒机配置:"
    jq -r '.bastion | "  主机: \(.host):\(.port)\n  用户: \(.user)\n  认证: \(.auth_method)"' "$CONFIG_FILE"
    echo ""

    echo "项目配置:"
    jq -r '.projects | keys[]' "$CONFIG_FILE" | while read -r project; do
        echo "  $project:"
        jq -r ".projects.\"$project\" | \"    部署路径: \(.deploy_path)\n    服务器模式: \(.server_pattern)\"" "$CONFIG_FILE"
    done
    echo ""

    echo "系统信息:"
    echo "  OS: $(uname -s) $(uname -r)"
    echo "  Shell: $SHELL"
    echo "  User: $(whoami)"
    echo ""

    echo "=========================================="
}

# 主函数
main() {
    local skip_network="${1:-false}"

    log "开始配置验证..."

    check_local_config
    check_project_config
    check_system_dependencies

    if [[ "$skip_network" != "true" ]]; then
        check_network_connectivity
    fi

    generate_report

    success "配置验证完成，所有检查通过！"
    echo ""
    echo "接下来可以运行部署命令："
    echo "  ./kd-fe-deploy/scripts/full-deploy.sh"
}

# 参数处理
case "${1:-}" in
    "--skip-network"|"-n")
        main "true"
        ;;
    "--help"|"-h")
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  -n, --skip-network    跳过网络连接检查"
        echo "  -h, --help           显示帮助信息"
        exit 0
        ;;
    *)
        main
        ;;
esac