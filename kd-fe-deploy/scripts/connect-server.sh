#!/bin/bash

# 堡垒机连接和服务器选择脚本
# 自动化SSH连接堡垒机并处理JumpServer交互

set -e  # 遇到错误立即退出

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

# 检查expect是否可用
check_expect() {
    if ! command -v expect &> /dev/null; then
        error "expect 命令未找到，请安装expect工具: apt-get install expect 或 brew install expect"
    fi
}

# 验证配置
validate_config() {
    local project_name="$1"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "配置文件不存在: $CONFIG_FILE"
    fi

    # 检查堡垒机配置
    if ! jq -e '.bastion' "$CONFIG_FILE" &>/dev/null; then
        error "堡垒机配置不存在"
    fi

    # 检查项目配置
    if ! jq -e ".projects.\"$project_name\"" "$CONFIG_FILE" &>/dev/null; then
        error "项目 '$project_name' 配置不存在"
    fi
}

# 获取堡垒机配置
get_bastion_config() {
    BASTION_HOST=$(jq -r '.bastion.host' "$CONFIG_FILE")
    BASTION_PORT=$(jq -r '.bastion.port // 22' "$CONFIG_FILE")
    BASTION_USER=$(jq -r '.bastion.user' "$CONFIG_FILE")
    AUTH_METHOD=$(jq -r '.bastion.auth_method // "password"' "$CONFIG_FILE")
    KEY_FILE=$(jq -r '.bastion.key_file // "~/.ssh/id_rsa"' "$CONFIG_FILE")

    # 获取密码（优先从环境变量）
    PASSWORD=$(jq -r '.bastion.password // ""' "$CONFIG_FILE")
    PASSWORD_ENV_VAR=$(jq -r '.bastion.password_env_var // "DEPLOY_PASSWORD"' "$CONFIG_FILE")

    if [[ -z "$PASSWORD" ]] && [[ -n "${!PASSWORD_ENV_VAR:-}" ]]; then
        PASSWORD="${!PASSWORD_ENV_VAR}"
    fi

    TIMEOUT=$(jq -r '.bastion.connection_timeout // 30' "$CONFIG_FILE")
}

# 获取项目配置
get_project_config() {
    local project_name="$1"

    SERVER_PATTERN=$(jq -r ".projects.\"$project_name\".server_pattern" "$CONFIG_FILE")
    DEPLOY_PATH=$(jq -r ".projects.\"$project_name\".deploy_path" "$CONFIG_FILE")

    if [[ "$SERVER_PATTERN" == "null" ]]; then
        error "项目 '$project_name' 未配置server_pattern"
    fi

    if [[ "$DEPLOY_PATH" == "null" ]]; then
        error "项目 '$project_name' 未配置deploy_path"
    fi
}

# SSH密钥认证连接
connect_with_key() {
    local expect_script=$(cat << 'EOF'
#!/usr/bin/expect -f
set timeout [lindex $argv 0]
set bastion_host [lindex $argv 1]
set bastion_port [lindex $argv 2]
set bastion_user [lindex $argv 3]
set key_file [lindex $argv 4]
set server_pattern [lindex $argv 5]
set deploy_path [lindex $argv 6]

# 连接堡垒机
spawn ssh -p $bastion_port -i $key_file $bastion_user@$bastion_host
expect {
    "password:" {
        send_user "SSH密钥认证失败，可能是密钥文件不存在或权限问题\n"
        exit 1
    }
    "Enter passphrase for key" {
        send_user "SSH密钥需要密码，请先解锁密钥\n"
        exit 1
    }
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    "Opt>" {
        # 成功连接到JumpServer
    }
    timeout {
        send_user "连接堡垒机超时\n"
        exit 1
    }
}

# 选择服务器
send "$server_pattern\r"

# 等待登录到目标服务器
expect {
    "dev@" {
        # 成功登录到开发服务器
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
send "sudo -i\r"
expect {
    "password for dev:" {
        send_user "需要sudo密码，请手动输入\n"
        interact
    }
    "#" {
        # 成功切换到root权限
    }
    timeout {
        send_user "sudo切换超时\n"
        exit 1
    }
}

# 进入部署目录
send "cd $deploy_path\r"
expect "#"
send "pwd\r"
expect "#"

send_user "成功连接到服务器并进入部署目录: $deploy_path\n"
interact
EOF
)

    # 执行expect脚本
    expect -c "$expect_script" "$TIMEOUT" "$BASTION_HOST" "$BASTION_PORT" "$BASTION_USER" "$KEY_FILE" "$SERVER_PATTERN" "$DEPLOY_PATH"
}

# 密码认证连接
connect_with_password() {
    if [[ -z "$PASSWORD" ]]; then
        # 尝试从环境变量获取
        PASSWORD="${DEPLOY_PASSWORD:-}"
        if [[ -z "$PASSWORD" ]]; then
            error "未配置密码认证信息，请在配置文件中设置password或设置DEPLOY_PASSWORD环境变量"
        fi
    fi

    local expect_script=$(cat << 'EOF'
#!/usr/bin/expect -f
set timeout [lindex $argv 0]
set bastion_host [lindex $argv 1]
set bastion_port [lindex $argv 2]
set bastion_user [lindex $argv 3]
set password [lindex $argv 4]
set server_pattern [lindex $argv 5]
set deploy_path [lindex $argv 6]

# 连接堡垒机
spawn ssh -p $bastion_port $bastion_user@$bastion_host
expect {
    "password:" {
        send "$password\r"
    }
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    timeout {
        send_user "连接堡垒机超时\n"
        exit 1
    }
}

# 等待JumpServer界面
expect {
    "Opt>" {
        # 成功进入JumpServer
    }
    "Permission denied" {
        send_user "堡垒机认证失败\n"
        exit 1
    }
    timeout {
        send_user "等待JumpServer界面超时\n"
        exit 1
    }
}

# 选择服务器
send "$server_pattern\r"

# 等待登录到目标服务器
expect {
    "dev@" {
        # 成功登录到开发服务器
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
send "sudo -i\r"
expect {
    "password for dev:" {
        send_user "需要sudo密码，请手动输入\n"
        interact
    }
    "#" {
        # 成功切换到root权限
    }
    timeout {
        send_user "sudo切换超时\n"
        exit 1
    }
}

# 进入部署目录
send "cd $deploy_path\r"
expect "#"
send "pwd\r"
expect "#"

send_user "成功连接到服务器并进入部署目录: $deploy_path\n"
interact
EOF
)

    # 执行expect脚本
    expect -c "$expect_script" "$TIMEOUT" "$BASTION_HOST" "$BASTION_PORT" "$BASTION_USER" "$PASSWORD" "$SERVER_PATTERN" "$DEPLOY_PATH"
}

# 测试连接
test_connection() {
    log "测试堡垒机连接..."

    if [[ "$AUTH_METHOD" == "key" ]]; then
        log "使用SSH密钥认证测试连接"
        if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p "$BASTION_PORT" -i "$KEY_FILE" "$BASTION_USER@$BASTION_HOST" "echo 'Connection test successful'" 2>/dev/null; then
            error "SSH密钥连接测试失败"
        fi
    else
        log "使用密码认证测试连接"
        if [[ -z "$PASSWORD" ]]; then
            error "密码认证需要设置密码，请在配置文件中设置password或设置环境变量${PASSWORD_ENV_VAR:-DEPLOY_PASSWORD}"
        fi

        # 尝试使用expect进行密码认证测试
        local test_script=$(cat << EOF
#!/usr/bin/expect -f
set timeout 10
spawn ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p $BASTION_PORT $BASTION_USER@$BASTION_HOST "echo 'Connection test successful'"
expect {
    "password:" {
        send "$PASSWORD\r"
        expect {
            "Connection test successful" {
                exit 0
            }
            timeout {
                send_user "连接测试超时\n"
                exit 1
            }
        }
    }
    "Connection test successful" {
        exit 0
    }
    timeout {
        send_user "连接测试超时\n"
        exit 1
    }
}
EOF
)
        if ! expect -c "$test_script" 2>/dev/null; then
            error "密码认证连接测试失败"
        fi
    fi

    success "连接测试完成"
}

# 主函数
main() {
    local project_name="$1"
    local test_only="${2:-false}"

    if [[ -z "$project_name" ]]; then
        error "请指定项目名称"
    fi

    log "开始连接堡垒机 for project: $project_name"

    check_expect
    validate_config "$project_name"
    get_bastion_config
    get_project_config "$project_name"

    if [[ "$test_only" == "test" ]]; then
        test_connection
        success "连接测试完成"
        exit 0
    fi

    log "堡垒机信息: $BASTION_USER@$BASTION_HOST:$BASTION_PORT"
    log "认证方式: $AUTH_METHOD"
    log "目标服务器模式: $SERVER_PATTERN"
    log "部署目录: $DEPLOY_PATH"

    # 执行连接
    if [[ "$AUTH_METHOD" == "key" ]]; then
        log "使用SSH密钥认证连接..."
        connect_with_key
    else
        log "使用密码认证连接..."
        connect_with_password
    fi
}

# 参数处理
if [[ $# -eq 0 ]]; then
    echo "用法: $0 <project_name> [test]"
    echo "示例:"
    echo "  $0 rhea          # 连接并进入服务器"
    echo "  $0 rhea test     # 仅测试连接"
    exit 1
fi

main "$@"