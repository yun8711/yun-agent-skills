#!/bin/bash

# 堡垒机密码设置脚本
# 帮助用户安全地设置堡垒机密码环境变量

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# 显示帮助信息
show_help() {
    echo "堡垒机密码设置工具"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -i, --interactive    交互式设置密码"
    echo "  -c, --check          检查当前密码设置"
    echo "  -r, --reset          重置密码环境变量"
    echo "  -h, --help           显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 --interactive     # 交互式设置密码"
    echo "  $0 --check          # 检查密码设置状态"
    echo "  $0 --reset          # 清除密码设置"
}

# 检查当前密码设置
check_password() {
    log "检查当前密码设置..."

    # 检查环境变量
    if [[ -n "${DEPLOY_PASSWORD:-}" ]]; then
        log "✅ 环境变量 DEPLOY_PASSWORD 已设置"
    else
        log "❌ 环境变量 DEPLOY_PASSWORD 未设置"
    fi

    # 检查配置文件
    if [[ -f "$CONFIG_FILE" ]]; then
        local auth_method=$(jq -r '.bastion.auth_method // "password"' "$CONFIG_FILE" 2>/dev/null || echo "password")
        local password_env_var=$(jq -r '.bastion.password_env_var // "DEPLOY_PASSWORD"' "$CONFIG_FILE" 2>/dev/null || echo "DEPLOY_PASSWORD")
        local password=$(jq -r '.bastion.password // ""' "$CONFIG_FILE" 2>/dev/null || echo "")

        log "配置文件认证方式: $auth_method"
        log "密码环境变量名: $password_env_var"

        if [[ -n "$password" ]]; then
            log "⚠️  配置文件中设置了明文密码（不推荐）"
        fi

        if [[ "$auth_method" == "password" ]]; then
            if [[ -n "${!password_env_var:-}" ]] || [[ -n "$password" ]]; then
                success "密码认证配置正确"
            else
                error "密码认证需要设置密码，请运行: $0 --interactive"
            fi
        else
            log "⚠️  认证方式不是密码认证: $auth_method"
        fi
    else
        log "❌ 配置文件不存在: $CONFIG_FILE"
    fi
}

# 交互式设置密码
setup_password_interactive() {
    log "开始交互式密码设置..."

    # 检查配置文件
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "配置文件不存在，请先创建配置文件"
    fi

    echo ""
    echo "堡垒机密码设置向导"
    echo "=================="
    echo ""

    # 确认认证方式
    local current_auth=$(jq -r '.bastion.auth_method // "password"' "$CONFIG_FILE" 2>/dev/null || echo "password")
    if [[ "$current_auth" != "password" ]]; then
        echo "当前认证方式: $current_auth"
        read -p "是否更改为密码认证? (y/N): " change_auth
        if [[ "${change_auth,,}" == "y" ]] || [[ "${change_auth,,}" == "yes" ]]; then
            # 更新认证方式
            jq '.bastion.auth_method = "password"' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            log "已将认证方式更改为密码认证"
        fi
    fi

    # 获取堡垒机信息
    local bastion_host=$(jq -r '.bastion.host // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
    local bastion_user=$(jq -r '.bastion.user // ""' "$CONFIG_FILE" 2>/dev/null || echo "")

    if [[ -n "$bastion_host" ]] && [[ -n "$bastion_user" ]]; then
        echo "堡垒机信息: $bastion_user@$bastion_host"
    fi

    echo ""
    echo "请选择密码设置方式:"
    echo "1. 设置环境变量 (推荐)"
    echo "2. 写入配置文件 (不推荐)"
    echo ""

    local choice=""
    while [[ -z "$choice" ]] || [[ ! "$choice" =~ ^[12]$ ]]; do
        read -p "请选择 (1或2): " choice
    done

    if [[ "$choice" == "1" ]]; then
        # 环境变量方式
        echo ""
        echo "环境变量设置说明:"
        echo "- 将在当前shell会话中设置 DEPLOY_PASSWORD"
        echo "- 建议将此命令添加到你的shell配置文件 (~/.bashrc 或 ~/.zshrc)"
        echo ""

        # 隐藏密码输入
        local password=""
        local confirm=""
        while true; do
            read -s -p "请输入堡垒机密码: " password
            echo ""
            read -s -p "请再次输入密码确认: " confirm
            echo ""

            if [[ "$password" != "$confirm" ]]; then
                echo "❌ 两次输入的密码不一致，请重新输入"
                echo ""
            elif [[ -z "$password" ]]; then
                echo "❌ 密码不能为空"
                echo ""
            else
                break
            fi
        done

        # 设置环境变量
        export DEPLOY_PASSWORD="$password"

        echo ""
        echo "✅ 密码已设置到环境变量 DEPLOY_PASSWORD"
        echo ""
        echo "为了永久保存，请将以下命令添加到你的shell配置文件:"
        echo "  echo 'export DEPLOY_PASSWORD=\"your_password\"' >> ~/.bashrc  # 或 ~/.zshrc"
        echo ""
        echo "注意: 请妥善保管你的shell配置文件，不要将其提交到版本控制"

    else
        # 配置文件方式
        echo ""
        echo "⚠️  警告: 将密码明文存储在配置文件中存在安全风险！"
        read -p "确定要继续吗? (y/N): " confirm

        if [[ "${confirm,,}" != "y" ]] && [[ "${confirm,,}" != "yes" ]]; then
            echo "已取消操作"
            exit 0
        fi

        read -s -p "请输入堡垒机密码: " password
        echo ""

        # 更新配置文件
        jq --arg pwd "$password" '.bastion.password = $pwd' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

        echo ""
        echo "✅ 密码已保存到配置文件"
        echo "⚠️  请确保配置文件不会被提交到版本控制系统"
    fi

    # 测试连接
    echo ""
    read -p "是否现在测试连接? (Y/n): " test_connect
    if [[ "${test_connect,,}" != "n" ]] && [[ "${test_connect,,}" != "no" ]]; then
        echo ""
        log "开始连接测试..."
        "$SCRIPT_DIR/connect-server.sh" rhea test
    fi

    success "密码设置完成！"
}

# 重置密码设置
reset_password() {
    log "重置密码设置..."

    # 清除环境变量
    unset DEPLOY_PASSWORD

    # 清除配置文件中的密码
    if [[ -f "$CONFIG_FILE" ]]; then
        jq 'del(.bastion.password)' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE" || true
    fi

    success "密码设置已重置"
}

# 主函数
main() {
    case "${1:-}" in
        "-i"|"--interactive")
            setup_password_interactive
            ;;
        "-c"|"--check")
            check_password
            ;;
        "-r"|"--reset")
            reset_password
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