#!/bin/sh

# Loading of the properties
. ./db_sandbox_properties.sh

# do not change the following vars; they are dependent on the structure of mysql and mongodb apps.
MYSQL_CLIENT="$RAMDISK_DIR/$MYSQL_DIRNAME/use"
MONGODB_BIN="$MONGODB_BINDIR/mongod"

# Mount ramdisk <https://www.kernel.org/doc/Documentation/filesystems/tmpfs.txt>
sudo mount -t tmpfs ramdisk $RAMDISK_DIR

# Launch MySQL in sandbox <http://mysqlsandbox.net/>
SANDBOX_HOME="$RAMDISK_DIR" make_sandbox "$MYSQL_PACKAGE" -- \
  --sandbox_port="$MYSQL_PORT_DESIRED" --sandbox_directory="$MYSQL_DIRNAME"

# Create a database for tests
$MYSQL_CLIENT --exec "create database $DBNAME default charset utf8 collate utf8_unicode_ci"

# Migrate database schema from existing working server
mysqldump -d --compress \
	--user="$SOURCE_DB_USER" --password="$SOURCE_DB_PASSWORD" \
	--host="$SOURCE_DB_HOST" --port="$SOURCE_DB_PORT" \
  "$SOURCE_DB_NAME" \
| $MYSQL_CLIENT --database="$DBNAME" --compress

# Launching a mongodb instance
mkdir "$MONGODB_DIR"
"$MONGODB_BIN" --dbpath="$MONGODB_DIR" \
  --pidfilepath="$MONGODB_DIR/mongodb.pid" \
  --port $MONGODB_PORT_DESIRED \
  --fork --logpath="$MONGODB_DIR/mongodb.log"
