#!/usr/bin/env bash

# 安装命令

# 安装组件
devenv_install() {
    local components=()
    local options=()

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                components=("git" "maven" "conda" "docker" "java" "node" "python" "go" "rust")
                shift
                ;;
            --help)
                show_install_help
                return 0
                ;;
            -*)
                options+=("$1")
                shift
                ;;
            *)
                components+=("$1")
                shift
                ;;
        esac
    done

    # 如果没有指定组件，显示帮助
    if [ ${#components[@]} -eq 0 ]; then
        show_install_help
        return 1
    fi

    # 安装每个组件
    for component in "${components[@]}"; do
        install_component "$component"
    done
}

# 显示安装帮助
show_install_help() {
    cat << EOF
用法: devenv install [选项] [组件...]

组件:
  git           Git 版本控制工具
  maven         Maven 构建工具
  conda         Conda 环境管理
  docker        Docker 容器平台
  java         Java 开发环境
  node         Node.js 运行时
  python       Python 解释器
  go           Go 编程语言
  rust         Rust 编程语言
  mysql        MySQL 数据库
  redis        Redis 缓存
  mongodb      MongoDB 数据库
  kafka        Kafka 消息队列
  consul       Consul 服务发现
  prometheus   Prometheus 监控
  grafana      Grafana 可视化
  elasticsearch Elasticsearch 搜索引擎
  kibana       Kibana 数据可视化

选项:
  --all        安装所有组件
  --help       显示帮助

示例:
  devenv install git maven
  devenv install --all
  devenv install docker
EOF
}

# 安装组件
install_component() {
    local component="$1"

    case "$component" in
        git)
            source "$SRC_DIR/modules/git/install.sh"
            install_git
            ;;
        maven)
            source "$SRC_DIR/modules/maven/install.sh"
            install_maven
            ;;
        conda)
            source "$SRC_DIR/modules/conda/install.sh"
            install_conda
            ;;
        docker)
            source "$SRC_DIR/modules/docker/install.sh"
            install_docker
            ;;
        java)
            source "$SRC_DIR/modules/java/install.sh"
            install_java
            ;;
        node)
            source "$SRC_DIR/modules/node/install.sh"
            install_node
            ;;
        python)
            source "$SRC_DIR/modules/python/install.sh"
            install_python
            ;;
        go)
            source "$SRC_DIR/modules/go/install.sh"
            install_go
            ;;
        rust)
            source "$SRC_DIR/modules/rust/install.sh"
            install_rust
            ;;
        mysql)
            source "$SRC_DIR/modules/middleware/mysql/install.sh"
            install_mysql
            ;;
        redis)
            source "$SRC_DIR/modules/middleware/redis/install.sh"
            install_redis
            ;;
        mongodb)
            source "$SRC_DIR/modules/middleware/mongodb/install.sh"
            install_mongodb
            ;;
        kafka)
            source "$SRC_DIR/modules/middleware/kafka/install.sh"
            install_kafka
            ;;
        consul)
            source "$SRC_DIR/modules/middleware/consul/install.sh"
            install_consul
            ;;
        prometheus)
            source "$SRC_DIR/modules/monitoring/prometheus/install.sh"
            install_prometheus
            ;;
        grafana)
            source "$SRC_DIR/modules/monitoring/grafana/install.sh"
            install_grafana
            ;;
        elasticsearch)
            source "$SRC_DIR/modules/logging/elasticsearch/install.sh"
            install_elasticsearch
            ;;
        kibana)
            source "$SRC_DIR/modules/logging/kibana/install.sh"
            install_kibana
            ;;
        *)
            log_error "不支持的组件: $component"
            return 1
            ;;
    esac

    # 更新状态
    update_state "components.$component.installed" "true"
    update_state "components.$component.installed_at" "$(date -Iseconds)"
}