#!/usr/bin/perl

# This script will use the db defined in config.pm for testing, if you
# want to use a local db you have to change that file to point to it
# (that file contains instructions on how to set up one using msql). This
# db does not need to have any tables defined as the tables will be
# created as one of the first things below.

# Note the test here presumes id numbers are assigned in the order the
# posts are added starting from 0

BEGIN { $| = 1; print "Compilation 1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use DBIx::HTMLView;
use Data::Dumper;

$loaded = 1;
print "ok 1\n";

$tot_ok=1;
$tot_fail=0;

print "\nNOTE: Those test are done against a central db server,so without inet\nacces they will probably fail. See the test.pl on how to specify the\nuse of a local db.\n";

print "\nDatabase set up and construction\n";
$test_cnt=0;

# Set up the database structure
use config;
my $dbi=config::dbi;

test($dbi->isa('DBIx::HTMLView::DB'));

# Clear out the database table to make sure we'll do a fresh start
# FIXME: Prevent those drop commands from generating error out if
#        there is no table
print "Sending drop table commands to the database, this will generate error\n";
print "reports if they do not exist, don't worry about that.\n";
eval {$dbi->send("drop table Test");};
eval {$dbi->send("drop table Test2");};
eval {$dbi->send("drop table Test2_to_Test");};

# The db in the SQL server is now empty, so let's create the tables
$dbi->sql_create;

print "\nClean db tests\n";
$test_cnt=0;
# We start with these tests as they operates on empty tables. Basic
# functions is tested below.

require DBIx::HTMLView::CGIListView;
# Generate the ListView's page on an empty table
$v=new DBIx::HTMLView::CGIListView("View.cgi", $dbi, new CGI({}));
$v->extra_sql("order by id"); # Sort by id to simplify check
$v->restrict_tabs(['Test']);   # Show only one Table, to simplify check
test($v->view_html eq '<h1>Current table: Test</h1>

<b>Change table</b>: 
<form method=POST action="View.cgi"><input type=submit name=_Table value="Test"></form><p>
<form method=POST action="View.cgi">
  <B>Search</b>: <input name="_Command" VALUE="">
	<input type=hidden name="_Action"  value="search">
  <input type=submit value="Search">
<input type=hidden name="_Table" value="Test"></from><hr><table><p><i>Empty</i></p><a href="View.cgi?_Action=add&_Table=Test">Add</a> ');

print "\nBasic database functions\n";
$test_cnt=0;

# Add a post
my $post=$dbi->tab('Test')->new_post;
$post->set('testf', 6);
$post->update;

# List the contents of the database
my $tab=$dbi->tab('Test');
my $hits=$tab->list();
test($hits->view_text eq "id: 0\ntestf: 6\n\n");

# Change the value of testf to 7
$post->set('testf', 7);
$post->update;

# List the contents of the database
test($tab->list()->view_text eq "id: 0\ntestf: 7\n\n");

# Add two more post to have something more to test with 
$post=$dbi->tab('Test')->new_post;
$post->set('testf', 42);
$post->update;

$post=$dbi->tab('Test')->new_post;
$post->set('testf', 13);
$post->update;


# List the contents of the database sorted by the id field
$hits=$tab->list(undef,"order by id");
test($hits->view_text eq "id: 0\ntestf: 7\n\nid: 1\ntestf: 42\n\nid: 2\ntestf: 13\n\n");

# List the contents of the database sorted by the id field view in html
$hits=$tab->list(undef,"order by id");
test ($hits->view_html eq '<table><tr><th>id</th><th>testf</th></tr><tr><td>0</td><td>7</td></tr><tr><td>1</td><td>42</td></tr><tr><td>2</td><td>13</td></tr></table>');

# List all posts where the testf field is greater than 8 sorted by id
$hits=$tab->list("testf>8","order by id");
test($hits->view_text eq "id: 1\ntestf: 42\n\nid: 2\ntestf: 13\n\n");

# List all posts where the testf field is greater than 8 sorted by testf
$hits=$tab->list("testf>8", "order by testf");
test($hits->view_text eq "id: 2\ntestf: 13\n\nid: 1\ntestf: 42\n\n");


# Delete a post
$tab->del(2);

# List the table to check the result
$hits=$tab->list(undef,"order by id");
test($hits->view_text eq "id: 0\ntestf: 7\n\nid: 1\ntestf: 42\n\n");

# Readd post for future test (now with new id)
$post=$dbi->tab('Test')->new_post;
$post->set('testf', 13);
$post->update;

print "\nRelations\n";
$test_cnt=0;

# Add a post to Test2 related to 7 and 42 in Test
my $tab2=$dbi->tab('Test2');
my $post1=$tab2->new_post;
$post1->set('str', 'A test post');
$post1->set('Lnk', [0,1]);
$post1->update;

# List table to check result
test($tab2->list->view_text eq 
		 "id: 0\nstr: A test post\nnr: \nLnk: 7, 42\n\n");

# Add a post to Test2 related to 13 and 42 in Test
my $post2=$tab2->new_post;
$post2->set('str', 'Another test post');
$post2->set('Lnk', [1,3]);
$post2->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: \nLnk: 7, 42\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: 42, 13\n\n");

# Add a post to Test2 with no relations
my $post3=$tab2->new_post;
$post3->set('nr', 7);
$post3->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: \nLnk: 7, 42\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: 42, 13\n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: \n\n");

# Update post 1 to only be related to 7
$post1->set('Lnk', [0]);
$post1->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: \nLnk: 7\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: 42, 13\n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: \n\n");

# Update post 3 to only be related to 7, 13, 42
$post3->set('Lnk', [0,1,3]);
$post3->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: \nLnk: 7\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: 42, 13\n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: 7, 42, 13\n\n");

# Update post 2 to have no relations
$post2->set('Lnk', []);
$post2->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: \nLnk: 7\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: 7, 42, 13\n\n");

print "\nCGIView interface tests\n";
$test_cnt=0;

# Bring up the CGIReqEdit editor with the post with id 0
require DBIx::HTMLView::CGIReqEdit;
$post=$dbi->tab("Test")->get(0);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
my $html=$v->view_html;
test($html eq '<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>0<input type=hidden name="id" value="0"></td></tr><tr><td valign=top><b>testf </b></td><td><input name="testf" value="7" size=20></td></tr></table><input type=hidden name="_Table" value="Test"></dl><input type=submit value=OK></from>');

# Fake a CGI response changing the testf field to 8
my $q=new CGI({'id'=>0, 'testf'=>8, '_Table'=>'Test', '_Action'=>'update'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List the table to check the result
$hits=$tab->list(undef,"order by id");
test($hits->view_text eq "id: 0\ntestf: 8\n\nid: 1\ntestf: 42\n\nid: 3\ntestf: 13\n\n");

# Bring up the CGIReqEdit editor with the post with a blank post
$post=$dbi->tab("Test")->new_post();
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);	
$html=$v->view_html;
test($html eq '<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td></td></tr><tr><td valign=top><b>testf </b></td><td><input name="testf" value="" size=20></td></tr></table><input type=hidden name="_Table" value="Test"></dl><input type=submit value=OK></from>');

# Fake a CGI response adding a new post with testf 77
$q=new CGI({'testf'=>77, '_Table'=>'Test', '_Action'=>'update'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List the table to check the result
$hits=$tab->list(undef,"order by id");
test($hits->view_text eq "id: 0\ntestf: 8\n\nid: 1\ntestf: 42\n\nid: 3\ntestf: 13\n\nid: 4\ntestf: 77\n\n");
                          

# Generate the ListView's default page
use CGI;
my $v=new DBIx::HTMLView::CGIListView("View.cgi", $dbi, new CGI({}));
$v->extra_sql("order by id"); # Sort by id to simplify check
$v->restrict_tabs(['Test']);   # Show only one Table, to simplify check
test($v->view_html eq '<h1>Current table: Test</h1>

<b>Change table</b>: 
<form method=POST action="View.cgi"><input type=submit name=_Table value="Test"></form><p>
<form method=POST action="View.cgi">
  <B>Search</b>: <input name="_Command" VALUE="">
	<input type=hidden name="_Action"  value="search">
  <input type=submit value="Search">
<input type=hidden name="_Table" value="Test"></from><hr><table><tr><th>id</th><th>testf</th></tr><tr><td>0</td><td>8</td><td><a href="View.cgi?_id=0&_Action=show&_Table=Test">Show</a> <a href="View.cgi?_id=0&_Action=edit&_Table=Test">Edit</a> <a href="View.cgi?_id=0&_Action=delete&_Table=Test">Delete</a> </td></tr><tr><td>1</td><td>42</td><td><a href="View.cgi?_id=1&_Action=show&_Table=Test">Show</a> <a href="View.cgi?_id=1&_Action=edit&_Table=Test">Edit</a> <a href="View.cgi?_id=1&_Action=delete&_Table=Test">Delete</a> </td></tr><tr><td>3</td><td>13</td><td><a href="View.cgi?_id=3&_Action=show&_Table=Test">Show</a> <a href="View.cgi?_id=3&_Action=edit&_Table=Test">Edit</a> <a href="View.cgi?_id=3&_Action=delete&_Table=Test">Delete</a> </td></tr><tr><td>4</td><td>77</td><td><a href="View.cgi?_id=4&_Action=show&_Table=Test">Show</a> <a href="View.cgi?_id=4&_Action=edit&_Table=Test">Edit</a> <a href="View.cgi?_id=4&_Action=delete&_Table=Test">Delete</a> </td></tr></table><a href="View.cgi?_Action=add&_Table=Test">Add</a> ');

# Generate the ListView's page on Test2
$v=new DBIx::HTMLView::CGIListView("View.cgi", $dbi, 
																	 new CGI({'_Table'=>'Test2'}));
$v->extra_sql("order by id"); # Sort by id to simplify check
$v->restrict_tabs(['Test2']);   # Show only one Table, to simplify check
test ($v->view_html eq '<h1>Current table: Test2</h1>

<b>Change table</b>: 
<form method=POST action="View.cgi"><input type=submit name=_Table value="Test2"></form><p>
<form method=POST action="View.cgi">
  <B>Search</b>: <input name="_Command" VALUE="">
	<input type=hidden name="_Action"  value="search">
  <input type=submit value="Search">
<input type=hidden name="_Table" value="Test2"></from><hr><table><tr><th>id</th><th>str</th><th>nr</th><th>Lnk</th></tr><tr><td>0</td><td>A test post</td><td></td><td>8</td><td><a href="View.cgi?_id=0&_Action=show&_Table=Test2">Show</a> <a href="View.cgi?_id=0&_Action=edit&_Table=Test2">Edit</a> <a href="View.cgi?_id=0&_Action=delete&_Table=Test2">Delete</a> </td></tr><tr><td>1</td><td>Another test post</td><td></td><td></td><td><a href="View.cgi?_id=1&_Action=show&_Table=Test2">Show</a> <a href="View.cgi?_id=1&_Action=edit&_Table=Test2">Edit</a> <a href="View.cgi?_id=1&_Action=delete&_Table=Test2">Delete</a> </td></tr><tr><td>2</td><td></td><td>7</td><td>8, 42, 13</td><td><a href="View.cgi?_id=2&_Action=show&_Table=Test2">Show</a> <a href="View.cgi?_id=2&_Action=edit&_Table=Test2">Edit</a> <a href="View.cgi?_id=2&_Action=delete&_Table=Test2">Delete</a> </td></tr></table><a href="View.cgi?_Action=add&_Table=Test2">Add</a> ');


# Bring up the CGIReqEdit editor with the post with id 0
require DBIx::HTMLView::CGIReqEdit;
$post=$tab2->get(0);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
test ($v->view_html eq '<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>0<input type=hidden name="id" value="0"></td></tr><tr><td valign=top><b>str </b></td><td><input name="str" value="A test post" size=20></td></tr><tr><td valign=top><b>nr </b></td><td><input name="nr" value="" size=20></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=checkbox name="Lnk" value=0 checked> 8<br><input type=checkbox name="Lnk" value=1 > 42<br><input type=checkbox name="Lnk" value=3 > 13<br><input type=checkbox name="Lnk" value=4 > 77<br><input type=hidden name="Lnk" value=do_edit></td></tr></table><input type=hidden name="_Table" value="Test2"></dl><input type=submit value=OK></from>');

# Bring up the CGIReqEdit editor with the post with id 1
require DBIx::HTMLView::CGIReqEdit;
$post=$tab2->get(1);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
test ($v->view_html eq '<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>1<input type=hidden name="id" value="1"></td></tr><tr><td valign=top><b>str </b></td><td><input name="str" value="Another test post" size=20></td></tr><tr><td valign=top><b>nr </b></td><td><input name="nr" value="" size=20></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=checkbox name="Lnk" value=0 > 8<br><input type=checkbox name="Lnk" value=1 > 42<br><input type=checkbox name="Lnk" value=3 > 13<br><input type=checkbox name="Lnk" value=4 > 77<br><input type=hidden name="Lnk" value=do_edit></td></tr></table><input type=hidden name="_Table" value="Test2"></dl><input type=submit value=OK></from>');

# Bring up the CGIReqEdit editor with the post with id 2
require DBIx::HTMLView::CGIReqEdit;
$post=$tab2->get(2);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
test ($v->view_html eq '<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>2<input type=hidden name="id" value="2"></td></tr><tr><td valign=top><b>str </b></td><td><input name="str" value="" size=20></td></tr><tr><td valign=top><b>nr </b></td><td><input name="nr" value="7" size=20></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=checkbox name="Lnk" value=0 checked> 8<br><input type=checkbox name="Lnk" value=1 checked> 42<br><input type=checkbox name="Lnk" value=3 checked> 13<br><input type=checkbox name="Lnk" value=4 > 77<br><input type=hidden name="Lnk" value=do_edit></td></tr></table><input type=hidden name="_Table" value="Test2"></dl><input type=submit value=OK></from>');

# Fake a CGI response make post with id 0 related to 42, 13 and with
# nr set to 42 but without touching str
$q=new CGI({'_Action'=>'update', 'id'=>0, 'nr'=>42, 
						'Lnk'=>[1,3,'do_edit'], '_Table'=>'Test2'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: 42\nLnk: 42, 13\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: 8, 42, 13\n\n");

# Fake a CGI response make post with id 2 related to no posts
$q=new CGI({'_Action'=>'update', 'id'=>2,
						'Lnk'=>['do_edit'], '_Table'=>'Test2'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: 42\nLnk: 42, 13\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: \n\n");

# Fake a CGI response seting nr to 7 of post with id 0
$q=new CGI({'_Action'=>'update', 'id'=>0, 'nr'=>7,
						'_Table'=>'Test2'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: \n\n");

# Fake a CGI response to make post with id 2 related to 8,42
$q=new CGI({'_Action'=>'update', 'id'=>2, 
						'Lnk'=>[0,1,'do_edit'],'_Table'=>'Test2'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: 8, 42\n\n");

print "\nSelecting related data\n";
$test_cnt=0;

# List all posts related to posts with testf 42
test($tab2->list("Lnk->testf=42", "order by Test2.id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: 8, 42\n\n");

# List all posts related to posts with testf 13 or 8
test($tab2->list("Lnk->testf=13 OR Lnk->testf=8", 
								 "order by Test2.id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: 2\nstr: \nnr: 7\nLnk: 8, 42\n\n");

# Relate $post2 to testf 77
$post2->set('Lnk', [4]);
$post2->update;

# List all posts related to posts with testf 77 or nr 7 and lnk 13
test($tab2->list("Lnk->testf=77 OR (nr=7 AND Lnk->testf=13)", 
								 "order by Test2.id")->view_text eq 
		 "id: 0\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: 1\nstr: Another test post\nnr: \nLnk: 77\n\n");

# List all posts related to posts with testf 13 and 42
#test($tab2->list("Lnk->testf=13 AND Lnk->testf=42", 
#								 "order by Test2.id")->view_text eq 
#		 "id: 0\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n");
# FIXME: How should this be implemented in an SQL query??

# List 

#undef tests
#read only

print "\nTotal: $tot_ok tests was successful and $tot_fail test failed\n";
# Used to print the results
sub test {
	$test_cnt++;
	if (shift) {
		$tot_ok++;
		print "ok $test_cnt\n";
	} else {
		$tot_fail++;
		print "not ok $test_cnt\n";
	}
}
#  LocalWords:  ListView's sql nstr nnr nLnk
