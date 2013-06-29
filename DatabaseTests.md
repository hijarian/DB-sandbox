# Running Database Dependent Tests on Ramdisk

Today's guess is this: you have a test harness which utilizes the database, and it has enough test cases in it for full test run to be so slow you cringe at the very thought of launching it.

We discuss a lifehack-style solution to this problem: putting the DBMS which will be used by our test harness *completely on a [RAM disk](https://en.wikipedia.org/wiki/RAM_drive)*, so it'll operate from much faster memory than the hard drive (even faster than from SSD).

Main issue is this: as you probably need only a test datasets at ramdisk, and only for a period of running test suite, you will need *separate* DBMS instances to work on ramdisk, not the ones already installed on your system.

Here we'll look at how to prepare [MySQL](https://www.mysql.com/) and [MongoDB](http://www.mongodb.org/) instances to work on ramdisk.

## End Result

In the end you'll get the special preparation script which you should launch before your tests.
After this, your test suite will run with the isolated MySQL and MongoDB instances on top of ramdisk.

If your test suite has large quantities of integration tests using databases, this will greatly increase the speed of test run. It is reported in one particular case that the drop in run time was from 1:30 to 18 seconds, 5 times faster.

## Prequisites

You should have a *nix system as a MySQL Sandbox (see below) works only there. OSX probably will do, too.
This system should have some bash-like shell (obviously) and Perl installed.
Kernel should have [`tmpfs`](https://www.kernel.org/doc/Documentation/filesystems/tmpfs.txt) support. 
Your nonprivileged user should be able to mount filesystems, or you'll need to hack the script to introduce `sudo` at mount step (assuming your user can sudo).

For isolated MySQL instance you need the [MySQL distirbutive downloaded from the website](https://dev.mysql.com/downloads/mysql/).
For isolated MongoDB instance you need the [MongoDB distirbutive downloaded from the website](http://www.mongodb.org/downloads). Note, however, that the whole MongoDB server is contained in just a single binary file ~8MB in size.

Of course as we will work completely in memory you have to be sure that you have enough RAM to store your (presumably test) datasets. 

## Ramdisk

Making ramdisk is very simple with latest Linux:

    mount -t tmpfs $RAMDISK_NAME $RAMDISK_DIR

as root.

`RAMDISK_NAME` is some identifier for mountpoints table.
`RAMDISK_DIR` is the directory which will be turned into RAM-based filesystem.

After this `mount` action, anything you put into `RAMDISK_DIR` will be placed into memory, without interaction with the physical hard drive.

Of course, it means that *after unmounting the ramdisk everything which was in it will be lost*.

### Shutting down the ramdisk

Just unmount the created mount point:

    umount $RAMDISK_NAME
    
as root.

Note that you probably should stop all running services which still use the ramdisk prior to unmounting!

## Isolated MySQL instance

We'll use the [MySQL Sandbox](http://mysqlsandbox.net/) project to launch isolated MySQL instances.

For it to work you need the [MySQL distirbutive downloaded from the website](https://dev.mysql.com/downloads/mysql/).

MySQL Sandbox is installed with the following command:

    # cpan MySQL::Sandbox

as root, and you'll need to run it as follows:


    SANDBOX_HOME="$RAMDISK_DIR" make_sandbox "$MYSQL_PACKAGE" -- \
      --sandbox_port="$MYSQL_PORT_DESIRED" --sandbox_directory="$MYSQL_DIRNAME"

It's a one-liner split to two lines for readability.

Note that you need root privileges only to *install* the MySQL Sandbox application itself, all further communication with it will be done from unprivileged account, most possibly the same under which you launch the test suite.

We need to set the `SANDBOX_HOME` variable prior to launching the sandbox factory because that's how we control where it'll put the sandboxed MySQL instance. By default it'll use `$HOME/sandboxes`, which is probably not what you need.
Note that `RAMDISK_DIR` is the same directory that the one we prepared in previous step.

`MYSQL_PACKAGE` is a full path to the MySQL distirbutive package downloaded from website.
Please note that MySQL Sandbox *will unpack it to the same directory* and will essentially use this unpacked contents to launch the sandboxed MySQL.
So, probably, you'll need to move the package to ramdisk, too, to increase performance of actually launching and running the MySQL server itself, however, note that unpacked 5.6.0 contents are 1GB in size.

Remember the `MYSQL_PORT_DESIRED` value you use here, because you'll need to use it to configure your test suite to point at correct MySQL instance.

`MYSQL_DIRNAME` is of least importance here, because it's just a name of a subfolder under the `SANDBOX_HOME` in which this particular sandbox will be put.

After `make_sandbox` ended it's routine you can check that your sandbox is indeed working by running:

    "$RAMDISK_DIR/$MYSQL_DIRNAME/use"
    
### Connection to Isolated MySQL Instance

You should use the following credentials to connect to sandboxed MySQL:

    * host     : '127.0.0.1'
    * port     : $MYSQL_PORT_DESIRED
    * username : 'msandbox'
    * password : 'msandbox'

Please note that you must use `127.0.0.1` value for host and not a `localhost` as usual, because of sandbox internal security configuration.

### Shutting Down the Isolated MySQL Instance

To shutdown the sandboxed MySQL, issue the following command:

    "$RAMDISK_DIR/$MYSQL_DIRNAME/stop"

or more forceful

    "$RAMDISK_DIR/$MYSQL_DIRNAME/send_kill"

This commands are needed mostly to stop the working daemon; after the unmounting of ramdisk all of sandbox data will be purged out of existence.

## Isolated MongoDB instance

MongoDB server is contained in just a single binary file so it'll be a lot more easier compared to MySQL.

You'll need the [MongoDB distirbutive downloaded from the website](http://www.mongodb.org/downloads), too.
This time unpack it to some directory.

After that, you can launch a separate instance of MongoDB with the following command:

    "$MONGODB_BIN" --dbpath="$MONGODB_DIR" \
      --pidfilepath="$MONGODB_DIR/mongodb.pid \
      --port $MONGODB_PORT_DESIRED \
      --fork --logpath="$MONGODB_DIR/mongodb.log"

`MONGODB_BIN` is a `/bin/mongod` path preceded by the full path to the unpacked MongoDB distributive.
Here you can even use your system MongoDB package, in case you have it installed.
As a full example, `MONGODB_BIN` can have a value of `~/systems/mongodb-linux-x86_64-2.4.4/bin/mongod`

`MONGODB_DIR` is a path to directory under `RAMDISK_DIR` to which this MongoDB instance should put it's files.
For example, it can be just a `$RAMDISK_DIR/mongo`.

As with MySQL, `MONGODB_PORT_DESIRED` is a crucial parameter to specify the correct MongoDB instance to connect to.
Remember it as you will need to set it up in your test suite.

### Connecting to Isolated MongoDB Instance

By default MongoDB do not enforce any usernames or passwords so you need to just use the hostname and port parameters.

    * host : 'localhost'
    * port : $MONGODB_PORT_DESIRED
    
For example, for PHP Mongo extension, you get a connection to this instance as follows:

    $connection = new MongoClient("mongodb://localhost:$MONGODB_PORT_DESIRED");

### Shutting Down the Isolated MongoDB Instance

As you provided the `--pidfilepath` commandline argument when launching the MongoDB server, the following command should do the trick:

    cat "$MONGODB_DIR/mongodb.pid" | xargs kill ; rm "$MONGODB_DIR/mongob.pid"
    
Essentially we are feeding the `kill` command with the contents of pidfile and removing it afterwards.
    

