#!/usr/bin/env bash

# 工具函数模块
# 提供各种工具函数

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查是否以 root 运行
is_root() {
    [ "$EUID" -eq 0 ]
}

# 检查操作系统
get_os() {
    local os
    case "$(uname -s)" in
        Linux*)     os="linux" ;;
        Darwin*)    os="macos" ;;
        CYGWIN*)    os="windows" ;;
        MINGW*)     os="windows" ;;
        *)          os="unknown" ;;
    esac
    echo "$os"
}

# 检查架构
get_arch() {
    local arch
    case "$(uname -m)" in
        x86_64)     arch="amd64" ;;
        aarch64)    arch="arm64" ;;
        arm64)      arch="arm64" ;;
        armv7l)     arch="arm" ;;
        *)          arch="unknown" ;;
    esac
    echo "$arch"
}

# 获取平台信息
get_platform() {
    echo "$(get_os)-$(get_arch)"
}

# 检查是否支持颜色输出
supports_colors() {
    [ -t 1 ] && [ -n "$TERM" ] && [ "$TERM" != "dumb" ]
}

# 检查是否为交互式终端
is_interactive() {
    [ -t 0 ]
}

# 检查是否在 CI 环境中
is_ci() {
    [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$TRAVIS" ] || [ -n "$CIRCLECI" ]
}

# 下载文件
download_file() {
    local url="$1"
    local output="$2"

    if command_exists curl; then
        curl -L -o "$output" "$url"
    elif command_exists wget; then
        wget -O "$output" "$url"
    else
        log_error "需要 curl 或 wget 来下载文件"
        return 1
    fi
}

# 下载并验证文件
download_and_verify() {
    local url="$1"
    local output="$2"
    local checksum_url="$3"
    local algorithm="$4"

    # 下载文件
    download_file "$url" "$output"

    if [ -n "$checksum_url" ]; then
        # 下载校验和
        local checksum_file="/tmp/$(basename "$output").checksum"
        download_file "$checksum_url" "$checksum_file"

        # 计算校验和
        local actual_checksum
        case "$algorithm" in
            md5)    actual_checksum=$(md5sum "$output" | cut -d' ' -f1) ;;
            sha1)   actual_checksum=$(sha1sum "$output" | cut -d' ' -f1) ;;
            sha256) actual_checksum=$(sha256sum "$output" | cut -d' ' -f1) ;;
            sha512) actual_checksum=$(sha512sum "$output" | cut -d' ' -f1) ;;
            *)      log_error "不支持的校验算法: $algorithm"; return 1 ;;
        esac

        # 获取期望的校验和
        local expected_checksum
        if [ "$algorithm" = "sha256" ]; then
            expected_checksum=$(grep "$(basename "$output")" "$checksum_file" | cut -d' ' -f1)
        else
            expected_checksum=$(cat "$checksum_file")
        fi

        # 验证校验和
        if [ "$actual_checksum" != "$expected_checksum" ]; then
            log_error "校验和验证失败"
            log_error "期望: $expected_checksum"
            log_error "实际: $actual_checksum"
            return 1
        fi

        log_success "文件校验通过"
    fi

    return 0
}

# 解压文件
extract_file() {
    local file="$1"
    local output_dir="$2"

    mkdir -p "$output_dir"

    case "$file" in
        *.tar.gz|*.tgz)
            tar -xzf "$file" -C "$output_dir" --strip-components=1
            ;;
        *.tar.bz2|*.tbz2)
            tar -xjf "$file" -C "$output_dir" --strip-components=1
            ;;
        *.tar.xz|*.txz)
            tar -xJf "$file" -C "$output_dir" --strip-components=1
            ;;
        *.zip)
            unzip -q "$file" -d "$output_dir"
            ;;
        *)
            log_error "不支持的文件格式: $file"
            return 1
            ;;
    esac
}

# 创建符号链接
create_symlink() {
    local source="$1"
    local target="$2"
    local backup="${3:-true}"

    if [ -L "$target" ]; then
        local current_target
        current_target=$(readlink "$target")
        if [ "$current_target" = "$source" ]; then
            log_debug "符号链接已存在: $target -> $source"
            return 0
        fi
    fi

    if [ -e "$target" ] && [ "$backup" = "true" ]; then
        local backup_file="$target.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$backup_file"
        log_debug "已备份: $target -> $backup_file"
    fi

    ln -sf "$source" "$target"
    log_debug "创建符号链接: $target -> $source"
}

# 添加到 PATH
add_to_path() {
    local dir="$1"

    if [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
        log_debug "添加到 PATH: $dir"
    fi
}

# 检查端口是否被占用
is_port_available() {
    local port="$1"

    if command_exists lsof; then
        ! lsof -i ":$port" >/dev/null 2>&1
    elif command_exists netstat; then
        ! netstat -tulpn 2>/dev/null | grep -q ":$port"
    elif command_exists ss; then
        ! ss -tulpn 2>/dev/null | grep -q ":$port"
    else
        # 如果无法检查，假设端口可用
        true
    fi
}

# 等待端口可用
wait_for_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-30}"

    local start_time
    start_time=$(date +%s)

    while true; do
        if command_exists nc; then
            if nc -z "$host" "$port" 2>/dev/null; then
                return 0
            fi
        elif command_exists telnet; then
            if echo "quit" | telnet "$host" "$port" 2>&1 | grep -q "Connected"; then
                return 0
            fi
        fi

        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -ge "$timeout" ]; then
            return 1
        fi

        sleep 1
    done
}

# 生成随机密码
generate_password() {
    local length="${1:-16}"

    tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom 2>/dev/null | head -c "$length" || \
    openssl rand -base64 "$length" 2>/dev/null | tr -d '\n' | head -c "$length" || \
    date +%s | sha256sum | base64 | head -c "$length"
}

# 确认操作
confirm() {
    local message="${1:-是否继续?}"
    local default="${2:-y}"

    if [ "$default" = "y" ]; then
        read -rp "$message [Y/n]: " response
        response=${response:-y}
    else
        read -rp "$message [y/N]: " response
        response=${response:-n}
    fi

    [[ "$response" =~ ^[Yy]$ ]]
}

# 安全删除
safe_remove() {
    local path="$1"
    local force="${2:-false}"

    if [ ! -e "$path" ]; then
        return 0
    fi

    if [ "$force" = "false" ]; then
        if ! confirm "确认删除 $path?"; then
            return 1
        fi
    fi

    rm -rf "$path"
    log_debug "已删除: $path"
}

# 备份文件
backup_file() {
    local file="$1"
    local backup_dir="${2:-$HOME/.devenv/backups}"

    if [ ! -f "$file" ] && [ ! -d "$file" ]; then
        log_debug "文件不存在，跳过备份: $file"
        return
    fi

    mkdir -p "$backup_dir"
    local backup_path="$backup_dir/$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"

    cp -r "$file" "$backup_path"
    log_debug "已备份: $file -> $backup_path"

    echo "$backup_path"
}

# 恢复备份
restore_backup() {
    local pattern="$1"
    local backup_dir="${2:-$HOME/.devenv/backups}"
    local target="${3:-.}"

    local latest_backup
    latest_backup=$(ls -t "$backup_dir/$pattern" 2>/dev/null | head -1)

    if [ -z "$latest_backup" ]; then
        log_error "未找到备份文件: $backup_dir/$pattern"
        return 1
    fi

    cp -r "$latest_backup" "$target"
    log_debug "已恢复: $latest_backup -> $target"

    echo "$latest_backup"
}