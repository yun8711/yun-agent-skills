#!/bin/bash

# 配置加载库
# 统一管理本地配置和项目配置的加载与合并

# 加载配置
# 用法: source scripts/lib/config-loader.sh && load_config
load_config() {
    # 本地配置文件，只支持用户目录下的配置 ~/.kd-deploy/config.json
    local user_config_file="${HOME}/.kd-deploy/config.json"
    local project_config="${PROJECT_ROOT}/package.json"
    
    local config_path=""
    if [[ -f "$user_config_file" ]]; then
        config_path="$user_config_file"
    fi

    # 1. 加载本地配置（堡垒机信息、通用账号密码）
    if [[ -n "$config_path" ]]; then
        # 读取通用账号密码
        BASTION_USER=$(jq -r '.user // ""' "$config_path" 2>/dev/null)
        PASSWORD=$(jq -r '.password // ""' "$config_path" 2>/dev/null)
        
        # 如果提供了环境别名，从 env_list 中匹配
        if [[ -n "${ENVIRONMENT:-}" ]]; then
            # 使用 jq 查找匹配 alias 的环境配置
            # alias 字段支持逗号分隔，如 "12,12环境,内网"
            local env_info=$(jq -c ".env_list[] | select(.alias | split(\",\") | contains([\"$ENVIRONMENT\"]))" "$config_path" 2>/dev/null | head -n 1)
            
            if [[ -n "$env_info" ]]; then
                BASTION_HOST=$(echo "$env_info" | jq -r '.host // ""')
                BASTION_PORT=$(echo "$env_info" | jq -r '.port // 22')
            fi
        fi
        
        # 如果没有匹配到环境，或者没有指定环境，尝试读取默认的 bastion 配置（向下兼容）
        if [[ -z "$BASTION_HOST" ]]; then
            BASTION_HOST=$(jq -r '.bastion.host // ""' "$config_path" 2>/dev/null)
            BASTION_PORT=$(jq -r '.bastion.port // 22' "$config_path" 2>/dev/null)
            # 如果 bastion 下有独立的 user/password，则覆盖通用的
            local b_user=$(jq -r '.bastion.user // ""' "$config_path" 2>/dev/null)
            [[ -n "$b_user" ]] && BASTION_USER="$b_user"
            local b_pass=$(jq -r '.bastion.password // ""' "$config_path" 2>/dev/null)
            [[ -n "$b_pass" ]] && PASSWORD="$b_pass"
        fi
    fi

    # 2. 加载项目配置（从package.json）
    if [[ -f "$project_config" ]]; then
        PROJECT_NAME=$(jq -r '.name // ""' "$project_config" 2>/dev/null)
        PROJECT_VERSION=$(jq -r '.version // "1.0.0"' "$project_config" 2>/dev/null)
        
        # 从 package.json 一级属性读取配置
        DEPLOY_PATH=$(jq -r '."deploy-path" // ""' "$project_config" 2>/dev/null)
        
        # 默认配置
        BUILD_COMMAND="npm run build"
        OUTPUT_PATTERN="*.zip"
        SERVER_PATTERN=""
        BACKUP_ENABLED=true

        # 允许通过环境变量覆盖默认值
        BUILD_COMMAND="${BUILD_COMMAND_ENV:-$BUILD_COMMAND}"
    fi

    # 3. 环境变量覆盖（最高优先级）
    BASTION_HOST="${BASTION_HOST_ENV:-$BASTION_HOST}"
    BASTION_PORT="${BASTION_PORT_ENV:-$BASTION_PORT}"
    BASTION_USER="${BASTION_USER_ENV:-$BASTION_USER}"
    PASSWORD="${PASSWORD_ENV:-$PASSWORD}"
    DEPLOY_PATH="${DEPLOY_PATH_ENV:-$DEPLOY_PATH}"
    SERVER_PATTERN="${SERVER_PATTERN_ENV:-$SERVER_PATTERN}"

    # 4. 验证必需配置
    if [[ -z "$BASTION_HOST" ]]; then
        error "堡垒机主机未配置。请在 ~/.kd-deploy/config.json 的 env_list 中配置或指定 BASTION_HOST_ENV"
    fi

    if [[ -z "$BASTION_USER" ]]; then
        error "登录用户未配置。请在 ~/.kd-deploy/config.json 中配置 user 或指定 BASTION_USER_ENV"
    fi

    if [[ -z "$DEPLOY_PATH" ]]; then
        error "部署路径未配置。请检查 package.json 中的 deploy-path 一级属性"
    fi
}

# 获取后部署命令
get_post_deploy_commands() {
    echo ""
}
