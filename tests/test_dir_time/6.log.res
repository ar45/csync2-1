cmd u "New dir timestamp (update)" local
Reading symbols from shared library libmysqlclient.so
Connecting to host peer (PLAIN) ...
CONN local> CONFIG 

CONN local> HELLO local

Updating 'peer:/export/home/dennis/Projects/csync2/csync2/tests/test/local' mark ''
CONN local> SIG %25test%25 user/group 1000 1000 dennis schafroth 16877 
Updating 'peer:/export/home/dennis/Projects/csync2/csync2/tests/test/local/usr' mark ''
CONN local> SIG %25test%25/usr user/group 1000 1000 dennis schafroth 16877 
Updating 'peer:/export/home/dennis/Projects/csync2/csync2/tests/test/local/usr/local' mark ''
CONN local> SIG %25test%25/usr/local user/group 1000 1000 dennis schafroth 16877 
?M: peer            /export/home/dennis/Projects/csync2/csync2/tests/test/local/usr/local
CONN local> MKDIR %25test%25/usr/local - 1000 1000 dennis schafroth 16877 
Updating 'peer:/export/home/dennis/Projects/csync2/csync2/tests/test/local/usr/local/sbin' mark ''
CONN local> SIG %25test%25/usr/local/sbin user/group 1000 1000 dennis schafroth 16877 
CONN local> SETTIME %25test%25/usr/local 
CONN local> SETTIME %25test%25/usr 
CONN local> SETTIME %25test%25 
CONN local> BYE

Finished succesfully.