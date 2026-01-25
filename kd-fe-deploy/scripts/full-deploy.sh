#!/bin/bash

# 完整部署流程脚本
# 包含构建、部署、验证的完整流程

set -e

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

# 显示帮助信息
show_help() {
    echo "前端自动化部署工具"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -e, --env ENV      指定环境 (dev/test/prod)"
    echo "  -b, --build-only   仅执行构建"
    echo "  -d, --deploy-only  仅执行部署"
    echo "  -t, --test         测试模式"
    echo "  -v, --verbose      详细输出"
    echo "  -h, --help         显示帮助"
    echo ""
    echo "配置:"
    echo "  本地配置: ~/.kd-deploy/config.json (堡垒机等敏感信息)"
    echo "  项目配置: package.json 中的 deploy 字段"
    echo ""
    echo "示例:"
    echo "  $0                        # 完整部署（读取package.json配置）"
    echo "  $0 --env prod             # 部署到生产环境"
    echo "  $0 --build-only           # 仅构建"
    echo "  $0 --deploy-only          # 仅部署"
    echo "  $0 --test                 # 测试模式"
}

# 解析命令行参数
parse_args() {
    ENVIRONMENT=""
    BUILD_ONLY=false
    DEPLOY_ONLY=false
    TEST_MODE=false
    VERBOSE=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -b|--build-only)
                BUILD_ONLY=true
                shift
                ;;
            -d|--deploy-only)
                DEPLOY_ONLY=true
                shift
                ;;
            -t|--test)
                TEST_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "未知参数: $1"
                ;;
        esac
    done
}

# 读取项目配置
load_project_config() {
    local package_json="${PROJECT_ROOT}/package.json"

    if [[ ! -f "$package_json" ]]; then
        error "未找到package.json文件，请确保在项目根目录运行"
    fi

    # 检查是否有deploy配置
    if ! jq -e '.deploy' "$package_json" &>/dev/null; then
        error "package.json中未找到deploy配置"
    fi

    # 读取项目基本信息
    PROJECT_NAME=$(jq -r '.name // "unknown-project"' "$package_json")
    PROJECT_VERSION=$(jq -r '.version // "1.0.0"' "$package_json")

    # 读取构建配置
    BUILD_COMMAND=$(jq -r '.deploy.build.command // "yk zip-dist -b build"' "$package_json")
    OUTPUT_PATTERN=$(jq -r '.deploy.build.output_pattern // "*.zip"' "$package_json")

    # 读取服务器配置
    SERVER_PATTERN=$(jq -r '.deploy.server.pattern // "12.168"' "$package_json")

    # 读取目标配置
    DEPLOY_PATH=$(jq -r '.deploy.target.path // ""' "$package_json")
    BACKUP_ENABLED=$(jq -r '.deploy.target.backup // true' "$package_json")

    # 读取环境特定配置
    if [[ -n "$ENVIRONMENT" ]] && jq -e ".deploy.environments.\"$ENVIRONMENT\"" "$package_json" &>/dev/null; then
        local env_pattern=$(jq -r ".deploy.environments.\"$ENVIRONMENT\".server_pattern // \"$SERVER_PATTERN\"" "$package_json")
        SERVER_PATTERN="$env_pattern"
    fi

    # 验证必需配置
    if [[ -z "$DEPLOY_PATH" ]]; then
        error "deploy.target.path 未配置"
    fi

    success "项目配置加载完成: $PROJECT_NAME v$PROJECT_VERSION"
}

# 设置环境变量
setup_environment() {
    if [[ "$VERBOSE" == "true" ]]; then
        set -x
    fi

    if [[ "$TEST_MODE" == "true" ]]; then
        log "运行在测试模式下"
        export DRY_RUN=true
    fi

    # 设置默认环境
    if [[ -z "$ENVIRONMENT" ]]; then
        ENVIRONMENT="dev"
    fi

    log "部署环境: $ENVIRONMENT"
}

# 验证环境
validate_environment() {
    log "验证部署环境..."

    # 检查本地配置文件
    local config_file="${HOME}/.kd-deploy/config.json"
    if [[ ! -f "$config_file" ]]; then
        error "本地配置文件不存在: $config_file"
        echo ""
        echo "请运行以下命令创建本地配置:"
        echo "  mkdir -p ~/.kd-deploy"
        echo "  cp kd-fe-deploy/config-template-local.json ~/.kd-deploy/config.json"
        echo "  vim ~/.kd-deploy/config.json"
        exit 1
    fi

    # 验证配置
    if ! "$SCRIPT_DIR/validate-config.sh" --skip-network; then
        error "配置验证失败"
    fi

    success "环境验证完成"
}

# 执行构建
do_build() {
    if [[ "$DEPLOY_ONLY" == "true" ]]; then
        log "跳过构建阶段 (--deploy-only)"
        return 0
    fi

    log "开始构建阶段..."

    # 使用从package.json中读取的构建命令
    if ! "$SCRIPT_DIR/build.sh" "$BUILD_COMMAND"; then
        error "构建失败"
    fi

    success "构建阶段完成"
}

# 执行部署
do_deploy() {
    if [[ "$BUILD_ONLY" == "true" ]]; then
        log "跳过部署阶段 (--build-only)"
        return 0
    fi

    log "开始部署阶段..."

    if ! "$SCRIPT_DIR/deploy.sh" "$PROJECT_NAME"; then
        error "部署失败"
    fi

    success "部署阶段完成"
}

# 执行测试
do_test() {
    if [[ "$TEST_MODE" != "true" ]]; then
        return 0
    fi

    log "开始测试阶段..."

    # 这里可以添加各种测试
    # - 连接测试
    # - 部署验证
    # - 健康检查

    log "运行连接测试..."
    if ! "$SCRIPT_DIR/connect-server.sh" "$PROJECT_NAME" test; then
        error "连接测试失败"
    fi

    success "测试阶段完成"
}

# 生成部署报告
generate_report() {
    local start_time="$1"
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local duration=$((SECONDS))

    echo ""
    echo "=========================================="
    echo "部署完成报告"
    echo "=========================================="
    echo "项目名称: $PROJECT_NAME"
    echo "部署环境: $ENVIRONMENT"
    echo "开始时间: $start_time"
    echo "结束时间: $end_time"
    echo "总耗时: ${duration}秒"

    if [[ "$TEST_MODE" == "true" ]]; then
        echo "运行模式: 测试模式"
    else
        echo "运行模式: 生产模式"
    fi

    if [[ "$BUILD_ONLY" == "true" ]]; then
        echo "执行阶段: 仅构建"
    elif [[ "$DEPLOY_ONLY" == "true" ]]; then
        echo "执行阶段: 仅部署"
    else
        echo "执行阶段: 完整部署"
    fi

    echo "=========================================="
}

# 主函数
main() {
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')

    parse_args "$@"
    setup_environment
    load_project_config
    validate_environment

    log "开始完整部署流程 for project: $PROJECT_NAME"

    do_build
    do_deploy
    do_test

    generate_report "$start_time"

    success "完整部署流程执行完毕！"

    # 显示后续操作提示
    echo ""
    echo "后续操作提示:"
    echo "1. 检查应用是否正常运行"
    echo "2. 验证功能是否正常"
    echo "3. 如有问题，可以执行回滚操作"
    echo ""
    echo "常用命令:"
    echo "  # 查看部署日志"
    echo "  tail -f /tmp/kd-deploy.log"
    echo ""
    echo "  # 检查应用状态"
    echo "  curl http://your-app/health"
}

# 错误处理
trap 'error "部署过程中发生错误，退出代码: $?"' ERR

# 执行主函数
main "$@"