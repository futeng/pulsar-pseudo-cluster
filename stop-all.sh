#!/usr/bin/env bash
# Script to stop all thread related to pulsar pesudo-cluster(PPC).
# More info https://github.com/futeng/pulsar-pseudo-cluster
# Copyright (C) 2022 fu teng (Please feel free to contact me : ifuteng@gmail.com)
# Permission to copy and modify is granted under the Apache 2.0 license
# Last revised 23/3/2022

pulsar-1/bin/pulsar-daemon stop zookeeper
pulsar-2/bin/pulsar-daemon stop zookeeper
pulsar-3/bin/pulsar-daemon stop zookeeper

pulsar-1/bin/pulsar-daemon stop bookie
pulsar-2/bin/pulsar-daemon stop bookie
pulsar-3/bin/pulsar-daemon stop bookie

pulsar-1/bin/pulsar-daemon stop broker
pulsar-2/bin/pulsar-daemon stop broker
pulsar-3/bin/pulsar-daemon stop broker
