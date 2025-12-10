#!/usr/bin/env bash

# 日志模块
# 提供分级日志输出功能

# 日志级别
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# 默认日志级别
DEVENV_LOG_LEVEL=${DEVENV_LOG_LEVEL:-$LOG_LEVEL_INFO}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取时间戳
_get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 调试日志
log_debug() {
    if [ $DEVENV_LOG_LEVEL -le $LOG_LEVEL_DEBUG ]; then
        printf "${PURPLE}[DEBUG]${NC} [%s] %s\n" "$(_get_timestamp)" "$*" >&2
    fi
}

# 信息日志
log_info() {
    if [ $DEVENV_LOG_LEVEL -le $LOG_LEVEL_INFO ]; then
        printf "${GREEN}[INFO]${NC}  [%s] %s\n" "$(_get_timestamp)" "$*" >&2
    fi
}

# 警告日志
log_warn() {
    if [ $DEVENV_LOG_LEVEL -le $LOG_LEVEL_WARN ]; then
        printf "${YELLOW}[WARN]${NC}  [%s] %s\n" "$(_get_timestamp)" "$*" >&2
    fi
}

# 错误日志
log_error() {
    if [ $DEVENV_LOG_LEVEL -le $LOG_LEVEL_ERROR ]; then
        printf "${RED}[ERROR]${NC} [%s] %s\n" "$(_get_timestamp)" "$*" >&2
    fi
}

# 成功日志
log_success() {
    printf "${GREEN}✓${NC} %s\n" "$*" >&2
}

# 步骤开始
log_step() {
    local step="$1"
    local total="$2"
    local message="$3"

    printf "${CYAN}[%02d/%02d]${NC} %s\n" "$step" "$total" "$message" >&2
}

# 进度条
log_progress() {
    local current="$1"
    local total="$2"
    local width=50

    if [ $DEVENV_LOG_LEVEL -gt $LOG_LEVEL_INFO ]; then
        return
    fi

    local progress=$((current * width / total))
    local percent=$((current * 100 / total))

    printf "\r["
    for ((i=0; i<progress; i++)); do
        printf "█"
    done
    for ((i=progress; i<width; i++)); do
        printf " "
    done
    printf "] %3d%%" "$percent"

    if [ "$current" -eq "$total" ]; then
        printf "\n"
    fi
}

# 标题
log_title() {
    printf "\n${CYAN}%s${NC}\n" "$*" >&2
    printf "${CYAN}%s${NC}\n" "$(printf '%*s' "${#*}" | tr ' ' '=')" >&2
}

# 子标题
log_subtitle() {
    printf "\n${BLUE}%s${NC}\n" "$*" >&2
    printf "${BLUE}%s${NC}\n" "$(printf '%*s' "${#*}" | tr ' ' '-')" >&2
}

# 分隔线
log_separator() {
    printf "\n%s\n\n" "$(printf '%*s' 80 | tr ' ' '─')" >&2
}

# 键值对输出
log_kv() {
    local key="$1"
    local value="$2"

    printf "  ${BLUE}%-20s${NC}: %s\n" "$key" "$value" >&2
}

# 表格输出
log_table() {
    local headers=("$@")
    local rows=("${@:$((${#headers[@]}+1))}")

    # TODO: 实现表格输出
    printf "表格功能开发中...\n" >&2
}