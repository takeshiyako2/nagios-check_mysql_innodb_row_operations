# check_mysql_innodb_row_operations.rb

This is Monitoring Script for MYSQL InnoDB Row Operations.


## Usage


1) Init script and instll Ruby mysql2 library
```
$ git clone git@github.com:takeshiyako2/nagios-check_mysql_innodb_row_operations.git
$ cd nagios-check_mysql_innodb_row_operations
$ bundle
```

2) Run script

Choice operation with -o option. 
You can choice with inserts, updates, deletes or reads.
Default operation is reads. 

```
$ ruby check_mysql_innodb_row_operations.rb -H localhost -u username -p xxxx -o reads -w 100000 -c 200000
OK - Current Status is saved. values:{:inserts=>"10000000", :updates=>"10000000", :deletes=>"10000000", :reads=>"10000000", :unixtime=>1424072459}

$ ruby check_mysql_innodb_row_operations.rb -H localhost -u username -p xxxx -o reads -w 100000 -c 200000
OK - reads 12345 Operations per second|OPS=12345
```

3) Remove tmp file for nagios check
```
$ rm /tmp/check_mysql_innodb_row_operations.dat
```

4) Set up Nagios

## Auter

Takeshi Yako

## Licence

MIT

