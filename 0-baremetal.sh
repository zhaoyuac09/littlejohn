#!/bin/bash
# This script is run on the bare metal. Needs admin privileges, though.
if [ "$(whoami)" != "root" ]; then
    echo "Must be run with sudo."
    exit 1
fi

# Step 0: Let's define some variables.
HADOOP_VERSION=2.7.0
HADOOP_PREFIX=/opt/hadoop

MESOS_VERSION=0.22.1
MESOS_PREFIX=/opt/mesos

SPARK_VERSION 1.4.0-bin-hadoop2.6
SPARK_PREFIX /opt/spark

# Step 1: Perform the apt updates and install Docker.
apt-get -y update
apt-get -y install build-essential wget openjdk-7-jdk python-dev python-boto \
    libcurl4-nss-dev libsasl2-dev maven libapr1-dev libsvn-dev openssh-server \
    rsync
wget -qO- https://get.docker.com/ | sh

# Step 2: Install the various configuration files and environment variables:
# - /etc/hosts
# - bashrc
# - Potentially SSH configuration later, if needed
cp config/etc/hosts /etc/
cp config/bashrc.sh ~/.bashrc

# Step 3: Install Hadoop. We're not strictly using Hadoop MapReduce so much
# as HDFS; this is where we store the data long-term. Containers are just
# for ephemeral analysis. Which means we also need to configure Hadoop.
wget http://mirrors.sonic.net/apache/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
tar zxvf hadoop-$HADOOP_VERSION.tar.gz
rm hadoop-$HADOOP_VERSION.tar.gz
mv hadoop-$HADOOP_VERSION $HADOOP_PREFIX
cp config/hadoop/etc/hadoop/* $HADOOP_PREFIX/etc/hadoop/  # Copy the config files over.

# Step 4: Install Spark.
# (yeah I know, install Spark on metal to run Spark in Docker. Talk to the
# Mesos guys about that one; I don't code up these ridiculous requirements.)
wget http://d3kbcqa49mib13.cloudfront.net/spark-$SPARK_VERSION.tgz && \
    tar zxvf spark-$SPARK_VERSION.tgz && rm spark-$SPARK_VERSION.tgz
mv spark-$SPARK_VERSION $SPARK_PREFIX
cp config/spark/conf/* $SPARK_PREFIX/conf/

# Step 4: Install Mesos.
wget http://www.apache.org/dist/mesos/$MESOS_VERSION/mesos-$MESOS_VERSION.tar.gz
tar zxvf mesos-$MESOS_VERSION.tar.gz
rm mesos-$MESOS_VERSION.tar.gz
mkdir mesos-$MESOS_VERSION/build

cd mesos-$MESOS_VERSION/build
../configure --prefix=$MESOS_PREFIX
make -j && make check && make install
cd -
cp -r config/mesos/var/ $MESOS_PREFIX/

# Step 3: Pull down the Docker image and get to work.
