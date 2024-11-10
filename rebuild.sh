#!/usr/bin/env bash
# Script to deploy pulsar in pseudo-cluster.
# More info https://github.com/futeng/pulsar-pseudo-cluster
# Copyright (C) 2022 fu teng (Please feel free to contact me : ifuteng@gmail.com)
# Permission to copy and modify is granted under the Apache 2.0 license
# Last revised 23/3/2022

printHello() {

echo " _   _  _     ______        _                    _ ";
echo "| | | |(_)    | ___ \      | |                  | |";
echo "| |_| | _     | |_/ /_   _ | | ___   __ _  _ __ | |";
echo "|  _  || |    |  __/| | | || |/ __| / _\` || '__|| |";
echo "| | | || | _  | |   | |_| || |\__ \| (_| || |   |_|";
echo "\_| |_/|_|( ) \_|    \__,_||_||___/ \__,_||_|   (_)";
echo "          |/                                       ";
echo "                                                   ";
}

# 变量，用户可在 cell 中自定义调整
pulsar_cluster_name=pulsar_cluster_1
zk_dir="$pulsar_cluster_name/zk"

# 端口
zk_server_port=12181
zk_stats_server_port=18001
zk_admin_serverPort=19990
zk_metricsProvider_httpPort=18000

br_1_web_service_url=18080
br_1_web_service_url_tls=18443
br_1_broker_service_url=16650
br_1_broker_service_url_tls=16651

br_2_web_service_url=18081
br_2_web_service_url_tls=18444
br_2_broker_service_url=16652
br_2_broker_service_url_tls=16653

bk_1_bookiePort=13181
bk_1_prometheusStatsHttpPort=18004
bk_2_bookiePort=13182
bk_2_prometheusStatsHttpPort=18005
bk_3_bookiePort=13183
bk_3_prometheusStatsHttpPort=18006



# Zookeeper 服务地址
ZK_SERVER="127.0.0.1:$zk_server_port"

# 将端口聚合到一个数组中
declare -a ports=(
    $zk_server_port        
    $zk_stats_server_port  
    $zk_admin_serverPort
    $zk_metricsProvider_httpPort
    # 在这里引用更多定义的端口变量
)



# 系统命令 
sed_i='sed -i'
datename=$(date +"%Y-%m-%d %H:%M:%S")
alias echo_info="echo [$datename][info]"
alias echo_error="echo [$datename][error]"
alias echo_warn="echo [$datename][warn]"

# 检查用户配置文件是否存在
if [ -f "user-config.conf" ]; then
    # 读取用户配置
    source user-config.conf
fi

# 使用配置
echo "Using Zookeeper server at: $zk_server"

# 检测操作系统，当前只适配了 Linux 和 macOS
checkOS() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)
            machine="Linux"
            echo_info "[√] Your OS is ready => GNU/Linux"
            ;;
        Darwin*)
            machine="Mac"
            sed_i="sed -i ''"
            echo_info "[√] Your OS is ready => macOS"
            ;;
        CYGWIN*|MINGW*)
            echo_error "Your OS is not supported => ${unameOut}"
            exit 1
            ;;
        *)
            echo_error "Your OS is unknown and not supported => ${unameOut}"
            exit 1
            ;;
    esac
}

checkJDK() {
    datename=$(date +"%Y-%m-%d %H:%M:%S")  # 获取当前时间，用于日志输出
    
    # 检查 JAVA_HOME 是否被设置
    if [ -z "$JAVA_HOME" ]; then
        echo_error "JAVA_HOME is not set."
        exit 1
    else
        echo_info "JAVA_HOME is set to $JAVA_HOME"
    fi

    # 检查 JAVA_HOME 目录下是否存在 java 可执行文件
    if [ ! -x "$JAVA_HOME/bin/java" ]; then
        echo_error "JAVA_HOME is set, but java executable is not found in $JAVA_HOME/bin."
        exit 1
    fi

    # 获取 Java 版本
    java_version=$("$JAVA_HOME/bin/java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo_info "Detected Java version: $java_version"
    
    # 比较版本是否大于等于 17
    if [[ "$java_version" < "17" ]]; then
        echo_error "Java version is less than 17. Detected version: $java_version"
        exit 1
    else
        echo_info "[√] Java version is 17 or greater."
    fi
}



checkPortConflicts() {
    # 检测端口冲突
    echo_info "Checking for port conflicts..."

    # 检查每个端口
    for port in "${ports[@]}"; do
        if lsof -i:$port &> /dev/null; then
            echo_error "Port $port is already in use."
            exit 1
        else
            echo_info "Port $port is available."
        fi
    done

    echo_info "[√] No port conflicts detected."
}

checkDiskSpace() {
    # 获取脚本所在目录的磁盘分区
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    disk_part=$(df "$script_dir" | tail -1 | awk '{print $1}')
    
    # 获取该分区的可用空间（单位：1K blocks）
    available_space_kb=$(df "$script_dir" | tail -1 | awk '{print $4}')
    available_space_gb=$(bc <<< "scale=2; $available_space_kb/1024/1024")
    
    # 检查空间是否大于或等于10GB
    if (( $(echo "$available_space_gb >= 10" | bc -l) )); then
        echo_info "[√] The disk $disk_part has sufficient space ($available_space_gb GB available)."
    else
        echo_error "The disk $disk_part does not have enough space. Only $available_space_gb GB available. Please clear disk space."
    fi
}

checkPulsarBinary() {
    # 检查当前目录下是否存在 Pulsar 二进制包
    if ls apache-pulsar-*-bin.tar.gz 1> /dev/null 2>&1; then
        echo_info "[√] Apache Pulsar binary package is found in the current directory."
    else
        echo_error "Apache Pulsar binary package not found."
        echo "You can download it from the Apache Pulsar official website or the CDN site:"
        echo "Official: https://pulsar.apache.org/en/download/"
        echo "CDN: https://dlcdn.apache.org/pulsar/"
        exit 1
    fi
}

initializeDirectories() {

    # 创建主目录
    mkdir -p "$pulsar_cluster_name"

    # 在主目录下创建子目录
    mkdir -p "$pulsar_cluster_name"/{broker1,broker2,bookie1,bookie2,bookie3,zk,client}

    # 创建 ZK 的子目录及文件
    mkdir -p "$pulsar_cluster_name"/zk/data
    echo "1" > "$pulsar_cluster_name"/zk/data/myid

    echo_info "Directory structure initialized under '$pulsar_cluster_name'."
}
shutdownPulsarServicesV1() {
    local services=("bookie1" "bookie2" "bookie3" "broker1" "broker2" "zk")
    local service_dir=""
    local service_type=""
    local pid=""

    for service in "${services[@]}"; do
        service_dir="$pulsar_cluster_name/$service"

        # 确定服务类型
        if [[ "$service" == *"broker"* ]]; then
            service_type="broker"
        elif [[ "$service" == *"bookie"* ]]; then
            service_type="bookie"
        elif [[ "$service" == *"zk"* || "$service" == *"Zookeeper"* ]]; then
            service_type="zookeeper"
        fi

        # 使用 pulsar-daemon 停止服务
        if [ -d "$service_dir" ]; then
            echo_info "Stopping $service_type service in $service using pulsar-daemon."
            "$service_dir/bin/pulsar-daemon" stop "$service_type"

            # 检查 JVM 进程是否还在运行
            sleep 5  # 给予一些时间让进程优雅退出
            pid=$(pgrep -f "$service_dir" | grep java)

            if [ ! -z "$pid" ]; then
                echo_warn "Service $service_type in $service is still running, PID: $pid, attempting kill."
                kill -9 "$pid"
                if [ $? -eq 0 ]; then
                    echo_info "Successfully killed $service_type in $service, PID: $pid."
                else
                    echo_error "Failed to kill $service_type in $service, PID: $pid."
                fi
            else
                echo_info "$service_type in $service has been stopped gracefully."
            fi
        else
            echo_warn "Directory $service_dir does not exist, skipping."
        fi
    done
}

shutdownPulsarServices() {
    local services=("broker1" "broker2" "bookie1" "bookie2" "bookie3" "zk")
    local service_dir=""
    local service_type=""
    local pid=""

    for service in "${services[@]}"; do
        service_dir="$pulsar_cluster_name/$service"

        # 确定服务类型
        if [[ "$service" == *"broker"* ]]; then
            service_type="broker"
        elif [[ "$service" == *"bookie"* ]]; then
            service_type="bookie"
        elif [[ "$service" == *"zk"* || "$service" == *"Zookeeper"* ]]; then
            service_type="zookeeper"
        fi

        # 检查 JVM 进程是否存在
        pid=$(pgrep -f "$service_dir")
        if [ ! -z "$pid" ]; then
            # 使用 pulsar-daemon 停止服务
            echo_info "Stopping $service_type service in $service using pulsar-daemon."
            "$service_dir/bin/pulsar-daemon" stop "$service_type"

            # 给予一些时间让进程优雅退出
            sleep 5
            # 再次检查进程是否还在
            pid=$(pgrep -f "$service_dir" | grep java)
            if [ ! -z "$pid" ]; then
                echo_warn "Service $service_type in $service is still running, PID: $pid, attempting kill."
                kill -9 "$pid"
                if [ $? -eq 0 ]; then
                    echo_info "Successfully killed $service_type in $service, PID: $pid."
                else
                    echo_error "Failed to kill $service_type in $service, PID: $pid."
                fi
            else
                echo_info "$service_type in $service has been stopped gracefully."
            fi
        else
            echo_info "No JVM process found for $service_type in $service. Skipping shutdown."
        fi
    done
}


cleanupDirectories() {

    # 安全检查，确保集群名称不为空且不包含潜在危险字符
    if [ -z "$pulsar_cluster_name" ] || [[ "$pulsar_cluster_name" == */* ]]; then
        echo_error "Error: Invalid cluster name '$pulsar_cluster_name'. Exiting to prevent unintended deletion."
        exit 1
    fi

    # 检查目标目录是否存在
    if [ ! -d "$pulsar_cluster_name" ]; then
        echo_info "The directory '$pulsar_cluster_name' does not exist. No need to clean up."
    fi

    # 删除目录及其内容
    rm -rf "$pulsar_cluster_name"
    echo_info "Directory '$pulsar_cluster_name' and all its contents have been removed."
}

adjustJVMSettings() {
    local pulsar_env="$1/conf/pulsar_env.sh"
    local bkenv="$1/conf/bkenv.sh"

    # 调整 Pulsar 的 JVM 设置
    ${sed_i} 's|PULSAR_MEM=.*|PULSAR_MEM=${PULSAR_MEM:-"-Xms128m -Xmx128m -XX:MaxDirectMemorySize=256m"}|' "$pulsar_env"

    # 调整 Bookie 的 JVM 设置
    ${sed_i} 's|BOOKIE_MEM=.*|BOOKIE_MEM=${BOOKIE_MEM:-${PULSAR_MEM:-"-Xms128m -Xmx128m -XX:MaxDirectMemorySize=128m"}}|' "$bkenv"

    echo "JVM settings adjusted for $1"
}

initializePulsarEnvironment() {

    # 查找 Pulsar 二进制包
    pulsar_package=$(ls apache-pulsar-*-bin.tar.gz)
    if [ -z "$pulsar_package" ]; then
        echo_error "Error: Pulsar binary package not found."
        exit 1
    fi

    # 解压到 packages 目录
    packages_dir="$pulsar_cluster_name/packages"
    if [ -d "$packages_dir" ]; then
        rm -rf "$packages_dir"  # 删除已存在的目录
    fi
    mkdir -p "$packages_dir"
    tar -xzf "$pulsar_package" -C "$packages_dir"
    pulsar_dir=$(find "$packages_dir" -mindepth 1 -maxdepth 1 -type d)

    if [ -z "$pulsar_dir" ]; then
        echo_error "Error: Failed to find the Pulsar directory after extraction."
        exit 1
    fi

    # 检查和修改 log4j2.yaml
    log4j2_config_path="$pulsar_dir/conf/log4j2.yaml"
    if [ -f "$log4j2_config_path" ]; then
        if command -v yq &>/dev/null; then
            # 检查是否存在需要修改的条目，如果不存在，添加相应的条目
            property_exists=$(yq eval '.Configuration.Properties.Property[] | select(.name == "pulsar.log.immediateFlush")' "$log4j2_config_path")
            if [ -z "$property_exists" ]; then
                # 如果属性不存在，添加新属性
                yq e '.Configuration.Properties.Property += [{"name": "pulsar.log.immediateFlush", "value": "true"}]' -i "$log4j2_config_path"
            else
                # 如果属性存在，修改该属性的值
                yq e '(.Configuration.Properties.Property[] | select(.name == "pulsar.log.immediateFlush").value) = "true"' -i "$log4j2_config_path"
            fi
        else
            echo_warn "Warning: yq is not installed. Skipping modification of 'pulsar.log.immediateFlush'."
        fi
    else
        echo_warn "Warning: log4j2.yaml not found. Skipping modification."
    fi

    adjustJVMSettings "$pulsar_dir"

    # 创建其他子目录
    for subdir in broker1 broker2 bookie1 bookie2 bookie3 zk client; do
        dest_dir="$pulsar_cluster_name/$subdir"
        mkdir -p "$dest_dir"
        cp -r "$pulsar_dir/bin" "$pulsar_dir/conf" "$dest_dir"
    done

    # 设置 lib 目录的软链接
    for subdir in broker1 broker2 bookie1 bookie2 bookie3 zk client; do
        subdir_lib="$pulsar_cluster_name/$subdir/lib"
        mkdir -p "$subdir_lib"  # 确保 lib 目录存在
        if [ -d "$subdir_lib" ]; then
            rm -rf "$subdir_lib"/*  # 清空现有的链接或文件
        fi

        # 使用绝对路径对每个 jar 包和其他 lib 目录中的文件创建软链接
        for lib_file in "$pulsar_dir/lib/"*; do
            absolute_path=$(readlink -f "$lib_file")
            ln -s "$absolute_path" "$subdir_lib/$(basename "$lib_file")"
        done
    done

    echo_info "[√]Pulsar environment has been initialized successfully under '$pulsar_cluster_name'."
}

modifyZookeeperConfig() {
    local zk_conf_file="$pulsar_cluster_name/zk/conf/zookeeper.conf"

    # 检查配置文件是否存在
    if [ ! -f "$zk_conf_file" ]; then
        echo "Error: Configuration file not found at '$zk_conf_file'"
        return 1
    fi

    # 使用 sed 修改配置
    eval $sed_i "s/clientPort=[0-9]*/clientPort=$zk_server_port/" "$zk_conf_file"
    eval $sed_i "s/admin\.serverPort=[0-9]*/admin.serverPort=$zk_admin_serverPort/" "$zk_conf_file"
    eval $sed_i "s/metricsProvider\.httpPort=[0-9]*/metricsProvider.httpPort=$zk_metricsProvider_httpPort/" "$zk_conf_file"

    echo_info "[√]Zookeeper configuration updated successfully."
}

startSingleZookeeperNode() {
    local zk_dir="$pulsar_cluster_name/zk"

    # 环境变量设置
    export PULSAR_EXTRA_OPTS="-Dstats_server_port=$zk_stats_server_port"
    
    # 启动 Zookeeper
    if [ -d "$zk_dir" ] && [ -x "$zk_dir/bin/pulsar-daemon" ]; then
        "$zk_dir/bin/pulsar-daemon" start zookeeper
        echo_info "Zookeeper started with stats server port: $zk_stats_server_port"
    else
        echo_error "Error: Invalid Zookeeper directory or executable not found at '$zk_dir/bin/pulsar-daemon'"
        return 1
    fi
}


# 检测 Zookeeper 服务的函数
checkZookeeper() {
    local zk_dir="$pulsar_cluster_name/zk"
    echo_info "Checking Zookeeper service on ${ZK_SERVER}..."

    # 尝试创建一个临时节点
    create_output=$($zk_dir/bin/pulsar zookeeper-shell -server $ZK_SERVER create /testzk "data" 2>&1)
    if [[ $create_output == *"Created"* ]]; then
        echo_info "Create operation successful."
    else
        echo_error "Create operation failed."
        return 1
    fi

    # 尝试读取刚才创建的节点
    get_output=$($zk_dir/bin/pulsar zookeeper-shell -server $ZK_SERVER get /testzk 2>&1)
    if [[ $get_output == *"data"* ]]; then
        echo_info "Get operation successful."
    else
        echo_error "Get operation failed."
        return 1
    fi

    # 尝试删除临时节点
    delete_output=$($zk_dir/bin/pulsar zookeeper-shell -server $ZK_SERVER delete /testzk 2>&1)

    echo_info "[√]Zookeeper service is working correctly."
    return 0
}

# 初始化集群元数据

initialize_metadata() {
    # 执行命令并将输出重定向到变量
    init_output=$($zk_dir/bin/pulsar initialize-cluster-metadata \
      --cluster $pulsar_cluster_name \
      --metadata-store "zk:127.0.0.1:$zk_server_port/$pulsar_cluster_name" \
      --configuration-metadata-store "zk:127.0.0.1:$zk_server_port/$pulsar_cluster_name" \
      --web-service-url "http://127.0.0.1:$br_1_web_service_url" \
      --web-service-url-tls "https://127.0.0.1:$br_1_web_service_url_tls" \
      --broker-service-url "pulsar://127.0.0.1:$br_1_broker_service_url" \
      --broker-service-url-tls "pulsar+ssl://127.0.0.1:$br_1_broker_service_url_tls" 2>&1)

    # 检查输出中是否包含成功的关键字
    echo "$init_output" | grep -q "Cluster metadata for '$pulsar_cluster_name' setup correctly"
    if [ $? -eq 0 ]; then
        echo_info "[√]Metadata initialization succeeded: Cluster metadata for '$pulsar_cluster_name' setup correctly."
    else
        echo_error "Metadata initialization failed or the success message was not found in the output."
    fi
}

check_metadata_initialization() {
    # 定义需要检查的节点
    node_path="/$pulsar_cluster_name"

    # 使用 ZooKeeper shell 命令获取节点信息
    check_output=$($zk_dir/bin/pulsar zookeeper-shell -server $ZK_SERVER get $node_path 2>&1)

    # 检查输出中是否包含 "Node does not exist"，这个信息表示节点不存在
    if echo "$check_output" | grep -q "Node does not exist"; then
        echo_error "Metadata initialization failed: Node $node_path does not exist in ZooKeeper."
        return 1
    else
        echo_info "[√]Metadata initialization succeeded: Node $node_path exists in ZooKeeper."
        return 0
    fi
}

modifyBookieConfig() {
    local bookie_dir_base="bookie"
    local bookie_conf="conf/bookkeeper.conf"
    local bookie_count=3

    for i in $(seq 1 $bookie_count); do
        local bookie_dir="$bookie_dir_base$i"
        local conf_file="$pulsar_cluster_name/$bookie_dir/$bookie_conf"
        local bookiePort_var="bk_${i}_bookiePort"
        local prometheusStatsHttpPort_var="bk_${i}_prometheusStatsHttpPort"

        if [ -w "$conf_file" ]; then
            # 替换 bookiePort

            eval $sed_i "s/bookiePort=[0-9]*/bookiePort=${!bookiePort_var}/" "$conf_file"

            # 替换 prometheusStatsHttpPort
            eval $sed_i "s/prometheusStatsHttpPort=[0-9]*/prometheusStatsHttpPort=${!prometheusStatsHttpPort_var}/" "$conf_file"

            # 构建新的 metadataServiceUri 字符串
            local new_uri="metadataServiceUri=zk://$ZK_SERVER/$pulsar_cluster_name/ledgers"

            # 使用 '|' 作为分隔符来避免转义问题
            ${sed_i} "s|metadataServiceUri=.*|$new_uri|" "$conf_file"

            # 替换 zkServers（适用于版本低于 2.11.x），使用 '|' 作为分隔符
            eval $sed_i "s/zkServers=.*$/zkServers=$ZK_SERVER/" "$conf_file"

            # 替换 advertisedAddress，使用 '|' 作为分隔符
            eval $sed_i "s/advertisedAddress=.*$/advertisedAddress=127.0.0.1/" "$conf_file"

            # 修改 autoRecoveryDaemonEnabled
            eval $sed_i "s/autoRecoveryDaemonEnabled=true/autoRecoveryDaemonEnabled=false/" "$conf_file"
        else
            echo "Error: No write permission for $conf_file"
        fi
    done
}

startAllBookies() {
    local bookie_dir_base="bookie"
    local bookie_count=3  # 有三个bookie节点

    # 循环遍历每个bookie节点
    for i in $(seq 1 $bookie_count); do
        local bookie_dir="$pulsar_cluster_name/$bookie_dir_base$i"
        local daemon_script="$bookie_dir/bin/pulsar-daemon"

        echo "Starting Bookie $i from directory $bookie_dir..."
        $daemon_script start bookie

    done

    echo_info "All Bookies have been started."
}

testBookies() {
    local bookie_dir_base="bookie1"  # 指定第一个Bookie
    local bookie_test_script="$pulsar_cluster_name/$bookie_dir_base/bin/bookkeeper"  # 构建测试脚本路径

    echo_info "Testing Bookie at $bookie_test_script..."

    # 执行测试
    $bookie_test_script shell simpletest --ensemble 2 --writeQuorum 2 --ackQuorum 2 --numEntries 10 > ./10_entries_written.log 2>&1 

    # 检查测试结果
    if [[ -f ./10_entries_written.log && $(grep -c "10 entries written" ./10_entries_written.log) -ne 0 ]]; then
        echo_info "[√] Your bookies is all ready."
        rm ./10_entries_written.log
    else
        echo_error "[x] Bookies simpletest failed. Please check it manually."
        exit 1
    fi
}

modifyBrokerConfig() {
    local broker_count=2  # 假设有两个Broker
    local broker_conf_base="$pulsar_cluster_name/broker"  # 基本路径，每个Broker配置文件的前缀

    for i in $(seq 1 $broker_count); do
        local broker_conf="${broker_conf_base}${i}/conf/broker.conf"
        local web_service_url_var="br_${i}_web_service_url"
        local web_service_url_tls_var="br_${i}_web_service_url_tls"
        local broker_service_url_var="br_${i}_broker_service_url"
        local broker_service_url_tls_var="br_${i}_broker_service_url_tls"

        # 动态获取每个Broker的端口
        local web_service_url=${!web_service_url_var}
        local web_service_url_tls=${!web_service_url_tls_var}
        local broker_service_url=${!broker_service_url_var}
        local broker_service_url_tls=${!broker_service_url_tls_var}

        # 更新配置文件
        ${sed_i} "s|metadataStoreUrl=.*|metadataStoreUrl=$ZK_SERVER/$pulsar_cluster_name|" "$broker_conf"
        ${sed_i} "s|configurationMetadataStoreUrl=.*|configurationMetadataStoreUrl=$ZK_SERVER/$pulsar_cluster_name|" "$broker_conf"
        ${sed_i} "s|webServicePort=.*|webServicePort=$web_service_url|" "$broker_conf"
        ${sed_i} "s|webServicePortTls=.*|webServicePortTls=$web_service_url_tls|" "$broker_conf"
        ${sed_i} "s|brokerServicePort=.*|brokerServicePort=$broker_service_url|" "$broker_conf"
        ${sed_i} "s|brokerServicePortTls=.*|brokerServicePortTls=$broker_service_url_tls|" "$broker_conf"
        ${sed_i} "s|clusterName=.*|clusterName=$pulsar_cluster_name|" "$broker_conf"
        ${sed_i} "s|advertisedAddress=.*|advertisedAddress=127.0.0.1|" "$broker_conf"
        ${sed_i} "s|allowAutoTopicCreationType=.*|allowAutoTopicCreationType=partitioned|" "$broker_conf"
        ${sed_i} "s|brokerDeleteInactiveTopicsEnabled=.*|brokerDeleteInactiveTopicsEnabled=false|" "$broker_conf"

        echo_info "Broker configuration for broker $i updated."
    done
}

startAllBrokers() {
    local bookie_dir_base="broker"
    local bookie_count=2  # 有三个bookie节点

    # 循环遍历每个bookie节点
    for i in $(seq 1 $bookie_count); do
        local bookie_dir="$pulsar_cluster_name/$bookie_dir_base$i"
        local daemon_script="$bookie_dir/bin/pulsar-daemon"

        echo "Starting Bookie $i from directory $bookie_dir..."
        $daemon_script start broker

    done

    echo_info "All Bookies have been started."
}

modifyClientConfig() {
    local client_conf_file="$pulsar_cluster_name/client/conf/client.conf"

    # 获取web服务和broker服务的URLs
    local web_service_urls="http://127.0.0.1:$br_1_web_service_url,127.0.0.1:$br_2_web_service_url"
    local broker_service_urls="pulsar://127.0.0.1:$br_1_broker_service_url,127.0.0.1:$br_2_broker_service_url"

    # 更新webServiceUrl
    ${sed_i} "s|webServiceUrl=.*|webServiceUrl=$web_service_urls|" "$client_conf_file"

    # 更新brokerServiceUrl
    ${sed_i} "s|brokerServiceUrl=.*|brokerServiceUrl=$broker_service_urls|" "$client_conf_file"

    echo_info "Client configuration updated in $client_conf_file"
}

testPulsarService() {
    local client_dir="$pulsar_cluster_name/client"
    local pulsar_admin="$client_dir/bin/pulsar-admin"
    local pulsar_client="$client_dir/bin/pulsar-client"

    # 创建集群
    $pulsar_admin clusters create $pulsar_cluster_name
    # 创建租户
    $pulsar_admin tenants create t1 -c $pulsar_cluster_name

    # 创建命名空间
    $pulsar_admin namespaces create t1/ns1 -c $pulsar_cluster_name

    # 创建一个3分区的topic
    $pulsar_admin topics create-partitioned-topic persistent://t1/ns1/test -p 3 

    # 使用pulsar-client发送10条消息
    $pulsar_client produce persistent://t1/ns1/test -n 10 -m "hello pulsar" > ./produce.log 2>&1

    # 检查消息是否成功发送
    if [[ -f ./produce.log && $(grep -c "10 messages successfully produced" ./produce.log) -ne 0 ]]; then
        echo_info "[pulsar-client produce][√] 10 messages successfully produced"
        rm ./produce.log
    else
        echo_error "[pulsar-client produce][x] Something wrong when using pulsar-client produce message."
        exit 1
    fi
}

checkOS

shutdownPulsarServices
cleanupDirectories

checkJDK
checkPortConflicts
checkDiskSpace
checkPulsarBinary

initializeDirectories
initializePulsarEnvironment

modifyZookeeperConfig
startSingleZookeeperNode
checkZookeeper

initialize_metadata
check_metadata_initialization

modifyBookieConfig
startAllBookies
testBookies

modifyBrokerConfig
startAllBrokers

modifyClientConfig
testPulsarService
printHello