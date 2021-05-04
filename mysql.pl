#!/usr/bin/perl

# build a data dictionary from a given mysql database
# and pretty print out a simple html on stdout


# MIT License
# Copyright (c) 2021 Joerg Kost <jk@ip-clear.de>

####### Configuration
my $host   = "localhost";
my $user   = "root";
my $pass   = "";
my $dbname = "datamart";
#####################

use strict;
use warnings FATAL => 'all';
use DBI;

sub html_end();
sub html_header();
sub print_sql_infos();

my @tables;            # to have a sorted list
my %tables_comment;    # to have the comments ready

my $dbh = DBI->connect( "DBI:mysql:$dbname;$host", "$user", "$pass");

html_header();
print_sql_infos();
html_end();

$dbh->disconnect();

sub print_sql_infos() {
    my $sth = $dbh->prepare(
        'SELECT TABLE_NAME, TABLE_COMMENT from information_schema.tables where table_schema = ? order by TABLE_NAME;'
    );
    $sth->execute($dbname);

    while ( my @row = $sth->fetchrow() ) {
        push( @tables, $row[0] );
        $tables_comment{ $row[0] } = $row[1];
    }
    $sth->finish;

    my %tc_mapping;

    for my $table (@tables) {
        print qq ~\n\n<table id ="$table" class="tableiu">
    <caption>$table (<i>$tables_comment{$table}</i>)</caption>
    <thead><tr>
        <th>NAME</th><th>IS_KEY</th><th>DEFAULT</th><th>CAN_BE_NULL</th><th>PRECISION</th><th>SCALE</th>
        <th>TYPE</th><th>COMMENT</th><th>REF TABLE:COLUMN</th>
    </tr></thead>\n~;

        # Select foreign keys
        $sth = $dbh->prepare(
            qq~SELECT COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME FROM
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE where TABLE_SCHEMA = ?  and REFERENCED_TABLE_NAME IS NOT NULL and TABLE_NAME = ?~
        );
        $sth->execute( $dbname, $table );
        while ( my @row = $sth->fetchrow() ) {
            $tc_mapping{"$table:$row[0]"} = "$row[1]:$row[2]";
        }
        $sth->finish;

        # Select all columns
        $sth = $dbh->prepare(
            qq~SELECT COLUMN_NAME, COLUMN_KEY, COLUMN_DEFAULT, IS_NULLABLE, NUMERIC_PRECISION, NUMERIC_SCALE, COLUMN_TYPE, EXTRA,
    COLUMN_COMMENT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? order by COLUMN_KEY desc, COLUMN_NAME~
        );
        $sth->execute($table);

        print "<tbody>\n";
        while ( my @row = $sth->fetchrow() ) {

            # Body body lady
            print "<tr>\n";
            my $cnum = 0;

            foreach my $c (@row) {

                # Ignore extra column as discrete
                if($cnum == 7) {
                    $cnum++;
                    next;
                }

                if ( defined($c) ) {
                    # make some magic
                    if ( $c eq 'PRI' ) {
                        $c = 'PRIMARY';
                        if($row[7] eq 'auto_increment') {
                            $row[2] .= ' auto_increment';
                        }
                    }
                    elsif ( $c eq 'MUL' ) {
                        $c = 'FOREIGN';
                    }
                    elsif ( $c eq 'UNI' ) {
                        $c = 'UNIQUE';
                    }
                    print "<td>$c</td>\n";
                } else {
                    print "<td></td>\n";
                }
                $cnum++;
            }

            # Mapping left as foreign key?
            if ( $tc_mapping{"$table:$row[0]"} ) {

                # Construct backlink
                my $bhref = $tc_mapping{"$table:$row[0]"};
                $bhref =~ s/:.*//ig;
                print
                    qq ~<td><a href="#$bhref">$tc_mapping{"$table:$row[0]"}</td>\n~;

            }
            else {
                print "<td></td>\n";
            }
            print "</tr>\n";
        }
        print("</tbody></table>\n\n");
        $sth->finish;
    }
}

sub html_end() {
    print qq ~</body></html>~;
}

sub html_header() {
    print qq~
<html>
    <meta charset="utf-8">
    <title>Data dictionary for $dbname</title>
    <style>
        .tableiu { width: 90%; font-size: 0.8em; font-family: sans-serif; margin: 25px 20px; border-collapse: collapse; box-shadow: 5 5 20px rgba(179, 156, 156, 0.15);}
        .tableiu thead tr { background-color: #009879; color: #ffffff; text-align: center; border-top: 1px solid #000000; }
        .tableiu th, .tableiu td { padding: 10px 12px; border-left: 1px solid #000; border-right: 1px solid #000;}
        .tableiu tbody tr {border-bottom: 1px solid #000000;}
        .tableiu caption { font-size: 120%;}
        .tableiu tbody tr:nth-of-type(even) { background-color: #f4f0f3; }
        .tableiu tbody tr:last-of-type  {border-bottom: 2px solid #008871;}
    </style>
    <body><h1  style="text-align:center">Database $dbname</h1>
    ~;
}
