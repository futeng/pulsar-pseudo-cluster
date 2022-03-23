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

# Default values
zk_server=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181
sed_i='sed -i'
datename=$(date +"%Y-%m-%d %H:%M:%S")
echo_with_date="echo [$datename]"

checkOS() {
	unameOut="$(uname -s)"
	case "${unameOut}" in
	    Linux*)     machine=Linux; ${echo_with_date} "[1/9][√] Your OS is ready => GNU/Linux" ;;
	    Darwin*)    machine=Mac; sed_i='sed -i "" '; ${echo_with_date} "[1/9][√] Your OS is ready => Mac OS" ;;
	    CYGWIN*)    machine=Cygwin; exit 1;;
	    MINGW*)     machine=MinGw; exit 1;;
	    *)          machine="UNKNOWN:${unameOut}"; exit 1
	esac
	# ${echo_with_date} ${machine}
}

checkJDK() {
	jdk_version=$(java -version 2>&1 | sed '1!d' | sed -e 's/"//g' | awk '{print $3}')

	if [ "$jdk_version" = "not" ]; then
		${echo_with_date} "[x] JDK test failed => Please install JDK and configure JAVA_HOME first.)"
		exit 1
	else
		${echo_with_date} "[2/9][√] Your JDK is ready => $jdk_version. Please check the version conflicts with Pulsar manually(JDK11+ is recommend)."
	fi
}


# Commands for check enviroments

# Check the exists for apache-pulsar-*-bin.tar.gz
pulsar_tarball=""
checkTarball() {
	if ls apache-pulsar-*-bin.tar.gz >/dev/null 2>&1; then
		pulsar_tarball=$(ls apache-pulsar-*-bin.tar.gz)
		${echo_with_date} "[3/9][√] Your Pulsar tarball is ready => "$pulsar_tarball
	else
		${echo_with_date} "[x] tarball check => Please download and put the tarball under the same directory with this deploy script."
		${echo_with_date} "tips: wget https://dlcdn.apache.org/pulsar/pulsar-2.9.1/apache-pulsar-2.9.1-bin.tar.gz --no-check-certificate"
		exit 1
	fi
}

# Check for Ports conflicts
checkPortConflict() {
	port_list="12181|22181|32181|19990|29990|39990|18001|18002|18003|18004|18005|18006|12888|13888|22888|23888|32888|33888|18443|28443|38443|16650|26650|36650|13181|23181|33181|18080|28080|38080|16651|26651|36651"
	if [[ -n $(netstat -ant|grep -E "$port_list")  ]]; then
		${echo_with_date} "[x] Ports Conflicts => Please ensure that the following ports are not occupied:"
		${echo_with_date} 'Tips: netstat -ant|grep -E "$port_list"'
		exit 1
	else
		${echo_with_date} "[4/9][√] Your Ports are ready => Port list: $port_list"
	fi
}

# Check the disk's remaining capacity
checkDisk() {
	${echo_with_date} "[5/9][√] Please check the disk's remaining capacity manually. It's should remaining more than 95%."
}


# Command to start/stop/test for Zookeeper/Bookie/Broker 
stopZK() {
	pulsar-1/bin/pulsar-daemon stop zookeeper
	pulsar-2/bin/pulsar-daemon stop zookeeper
	pulsar-3/bin/pulsar-daemon stop zookeeper
}

startZK() {
	pulsar-1/bin/pulsar-daemon start zookeeper
	pulsar-2/bin/pulsar-daemon start zookeeper
	pulsar-3/bin/pulsar-daemon start zookeeper
}

testZK() {

	pulsar-1/bin/pulsar zookeeper-shell -server 127.0.0.1:32181 create /testzk >/dev/null 2>&1 
	pulsar-2/bin/pulsar zookeeper-shell -server 127.0.0.1:22181 set /testzk pulsar_pseudo_cluster >/dev/null 2>&1
	pulsar-1/bin/pulsar zookeeper-shell -server 127.0.0.1:12181 get  /testzk > ./zktest 2>&1

	if [[ -f ./zktest && $(grep "pulsar_pseudo_cluster" ./zktest)="pulsar_pseudo_cluster" ]]; then
		${echo_with_date} "[6/9][√] Your Zookeeper pseudo-cluster is all ready."
		rm ./zktest
		pulsar-1/bin/pulsar zookeeper-shell -server $zk_server delete /testzk >/dev/null 2>&1
	else
		${echo_with_date} "[x] Your Zookeeper Pseudo cluster test failed. Please check it manually."
		exit 1
	fi
}

startBookies() {
	pulsar-1/bin/pulsar-daemon start bookie
	pulsar-2/bin/pulsar-daemon start bookie
	pulsar-3/bin/pulsar-daemon start bookie
}

stopBookies() {
	pulsar-1/bin/pulsar-daemon stop bookie
	pulsar-2/bin/pulsar-daemon stop bookie
	pulsar-3/bin/pulsar-daemon stop bookie
}

testBookies() {
	pulsar-1/bin/bookkeeper shell simpletest --ensemble 2 --writeQuorum 2 --ackQuorum 2 --numEntries 10 > ./10_entries_written.log 2>&1 

  	if [[ -f ./10_entries_written.log && $(grep -c "10 entries written" ./10_entries_written.log) -ne 0 ]]; then
		${echo_with_date} "[9/9][√] Your bookies is all ready."
		rm ./10_entries_written.log

	else
		${echo_with_date} "[x] Bookies simpletest failed. Please check it manually."
		exit 1
	fi	
}

startBrokers() {
	pulsar-1/bin/pulsar-daemon start broker
	pulsar-2/bin/pulsar-daemon start broker
	pulsar-3/bin/pulsar-daemon start broker
}

stopBrokers() {
	pulsar-1/bin/pulsar-daemon stop broker
	pulsar-2/bin/pulsar-daemon stop broker
	pulsar-3/bin/pulsar-daemon stop broker
}

testBrokers() {
	pulsar-1/bin/pulsar-client produce persistent://t1/ns1/test -n 10  -m "hello pulsar" > ./produce.log 2>&1
	
  	if [[ -f ./produce.log && $(grep -c "10 messages successfully produced" ./produce.log) -ne 0 ]]; then
		${echo_with_date} "[pulsar-client produce][√] 10 messages successfully produced"
		rm ./produce.log
	else
		${echo_with_date} "[pulsar-client produce][x] Something wrong when using pulsar-client produce message."
		exit 1
	fi		

	pulsar-1/bin/pulsar-client consume persistent://t1/ns1/test -n 10 -s "consumer-test"  -t "Exclusive" -p Earliest > ./consume.log 2>&1

  	if [[ -f ./consume.log && $(grep -c "10 messages successfully consumed" ./consume.log) -ne 0 ]]; then
		${echo_with_date} "[pulsar-client consume][√] 10 messages successfully consumed"
		rm ./consume.log
	else
		${echo_with_date} "[pulsar-client consume][x] Something wrong when using pulsar-client consume message."
		exit 1
	fi	
}

# You may need kill threads manually if it's some err happens.
stopAll() {
	if [[ $(ps -ef |grep "pulsar-" | grep -v "grep" |  grep QuorumPeerMain | wc -l) -gt 1 ]]; then
		stopZK
	fi

	if [[ $(ps -ef |grep "pulsar-" | grep -v "grep" |  grep bookkeeper.conf | wc -l) -gt 1 ]]; then
		stopBookies
	fi

	if [[ $(ps -ef |grep "pulsar-" | grep -v "grep" |  grep broker.conf | wc -l) -gt 1 ]]; then
		stopBrokers
	fi
}

# Command to clean data( All data will be cleaned up every time you redeploy the cluster.)
removeAllPulsarDir() {
	rm -rf pulsar-1
	rm -rf pulsar-2
	rm -rf pulsar-3
}

initDataDir() {	
	mkdir -p pulsar-1/data/zookeeper
	mkdir -p pulsar-2/data/zookeeper
	mkdir -p pulsar-3/data/zookeeper
}
unzipPulsar() {
	mkdir ./pulsar-1
	tar zxf apache-pulsar-*-bin.tar.gz --strip-components 1 -C ./pulsar-1
	cp -R pulsar-1 pulsar-2
	cp -R pulsar-1 pulsar-3
}


# Commands to configure Zookeeper/Bookie/Broker/Client
replaceLog4j2() {
	
	${sed_i} 's/immediateFlush: false/immediateFlush: true/' pulsar-1/conf/log4j2.yaml
	${sed_i} 's/immediateFlush: false/immediateFlush: true/' pulsar-2/conf/log4j2.yaml
	${sed_i} 's/immediateFlush: false/immediateFlush: true/' pulsar-3/conf/log4j2.yaml
}

replaceZookeeperConf() {

	echo "1" > pulsar-1/data/zookeeper/myid
	echo "2" > pulsar-2/data/zookeeper/myid
	echo "3" > pulsar-3/data/zookeeper/myid

	${sed_i} 's/=2181/=12181/' pulsar-1/conf/zookeeper.conf
	${sed_i} 's/=2181/=22181/' pulsar-2/conf/zookeeper.conf
	${sed_i} 's/=2181/=32181/' pulsar-3/conf/zookeeper.conf
	
	${sed_i} "s|admin.serverPort=9990|admin.serverPort=19990|" pulsar-1/conf/zookeeper.conf
	${sed_i} "s|admin.serverPort=9990|admin.serverPort=29990|" pulsar-2/conf/zookeeper.conf
	${sed_i} "s|admin.serverPort=9990|admin.serverPort=39990|" pulsar-3/conf/zookeeper.conf

	${sed_i} "s|metricsProvider.httpPort=8000|metricsProvider.httpPort=18001|" pulsar-1/conf/zookeeper.conf
	${sed_i} "s|metricsProvider.httpPort=8000|metricsProvider.httpPort=18002|" pulsar-2/conf/zookeeper.conf
	${sed_i} "s|metricsProvider.httpPort=8000|metricsProvider.httpPort=18003|" pulsar-3/conf/zookeeper.conf

	echo "server.1=localhost:12888:13888" >> pulsar-1/conf/zookeeper.conf
	echo "server.2=localhost:22888:23888" >> pulsar-1/conf/zookeeper.conf
	echo "server.3=localhost:32888:33888" >> pulsar-1/conf/zookeeper.conf
	echo "server.1=localhost:12888:13888" >> pulsar-2/conf/zookeeper.conf
	echo "server.2=localhost:22888:23888" >> pulsar-2/conf/zookeeper.conf
	echo "server.3=localhost:32888:33888" >> pulsar-2/conf/zookeeper.conf
	echo "server.1=localhost:12888:13888" >> pulsar-3/conf/zookeeper.conf
	echo "server.2=localhost:22888:23888" >> pulsar-3/conf/zookeeper.conf
	echo "server.3=localhost:32888:33888" >> pulsar-3/conf/zookeeper.conf

}

replaceBookKeeperConf() {
	${sed_i} 's/bookiePort=3181/bookiePort=13181/' pulsar-1/conf/bookkeeper.conf
	${sed_i} 's/bookiePort=3181/bookiePort=23181/' pulsar-2/conf/bookkeeper.conf
	${sed_i} 's/bookiePort=3181/bookiePort=33181/' pulsar-3/conf/bookkeeper.conf
	
	${sed_i} 's/prometheusStatsHttpPort=8000/prometheusStatsHttpPort=18004/' pulsar-1/conf/bookkeeper.conf
	${sed_i} 's/prometheusStatsHttpPort=8000/prometheusStatsHttpPort=18005/' pulsar-2/conf/bookkeeper.conf
	${sed_i} 's/prometheusStatsHttpPort=8000/prometheusStatsHttpPort=18006/' pulsar-3/conf/bookkeeper.conf
	
	${sed_i} 's/zkServers=localhost:2181/zkServers=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/' pulsar-1/conf/bookkeeper.conf
	${sed_i} 's/zkServers=localhost:2181/zkServers=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/' pulsar-2/conf/bookkeeper.conf
	${sed_i} 's/zkServers=localhost:2181/zkServers=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/' pulsar-3/conf/bookkeeper.conf
	
	# advertisedAddress=
	${sed_i} 's/advertisedAddress=/advertisedAddress=127.0.0.1/' pulsar-1/conf/bookkeeper.conf
	${sed_i} 's/advertisedAddress=/advertisedAddress=127.0.0.1/' pulsar-2/conf/bookkeeper.conf
	${sed_i} 's/advertisedAddress=/advertisedAddress=127.0.0.1/' pulsar-3/conf/bookkeeper.conf
}

replaceClientConf() {
	### client
	# webServiceUrl=http://127.0.0.1:8080/
	${sed_i} 's|webServiceUrl=http://localhost:8080/|webServiceUrl=http://127.0.0.1:18080/|' pulsar-1/conf/client.conf
	${sed_i} 's|webServiceUrl=http://localhost:8080/|webServiceUrl=http://127.0.0.1:28080/|' pulsar-2/conf/client.conf
	${sed_i} 's|webServiceUrl=http://localhost:8080/|webServiceUrl=http://127.0.0.1:38080/|' pulsar-3/conf/client.conf
	
	
	# brokerServiceUrl=pulsar://127.0.0.1:6650/
	${sed_i} 's|brokerServiceUrl=pulsar://localhost:6650/|brokerServiceUrl=pulsar://127.0.0.1:16650/|' pulsar-1/conf/client.conf
	${sed_i} 's|brokerServiceUrl=pulsar://localhost:6650/|brokerServiceUrl=pulsar://127.0.0.1:26650/|' pulsar-2/conf/client.conf
	${sed_i} 's|brokerServiceUrl=pulsar://localhost:6650/|brokerServiceUrl=pulsar://127.0.0.1:36650/|' pulsar-3/conf/client.conf

}

replaceBrokerConf() {

	# zookeeperServers=
	${sed_i} 's/zookeeperServers=/zookeeperServers=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/' pulsar-1/conf/broker.conf
	${sed_i} 's/zookeeperServers=/zookeeperServers=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/' pulsar-2/conf/broker.conf
	${sed_i} 's/zookeeperServers=/zookeeperServers=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/' pulsar-3/conf/broker.conf
	
	# configurationStoreServers=
	${sed_i} 's|configurationStoreServers=|configurationStoreServers=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/pulsar-configuration-store|' pulsar-1/conf/broker.conf
	${sed_i} 's|configurationStoreServers=|configurationStoreServers=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/pulsar-configuration-store|' pulsar-2/conf/broker.conf
	${sed_i} 's|configurationStoreServers=|configurationStoreServers=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/pulsar-configuration-store|' pulsar-3/conf/broker.conf
	
	# brokerServicePort=6650
	${sed_i} 's|brokerServicePort=6650|brokerServicePort=16650|' pulsar-1/conf/broker.conf
	${sed_i} 's|brokerServicePort=6650|brokerServicePort=26650|' pulsar-2/conf/broker.conf
	${sed_i} 's|brokerServicePort=6650|brokerServicePort=36650|' pulsar-3/conf/broker.conf
	
	# brokerServicePortTls=
	${sed_i} 's|brokerServicePortTls=|brokerServicePortTls=16651|' pulsar-1/conf/broker.conf
	${sed_i} 's|brokerServicePortTls=|brokerServicePortTls=26651|' pulsar-2/conf/broker.conf
	${sed_i} 's|brokerServicePortTls=|brokerServicePortTls=36651|' pulsar-3/conf/broker.conf
	
	# webServicePort=8080
	${sed_i} 's|webServicePort=8080|webServicePort=18080|' pulsar-1/conf/broker.conf
	${sed_i} 's|webServicePort=8080|webServicePort=28080|' pulsar-2/conf/broker.conf
	${sed_i} 's|webServicePort=8080|webServicePort=38080|' pulsar-3/conf/broker.conf
	
	# webServicePortTls=
	${sed_i} 's|webServicePortTls=|webServicePortTls=18443|' pulsar-1/conf/broker.conf
	${sed_i} 's|webServicePortTls=|webServicePortTls=28443|' pulsar-2/conf/broker.conf
	${sed_i} 's|webServicePortTls=|webServicePortTls=38443|' pulsar-3/conf/broker.conf
	
	# clusterName=
	${sed_i} 's|clusterName=|clusterName=pulsar_pseudo_cluster|' pulsar-1/conf/broker.conf
	${sed_i} 's|clusterName=|clusterName=pulsar_pseudo_cluster|' pulsar-2/conf/broker.conf
	${sed_i} 's|clusterName=|clusterName=pulsar_pseudo_cluster|' pulsar-3/conf/broker.conf
	
	# advertisedAddress
	${sed_i} 's|advertisedAddress=|advertisedAddress=127.0.0.1|' pulsar-1/conf/broker.conf
	${sed_i} 's|advertisedAddress=|advertisedAddress=127.0.0.1|' pulsar-2/conf/broker.conf
	${sed_i} 's|advertisedAddress=|advertisedAddress=127.0.0.1|' pulsar-3/conf/broker.conf

}

# Command for init pulsar metadata
initPulsarMetadata() {
	pulsar-1/bin/pulsar initialize-cluster-metadata \
  		--cluster pulsar_pseudo_cluster \
  		--zookeeper 127.0.0.1:12181 \
  		--configuration-store 127.0.0.1:12181 \
  		--web-service-url http://127.0.0.1:12181:18080 \
  		--web-service-url-tls https://127.0.0.1:12181:18443 \
  		--broker-service-url pulsar://127.0.0.1:12181:16650 \
  		--broker-service-url-tls pulsar+ssl://127.0.0.1:12181:16651 > ./initialize-cluster-metadata.log 2>&1

  	if [[ -f ./initialize-cluster-metadata.log && $(grep -c "Successfully" ./initialize-cluster-metadata.log) -ne 0 ]]; then
		${echo_with_date} "[7/9][√] Your cluster metadata initialized in Zookeeper is ready."
		rm ./initialize-cluster-metadata.log

	else
		${echo_with_date} "[x] Initialize pulsar metadata in Zookeeper failed. Please check it manually."
		exit 1
	fi
}

getPulsarMetaDate() {
	metadata_info=$(pulsar-1/bin/pulsar zookeeper-shell -server 127.0.0.1:12181 get  /admin/clusters/pulsar_pseudo_cluster | grep serviceUrl)
	if [[ $metadata_info =~ "http://127.0.0.1:12181:18080"  ]]; then
		${echo_with_date} "[8/9][√] Your cluster metadata test is ready. => "$metadata_info
	else 
		${echo_with_date} "[x] Something wrong when initialize your cluster metadata, please check Zookeeper manually, then re-execute this script."
	fi
}

# Commands for create local cluster, tenant and namespaces.
crateTenantAndNamespace() {
	# jps -m| grep -v Jps

	${echo_with_date} "[ list brokers ] -> pulsar-1/bin/pulsar-admin brokers list pulsar_pseudo_cluster"
	pulsar-1/bin/pulsar-admin brokers list pulsar_pseudo_cluster
	${echo_with_date} "[ leader-broker ] -> pulsar-1/bin/pulsar-admin brokers leader-broker"
	pulsar-1/bin/pulsar-admin brokers leader-broker
	${echo_with_date} "[ create local cluster ] -> pulsar-1/bin/pulsar-admin clusters create pulsar_pseudo_cluster"	
	pulsar-1/bin/pulsar-admin clusters create  pulsar_pseudo_cluster
	${echo_with_date} "[ create tenant ] -> pulsar-1/bin/pulsar-admin tenants create t1 -c pulsar_pseudo_cluster"	
	pulsar-1/bin/pulsar-admin tenants create t1 -c pulsar_pseudo_cluster
	${echo_with_date} "[ create tenant/namespaces ] -> pulsar-1/bin/pulsar-admin namespaces create t1/ns1 -c pulsar_pseudo_cluster"
	pulsar-1/bin/pulsar-admin namespaces create t1/ns1 -c pulsar_pseudo_cluster

	${echo_with_date} "[ create second cluster ] -> pulsar-1/bin/pulsar-admin clusters create cluster_2"
	pulsar-1/bin/pulsar-admin clusters create cluster_2
	${echo_with_date} "[ create second tenant ] -> pulsar-1/bin/pulsar-admin tenants create t2 -c cluster_2"
	pulsar-1/bin/pulsar-admin tenants create t2 -c cluster_2
	${echo_with_date} "[ create second tenant/namespaces ] -> pulsar-1/bin/pulsar-admin namespaces create t2/ns2 -c cluster_2"
	pulsar-1/bin/pulsar-admin namespaces create t2/ns2 -c cluster_2

	${echo_with_date} "[ list tenants ] -> pulsar-1/bin/pulsar-admin tenants list"
	pulsar-1/bin/pulsar-admin tenants list 
	${echo_with_date} "[ list tenant's namespaces ] -> pulsar-1/bin/pulsar-admin namespaces list t1"
	pulsar-1/bin/pulsar-admin namespaces list t1
	${echo_with_date} "[ get tenant's clusters ] -> pulsar-1/bin/pulsar-admin namespaces get-clusters t1/ns1"
	pulsar-1/bin/pulsar-admin namespaces get-clusters t1/ns1

}





############################
####### => Let's go
############################
${echo_with_date} "====> Start to (re)deploy the pseudo-cluster of pulsar <===="

# 0. Prepare
# - Check enviroments.
# - Stop all Pulsar related threads if exists(only started by this deploy script ).
# - Remove Pulsar directorie if exists.
checkOS
checkJDK
checkTarball
stopAll
checkPortConflict
checkDisk
removeAllPulsarDir

# 1. Generate data directory
# - Uncompress tarball and generate three directories.
unzipPulsar
# - Generate Zookeeper data dir
initDataDir

# 2. Deploy pseudo-cluster of Zookeeper
# - Configure Zookeeper 
replaceZookeeperConf
# - Start Zookeeper pseudo-cluster
startZK
# - Test Zookeeper
testZK

# 3. Cluster metadata initialization
initPulsarMetadata
getPulsarMetaDate

# 4. Deploy pseudo-cluster of BookKeeper(bookies)
# - Configure log4j2 for flush log immediatelly
replaceLog4j2
# - Configure bookkeeper.conf
replaceBookKeeperConf
# - Start Bookis
startBookies
# - Test Bookies
testBookies


# 5. Deploy brokers
# - Configure broker.conf
replaceBrokerConf
# - Start broker
startBrokers
# - Configure client.conf
replaceClientConf

# 6. Pub-sub test
# - Create local cluster and tenants/namespace）
crateTenantAndNamespace
# - Test broker(pub-sub)
testBrokers
printHello
