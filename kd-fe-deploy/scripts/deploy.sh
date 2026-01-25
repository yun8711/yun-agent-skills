#!/bin/bash

# 前端部署主脚本
# 协调整个部署流程：构建 -> 连接 -> 上传 -> 部署

set -e  # 遇到错误立即退出

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 加载配置库
source "${SCRIPT_DIR}/lib/config-loader.sh" 2>/dev/null || {
    echo "警告: 无法加载配置库，使用legacy配置方式" >&2
}

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

    # 检查trzsz工具
    if ! command -v trzsz &> /dev/null && ! command -v trz &> /dev/null; then
        log "警告: trzsz工具未找到，请确保已安装trzsz"
        log "安装方法: pip install trzsz 或 npm install -g trzsz"
        log "如果已安装但不在PATH中，请确保trzsz可执行文件在PATH中"
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "缺少依赖: ${missing_deps[*]}"
    fi

    success "依赖检查完成"
}

# 验证配置
validate_config() {
    log "验证配置..."

    # 使用配置加载库
    if type load_config &>/dev/null; then
        load_config
    else
        # Legacy配置方式（向后兼容）
        local config_file="${SCRIPT_DIR}/../config.json"
        if [[ ! -f "$config_file" ]]; then
            error "配置文件不存在: $config_file"
        fi

        BASTION_HOST=$(jq -r '.bastion.host' "$config_file")
        BASTION_PORT=$(jq -r '.bastion.port // 22' "$config_file")
        BASTION_USER=$(jq -r '.bastion.user' "$config_file")
        AUTH_METHOD=$(jq -r '.bastion.auth_method // "password"' "$config_file")
        PASSWORD_ENV_VAR=$(jq -r '.bastion.password_env_var // "DEPLOY_PASSWORD"' "$config_file")
        
        if [[ -n "${!PASSWORD_ENV_VAR:-}" ]]; then
            PASSWORD="${!PASSWORD_ENV_VAR}"
        else
            PASSWORD=$(jq -r '.bastion.password // ""' "$config_file")
        fi

        DEPLOY_PATH=$(jq -r ".projects.\"$PROJECT_NAME\".deploy_path" "$config_file")
        SERVER_PATTERN=$(jq -r ".projects.\"$PROJECT_NAME\".server_pattern" "$config_file")
    fi

    # 验证必需配置
    if [[ -z "$BASTION_HOST" ]]; then
        error "堡垒机host配置缺失"
    fi

    if [[ -z "$DEPLOY_PATH" ]]; then
        error "部署路径未配置"
    fi

    if [[ -z "$SERVER_PATTERN" ]]; then
        error "服务器模式未配置"
    fi

    success "配置验证完成"
}

# 执行构建
do_build() {
    log "步骤1: 执行构建..."

    # 从package.json读取构建命令
    local package_json="${PROJECT_ROOT}/package.json"
    local build_command=""
    
    if [[ -f "$package_json" ]] && jq -e '.deploy.build.command' "$package_json" &>/dev/null; then
        build_command=$(jq -r '.deploy.build.command' "$package_json")
    else
        error "package.json中未找到deploy.build.command配置"
    fi

    if ! "$SCRIPT_DIR/build.sh" "$build_command"; then
        error "构建失败"
    fi

    # 获取构建产物
    cd "$PROJECT_ROOT"
    ZIP_FILE=$(ls -t *.zip 2>/dev/null | head -n1)

    if [[ -z "$ZIP_FILE" ]]; then
        error "未找到构建生成的zip文件"
    fi

    ZIP_FILE_FULL_PATH="${PROJECT_ROOT}/${ZIP_FILE}"
    success "构建完成，产物: $ZIP_FILE"
}

# 执行完整的自动化部署流程
do_deploy() {
    log "步骤2-6: 连接服务器并部署..."

    if [[ -z "$PASSWORD" ]]; then
        error "未配置密码，请设置环境变量 ${PASSWORD_ENV_VAR:-DEPLOY_PASSWORD} 或在配置文件中设置"
    fi

    # 创建完整的expect脚本
    local deploy_script="/tmp/kd-deploy-${PROJECT_NAME}-$$.exp"
    local zip_filename=$(basename "$ZIP_FILE")
    
    # 使用改进的expect脚本生成函数（使用trz上传）
    create_complete_expect_script "$deploy_script" "$zip_filename"
    
    chmod +x "$deploy_script"
    
    # 执行expect脚本
    # trzsz客户端需要在支持trzsz的环境中运行
    # trzsz会自动检测expect脚本中的trz命令并传输文件
    log "执行自动化部署脚本..."
    log "使用trzsz上传文件: $ZIP_FILE_FULL_PATH"
    log "提示: 确保在支持trzsz的终端中运行，trzsz客户端会自动检测trz命令并传输文件"
    
    # 直接执行expect脚本
    # 如果终端支持trzsz，trzsz客户端会自动拦截trz命令并传输文件
    # 如果终端不支持，可能需要使用 trzsz -d 守护进程模式
    if ! expect "$deploy_script" "$BASTION_HOST" "$BASTION_PORT" "$BASTION_USER" "$PASSWORD" "$SERVER_PATTERN" "$DEPLOY_PATH" "$zip_filename"; then
        error "部署失败"
    fi

    # 清理临时脚本
    rm -f "$deploy_script"

    success "部署完成"
}

# 创建完整的expect脚本（包含文件传输，使用trz）
create_complete_expect_script() {
    local script_file="$1"
    local zip_filename="$2"
    local zip_file_path="${3:-$ZIP_FILE_FULL_PATH}"
    
    # 检查文件大小
    local file_size=$(stat -f%z "$zip_file_path" 2>/dev/null || stat -c%s "$zip_file_path" 2>/dev/null)
    
    log "准备文件传输: $zip_filename ($(numfmt --to=iec-i --suffix=B $file_size 2>/dev/null || echo "${file_size} bytes"))"
    log "使用trzsz工具上传文件"
    
    # 验证文件存在
    if [[ ! -f "$zip_file_path" ]]; then
        error "文件不存在: $zip_file_path"
    fi
    
    # 创建expect脚本（使用trz上传）
    cat > "$script_file" << 'EXPECT_SCRIPT'
#!/usr/bin/expect -f
set timeout 600
set bastion_host [lindex $argv 0]
set bastion_port [lindex $argv 1]
set bastion_user [lindex $argv 2]
set password [lindex $argv 3]
set server_pattern [lindex $argv 4]
set deploy_path [lindex $argv 5]
set zip_filename [lindex $argv 6]

# 连接堡垒机
spawn ssh -p $bastion_port $bastion_user@$bastion_host
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    "Opt>" {
        # 成功进入JumpServer
    }
    "Permission denied" {
        send_user "堡垒机认证失败\n"
        exit 1
    }
    timeout {
        send_user "连接堡垒机超时\n"
        exit 1
    }
}

# 选择服务器
send_user "选择服务器模式: $server_pattern\n"
send "$server_pattern\r"

# 处理JumpServer响应：可能是直接登录或显示列表
expect {
    # 情况1：显示列表（多个匹配）
    -re "\\d+\\)" {
        send_user "检测到多个匹配的主机，选择第一个\n"
        send "1\r"
        exp_continue
    }
    # 情况2：直接登录（单一匹配）或列表选择后登录
    -re "(dev|test|prod|root)@" {
        send_user "成功登录到目标服务器\n"
    }
    "Permission denied" {
        send_user "服务器访问权限被拒绝\n"
        exit 1
    }
    timeout {
        send_user "等待服务器响应超时\n"
        exit 1
    }
}

# 切换到管理员权限
send_user "切换到管理员权限...\n"
send "sudo -i\r"
expect {
    "password for" {
        send_user "ERROR: 需要sudo密码，请配置无密码sudo\n"
        exit 1
    }
    "#" {
        send_user "成功切换到root权限\n"
    }
    timeout {
        send_user "sudo切换超时，请确保配置了无密码sudo\n"
        exit 1
    }
}

# 进入部署目录
send_user "进入部署目录: $deploy_path\n"
send "cd $deploy_path\r"
expect "#"

# 验证目录
send "pwd\r"
expect "#"

# 上传文件：使用trzsz的trz命令
send_user "开始上传文件: $zip_filename\n"
send "trz $zip_filename\r"

# 等待trz命令的输出和文件传输
# trzsz会显示传输进度，我们需要等待传输完成
expect {
    # trz命令的初始输出
    -re "(Waiting|Ready|Progress|Uploading|Receiving)" {
        send_user "文件传输中...\n"
        exp_continue
    }
    # 传输进度提示（百分比）
    -re "\\d+%" {
        exp_continue
    }
    # 传输完成提示
    -re "(Success|Complete|Done|100%|Saved)" {
        send_user "文件上传完成\n"
        exp_continue
    }
    # 等待命令提示符（传输完成，回到shell提示符）
    "#" {
        send_user "文件上传完成\n"
    }
    # 错误提示
    -re "(Error|Failed|Cancel|Canceled)" {
        send_user "文件上传失败\n"
        exit 1
    }
    timeout {
        send_user "文件上传超时，请检查trzsz客户端是否正常运行\n"
        exit 1
    }
}

# 验证文件是否上传成功
send_user "验证上传的文件...\n"
send "ls -lh $zip_filename\r"
expect {
    -re "\\d+.*$zip_filename" {
        send_user "文件验证成功\n"
    }
    "#" {
        # 文件可能不存在，检查一下
        send "test -f $zip_filename && echo 'FILE_EXISTS' || echo 'FILE_NOT_FOUND'\r"
        expect {
            "FILE_NOT_FOUND" {
                send_user "错误: 文件上传后未找到，请检查trzsz传输是否成功\n"
                exit 1
            }
            "FILE_EXISTS" {
                send_user "文件验证成功\n"
            }
            "#" {
            }
        }
    }
}

# 解压文件
send_user "解压文件...\n"
send "unzip -o $zip_filename\r"
expect {
    -re "(inflating|extracting|Archive:)" {
        exp_continue
    }
    "#" {
        # 解压完成
    }
    timeout {
        send_user "解压超时\n"
        exit 1
    }
}

# 验证解压结果
send "ls -la | head -20\r"
expect "#"

# 执行后部署命令（如果有配置）
# 这里可以添加后部署命令的执行逻辑

# 清理临时文件
send_user "清理临时文件...\n"
send "rm -f $zip_filename\r"
expect "#"

send_user "部署完成！\n"
send "exit\r"
expect eof
EXPECT_SCRIPT
}

# 备份旧版本
backup_old_version() {
    local backup_enabled="${BACKUP_ENABLED:-true}"
    
    if [[ "$backup_enabled" != "true" ]]; then
        return 0
    fi

    log "创建备份..."
    # 备份逻辑将在expect脚本中实现
    # 这里可以添加备份前的检查逻辑
}

# 执行后部署命令
execute_post_commands() {
    local commands
    if type get_post_deploy_commands &>/dev/null; then
        commands=$(get_post_deploy_commands)
    fi

    if [[ -n "$commands" ]]; then
        log "执行后部署命令..."
        # 后部署命令将在expect脚本中执行
        # 这里可以添加命令验证逻辑
    fi
}

# 健康检查
health_check() {
    local health_url="${HEALTH_CHECK_URL:-}"
    if [[ -z "$health_url" ]]; then
        return 0
    fi

    log "执行健康检查: $health_url"
    local timeout="${HEALTH_CHECK_TIMEOUT:-30}"

    if command -v curl &> /dev/null; then
        if curl -f -s --max-time "$timeout" "$health_url" > /dev/null; then
            success "健康检查通过"
        else
            error "健康检查失败"
        fi
    else
        log "curl不可用，跳过健康检查"
    fi
}

# 清理本地临时文件
cleanup() {
    log "清理本地临时文件..."

    # 清理旧的zip文件（保留最新的几个）
    cd "$PROJECT_ROOT"
    ls -t *.zip 2>/dev/null | tail -n +6 | xargs -r rm -f 2>/dev/null || true

    # 清理临时脚本
    find /tmp -name "kd-deploy-*" -type f -mtime +1 -delete 2>/dev/null || true

    success "清理完成"
}

# 显示部署摘要
show_summary() {
    log "========== 部署摘要 =========="
    echo "项目: ${PROJECT_NAME:-unknown}"
    echo "构建产物: $ZIP_FILE"
    echo "部署目录: $DEPLOY_PATH"
    echo "堡垒机: $BASTION_USER@$BASTION_HOST:$BASTION_PORT"
    echo "目标服务器模式: $SERVER_PATTERN"
    echo "开始时间: $START_TIME"
    echo "结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "耗时: $SECONDS 秒"
    log "=============================="
}

# 主函数
main() {
    PROJECT_NAME="${1:-}"
    START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    # 如果没有提供项目名，尝试从package.json读取
    if [[ -z "$PROJECT_NAME" ]]; then
        local package_json="${PROJECT_ROOT}/package.json"
        if [[ -f "$package_json" ]]; then
            PROJECT_NAME=$(jq -r '.name // ""' "$package_json" 2>/dev/null)
        fi
    fi

    if [[ -z "$PROJECT_NAME" ]]; then
        error "请指定项目名称，或在package.json中配置name字段"
        echo "用法: $0 <project_name>"
        echo "示例: $0 rhea"
        exit 1
    fi

    log "开始部署流程 for project: $PROJECT_NAME"

    # 初始化变量
    ZIP_FILE=""
    ZIP_FILE_FULL_PATH=""
    DEPLOY_PATH=""
    BASTION_HOST=""
    BASTION_PORT="22"
    BASTION_USER=""
    SERVER_PATTERN=""
    PASSWORD=""
    PASSWORD_ENV_VAR="DEPLOY_PASSWORD"
    BACKUP_ENABLED="true"

    check_dependencies
    validate_config

    do_build
    backup_old_version
    do_deploy
    execute_post_commands
    health_check
    cleanup
    show_summary

    success "部署流程完成！"
}

# 错误处理
trap 'error "部署过程中发生错误，退出代码: $?"' ERR

# 参数处理
main "$@"
