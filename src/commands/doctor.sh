#!/usr/bin/env bash

# 系统诊断命令

# 运行诊断
devenv_doctor() {
    log_title "DevEnv 系统诊断"

    local checks_passed=0
    local checks_failed=0
    local checks_total=0

    # 检查操作系统
    check_os

    # 检查依赖
    check_dependencies

    # 检查网络
    check_network

    # 检查磁盘空间
    check_disk_space

    # 检查内存
    check_memory

    # 检查已安装组件
    check_installed_components

    # 显示结果
    log_separator
    log_info "诊断完成: 通过 $checks_passed/$checks_total"

    if [ $checks_failed -eq 0 ]; then
        log_success "所有检查通过"
    else
        log_error "发现 $checks_failed 个问题"
        return 1
    fi
}

# 检查操作系统
check_os() {
    log_subtitle "操作系统检查"

    local os
    os=$(get_os)

    if [ "$os" = "unknown" ]; then
        log_error "不支持的操作系统"
        return 1
    fi

    log_kv "操作系统" "$os"
    log_kv "架构" "$(get_arch)"
    log_kv "主机名" "$(hostname)"

    if [ "$os" = "macos" ]; then
        log_kv "版本" "$(sw_vers -productVersion)"
    elif [ "$os" = "linux" ]; then
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            log_kv "发行版" "$NAME $VERSION"
        fi
    fi

    return 0
}

# 检查依赖
check_dependencies() {
    log_subtitle "依赖检查"

    local deps=("curl" "wget" "git" "tar" "gzip")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if command_exists "$dep"; then
            log_success "$dep ✓"
        else
            log_error "$dep ✗"
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warn "缺少依赖: ${missing_deps[*]}"
        return 1
    fi

    return 0
}

# 检查网络
check_network() {
    log_subtitle "网络检查"

    # 检查互联网连接
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        log_success "互联网连接 ✓"
    else
        log_error "互联网连接 ✗"
        return 1
    fi

    # 检查 DNS
    if nslookup google.com >/dev/null 2>&1; then
        log_success "DNS 解析 ✓"
    else
        log_error "DNS 解析 ✗"
        return 1
    fi

    return 0
}

# 检查磁盘空间
check_disk_space() {
    log_subtitle "磁盘空间检查"

    local required_gb=20
    local available_gb

    if [ "$(get_os)" = "macos" ]; then
        available_gb=$(df -g . | awk 'NR==2 {print $4}')
    else
        available_gb=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    fi

    log_kv "可用空间" "${available_gb}GB"
    log_kv "要求空间" "${required_gb}GB"

    if [ "$available_gb" -lt "$required_gb" ]; then
        log_warn "磁盘空间不足"
        return 1
    fi

    log_success "磁盘空间充足 ✓"
    return 0
}

# 检查内存
check_memory() {
    log_subtitle "内存检查"

    local required_gb=8
    local total_gb

    if [ "$(get_os)" = "macos" ]; then
        total_gb=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
    else
        total_gb=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}')
    fi

    log_kv "总内存" "${total_gb}GB"
    log_kv "要求内存" "${required_gb}GB"

    if [ "$total_gb" -lt "$required_gb" ]; then
        log_warn "内存可能不足"
        return 1
    fi

    log_success "内存充足 ✓"
    return 0
}

# 检查已安装组件
check_installed_components() {
    log_subtitle "已安装组件"

    local components=("git" "maven" "java" "python" "node" "docker")

    for component in "${components[@]}"; do
        if check_component "$component"; then
            log_success "$component ✓"
        else
            log_info "$component -"
        fi
    done
}

# 检查组件
check_component() {
    local component="$1"

    case "$component" in
        git)
            command_exists git
            ;;
        maven)
            command_exists mvn
            ;;
        java)
            command_exists java
            ;;
        python)
            command_exists python3
            ;;
        node)
            command_exists node
            ;;
        docker)
            command_exists docker
            ;;
        *)
            return 1
            ;;
    esac
}