#### MySQL data dictionary generator

This script will generate a data dictionary from a given MySQL database and will save 
it to HTML with tables. I have written this script because other solutions are 
pretty much broken or have too many dependencies.

If you don't have a Perl interpreter running, try to install it. For example, under Debian:
"apt-get install libclass-dbi-mysql-perl perl".

To use this script, configure your database settings in the configuration stanza on the first few lines in the mysql.pl - file, then run it with your perl interpreter. The 
output will be on stdout and can be redirected to a file.