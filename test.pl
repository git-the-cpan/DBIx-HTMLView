#!/usr/bin/perl

my $db="DBI:mSQL:HTMLViewTester:athena.af.lu.se:1114";

# This is the db used for testing, if you want to use a local db you
# have to chnage this string to point to it and the db should be 
# ekvivialent to a mSQL db created as follows:

# CREATE TABLE Test (id INT,testf INT)
# CREATE UNIQUE  INDEX idx1 ON Test (id)
# CREATE SEQUENCE ON Test STEP 1 VALUE 1 

# INSERT INTO Test  VALUES (0,7)
# INSERT INTO Test  VALUES (1,42)


BEGIN { $| = 1; print "Compilation 1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

require DBIx::HTMLView::CGIListView;
require DBIx::HTMLView::CGIReqView;

$loaded = 1;
print "ok 1\n";

print "Database 1..1\n(This test will try to connect to a db server on the net, so if you are not connected this will fail and might even hang. Se the source code for info on how to set up a local test db.)\n";

my @tabels = ("Test");
my $script="View.cgi";
my $q=new CGI({});

open (T, ">/tmp/$$.tmp");
*SOUT=*STDOUT;
*STDOUT=*T;

my $v=new DBIx::HTMLView::CGIListView($db, {}, $q, \@tabels);
$v->PrintPage($script);
close(T);
*STDOUT=*SOUT;

$res= <<"EOF";
<html><head><title>DBI Interface</title></head><body>
<h1>Current table: Test</h1>

<form method=POST>
  <b>Change table</b>: 
<input type=submit name=_SetTable   value="Test">
  <p>
</form>
	
<form method=POST>
  <B>SQL</b>: <input name="_Command" VALUE=''>
  <input type=submit name="_Search"  value="Search">
  <input type=hidden name="_Search" value="!">
        <input type=hidden name="_Table" value="Test">
</form>

<hr>
<table>
<tr><td><td>7<td><a href="View.cgi?_Show=1&_Id=0&_Table=Test">Show</a><a href="View.cgi?_Edit=1&_Id=0&_Table=Test">Edit</a><a href="View.cgi?_Delete=1&_Id=0&_Table=Test">Delete</a></tr>
<tr><td><td>42<td><a href="View.cgi?_Show=1&_Id=1&_Table=Test">Show</a><a href="View.cgi?_Edit=1&_Id=1&_Table=Test">Edit</a><a href="View.cgi?_Delete=1&_Id=1&_Table=Test">Delete</a></tr>
</table>
<a href="View.cgi?_New=1&_Id=-1&_Table=Test">New</a>
</body></html>
EOF


open (O, ">/tmp/res");
print O $res;
close (O);


if ($res eq `cat /tmp/$$.tmp`) {
	print "ok 1\n";
} else {
	print "not ok 1\n";
}
#unlink("/tmp/$$.tmp");
