#!/bin/bash

# 本地配置初始化脚本
# 帮助用户创建和配置本地堡垒机等敏感信息

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/../config-template-local.json"
LOCAL_CONFIG_DIR="${HOME}/.kd-deploy"
LOCAL_CONFIG="${LOCAL_CONFIG_DIR}/config.json"

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

# 显示帮助信息
show_help() {
    echo "本地配置初始化工具"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -i, --interactive    交互式配置"
    echo "  -c, --check          检查当前配置"
    echo "  -e, --edit           编辑现有配置"
    echo "  -h, --help           显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 --interactive     # 交互式配置"
    echo "  $0 --check          # 检查配置状态"
    echo "  $0 --edit           # 编辑现有配置"
}

# 检查配置状态
check_config() {
    log "检查本地配置状态..."

    if [[ ! -d "$LOCAL_CONFIG_DIR" ]]; then
        log "本地配置目录不存在: $LOCAL_CONFIG_DIR"
        return 1
    fi

    if [[ ! -f "$LOCAL_CONFIG" ]]; then
        log "配置文件不存在: $LOCAL_CONFIG"
        return 1
    fi

    # 验证JSON语法
    if ! jq empty "$LOCAL_CONFIG" 2>/dev/null; then
        log "配置文件JSON语法错误"
        return 1
    fi

    # 检查必需配置
    if ! jq -e '.bastion' "$LOCAL_CONFIG" &>/dev/null; then
        log "缺少bastion配置"
        return 1
    fi

    local host=$(jq -r '.bastion.host // ""' "$LOCAL_CONFIG")
    local user=$(jq -r '.bastion.user // ""' "$LOCAL_CONFIG")
    local auth_method=$(jq -r '.bastion.auth_method // ""' "$LOCAL_CONFIG")

    log "堡垒机主机: $host"
    log "堡垒机用户: $user"
    log "认证方式: $auth_method"

    # 检查密码设置
    if [[ "$auth_method" == "password" ]]; then
        local password_env_var=$(jq -r '.bastion.password_env_var // "DEPLOY_PASSWORD"' "$LOCAL_CONFIG")
        if [[ -n "${!password_env_var:-}" ]]; then
            log "环境变量 $password_env_var 已设置"
        else
            log "警告: 环境变量 $password_env_var 未设置"
            echo "请运行: export $password_env_var='your_password'"
        fi
    fi

    success "本地配置检查完成"
}

# 创建配置目录
create_config_dir() {
    if [[ ! -d "$LOCAL_CONFIG_DIR" ]]; then
        log "创建本地配置目录: $LOCAL_CONFIG_DIR"
        mkdir -p "$LOCAL_CONFIG_DIR"
    fi
}

# 初始化配置文件
init_config() {
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        error "配置文件模板不存在: $TEMPLATE_FILE"
    fi

    log "从模板创建配置文件..."
    cp "$TEMPLATE_FILE" "$LOCAL_CONFIG"

    success "配置文件已创建: $LOCAL_CONFIG"
}

# 交互式配置
interactive_config() {
    log "开始交互式配置..."

    create_config_dir

    if [[ ! -f "$LOCAL_CONFIG" ]]; then
        init_config
    fi

    echo ""
    echo "堡垒机配置向导"
    echo "=============="
    echo ""

    # 读取当前配置
    local current_host=$(jq -r '.bastion.host // "192.168.12.100"' "$LOCAL_CONFIG")
    local current_port=$(jq -r '.bastion.port // 2222' "$LOCAL_CONFIG")
    local current_user=$(jq -r '.bastion.user // "liuyun"' "$LOCAL_CONFIG")

    echo "当前配置:"
    echo "  主机: $current_host"
    echo "  端口: $current_port"
    echo "  用户: $current_user"
    echo ""

    # 配置堡垒机主机
    read -p "堡垒机主机地址 [$current_host]: " bastion_host
    bastion_host="${bastion_host:-$current_host}"

    # 配置堡垒机端口
    read -p "堡垒机SSH端口 [$current_port]: " bastion_port
    bastion_port="${bastion_port:-$current_port}"

    # 配置堡垒机用户
    read -p "堡垒机用户名 [$current_user]: " bastion_user
    bastion_user="${bastion_user:-$current_user}"

    # 配置密码环境变量名
    local current_env_var=$(jq -r '.bastion.password_env_var // "DEPLOY_PASSWORD"' "$LOCAL_CONFIG")
    read -p "密码环境变量名 [$current_env_var]: " password_env_var
    password_env_var="${password_env_var:-$current_env_var}"

    # 更新配置文件
    jq --arg host "$bastion_host" \
       --arg port "$bastion_port" \
       --arg user "$bastion_user" \
       --arg env_var "$password_env_var" \
       '.bastion.host = $host | .bastion.port = ($port | tonumber) | .bastion.user = $user | .bastion.password_env_var = $env_var' \
       "$LOCAL_CONFIG" > "${LOCAL_CONFIG}.tmp" && mv "${LOCAL_CONFIG}.tmp" "$LOCAL_CONFIG"

    echo ""
    log "配置已保存到: $LOCAL_CONFIG"

    # 检查密码设置
    echo ""
    echo "密码设置检查:"
    if [[ -n "${!password_env_var:-}" ]]; then
        echo "环境变量 $password_env_var 已设置"
    else
        echo "警告: 环境变量 $password_env_var 未设置"
        echo ""
        echo "请运行以下命令设置密码:"
        echo "  export $password_env_var='your_actual_password'"
        echo ""
        echo "建议将此命令添加到 ~/.bashrc 或 ~/.zshrc 中:"
        echo "  echo 'export $password_env_var=\"your_password\"' >> ~/.bashrc"
    fi

    success "本地配置完成"
}

# 编辑现有配置
edit_config() {
    if [[ ! -f "$LOCAL_CONFIG" ]]; then
        error "配置文件不存在，请先运行: $0 --interactive"
    fi

    log "打开配置文件进行编辑: $LOCAL_CONFIG"

    if command -v code &> /dev/null; then
        code "$LOCAL_CONFIG"
    elif command -v vim &> /dev/null; then
        vim "$LOCAL_CONFIG"
    elif command -v nano &> /dev/null; then
        nano "$LOCAL_CONFIG"
    else
        echo "请手动编辑文件: $LOCAL_CONFIG"
        echo "编辑完成后，请运行: $0 --check"
    fi
}

# 主函数
main() {
    case "${1:-}" in
        "-i"|"--interactive")
            interactive_config
            ;;
        "-c"|"--check")
            check_config || exit 1
            ;;
        "-e"|"--edit")
            edit_config
            ;;
        "-h"|"--help"|"")
            show_help
            ;;
        *)
            error "未知选项: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"