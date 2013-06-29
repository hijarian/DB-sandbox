#!/bin/sh

# This is the environment-dependent parameters for DB sandbox script.

# Where to mount the RAM disk
RAMDISK_DIR=~/disk

# Where the downloaded package with MySQL installation is placed
MYSQL_PACKAGE=~/Загрузки/mysql-5.6.12-linux-glibc2.5-x86_64.tar.gz

# Name of the subdirectory under $RAMDISK_DIR where the mysql datasets will be sandboxed
MYSQL_DIRNAME=mysql

# Desired port number for MySQL
MYSQL_PORT_DESIRED=5612

# Directory where the MongoDB binaries lie
MONGODB_BINDIR=~/systems/mongodb-linux-x86_64-2.4.4/bin

# Name of the subdirectory under $RAMDISK_DIR where the mongodb datasets will be sandboxed
MONGODB_DIR="$RAMDISK_DIR"/mongo

# Desired port number for MongoDB
MONGODB_PORT_DESIRED=12345

## The following is needed to sync the test dataset schema from MySQL with the production one.

# Name of the DB to create at a new sandbox
DBNAME=pdecor_test

# Connection parameters for source MySQL DB.
SOURCE_DB_USER=pdecor_dumper
SOURCE_DB_PASSWORD=
SOURCE_DB_HOST=pdecor.local
SOURCE_DB_PORT=
SOURCE_DB_NAME=pdecor_private
