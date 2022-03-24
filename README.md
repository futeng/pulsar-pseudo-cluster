# pulsar-pseudo-cluster
One script to (re)deploy pulsar in pseudo-cluster (simply as PPC).

- Introduction video: https://www.bilibili.com/video/BV1rU4y1d7c7

## User case

1. Rapid deployment a cluster, which is more complex than standalone but simpler than production.
2. Quick install for take a experience with new releases and new features (perhaps your old environment is gone).
3. Require frequent testing (compatibility testing, etc.).

## Features

1. One click deployment (one script. `./deploy.sh` ).
2. Script can be executed repeatedly to deploy a new clusters.
3. Contains the simplest configuration and administration commands that might be useful for beginners.

## Test cross

| HOST\Apache Pulsar   | 2.9.1 | 2.8.2 | 2.7.4   | 2.6.1   |
| -------------------- | ----- | ----- | ------- | ------- |
| CentOS 7.5 + jdk 11  | √     | √     | √ ②     | waiting |
| CentOS 7.5 + jdk1.8  | √ ①   | √     | waiting | waiting |
| MacMini M1 + jdk 1.8 | √     | √     | √ ②     | waiting |

- ①：Not recomend. Sometimes get error: `Error occurred during initialization of VM. Could not create ConcurrentG1RefineThread`
- ②：Not recomend. Cluster is OK, some problem of ompatibility for using `cluster-admin`

## How to use

```shell
# Clone this repo
$ git clone https://github.com/futeng/pulsar-pseudo-cluster.git 
$ cd pulsar-pseudo-cluster/

# Put your apache-pulsar tarball in the `pulsar-pseudo-cluster` directory (keep in same directory)
# for example download from CDN (take version of 2.9.1)
$ wget https://dlcdn.apache.org/pulsar/pulsar-2.9.1/apache-pulsar-2.9.1-bin.tar.gz --no-check-certificate

# Just execute the deployment script
$ sh deploy.sh
```

 ## Full log example

```shell
[2022-03-24 11:34:27] ====> Start to (re)deploy the pseudo-cluster of pulsar <====
[2022-03-24 11:34:27] [1/9][√] Your OS is ready => Mac OS
[2022-03-24 11:34:27] [2/9][√] Your JDK is ready => 1.8.0_311. Please check the version conflicts with Pulsar manually(JDK11+ is recommend).
[2022-03-24 11:34:27] [3/9][√] Your Pulsar tarball is ready => apache-pulsar-2.8.2-bin.tar.gz
[2022-03-24 11:34:27] [4/9][√] Your Ports are ready => Port list: 12181|22181|32181|19990|29990|39990|18001|18002|18003|18004|18005|18006|12888|13888|22888|23888|32888|33888|18443|28443|38443|16650|26650|36650|13181|23181|33181|18080|28080|38080|16651|26651|36651
[2022-03-24 11:34:27] [5/9][√] Please check the disk's remaining capacity manually. It's should remaining more than 95%.
doing start zookeeper ...
starting zookeeper, logging to /Users/futeng/workspaces/tmp/tmp/pulsar-pseudo-cluster/pulsar-1/logs/pulsar-zookeeper-futengdeMac-mini.local.log
Note: Set immediateFlush to true in conf/log4j2.yaml will guarantee the logging event is flushing to disk immediately. The default behavior is switched off due to performance considerations.
doing start zookeeper ...
starting zookeeper, logging to /Users/futeng/workspaces/tmp/tmp/pulsar-pseudo-cluster/pulsar-2/logs/pulsar-zookeeper-futengdeMac-mini.local.log
Note: Set immediateFlush to true in conf/log4j2.yaml will guarantee the logging event is flushing to disk immediately. The default behavior is switched off due to performance considerations.
doing start zookeeper ...
starting zookeeper, logging to /Users/futeng/workspaces/tmp/tmp/pulsar-pseudo-cluster/pulsar-3/logs/pulsar-zookeeper-futengdeMac-mini.local.log
Note: Set immediateFlush to true in conf/log4j2.yaml will guarantee the logging event is flushing to disk immediately. The default behavior is switched off due to performance considerations.
[2022-03-24 11:34:27] [6/9][√] Your Zookeeper pseudo-cluster is all ready.
[2022-03-24 11:34:27] [7/9][√] Your cluster metadata initialized in Zookeeper is ready.
[2022-03-24 11:34:27] [8/9][√] Your cluster metadata test is ready. => {"serviceUrl":"http://127.0.0.1:12181:18080","serviceUrlTls":"https://127.0.0.1:12181:18443","brokerServiceUrl":"pulsar://127.0.0.1:12181:16650","brokerServiceUrlTls":"pulsar+ssl://127.0.0.1:12181:16651","brokerClientTlsEnabled":false,"tlsAllowInsecureConnection":false,"brokerClientTlsEnabledWithKeyStore":false,"brokerClientTlsTrustStoreType":"JKS"}
doing start bookie ...
starting bookie, logging to /Users/futeng/workspaces/tmp/tmp/pulsar-pseudo-cluster/pulsar-1/logs/pulsar-bookie-futengdeMac-mini.local.log
Note: Set immediateFlush to true in conf/log4j2.yaml will guarantee the logging event is flushing to disk immediately. The default behavior is switched off due to performance considerations.
doing start bookie ...
starting bookie, logging to /Users/futeng/workspaces/tmp/tmp/pulsar-pseudo-cluster/pulsar-2/logs/pulsar-bookie-futengdeMac-mini.local.log
Note: Set immediateFlush to true in conf/log4j2.yaml will guarantee the logging event is flushing to disk immediately. The default behavior is switched off due to performance considerations.
doing start bookie ...
starting bookie, logging to /Users/futeng/workspaces/tmp/tmp/pulsar-pseudo-cluster/pulsar-3/logs/pulsar-bookie-futengdeMac-mini.local.log
Note: Set immediateFlush to true in conf/log4j2.yaml will guarantee the logging event is flushing to disk immediately. The default behavior is switched off due to performance considerations.
[2022-03-24 11:34:27] [9/9][√] Your bookies is all ready.
doing start broker ...
starting broker, logging to /Users/futeng/workspaces/tmp/tmp/pulsar-pseudo-cluster/pulsar-1/logs/pulsar-broker-futengdeMac-mini.local.log
Note: Set immediateFlush to true in conf/log4j2.yaml will guarantee the logging event is flushing to disk immediately. The default behavior is switched off due to performance considerations.
doing start broker ...
starting broker, logging to /Users/futeng/workspaces/tmp/tmp/pulsar-pseudo-cluster/pulsar-2/logs/pulsar-broker-futengdeMac-mini.local.log
Note: Set immediateFlush to true in conf/log4j2.yaml will guarantee the logging event is flushing to disk immediately. The default behavior is switched off due to performance considerations.
doing start broker ...
starting broker, logging to /Users/futeng/workspaces/tmp/tmp/pulsar-pseudo-cluster/pulsar-3/logs/pulsar-broker-futengdeMac-mini.local.log
Note: Set immediateFlush to true in conf/log4j2.yaml will guarantee the logging event is flushing to disk immediately. The default behavior is switched off due to performance considerations.
[2022-03-24 11:34:27] [ list brokers ] -> pulsar-1/bin/pulsar-admin brokers list pulsar_pseudo_cluster
"127.0.0.1:28080"
"127.0.0.1:18080"
[2022-03-24 11:34:27] [ leader-broker ] -> pulsar-1/bin/pulsar-admin brokers leader-broker
{
  "serviceUrl" : "http://127.0.0.1:18080"
}
[2022-03-24 11:34:27] [ create local cluster ] -> pulsar-1/bin/pulsar-admin clusters create pulsar_pseudo_cluster
[2022-03-24 11:34:27] [ create tenant ] -> pulsar-1/bin/pulsar-admin tenants create t1 -c pulsar_pseudo_cluster
[2022-03-24 11:34:27] [ create tenant/namespaces ] -> pulsar-1/bin/pulsar-admin namespaces create t1/ns1 -c pulsar_pseudo_cluster
[2022-03-24 11:34:27] [ create second cluster ] -> pulsar-1/bin/pulsar-admin clusters create cluster_2
[2022-03-24 11:34:27] [ create second tenant ] -> pulsar-1/bin/pulsar-admin tenants create t2 -c cluster_2
[2022-03-24 11:34:27] [ create second tenant/namespaces ] -> pulsar-1/bin/pulsar-admin namespaces create t2/ns2 -c cluster_2
[2022-03-24 11:34:27] [ list tenants ] -> pulsar-1/bin/pulsar-admin tenants list
"t1"
"t2"
[2022-03-24 11:34:27] [ list tenant's namespaces ] -> pulsar-1/bin/pulsar-admin namespaces list t1
"t1/ns1"
[2022-03-24 11:34:27] [ get tenant's clusters ] -> pulsar-1/bin/pulsar-admin namespaces get-clusters t1/ns1
"pulsar_pseudo_cluster"
[2022-03-24 11:34:27] [pulsar-client produce][√] 10 messages successfully produced
[2022-03-24 11:34:27] [pulsar-client consume][√] 10 messages successfully consumed
 _   _  _     ______        _                    _
| | | |(_)    | ___ \      | |                  | |
| |_| | _     | |_/ /_   _ | | ___   __ _  _ __ | |
|  _  || |    |  __/| | | || |/ __| / _` || '__|| |
| | | || | _  | |   | |_| || |\__ \| (_| || |   |_|
\_| |_/|_|( ) \_|    \__,_||_||___/ \__,_||_|   (_)
          |/

```



## Contant me

Please feel free to contact me:

- ifuteng@gmail.com / ifuteng@qq.com
- WeChart: ifuteng
