package config;

use DBIx::HTMLView;

# This is the db description, the first argument to DB is the DBI
# specifikation of you database, while the second and the third is the
# username and password.

# mySQL is the sugested database engine, using it the test script
# takes less than half the time of what it needs using mSQL. mySQL can
# be found at http://www.mysql.org/. To set up a test database using
# an installed mysql server you simply:
#
#   mysqladmin create HTMLViewTester
#
# Then to make it accessable by everyone type:
#
#   mysql -e "insert into db values ('localhost','HTMLViewTester','','y'\
#   ,'y','y','y','y','y','y','y','y','y')" mysql
#
# Now uncomment the top return line below specifying a mysql DBD, and
# comment out the one below specifying msql.

# If you have mSQL installed setting up a local db for the test is
# simple. Just start msqlconfig, and the press the following keys:
#
#   D (Database configuration)
#   n (to create a new databse)
#   HTMLViewTester (to name the newly created database HTMLViewTester)
#   r (to set the read premitions)
#     (the name of the user you'll be running the tests as)
#   w (to set the write premitions)
#     (the name of the user you'll be running the tests as)
#   a (to set the access methods allowed)
#   local (to allow loacl accesses only)
#
# Now the new database is set up properly, press q, w, q, to return to
# the main menu, write the configuration to the disk and exit
# msqconfig. Now cahnge the DBI specifikation string (1a argument)
# below to "DBI:mSQL:HTMLViewTester" (eg remove
# ":hobbe.ub2.lu.se:1114").
#
# And that's it, not the test program as well as the example cgi
# scripts will use your local db instead of the central one.

sub dbi {
	my ($usr, $pw)=@_;
	return mysqlDB("DBI:mysql:HTMLViewTester", $usr, $pw, 
#  return msqlDB("DBI:mSQL:HTMLViewTester:hobbe.ub2.lu.se:1114", "", "", 
						Table('Test', Id('id'), Int('testf')),
						Table('Test2', Id('id'), Str('str'), Int('nr'), 
									N2N('Lnk',{tab=>'Test',view=>'$testf'})),
						Table('Test3', Id('id'), Bool('b1'), 
									Bool('b2', {true=>1,false=>0,
															view_true=>'Sure', view_false=>'No way'}),
									Str('s', {edit_size=>20, sql_size=>20})
								 )
					 );
}
1;
