#!/usr/bin/perl

# This script will use the db defined in config.pm for testing, if you
# want to use a local db you have to change that file to point to it
# (that file contains instructions on how to set up one using msql). This
# db does not need to have any tables defined as the tables will be
# created as one of the first things below.

# Note the test here presumes id numbers are assigned in the order the
# posts are added starting from 1

# FIXME: This script presumptations "order by id" = insertion order

BEGIN { $| = 1; print "Compilation 1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use DBIx::HTMLView;

$loaded = 1;
print "ok 1\n";

$tot_ok=1;
$tot_fail=0;

print "\nNOTE: Those test are done against a central db server,so without inet\nacces they will probably fail. See the test.pl on how to specify the\nuse of a local db.\n";

print "\nDatabase set up and construction\n";
$test_cnt=0;

# Set up the database structure
use config;
my $dbi=&config::dbi();

test($dbi->isa('DBIx::HTMLView::DB'));

# Clear out the database table to make sure we'll do a fresh start
# FIXME: Prevent those drop commands from generating error out if
#        there is no table
print "Sending drop table commands to the database, this will generate error\n";
print "reports if they do not exist, don't worry about that.\n";
eval {$dbi->send("drop table Test");};
eval {$dbi->send("drop table Test2");};
eval {$dbi->send("drop table Test2_to_Test");};
eval {$dbi->send("drop table Test3");};
eval {$dbi->send("drop table Test4");};
eval {$dbi->send("drop table Test4_to_Test2");};

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
<input type=hidden name="_Table" value="Test"></from><hr><table border=1><tr><th>id</th><th>testf</th></tr></table><a href="View.cgi?_Action=add&_Table=Test">Add</a> ');

print "\nBasic database functions\n";
$test_cnt=0;

# Add a post
my $post=$dbi->tab('Test')->new_post;
$post->set('testf', 6);
$post->update;
$id1=$post->id;

# List the contents of the database
my $tab=$dbi->tab('Test');
my $hits=$tab->list();
test($hits->rows == 1);
test($hits->view_text eq "id: $id1\ntestf: 6\n");

# Change the value of testf to 7
$post->set('testf', 7);
$post->update;

# List the contents of the database
test($tab->list()->view_text eq "id: $id1\ntestf: 7\n");

# Add two more post to have something more to test with 
$post=$dbi->tab('Test')->new_post;
$post->set('testf', 42);
$post->update;
$id2=$post->id;

$post=$dbi->tab('Test')->new_post;
$post->set('testf', 13);
$post->update;
$id3=$post->id;


# List the contents of the database sorted by the id field
$hits=$tab->list(undef,"order by id");
test($hits->view_text eq "id: $id1\ntestf: 7\n\nid: $id2\ntestf: 42\n\nid: $id3\ntestf: 13\n");
test($hits->rows == 3);

# List the contents of the database sorted by the id field view in html
$hits=$tab->list(undef,"order by id");
test($hits->view_html eq "<table border=1><tr><th>id</th><th>testf</th></tr><tr><td>$id1</td><td>7</td></tr><tr><td>$id2</td><td>42</td></tr><tr><td>$id3</td><td>13</td></tr></table>");

# List all posts where the testf field is greater than 8 sorted by id
$hits=$tab->list("testf>8","order by id");
test($hits->view_text eq "id: $id2\ntestf: 42\n\nid: $id3\ntestf: 13\n");

# List all posts where the testf field is greater than 8 sorted by testf
$hits=$tab->list("testf>8", "order by testf");
test($hits->view_text eq "id: $id3\ntestf: 13\n\nid: $id2\ntestf: 42\n");


# Delete a post
$tab->del($id3);

# List the table to check the result
$hits=$tab->list(undef,"order by id");
test($hits->view_text eq "id: $id1\ntestf: 7\n\nid: $id2\ntestf: 42\n");

# Readd post for future test 
$post=$dbi->tab('Test')->new_post;
$post->set('testf', 13);
$post->update;
$id4=$post->id;

# Add some postst to the Test3 table
$post=$dbi->tab('Test3')->new_post;
$post->set('b1', 'Y');
$post->set('b2', '1');
$post->set('s', 'hej');
$post->update;
$id31=$post->id;

$post=$dbi->tab('Test3')->new_post;
$post->set('b1', 'N');
$post->set('b2', '0');
$post->update;
$id32=$post->id;

$post=$dbi->tab('Test3')->new_post;
$post->set('b1', 'Y');
$post->set('b2', '0');
$post->set('s', 'hopp');
$post->update;
$id33=$post->id;

# List the table to check the result
test($dbi->tab('Test3')->list(undef,"order by id")->view_text eq
		 "id: $id31\nb1: Yes\nb2: Sure\ns: hej\n\n".
     "id: $id32\nb1: No\nb2: No way\ns: \n\n".
		 "id: $id33\nb1: Yes\nb2: No way\ns: hopp\n");


test($dbi->tab('Test3')->list(undef,"order by id")->view_html eq 
		 "<table border=1><tr><th>id</th><th>b1</th><th>b2</th><th>s</th></tr><tr><td>$id31</td><td>Yes</td><td>Sure</td><td>hej</td></tr><tr><td>$id32</td><td>No</td><td>No way</td><td></td></tr><tr><td>$id33</td><td>Yes</td><td>No way</td><td>hopp</td></tr></table>");

print "\nRelations\n";
$test_cnt=0;

# Add a post to Test2 related to 7 and 42 in Test
my $tab2=$dbi->tab('Test2');
my $post1=$tab2->new_post;
$post1->set('str', 'A test post');
$post1->set('Lnk', [$id1,$id2]);
$post1->update;
$id21=$post1->id;

# List table to check result
test($tab2->list->view_text eq 
		 "id: $id21\nstr: A test post\nnr: \nLnk: 7, 42\n");

# Add a post to Test2 related to 13 and 42 in Test
my $post2=$tab2->new_post;
$post2->set('str', 'Another test post');
$post2->set('Lnk', [$id2,$id4]);
$post2->update;
$id22=$post2->id;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: \nLnk: 7, 42\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: 42, 13\n");

# Add a post to Test2 with no relations
my $post3=$tab2->new_post;
$post3->set('nr', 7);
$post3->update;
$id23=$post3->id;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: \nLnk: 7, 42\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: 42, 13\n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: \n");

# Update post 1 to only be related to 7
$post1->set('Lnk', [$id1]);
$post1->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: \nLnk: 7\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: 42, 13\n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: \n");

# Update post 3 to only be related to 7, 13, 42
$post3->set('Lnk', [$id1,$id2,$id4]);
$post3->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: \nLnk: 7\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: 42, 13\n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: 7, 42, 13\n");

# Update post 2 to have no relations
$post2->set('Lnk', []);
$post2->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: \nLnk: 7\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: 7, 42, 13\n");

# Add a post to Test4 related to 7 in Test
my $tab4=$dbi->tab('Test4');
my $post41=$tab4->new_post;
$post41->set('Lnk', $id1);
$post41->update;
$id41=$post41->id;

# List table to check result
test($tab4->list->view_text eq "id: $id41\nLnk: 7($id1)\ns: This string is \nLink: <table></table>\n");

# Add a post to Test4 related to 42 in Test and 1,2,3 in Test2
my $post42=$tab4->new_post;
$post42->set('Lnk', $id2);
$post42->set('Link', [$id21, $id22, $id23]);
$post42->set('s', 'a test string');
$post42->update;
$id42=$post42->id;

# List table to check result
test($tab4->list->view_html  eq "<table border=1><tr><th>id</th><th>Lnk</th><th>s</th><th>Link</th></tr><tr><td>$id41</td><td>7($id1)</td><td>This string is </td><td><table></table></td></tr><tr><td>$id42</td><td>42($id2)</td><td>This string is a test string</td><td><table><tr><td></td><td>A test post(): 7</td></tr><tr><td></td><td>Another test post(): </td></tr><tr><td></td><td>(7): 7, 42, 13</td></tr></table></td></tr></table>");

print "\nview_fmt tests\n";
$test_cnt=0;

# List table with fmt_my 
test($tab4->list->view_fmt('my') eq "<table border=1><tr><th>id</th><th>Lnk</th><th>s</th><th>Link</th></tr><tr><td>$id41</td><td>7($id1)</td><td> it is</td><td></td></tr><tr><td>$id42</td><td>42($id2)</td><td>a test string it is</td><td>7!!7, 42, 13!</td></tr></table>");

# List table with a custom two level fmt
test($tab4->list->view_fmt('view_html',
													 '<node><fld s>: (<fmt Link><node>[<fld nr>], </node></fmt>)'."\n".'</node>') eq "This string is : ()\nThis string is a test string: ([], [], [7], )\n");

# List table with a custom three level fmt
test($tab4->list->view_fmt('view_html',
													 '<node><fld s>: <fmt Lnk><fld id>(<fld testf>)</fmt>: <fmt Link>[<node><fld str>: <fmt Lnk><node><fld testf>(<fld id>)</node></fmt>!</node>]</fmt>'."\n".'</node>') eq "This string is : $id1(7): []\nThis string is a test string: $id2(42): [A test post: 7($id1)!Another test post: !: 7($id1)42($id2)13($id3)!]\n");

print "\nCGIView interface tests\n";
$test_cnt=0;

# Bring up the CGIReqEdit editor with the post with id 1
require DBIx::HTMLView::CGIReqEdit;
$post=$dbi->tab("Test")->get($id1);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
my $html=$v->view_html;

test($html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>$id1<input type=hidden name=\"id\" value=\"$id1\"></td></tr><tr><td valign=top><b>testf </b></td><td><input name=\"testf\" value=\"7\" size=80></td></tr></table><input type=hidden name=\"_Table\" value=\"Test\"></dl><input type=submit value=OK></from>");

# Fake a CGI response changing the testf field to 8
my $q=new CGI({'id'=>$id1, 'testf'=>8, '_Table'=>'Test', '_Action'=>'update'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List the table to check the result
$hits=$tab->list(undef,"order by id");
test($hits->view_text eq "id: $id1\ntestf: 8\n\nid: $id2\ntestf: 42\n\nid: $id4\ntestf: 13\n");

# Bring up the CGIReqEdit editor with the post with a blank post
$post=$dbi->tab("Test")->new_post();
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);	
$html=$v->view_html;

test($html eq '<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td></td></tr><tr><td valign=top><b>testf </b></td><td><input name="testf" value="" size=80></td></tr></table><input type=hidden name="_Table" value="Test"></dl><input type=submit value=OK></from>');

# Fake a CGI response adding a new post with testf 77
$q=new CGI({'testf'=>77, '_Table'=>'Test', '_Action'=>'update'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;
$id5=$post->id;

# List the table to check the result
$hits=$tab->list(undef,"order by id");
test($hits->view_text eq "id: $id1\ntestf: 8\n\nid: $id2\ntestf: 42\n\nid: $id4\ntestf: 13\n\nid: $id5\ntestf: 77\n");
                          

# Generate the ListView's default page
use CGI;
my $v=new DBIx::HTMLView::CGIListView("View.cgi", $dbi, new CGI({}));
$v->extra_sql("order by id"); # Sort by id to simplify check
$v->restrict_tabs(['Test']);   # Show only one Table, to simplify check

test($v->view_html eq "<h1>Current table: Test</h1>

<b>Change table</b>: 
<form method=POST action=\"View.cgi\"><input type=submit name=_Table value=\"Test\"></form><p>
<form method=POST action=\"View.cgi\">
  <B>Search</b>: <input name=\"_Command\" VALUE=\"\">
	<input type=hidden name=\"_Action\"  value=\"search\">
  <input type=submit value=\"Search\">
<input type=hidden name=\"_Table\" value=\"Test\"></from><hr><table border=1><tr><th>id</th><th>testf</th></tr><tr><td>$id1</td><td>8</td><td><a href=\"View.cgi?_id=$id1&_Action=show&_Table=Test\">Show</a> <a href=\"View.cgi?_id=$id1&_Action=edit&_Table=Test\">Edit</a> <a href=\"View.cgi?_id=$id1&_Action=delete&_Table=Test\">Delete</a> </td></tr><tr><td>$id2</td><td>42</td><td><a href=\"View.cgi?_id=$id2&_Action=show&_Table=Test\">Show</a> <a href=\"View.cgi?_id=$id2&_Action=edit&_Table=Test\">Edit</a> <a href=\"View.cgi?_id=$id2&_Action=delete&_Table=Test\">Delete</a> </td></tr><tr><td>$id4</td><td>13</td><td><a href=\"View.cgi?_id=$id4&_Action=show&_Table=Test\">Show</a> <a href=\"View.cgi?_id=$id4&_Action=edit&_Table=Test\">Edit</a> <a href=\"View.cgi?_id=$id4&_Action=delete&_Table=Test\">Delete</a> </td></tr><tr><td>$id5</td><td>77</td><td><a href=\"View.cgi?_id=$id5&_Action=show&_Table=Test\">Show</a> <a href=\"View.cgi?_id=$id5&_Action=edit&_Table=Test\">Edit</a> <a href=\"View.cgi?_id=$id5&_Action=delete&_Table=Test\">Delete</a> </td></tr></table><a href=\"View.cgi?_Action=add&_Table=Test\">Add</a> ");

# Generate the ListView's page on Test2
$v=new DBIx::HTMLView::CGIListView("View.cgi", $dbi, 
																	 new CGI({'_Table'=>'Test2'}));
$v->extra_sql("order by id"); # Sort by id to simplify check
$v->restrict_tabs(['Test2']);   # Show only one Table, to simplify check
test($v->view_html eq "<h1>Current table: Test2</h1>

<b>Change table</b>: 
<form method=POST action=\"View.cgi\"><input type=submit name=_Table value=\"Test2\"></form><p>
<form method=POST action=\"View.cgi\">
  <B>Search</b>: <input name=\"_Command\" VALUE=\"\">
	<input type=hidden name=\"_Action\"  value=\"search\">
  <input type=submit value=\"Search\">
<input type=hidden name=\"_Table\" value=\"Test2\"></from><hr><table border=1><tr><th>id</th><th>str</th><th>nr</th><th>Lnk</th></tr><tr><td>$id21</td><td>A test post</td><td></td><td>8</td><td><a href=\"View.cgi?_id=$id21&_Action=show&_Table=Test2\">Show</a> <a href=\"View.cgi?_id=$id21&_Action=edit&_Table=Test2\">Edit</a> <a href=\"View.cgi?_id=$id21&_Action=delete&_Table=Test2\">Delete</a> </td></tr><tr><td>$id22</td><td>Another test post</td><td></td><td></td><td><a href=\"View.cgi?_id=$id22&_Action=show&_Table=Test2\">Show</a> <a href=\"View.cgi?_id=$id22&_Action=edit&_Table=Test2\">Edit</a> <a href=\"View.cgi?_id=$id22&_Action=delete&_Table=Test2\">Delete</a> </td></tr><tr><td>$id23</td><td></td><td>7</td><td>8, 42, 13</td><td><a href=\"View.cgi?_id=$id23&_Action=show&_Table=Test2\">Show</a> <a href=\"View.cgi?_id=$id23&_Action=edit&_Table=Test2\">Edit</a> <a href=\"View.cgi?_id=$id23&_Action=delete&_Table=Test2\">Delete</a> </td></tr></table><a href=\"View.cgi?_Action=add&_Table=Test2\">Add</a> ");


# Bring up the CGIReqEdit editor with the post with id 1
require DBIx::HTMLView::CGIReqEdit;
$post=$tab2->get($id21);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);

test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>$id21<input type=hidden name=\"id\" value=\"$id21\"></td></tr><tr><td valign=top><b>str </b></td><td><input name=\"str\" value=\"A test post\" size=80></td></tr><tr><td valign=top><b>nr </b></td><td><input name=\"nr\" value=\"\" size=80></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=checkbox name=\"Lnk\" value=$id1 checked> 8<br><input type=checkbox name=\"Lnk\" value=$id2 > 42<br><input type=checkbox name=\"Lnk\" value=$id4 > 13<br><input type=checkbox name=\"Lnk\" value=$id5 > 77<br><input type=hidden name=\"Lnk\" value=do_edit></td></tr></table><input type=hidden name=\"_Table\" value=\"Test2\"></dl><input type=submit value=OK></from>");

# Bring up the CGIReqEdit editor with the post with id 2
require DBIx::HTMLView::CGIReqEdit;
$post=$tab2->get($id22);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>$id22<input type=hidden name=\"id\" value=\"$id22\"></td></tr><tr><td valign=top><b>str </b></td><td><input name=\"str\" value=\"Another test post\" size=80></td></tr><tr><td valign=top><b>nr </b></td><td><input name=\"nr\" value=\"\" size=80></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=checkbox name=\"Lnk\" value=$id1 > 8<br><input type=checkbox name=\"Lnk\" value=$id2 > 42<br><input type=checkbox name=\"Lnk\" value=$id4 > 13<br><input type=checkbox name=\"Lnk\" value=$id5 > 77<br><input type=hidden name=\"Lnk\" value=do_edit></td></tr></table><input type=hidden name=\"_Table\" value=\"Test2\"></dl><input type=submit value=OK></from>");

# Bring up the CGIReqEdit editor with the post with id $id23
require DBIx::HTMLView::CGIReqEdit;
$post=$tab2->get($id23);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>$id3<input type=hidden name=\"id\" value=\"$id3\"></td></tr><tr><td valign=top><b>str </b></td><td><input name=\"str\" value=\"\" size=80></td></tr><tr><td valign=top><b>nr </b></td><td><input name=\"nr\" value=\"7\" size=80></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=checkbox name=\"Lnk\" value=$id1 checked> 8<br><input type=checkbox name=\"Lnk\" value=$id2 checked> 42<br><input type=checkbox name=\"Lnk\" value=$id4 checked> 13<br><input type=checkbox name=\"Lnk\" value=$id5 > 77<br><input type=hidden name=\"Lnk\" value=do_edit></td></tr></table><input type=hidden name=\"_Table\" value=\"Test2\"></dl><input type=submit value=OK></from>");

# Fake a CGI response make post with id 1 related to 42, 13 and with
# nr set to 42 but without touching str
$q=new CGI({'_Action'=>'update', 'id'=>$id21, 'nr'=>42, 
						'Lnk'=>[$id2,$id4,'do_edit'], '_Table'=>'Test2'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: 42\nLnk: 42, 13\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: 8, 42, 13\n");

# Fake a CGI response make post with id 3 related to no posts
$q=new CGI({'_Action'=>'update', 'id'=>$id23,
						'Lnk'=>['do_edit'], '_Table'=>'Test2'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: 42\nLnk: 42, 13\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: \n");

# Fake a CGI response seting nr to 7 of post with id 1
$q=new CGI({'_Action'=>'update', 'id'=>$id21, 'nr'=>7,
						'_Table'=>'Test2'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: \n");

# Fake a CGI response to make post with id 3 related to 8,42
$q=new CGI({'_Action'=>'update', 'id'=>$id23, 
						'Lnk'=>[$id1,$id2,'do_edit'],'_Table'=>'Test2'});
$post=$dbi->tab($q->param('_Table'))->new_post($q);
$post->update;

# List table to check result
test($tab2->list(undef, "order by id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: \n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: 8, 42\n");

# Select on bool valuse and true edit returned post
$post=$dbi->tab('Test3')->list("b1='Y' AND b2='0'")->first;
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);

test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>$id33<input type=hidden name=\"id\" value=\"$id33\"></td></tr><tr><td valign=top><b>b1 </b></td><td><input type='radio' name='b1' value='Y' checked >Yes&nbsp;&nbsp;<input type='radio' name='b1' value='N' >No</td></tr><tr><td valign=top><b>b2 </b></td><td><input type='radio' name='b2' value='1'  >Sure&nbsp;&nbsp;<input type='radio' name='b2' value='0' checked>No way</td></tr><tr><td valign=top><b>s </b></td><td><input name=\"s\" value=\"hopp\" size=20></td></tr></table><input type=hidden name=\"_Table\" value=\"Test3\"></dl><input type=submit value=OK></from>");

# Bring up the CGIReqEdit editor with the post with id $id41
$post=$tab4->get($id41);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td>1<input type=hidden name=\"id\" value=\"$id41\"></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=\"radio\" name=\"Lnk\" value=\"$id1\" checked> 8($id1)<br><input type=\"radio\" name=\"Lnk\" value=\"$id2\" > 42($id2)<br><input type=\"radio\" name=\"Lnk\" value=\"$id4\" > 13($id4)<br><input type=\"radio\" name=\"Lnk\" value=\"$id5\" > 77($id5)<br></td></tr><tr><td valign=top><b>s </b></td><td><input name=\"s\" value=\"\" size=80></td></tr><tr><td valign=top><b>Link </b></td><td><table><tr><td><input type=checkbox name=\"Link\" value=$id21 ></td><td>A test post(7): 42, 13</td></tr><tr><td><input type=checkbox name=\"Link\" value=$id22 ></td><td>Another test post(): </td></tr><tr><td><input type=checkbox name=\"Link\" value=$id23 ></td><td>(7): 8, 42</td></tr><input type=hidden name=\"Link\" value=do_edit></table></td></tr></table><input type=hidden name=\"_Table\" value=\"Test4\"></dl><input type=submit value=OK></from>");

# Bring up the CGIReqEdit editor with an empthy test4 post
$post=$tab4->new_post;
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);

test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><tr><td valign=top><b>id </b></td><td></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=\"radio\" name=\"Lnk\" value=\"$id1\" > 8($id1)<br><input type=\"radio\" name=\"Lnk\" value=\"$id2\" > 42($id2)<br><input type=\"radio\" name=\"Lnk\" value=\"$id4\" > 13($id4)<br><input type=\"radio\" name=\"Lnk\" value=\"$id5\" > 77($id5)<br></td></tr><tr><td valign=top><b>s </b></td><td><input name=\"s\" value=\"\" size=80></td></tr><tr><td valign=top><b>Link </b></td><td><table><tr><td><input type=checkbox name=\"Link\" value=$id21 ></td><td>A test post(7): 42, 13</td></tr><tr><td><input type=checkbox name=\"Link\" value=$id22 ></td><td>Another test post(): </td></tr><tr><td><input type=checkbox name=\"Link\" value=$id23 ></td><td>(7): 8, 42</td></tr><input type=hidden name=\"Link\" value=do_edit></table></td></tr></table><input type=hidden name=\"_Table\" value=\"Test4\"></dl><input type=submit value=OK></from>");

#FIXME: Multilevel edit fmts

print "\nSelecting related data\n";
$test_cnt=0;

# List all posts related to posts with testf 42
test($tab2->list("Lnk->testf=42", "order by Test2.id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: 8, 42\n");


# List all posts related to posts with testf 13 or 8
test($tab2->list("Lnk->testf=13 OR Lnk->testf=8", 
								 "order by Test2.id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: $id23\nstr: \nnr: 7\nLnk: 8, 42\n");

# Relate $post2 to testf 77
$post2->set('Lnk', [$id5]);
$post2->update;

# List all posts related to posts with testf 77 or nr 7 and lnk 13
test($tab2->list("Lnk->testf=77 OR (nr=7 AND Lnk->testf=13)", 
								 "order by Test2.id")->view_text eq 
		 "id: $id21\nstr: A test post\nnr: 7\nLnk: 42, 13\n\n".
		 "id: $id22\nstr: Another test post\nnr: \nLnk: 77\n");


# List all posts related to posts with testf 13 and 42
#test($tab2->list("Lnk->testf=13 AND Lnk->testf=42", 
#								 "order by Test2.id")->view_text eq 
#		 "id: 0\nstr: A test post\nnr: 7\nLnk: 42, 13\n");
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

# Bool, Modified bool, modified sql size, modified edit size
