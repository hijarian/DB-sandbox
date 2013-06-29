#!/bin/sh

. ./db_sandbox_properties.sh

"$RAMDISK_DIR/$MYSQL_DIRNAME/stop"
kill `cat "$MONGODB_DIR/mongodb.pid"` ; rm "$MONGODB_DIR/mongob.pid"
sudo umount ramdisk
