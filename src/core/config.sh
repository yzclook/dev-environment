#!/usr/bin/env bash

# 配置管理模块
# 管理 DevEnv 的配置

# 配置目录
CONFIG_DIR="$HOME/.devenv"
DEFAULT_CONFIG_DIR="$SCRIPT_DIR/config/defaults"
TEMPLATE_CONFIG_DIR="$SCRIPT_DIR/config/templates"
PROFILE_CONFIG_DIR="$SCRIPT_DIR/config/profiles"

# 配置文件
CONFIG_FILE="$CONFIG_DIR/config.yaml"
STATE_FILE="$CONFIG_DIR/state.yaml"
CACHE_FILE="$CONFIG_DIR/cache.yaml"

# 加载配置
load_config() {
    local config_file="${1:-$CONFIG_FILE}"

    if [ ! -f "$config_file" ]; then
        log_debug "配置文件不存在: $config_file"
        return 1
    fi

    # 检查 yq 是否存在
    if ! command_exists yq; then
        log_error "需要 yq 来解析 YAML 配置"
        return 1
    fi

    # 加载配置到环境变量
    while IFS='=' read -r key value; do
        if [[ -n "$key" && "$key" != "#"* ]]; then
            export "DEVENV_${key^^}"="$value"
        fi
    done < <(yq eval 'to_entries | map("\(.key)=\(.value | tostring)") | .[]' "$config_file")

    log_debug "已加载配置: $config_file"
}

# 保存配置
save_config() {
    local config_file="${1:-$CONFIG_FILE}"
    local key="$2"
    local value="$3"

    mkdir -p "$(dirname "$config_file")"

    if ! command_exists yq; then
        log_error "需要 yq 来写入 YAML 配置"
        return 1
    fi

    if [ -n "$key" ] && [ -n "$value" ]; then
        yq eval ".$key = \"$value\"" -i "$config_file"
        log_debug "已更新配置: $key=$value"
    fi
}

# 获取配置值
get_config() {
    local key="$1"
    local default="$2"

    local value
    value=$(yq eval ".$key" "$CONFIG_FILE" 2>/dev/null)

    if [ "$value" = "null" ] || [ -z "$value" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# 初始化配置
init_config() {
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
        cp "$DEFAULT_CONFIG_DIR/config.yaml" "$CONFIG_FILE"
        log_debug "已创建默认配置: $CONFIG_FILE"
    fi

    if [ ! -f "$STATE_FILE" ]; then
        cp "$DEFAULT_CONFIG_DIR/state.yaml" "$STATE_FILE"
        log_debug "已创建状态文件: $STATE_FILE"
    fi

    # 加载配置
    load_config
}

# 显示配置
show_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "配置文件不存在"
        return 1
    fi

    echo "配置文件: $CONFIG_FILE"
    echo "══════════════════════════════════════════════════════════════"

    if command_exists yq; then
        yq eval '.' "$CONFIG_FILE"
    else
        cat "$CONFIG_FILE"
    fi
}

# 编辑配置
edit_config() {
    local editor="${EDITOR:-vim}"

    if [ ! -f "$CONFIG_FILE" ]; then
        init_config
    fi

    "$editor" "$CONFIG_FILE"

    # 重新加载配置
    load_config
}

# 重置配置
reset_config() {
    if confirm "确认重置配置?"; then
        backup_file "$CONFIG_FILE"
        rm -f "$CONFIG_FILE"
        init_config
        log_success "配置已重置"
    fi
}

# 导出配置
export_config() {
    local output_file="${1:-devenv-config-$(date +%Y%m%d_%H%M%S).yaml}"

    cp "$CONFIG_FILE" "$output_file"
    log_success "配置已导出到: $output_file"
}

# 导入配置
import_config() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi

    backup_file "$CONFIG_FILE"
    cp "$config_file" "$CONFIG_FILE"

    # 重新加载配置
    load_config

    log_success "配置已导入"
}

# 使用配置模板
use_template() {
    local template_name="$1"
    local template_file="$TEMPLATE_CONFIG_DIR/$template_name.yaml"

    if [ ! -f "$template_file" ]; then
        log_error "模板不存在: $template_name"
        echo "可用模板:"
        ls -1 "$TEMPLATE_CONFIG_DIR"/*.yaml 2>/dev/null | xargs -n1 basename | sed 's/\.yaml$//'
        return 1
    fi

    backup_file "$CONFIG_FILE"
    cp "$template_file" "$CONFIG_FILE"

    # 重新加载配置
    load_config

    log_success "已应用模板: $template_name"
}

# 使用配置方案
use_profile() {
    local profile_name="$1"
    local profile_file="$PROFILE_CONFIG_DIR/$profile_name.yaml"

    if [ ! -f "$profile_file" ]; then
        log_error "配置方案不存在: $profile_name"
        echo "可用配置方案:"
        ls -1 "$PROFILE_CONFIG_DIR"/*.yaml 2>/dev/null | xargs -n1 basename | sed 's/\.yaml$//'
        return 1
    fi

    backup_file "$CONFIG_FILE"
    cp "$profile_file" "$CONFIG_FILE"

    # 重新加载配置
    load_config

    log_success "已应用配置方案: $profile_name"
}

# 更新状态
update_state() {
    local key="$1"
    local value="$2"

    if ! command_exists yq; then
        return
    fi

    yq eval ".$key = \"$value\"" -i "$STATE_FILE"
    log_debug "已更新状态: $key=$value"
}

# 获取状态
get_state() {
    local key="$1"
    local default="$2"

    if [ ! -f "$STATE_FILE" ] || ! command_exists yq; then
        echo "$default"
        return
    fi

    local value
    value=$(yq eval ".$key" "$STATE_FILE" 2>/dev/null)

    if [ "$value" = "null" ] || [ -z "$value" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}