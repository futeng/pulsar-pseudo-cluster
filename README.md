# pulsar-pseudo-cluster
Script to deploy pulsar in pseudo-cluster (simply as PPC).

## Test cross

| HOST\Apache Pulsar   | 2.9.1          | 2.8.2 | 2.6.1 |
| -------------------- | -------------- | ----- | ----- |
| CentOS 7.5 + JDK1.8  | probably *[1]* |       |       |
| CentOS 7.5 + JDK11   | √              |       |       |
| MacMini M1 + JDK 1.8 | √              |       |       |

- [1] Not recomend, sometimes get error: `Error occurred during initialization of VM. Could not create ConcurrentG1RefineThread`

## How to use

```shell
# clone this repo
$ git clone https://github.com/futeng/pulsar-pseudo-cluster.git
$ cd pulsar-pseudo-cluster/

# download apache-pulsar tarball (keep in same directory)
# for example take version of 2.9.1
$ wget https://dlcdn.apache.org/pulsar/pulsar-2.9.1/apache-pulsar-2.9.1-bin.tar.gz --no-check-certificate

# simply run the script deploy.sh
$ sh deploy.sh
```

 
