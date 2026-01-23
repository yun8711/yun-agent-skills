#!/bin/bash

# 前端部署主脚本
# 协调整个部署流程：构建 -> 连接 -> 上传 -> 部署

set -e  # 遇到错误立即退出

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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
    log "检查部署依赖..."

    local missing_deps=()

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if ! command -v expect &> /dev/null; then
        missing_deps+=("expect")
    fi

    if ! command -v ssh &> /dev/null; then
        missing_deps+=("openssh-client")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "缺少依赖: ${missing_deps[*]}"
    fi

    success "依赖检查完成"
}

# 验证配置
validate_config() {
    local config_file="${SCRIPT_DIR}/../config.json"

    if [[ ! -f "$config_file" ]]; then
        error "配置文件不存在: $config_file"
        echo "请复制 config-template.json 到 config.json 并配置"
        exit 1
    fi

    # 检查必需的配置项
    if ! jq -e '.bastion.host' "$config_file" &>/dev/null; then
        error "堡垒机host配置缺失"
    fi

    if ! jq -e ".projects.\"$PROJECT_NAME\"" "$config_file" &>/dev/null; then
        error "项目 '$PROJECT_NAME' 配置不存在"
    fi

    success "配置验证完成"
}

# 执行构建
do_build() {
    log "步骤1: 执行构建..."

    if ! "$SCRIPT_DIR/build.sh" "$PROJECT_NAME"; then
        error "构建失败"
    fi

    # 获取构建产物
    cd "$PROJECT_ROOT"
    ZIP_FILE=$(ls -t *.zip 2>/dev/null | head -n1)

    if [[ -z "$ZIP_FILE" ]]; then
        error "未找到构建生成的zip文件"
    fi

    success "构建完成，产物: $ZIP_FILE"
}

# 连接服务器
do_connect() {
    log "步骤2: 连接服务器..."

    # 创建expect脚本用于自动化部署流程
    local deploy_script="/tmp/kd-deploy-${PROJECT_NAME}-$$.exp"

    cat > "$deploy_script" << EOF
#!/usr/bin/expect -f
set timeout 300
set zip_file "$ZIP_FILE"
set deploy_path "$DEPLOY_PATH"

# 连接服务器（复用connect-server.sh的逻辑）
spawn "$SCRIPT_DIR/connect-server.sh" "$PROJECT_NAME"

# 等待进入部署目录
expect {
    "成功连接到服务器并进入部署目录" {
        # 连接成功
    }
    timeout {
        send_user "连接服务器超时\n"
        exit 1
    }
}

# 上传文件
send_user "开始上传文件: \$zip_file\n"
send "trz \$zip_file\r"
expect {
    "100%" {
        # 上传完成
    }
    timeout {
        send_user "文件上传超时\n"
        exit 1
    }
}

# 等待几秒确保文件传输完成
sleep 3

# 解压文件
send_user "解压文件...\n"
send "unzip \$zip_file\r"
expect "#"

# 验证解压结果
send "ls -la\r"
expect "#"

# 执行后部署命令
send_user "执行后部署命令...\n"
$(get_post_deploy_commands)

# 清理文件
send_user "清理临时文件...\n"
send "rm -f \$zip_file\r"
expect "#"

send_user "部署完成！\n"
send "exit\r"
EOF

    chmod +x "$deploy_script"
    expect "$deploy_script"

    # 清理临时脚本
    rm -f "$deploy_script"
}

# 获取后部署命令
get_post_deploy_commands() {
    local commands=$(jq -r ".projects.\"$PROJECT_NAME\".post_deploy_commands[] // empty" "${SCRIPT_DIR}/../config.json")

    if [[ -n "$commands" ]]; then
        echo "$commands" | while read -r cmd; do
            echo "send \"$cmd\\r\""
            echo "expect \"#\""
        done
    fi
}

# 备份旧版本
backup_old_version() {
    local backup_enabled=$(jq -r ".projects.\"$PROJECT_NAME\".backup_old_version // false" "${SCRIPT_DIR}/../config.json")

    if [[ "$backup_enabled" == "true" ]]; then
        log "创建备份..."

        local timestamp=$(date '+%Y%m%d_%H%M%S')
        local backup_dir="${DEPLOY_PATH%/}/backup_$timestamp"

        local expect_script=$(cat << EOF
#!/usr/bin/expect -f
spawn "$SCRIPT_DIR/connect-server.sh" "$PROJECT_NAME"
expect "成功连接到服务器并进入部署目录"
send "mkdir -p $backup_dir && cp -r . $backup_dir/ 2>/dev/null || true\r"
expect "#"
send "echo 'Backup created: $backup_dir'\r"
expect "#"
send "exit\r"
EOF
)
        expect -c "$expect_script"
        success "备份完成: $backup_dir"
    fi
}

# 健康检查
health_check() {
    local health_url=$(jq -r ".advanced.health_check_url // empty" "${SCRIPT_DIR}/../config.json")

    if [[ -n "$health_url" ]]; then
        log "执行健康检查: $health_url"

        local timeout=$(jq -r ".advanced.health_check_timeout // 30" "${SCRIPT_DIR}/../config.json")

        if command -v curl &> /dev/null; then
            if curl -f -s --max-time "$timeout" "$health_url" > /dev/null; then
                success "健康检查通过"
            else
                error "健康检查失败"
            fi
        else
            log "curl不可用，跳过健康检查"
        fi
    fi
}

# 发送通知
send_notification() {
    local enable_notify=$(jq -r ".notifications.enable // false" "${SCRIPT_DIR}/../config.json")

    if [[ "$enable_notify" == "true" ]]; then
        log "发送部署通知..."

        # 这里可以集成各种通知方式：邮件、Slack、微信等
        # 示例：发送邮件通知
        local notify_type=$(jq -r ".notifications.type // \"email\"" "${SCRIPT_DIR}/../config.json")

        case "$notify_type" in
            "email")
                # send_email_notification
                log "邮件通知功能待实现"
                ;;
            "slack")
                # send_slack_notification
                log "Slack通知功能待实现"
                ;;
            *)
                log "未知通知类型: $notify_type"
                ;;
        esac
    fi
}

# 清理本地临时文件
cleanup() {
    local cleanup_enabled=$(jq -r ".deployment.cleanup_temp_files // true" "${SCRIPT_DIR}/../config.json")

    if [[ "$cleanup_enabled" == "true" ]]; then
        log "清理本地临时文件..."

        # 清理旧的zip文件（保留最新的几个）
        cd "$PROJECT_ROOT"
        ls -t *.zip 2>/dev/null | tail -n +6 | xargs -r rm -f

        # 清理日志文件
        find /tmp -name "kd-deploy-*" -type f -mtime +1 -delete 2>/dev/null || true

        success "清理完成"
    fi
}

# 显示部署摘要
show_summary() {
    log "========== 部署摘要 =========="
    echo "项目: $PROJECT_NAME"
    echo "构建产物: $ZIP_FILE"
    echo "部署目录: $DEPLOY_PATH"
    echo "堡垒机: $BASTION_HOST:$BASTION_PORT"
    echo "目标服务器: $SERVER_PATTERN"
    echo "开始时间: $START_TIME"
    echo "结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "耗时: $SECONDS 秒"
    log "=============================="
}

# 主函数
main() {
    PROJECT_NAME="$1"
    START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ -z "$PROJECT_NAME" ]]; then
        error "请指定项目名称"
        echo "用法: $0 <project_name>"
        echo "示例: $0 rhea"
        exit 1
    fi

    log "开始部署流程 for project: $PROJECT_NAME"

    # 初始化变量
    ZIP_FILE=""
    DEPLOY_PATH=""
    BASTION_HOST=""
    SERVER_PATTERN=""

    check_dependencies
    validate_config

    # 获取配置信息
    DEPLOY_PATH=$(jq -r ".projects.\"$PROJECT_NAME\".deploy_path" "${SCRIPT_DIR}/../config.json")
    SERVER_PATTERN=$(jq -r ".projects.\"$PROJECT_NAME\".server_pattern" "${SCRIPT_DIR}/../config.json")
    BASTION_HOST=$(jq -r ".bastion.host" "${SCRIPT_DIR}/../config.json")

    do_build
    backup_old_version
    do_connect
    health_check
    send_notification
    cleanup
    show_summary

    success "部署流程完成！"
}

# 错误处理
trap 'error "部署过程中发生错误"' ERR

# 参数处理
main "$@"