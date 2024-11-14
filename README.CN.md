# pulsar-pseudo-cluster
One script to (re)deploy Pulsar in pseudo-cluster mode.

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

| HOST \ Apache Pulsar                                    | 2.11.0-SNAPSHOT | 2.10.0 | 2.9.1 | 2.8.2 | 2.7.4 | 2.6.1 |
| ------------------------------------------------------- | --------------- | ------ | ----- | ----- | ----- | ----- |
| CentOS 7.5 + jdk 11                                     | NTY             | √      | √     | √     | √     | √     |
| CentOS 7.5 + jdk1.8                                     | NTY             | √      | √     | √     | √     | √     |
| MacOS 12.2.1 M1 + jdk 1.8                               | NTY             | √      | √     | √     | √     | √     |
| Apple M1 Pro macOS 12.4 <br />+ JDK Corretto-17.0.3.6.1 | √               | NTY    | NTY   | NTY   | NTY   | NTY   |

- NTY: Not tested yet

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

Tips: It's recommend to stop all threads ( `./stop-all.sh` ) before you redeploy (double check).

 ## Full log example

```shell
[2024-11-11 13:03:03][info] ====> Start to (re)deploy the pseudo-cluster of pulsar <====
[2024-11-11 13:03:03][info] [√] Your operating system is supported => macOS
[2024-11-11 13:03:03][info] broker in broker1 has been stopped successfully.
[2024-11-11 13:03:03][info] broker in broker2 has been stopped successfully.
[2024-11-11 13:03:03][info] bookie in bookie1 has been stopped successfully.
[2024-11-11 13:03:03][info] bookie in bookie2 has been stopped successfully.
[2024-11-11 13:03:03][info] bookie in bookie3 has been stopped successfully.
[2024-11-11 13:03:03][info] zookeeper in zk has been stopped successfully.
[2024-11-11 13:03:03][info] Directory 'pulsar_cluster_1' and all its contents have been removed.
[2024-11-11 13:03:03][info] [√] JAVA_HOME is found in /Users/futeng/.sdkman/candidates/java/current
[2024-11-11 13:03:03][info] [√] Detected Java version: 17.0.13 is 17 or greater.
[2024-11-11 13:03:03][info] [√] No port conflicts detected.
[2024-11-11 13:03:03][info] [√] The disk /dev/disk3s1 has sufficient space (70.35 GB available).
[2024-11-11 13:03:03][info] [√] Apache Pulsar binary package is found in the current directory.
[2024-11-11 13:03:03][info] [√] Directory structure initialized under 'pulsar_cluster_1'.
[2024-11-11 13:03:03][info] [√] Pulsar JVM settings adjusted with Heap: 128m, Direct Memory: 256m
[2024-11-11 13:03:03][info] [√] Bookie JVM settings adjusted with Heap: 64m, Direct Memory: 64m
[2024-11-11 13:03:03][info] [√] Zookeeper JVM settings adjusted with Heap: 64m, Direct Memory: 64m
[2024-11-11 13:03:03][info] [√] Pulsar directories has been initialized successfully under path of 'pulsar_cluster_1'.
[2024-11-11 13:03:03][info] [√] Zookeeper started with server port: 12181
[2024-11-11 13:03:03][info] [√] Zookeeper service on 127.0.0.1:12181 is working correctly.
[2024-11-11 13:03:03][info] [√] Pulsar Metadata initialization succeeded: Cluster metadata for 'pulsar_cluster_1' setup correctly.
[2024-11-11 13:03:03][info] [√] Pulsar Metadata initialization succeeded in znode: /pulsar_cluster_1.
[2024-11-11 13:03:03][info] [√] All Bookies have been started.
[2024-11-11 13:03:03][info] [√] All your Bookie nodes has successfully passed the test.
[2024-11-11 13:03:03][info] [√] All Brokers have been started.
[2024-11-11 13:03:03][info] [√] 10 messages successfully produced
[2024-11-11 13:03:03][info] [√] Your Pulsar cluster is ready, enjoy!
[2024-11-11 13:03:03][info] Pulsar Cluster Name: pulsar_cluster_1
[2024-11-11 13:03:03][info] Pulsar Web Service URLs(Admin RESTFul Port, default 8080): http://127.0.0.1:18080,127.0.0.1:18081
[2024-11-11 13:03:03][info] Pulsar Broker Service URLs(Data Port, default 6650): pulsar://127.0.0.1:16650,127.0.0.1:16652
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

- [x] Change logs dir
- [ ] 