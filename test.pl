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

print "\nNOTE: Those test are done against a database named HTMLViewTester on\na local mysql server. If that db don't excists DBI->connect will fail\nwith a 'Unknown database' error. Se config.pm for instructions on how\nto create such a db.\n";

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
eval {$dbi->send("drop table Test1");};
eval {$dbi->send("drop table Test1_to_Test");};
eval {$dbi->send("drop table Test1_to_Test2");};
eval {$dbi->send("drop table Test1_to_Test3");};
eval {$dbi->send("drop table Test1_to_Test4");};
eval {$dbi->send("drop table Test5");};
eval {$dbi->send("drop table TreeTest");};
eval {$dbi->send("drop table SubTab");};
eval {$dbi->send("drop table SubTest");};
eval {$dbi->send("drop table SubTab_to_Test4");};
eval {$dbi->send("drop table Test6");};
eval {$dbi->send("drop table Test7");};
eval {$dbi->send("drop table Test7_to_Test");};

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
<a href="View.cgi?_Table=Test&_Table=Test">Test</a> <a href="View.cgi?_Table=Test&_Action=add&_Table=Test">+</a>, <p>
<form method=POST action="View.cgi">
  <B>Search</b>: <input name="_Command" VALUE="">
  <input type=hidden name="_Action"  value="search">
  <input type=submit value="Search">
<input type=hidden name="_Table" value="Test"></from><hr>1 <table border=1><tr><th><a href="View.cgi?_Order=id&_Table=Test">id</a></th><th><a href="View.cgi?_Order=testf&_Table=Test">testf</a></th></tr></table><a href="View.cgi?_Action=add&_Table=Test">Add</a> ');

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

test($tab->list('testf >= 13','order by id')->view_text eq 
     "id: 2\ntestf: 42\n\nid: 3\ntestf: 13\n");

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

$post=$dbi->tab('Test5')->new_post;
$post->set('d', '99-02-02');
$post->update;
$id52=$post->id;

$post=$dbi->tab('Test5')->new_post;
$post->set('d', '99:01:01');
$post->update;
$id51=$post->id;

test($dbi->tab('Test5')->list(undef, "order by d")->view_text eq
   "d: 1999-01-01\nid: $id51\n\nd: 1999-02-02\nid: $id52\n");

# Count the number of posts in Test
test ($dbi->tab('Test')->count == 3);

# Count the number of posts in Test with tesf greater than 10
test ($dbi->tab('Test')->count("testf > 10") == 2);

print "\nOrder Flds\n";
$test_cnt=0;

# Add three posts to Test6 
my $tab6=$dbi->tab('Test6');
my $p61=$tab6->new_post;
$p61->set('tst', 'Testing...');
$p61->update;
$id61=$p61->id;

test($tab6->list->view_text eq "tst: Testing...\nOrd1: 1\nOrd2: 1\nid: $id61\n");

my $p62=$tab6->new_post;
$p62->set('tst', 'Testing2...');
$p62->update;
$id62=$p62->id;

my $p63=$tab6->new_post;
$p63->set('tst', 'My test');
$p63->update;
$id63=$p63->id;

test($tab6->list(undef, 'order by Ord1')->view_text eq 
     "tst: Testing...\nOrd1: 1\nOrd2: 1\nid: $id61\n\ntst: Testing2...\nOrd1: 2\nOrd2: 2\nid: $id62\n\ntst: My test\nOrd1: 3\nOrd2: 3\nid: $id63\n");

# Move last post one step up in Ord1's order
$p63->fld('Ord1')->move_up;

test ($tab6->list(undef, 'order by Ord1')->view_text eq "tst: Testing...
Ord1: 1
Ord2: 1
id: $id61

tst: My test
Ord1: 2
Ord2: 3
id: $id63

tst: Testing2...
Ord1: 3
Ord2: 2
id: $id62
");

# Move middle post one step up to the top in Ord1's order
$p63->fld('Ord1')->move_up;

test($tab6->list(undef, 'order by Ord1')->view_text eq "tst: My test
Ord1: 1
Ord2: 3
id: $id63

tst: Testing...
Ord1: 2
Ord2: 1
id: $id61

tst: Testing2...
Ord1: 3
Ord2: 2
id: $id62
");

# Move middle post one step down to the bottom in Ord1's order
$p61=$tab6->get($id61); # It has changed in the db due to the moves above
$p61->fld('Ord1')->move_down;

test($tab6->list(undef, 'order by Ord1')->view_text eq "tst: My test
Ord1: 1
Ord2: 3
id: $id63

tst: Testing2...
Ord1: 2
Ord2: 2
id: $id62

tst: Testing...
Ord1: 3
Ord2: 1
id: $id61
");

# Move top post one step down to the middle in Ord2's order
$p61->fld('Ord2')->move_down;

test($tab6->list(undef, 'order by Ord2')->view_text eq "tst: Testing2...
Ord1: 2
Ord2: 1
id: $id62

tst: Testing...
Ord1: 3
Ord2: 2
id: $id61

tst: My test
Ord1: 1
Ord2: 3
id: $id63
");


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

# List only the str field (and the id field)
test($tab2->list(undef, "order by id", ["str"])->view_fmt('view_text',"<node><fld str>\n</node>") eq "A test post\nAnother test post\n\n");

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

print "\nTree tests\n";
$test_cnt=0;
my $ttab=$dbi->tab('TreeTest');

# Add two top level nodes
my $postt1=$ttab->new_post;
$postt1->set('Name', 'Hello');
$postt1->update;
$idt1=$postt1->id;

my $postt2=$ttab->new_post;
$postt2->set('Name', 'Hi');
$postt2->update;
$idt2=$postt2->id;

# Add a subnode to the node named Hi
my $postt3=$ttab->new_post;
$postt3->set('Name', 'There');
$postt3->set('Super', $idt2);
$postt3->update;
$idt3=$postt3->id;

# Check result
test($ttab->list->view_text eq 
     "id: $idt1\nName: Hello\nSuper: \n\n".
     "id: $idt2\nName: Hi\nSuper: \n\n".
     "id: $idt3\nName: There\nSuper: /Hi\n");

# Add a subnode to the node named There
my $postt4=$ttab->new_post;
$postt4->set('Name', 'Mr');
$postt4->set('Super', $idt3);
$postt4->update;
$idt4=$postt4->id;

# Add a subnode to the node named Mr
my $postt5=$ttab->new_post;
$postt5->set('Name', 'Tree');
$postt5->set('Super', $idt4);
$postt5->update;
$idt5=$postt5->id;

# Check result
test($ttab->list->view_text eq 
     "id: $idt1\nName: Hello\nSuper: \n\n".
     "id: $idt2\nName: Hi\nSuper: \n\n".
     "id: $idt3\nName: There\nSuper: /Hi\n\n".
     "id: $idt4\nName: Mr\nSuper: /Hi/There\n\n".
     "id: $idt5\nName: Tree\nSuper: /Hi/There/Mr\n");

# Move the node named Hi to become a subnode of Hello
$postt2->set('Super', $idt1);
$postt2->update;
test($ttab->list->view_text eq 
     "id: $idt1\nName: Hello\nSuper: \n\n".
     "id: $idt2\nName: Hi\nSuper: /Hello\n\n".
     "id: $idt3\nName: There\nSuper: /Hello/Hi\n\n".
     "id: $idt4\nName: Mr\nSuper: /Hello/Hi/There\n\n".
     "id: $idt5\nName: Tree\nSuper: /Hello/Hi/There/Mr\n");

# Make node named Mr a subnode of Hello
$postt4->set('Super', $idt1);
$postt4->update;
test($ttab->list->view_text eq 
     "id: $idt1\nName: Hello\nSuper: \n\n".
     "id: $idt2\nName: Hi\nSuper: /Hello\n\n".
     "id: $idt3\nName: There\nSuper: /Hello/Hi\n\n".
     "id: $idt4\nName: Mr\nSuper: /Hello\n\n".
     "id: $idt5\nName: Tree\nSuper: /Hello/Mr\n");

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

# Test noid_list 
test($tab2->noid_list(undef, undef, ['nr'])->view_fmt('view_text', "<node><fld nr>, </node>\n") eq ", 7, \n");

print "\nCGIView interface tests\n";
$test_cnt=0;

# Bring up the CGIReqEdit editor with the post with id 1
require DBIx::HTMLView::CGIReqEdit;
$post=$dbi->tab("Test")->get($id1);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
my $html=$v->view_html;

test($html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><input type=submit value=OK><tr><td valign=top><b>id </b></td><td>$id1<input type=hidden name=\"id\" value=\"$id1\"></td></tr><tr><td valign=top><b>testf </b></td><td><input name=\"testf\" value=\"7\" size=80></td></tr></table><input type=hidden name=\"_Table\" value=\"Test\"></dl><input type=submit value=OK></from>");

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

test($html eq '<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><input type=submit value=OK><tr><td valign=top><b>id </b></td><td></td></tr><tr><td valign=top><b>testf </b></td><td><input name="testf" value="" size=80></td></tr></table><input type=hidden name="_Table" value="Test"></dl><input type=submit value=OK></from>');

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
<a href=\"View.cgi?_Table=Test&_Table=Test\">Test</a> <a href=\"View.cgi?_Table=Test&_Action=add&_Table=Test\">+</a>, <p>
<form method=POST action=\"View.cgi\">
  <B>Search</b>: <input name=\"_Command\" VALUE=\"\">
  <input type=hidden name=\"_Action\"  value=\"search\">
  <input type=submit value=\"Search\">
<input type=hidden name=\"_Table\" value=\"Test\"></from><hr>1 <table border=1><tr><th><a href=\"View.cgi?_Order=id&_Table=Test\">id</a></th><th><a href=\"View.cgi?_Order=testf&_Table=Test\">testf</a></th></tr><tr><td>$id1</td><td>8</td><td><a href=\"View.cgi?_id=$id1&_Action=show&_Table=Test\">Show</a> <a href=\"View.cgi?_id=$id1&_Action=edit&_Table=Test\">Edit</a> <a href=\"View.cgi?_id=$id1&_Action=delete&_Table=Test\">Delete</a> </td></tr><tr><td>$id2</td><td>42</td><td><a href=\"View.cgi?_id=$id2&_Action=show&_Table=Test\">Show</a> <a href=\"View.cgi?_id=$id2&_Action=edit&_Table=Test\">Edit</a> <a href=\"View.cgi?_id=$id2&_Action=delete&_Table=Test\">Delete</a> </td></tr><tr><td>$id4</td><td>13</td><td><a href=\"View.cgi?_id=$id4&_Action=show&_Table=Test\">Show</a> <a href=\"View.cgi?_id=$id4&_Action=edit&_Table=Test\">Edit</a> <a href=\"View.cgi?_id=$id4&_Action=delete&_Table=Test\">Delete</a> </td></tr><tr><td>$id5</td><td>77</td><td><a href=\"View.cgi?_id=$id5&_Action=show&_Table=Test\">Show</a> <a href=\"View.cgi?_id=$id5&_Action=edit&_Table=Test\">Edit</a> <a href=\"View.cgi?_id=$id5&_Action=delete&_Table=Test\">Delete</a> </td></tr></table><a href=\"View.cgi?_Action=add&_Table=Test\">Add</a> ");

# Generate the ListView's page on Test2
$v=new DBIx::HTMLView::CGIListView("View.cgi", $dbi, 
                                   new CGI({'_Table'=>'Test2'}));
$v->extra_sql("order by id"); # Sort by id to simplify check
$v->restrict_tabs(['Test2']);   # Show only one Table, to simplify check

test ($v->view_html eq "<h1>Current table: Test2</h1>

<b>Change table</b>: 
<a href=\"View.cgi?_Table=Test2&_Table=Test2\">Test2</a> <a href=\"View.cgi?_Table=Test2&_Action=add&_Table=Test2\">+</a>, <p>
<form method=POST action=\"View.cgi\">
  <B>Search</b>: <input name=\"_Command\" VALUE=\"\">
  <input type=hidden name=\"_Action\"  value=\"search\">
  <input type=submit value=\"Search\">
<input type=hidden name=\"_Table\" value=\"Test2\"></from><hr>1 <table border=1><tr><th><a href=\"View.cgi?_Order=id&_Table=Test2\">id</a></th><th><a href=\"View.cgi?_Order=str&_Table=Test2\">str</a></th><th><a href=\"View.cgi?_Order=nr&_Table=Test2\">nr</a></th><th><a href=\"View.cgi?_Order=Lnk&_Table=Test2\">Lnk</a></th></tr><tr><td>$id21</td><td>A test post</td><td></td><td>8</td><td><a href=\"View.cgi?_id=$id21&_Action=show&_Table=Test2\">Show</a> <a href=\"View.cgi?_id=$id21&_Action=edit&_Table=Test2\">Edit</a> <a href=\"View.cgi?_id=$id21&_Action=delete&_Table=Test2\">Delete</a> </td></tr><tr><td>$id22</td><td>Another test post</td><td></td><td></td><td><a href=\"View.cgi?_id=$id22&_Action=show&_Table=Test2\">Show</a> <a href=\"View.cgi?_id=$id22&_Action=edit&_Table=Test2\">Edit</a> <a href=\"View.cgi?_id=$id22&_Action=delete&_Table=Test2\">Delete</a> </td></tr><tr><td>$id23</td><td></td><td>7</td><td>8, 42, 13</td><td><a href=\"View.cgi?_id=$id23&_Action=show&_Table=Test2\">Show</a> <a href=\"View.cgi?_id=$id23&_Action=edit&_Table=Test2\">Edit</a> <a href=\"View.cgi?_id=$id23&_Action=delete&_Table=Test2\">Delete</a> </td></tr></table><a href=\"View.cgi?_Action=add&_Table=Test2\">Add</a> ");


# Bring up the CGIReqEdit editor with the post with id 1
require DBIx::HTMLView::CGIReqEdit;
$post=$tab2->get($id21);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);

test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><input type=submit value=OK><tr><td valign=top><b>id </b></td><td>$id21<input type=hidden name=\"id\" value=\"$id21\"></td></tr><tr><td valign=top><b>str </b></td><td><input name=\"str\" value=\"A test post\" size=80></td></tr><tr><td valign=top><b>nr </b></td><td><input name=\"nr\" value=\"\" size=80></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=checkbox name=\"Lnk\" value=$id1 checked> 8<br><input type=checkbox name=\"Lnk\" value=$id2 > 42<br><input type=checkbox name=\"Lnk\" value=$id4 > 13<br><input type=checkbox name=\"Lnk\" value=$id5 > 77<br><input type=hidden name=\"Lnk\" value=do_edit></td></tr></table><input type=hidden name=\"_Table\" value=\"Test2\"></dl><input type=submit value=OK></from>");

# Bring up the CGIReqEdit editor with the post with id 2
require DBIx::HTMLView::CGIReqEdit;
$post=$tab2->get($id22);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><input type=submit value=OK><tr><td valign=top><b>id </b></td><td>$id22<input type=hidden name=\"id\" value=\"$id22\"></td></tr><tr><td valign=top><b>str </b></td><td><input name=\"str\" value=\"Another test post\" size=80></td></tr><tr><td valign=top><b>nr </b></td><td><input name=\"nr\" value=\"\" size=80></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=checkbox name=\"Lnk\" value=$id1 > 8<br><input type=checkbox name=\"Lnk\" value=$id2 > 42<br><input type=checkbox name=\"Lnk\" value=$id4 > 13<br><input type=checkbox name=\"Lnk\" value=$id5 > 77<br><input type=hidden name=\"Lnk\" value=do_edit></td></tr></table><input type=hidden name=\"_Table\" value=\"Test2\"></dl><input type=submit value=OK></from>");

# Bring up the CGIReqEdit editor with the post with id $id23
require DBIx::HTMLView::CGIReqEdit;
$post=$tab2->get($id23);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><input type=submit value=OK><tr><td valign=top><b>id </b></td><td>$id3<input type=hidden name=\"id\" value=\"$id3\"></td></tr><tr><td valign=top><b>str </b></td><td><input name=\"str\" value=\"\" size=80></td></tr><tr><td valign=top><b>nr </b></td><td><input name=\"nr\" value=\"7\" size=80></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=checkbox name=\"Lnk\" value=$id1 checked> 8<br><input type=checkbox name=\"Lnk\" value=$id2 checked> 42<br><input type=checkbox name=\"Lnk\" value=$id4 checked> 13<br><input type=checkbox name=\"Lnk\" value=$id5 > 77<br><input type=hidden name=\"Lnk\" value=do_edit></td></tr></table><input type=hidden name=\"_Table\" value=\"Test2\"></dl><input type=submit value=OK></from>");


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

test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><input type=submit value=OK><tr><td valign=top><b>id </b></td><td>$id33<input type=hidden name=\"id\" value=\"$id33\"></td></tr><tr><td valign=top><b>b1 </b></td><td><input type='radio' name='b1' value='Y' checked >Yes&nbsp;&nbsp;<input type='radio' name='b1' value='N' >No</td></tr><tr><td valign=top><b>b2 </b></td><td><input type='radio' name='b2' value='1'  >Sure&nbsp;&nbsp;<input type='radio' name='b2' value='0' checked>No way</td></tr><tr><td valign=top><b>s </b></td><td><input name=\"s\" value=\"hopp\" size=20></td></tr></table><input type=hidden name=\"_Table\" value=\"Test3\"></dl><input type=submit value=OK></from>");

# Bring up the CGIReqEdit editor with the post with id $id41
$post=$tab4->get($id41);
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);
test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><input type=submit value=OK><tr><td valign=top><b>id </b></td><td>1<input type=hidden name=\"id\" value=\"$id41\"></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=\"radio\" name=\"Lnk\" value=\"$id1\" checked> 8($id1)<br><input type=\"radio\" name=\"Lnk\" value=\"$id2\" > 42($id2)<br><input type=\"radio\" name=\"Lnk\" value=\"$id4\" > 13($id4)<br><input type=\"radio\" name=\"Lnk\" value=\"$id5\" > 77($id5)<br></td></tr><tr><td valign=top><b>s </b></td><td><input name=\"s\" value=\"\" size=80></td></tr><tr><td valign=top><b>Link </b></td><td><table><tr><td><input type=checkbox name=\"Link\" value=$id21 ></td><td>A test post(7): 42, 13</td></tr><tr><td><input type=checkbox name=\"Link\" value=$id22 ></td><td>Another test post(): </td></tr><tr><td><input type=checkbox name=\"Link\" value=$id23 ></td><td>(7): 8, 42</td></tr><input type=hidden name=\"Link\" value=do_edit></table></td></tr></table><input type=hidden name=\"_Table\" value=\"Test4\"></dl><input type=submit value=OK></from>");

# Bring up the CGIReqEdit editor with an empthy test4 post
$post=$tab4->new_post;
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $post);

test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><input type=submit value=OK><tr><td valign=top><b>id </b></td><td></td></tr><tr><td valign=top><b>Lnk </b></td><td><input type=\"radio\" name=\"Lnk\" value=\"$id1\" > 8($id1)<br><input type=\"radio\" name=\"Lnk\" value=\"$id2\" > 42($id2)<br><input type=\"radio\" name=\"Lnk\" value=\"$id4\" > 13($id4)<br><input type=\"radio\" name=\"Lnk\" value=\"$id5\" > 77($id5)<br></td></tr><tr><td valign=top><b>s </b></td><td><input name=\"s\" value=\"\" size=80></td></tr><tr><td valign=top><b>Link </b></td><td><table><tr><td><input type=checkbox name=\"Link\" value=$id21 ></td><td>A test post(7): 42, 13</td></tr><tr><td><input type=checkbox name=\"Link\" value=$id22 ></td><td>Another test post(): </td></tr><tr><td><input type=checkbox name=\"Link\" value=$id23 ></td><td>(7): 8, 42</td></tr><input type=hidden name=\"Link\" value=do_edit></table></td></tr></table><input type=hidden name=\"_Table\" value=\"Test4\"></dl><input type=submit value=OK></from>");

# Bring up the CGIReqEdit editor with the node named There in TreeTest
$v=new DBIx::HTMLView::CGIReqEdit("View.cgi", $postt3);
test($v->view_html eq "<form method=POST action=View.cgi><dl><input type=hidden name=_Action value=update><table><input type=submit value=OK><tr><td valign=top><b>id </b></td><td>3<input type=hidden name=\"id\" value=\"$idt3\"></td></tr><tr><td valign=top><b>Name </b></td><td><input name=\"Name\" value=\"There\" size=80></td></tr><tr><td valign=top><b>Super </b></td><td><dl><dt><input type=\"radio\" name=\"Super\" value=\"$idt1\" > Hello<br></dt><dd><dl><dt><input type=\"radio\" name=\"Super\" value=\"$idt2\" checked> Hi<br></dt><dd><dl><dt><input type=\"radio\" name=\"Super\" value=\"$idt3\" > There<br></dt><dd><dl></dl><dd></dl><dd><dt><input type=\"radio\" name=\"Super\" value=\"$idt4\" > Mr<br></dt><dd><dl><dt><input type=\"radio\" name=\"Super\" value=\"$idt5\" > Tree<br></dt><dd><dl></dl><dd></dl><dd></dl><dd></dl></td></tr></table><input type=hidden name=\"_Table\" value=\"TreeTest\"></dl><input type=submit value=OK></from>");

# Bring up page 2 of the CGIListView editor with TreeTest ordered by Name
$v=new DBIx::HTMLView::CGIListView("View.cgi", $dbi,
				  new CGI({_Order=>'Name',
					   _Table=>'TreeTest',
					   _Page=>'2',
					  }));
$v->rows(2);
test ($v->view_html eq "<h1>Current table: TreeTest</h1>

<b>Change table</b>: 
<input type=hidden name=\"_Page\" value=\"2\"><input type=hidden name=\"_Order\" value=\"Name\"><a href=\"View.cgi?_Table=TreeTest&_Table=TreeTest&_Page=2&_Order=Name\">TreeTest</a> <a href=\"View.cgi?_Table=TreeTest&_Action=add&_Table=TreeTest&_Page=2&_Order=Name\">+</a>, <a href=\"View.cgi?_Table=Test&_Table=TreeTest&_Page=2&_Order=Name\">Test</a> <a href=\"View.cgi?_Table=Test&_Action=add&_Table=TreeTest&_Page=2&_Order=Name\">+</a>, <a href=\"View.cgi?_Table=Test1&_Table=TreeTest&_Page=2&_Order=Name\">Test1</a> <a href=\"View.cgi?_Table=Test1&_Action=add&_Table=TreeTest&_Page=2&_Order=Name\">+</a>, <a href=\"View.cgi?_Table=Test2&_Table=TreeTest&_Page=2&_Order=Name\">Test2</a> <a href=\"View.cgi?_Table=Test2&_Action=add&_Table=TreeTest&_Page=2&_Order=Name\">+</a>, <a href=\"View.cgi?_Table=Test3&_Table=TreeTest&_Page=2&_Order=Name\">Test3</a> <a href=\"View.cgi?_Table=Test3&_Action=add&_Table=TreeTest&_Page=2&_Order=Name\">+</a>, <a href=\"View.cgi?_Table=Test4&_Table=TreeTest&_Page=2&_Order=Name\">Test4</a> <a href=\"View.cgi?_Table=Test4&_Action=add&_Table=TreeTest&_Page=2&_Order=Name\">+</a>, <a href=\"View.cgi?_Table=Test5&_Table=TreeTest&_Page=2&_Order=Name\">Test5</a> <a href=\"View.cgi?_Table=Test5&_Action=add&_Table=TreeTest&_Page=2&_Order=Name\">+</a>, <p>
<form method=POST action=\"View.cgi\">
  <B>Search</b>: <input name=\"_Command\" VALUE=\"\">
  <input type=hidden name=\"_Action\"  value=\"search\">
  <input type=submit value=\"Search\">
<input type=hidden name=\"_Table\" value=\"TreeTest\"><input type=hidden name=\"_Page\" value=\"2\"><input type=hidden name=\"_Order\" value=\"Name\"></from><hr><a href=\"View.cgi?_Page=1&_Table=TreeTest&_Page=2&_Order=Name\">1</a> 2 <a href=\"View.cgi?_Page=3&_Table=TreeTest&_Page=2&_Order=Name\">3</a> <table border=1><tr><th><a href=\"View.cgi?_Order=id&_Table=TreeTest&_Page=2&_Order=Name\">id</a></th><th><a href=\"View.cgi?_Order=Name&_Table=TreeTest&_Page=2&_Order=Name\">Name</a></th><th><a href=\"View.cgi?_Order=Super&_Table=TreeTest&_Page=2&_Order=Name\">Super</a></th></tr><tr><td>$idt4</td><td>Mr</td><td>/Hello</td><td><a href=\"View.cgi?_id=$idt4&_Action=show&_Table=TreeTest&_Page=2&_Order=Name\">Show</a> <a href=\"View.cgi?_id=$idt4&_Action=edit&_Table=TreeTest&_Page=2&_Order=Name\">Edit</a> <a href=\"View.cgi?_id=$idt4&_Action=delete&_Table=TreeTest&_Page=2&_Order=Name\">Delete</a> </td></tr><tr><td>$idt2</td><td>Hi</td><td>/Hello</td><td><a href=\"View.cgi?_id=$idt2&_Action=show&_Table=TreeTest&_Page=2&_Order=Name\">Show</a> <a href=\"View.cgi?_id=$idt2&_Action=edit&_Table=TreeTest&_Page=2&_Order=Name\">Edit</a> <a href=\"View.cgi?_id=$idt2&_Action=delete&_Table=TreeTest&_Page=2&_Order=Name\">Delete</a> </td></tr></table><a href=\"View.cgi?_Action=add&_Table=TreeTest&_Page=2&_Order=Name\">Add</a> ");

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

# Setting up Test1 (adding posts with only id fields)
$tab1=$dbi->tab('Test1');
$post=$tab1->new_post;
$post->set('Lnk1', [$id4]);
$post->set('Lnk2', [$id23]);
$post->set('Lnk3', [$id32]);
$post->set('Lnk4', [$id42]);
$post->update;
$id11=$post->id;

$post=$tab1->new_post;
$post->set('Lnk1', [$id1]);
$post->set('Lnk2', [$id21]);
$post->set('Lnk3', [$id31]);
$post->set('Lnk4', [$id41]);
$post->update;
$id12=$post->id;

$post=$tab1->new_post;
$post->set('Lnk1', [$id4,$id2]);
$post->set('Lnk2', [$id21,$id23]);
$post->set('Lnk3', [$id31,$id32]);
$post->set('Lnk4', [$id41,$id42]);
$post->update;
$id13=$post->id;

# Change id only post
$post->set('Lnk2', [$id21, $id22, $id23]);
$post->update;

# Select with several selected id fields
test ($tab1->list("Lnk1->id=$id4 AND Lnk2->id=$id23 AND Lnk3->id=$id32 AND Lnk4->id=$id42")->view_text eq "Lnk1: $id4\nLnk2: $id23\nLnk3: $id32\nLnk4: $id42\nid: $id11\n\nLnk1: $id2, $id4\nLnk2: $id21, $id22, $id23\nLnk3: $id31, $id32\nLnk4: $id41, $id42\nid: 3\n");

# Order related data
test ($tab1->list(undef, undef, undef, 'Lnk1->id desc')->view_text eq 'Lnk1: 3
Lnk2: 3
Lnk3: 2
Lnk4: 2
id: 1

Lnk1: 2, 3
Lnk2: 1, 2, 3
Lnk3: 1, 2
Lnk4: 1, 2
id: 3

Lnk1: 1
Lnk2: 1
Lnk3: 1
Lnk4: 1
id: 2
');

# FIXME: orber by several related fields

# List all posts related to posts with testf 13 and 42
#test($tab2->list("Lnk->testf=13 AND Lnk->testf=42", 
#                 "order by Test2.id")->view_text eq 
#     "id: 0\nstr: A test post\nnr: 7\nLnk: 42, 13\n");
# FIXME: How should this be implemented in an SQL query??

# FIXME: multilevel relational selects, eg Link->Lnk->testf = 7

# List 

#undef tests
#read only

ctst:
print "\nTesting compiled fmts\n";
print "FIXME: These test currently wont work if you dont install first\n";
$test_cnt=0;

# Simpel fmt to make a oneline list of the Test table
test(comp('Test', '<node><fld testf> </node>', undef, 'order by id')
     eq "8 42 13 77 \n");

# Create some data in SubTest and SubTab
$dbi->send("INSERT INTO SubTest VALUES (1,'Hi')");
$dbi->send("INSERT INTO SubTest VALUES (2,'Ho')");
$dbi->send("INSERT INTO SubTab VALUES (1,'First','34',1)");
$dbi->send("INSERT INTO SubTab VALUES (2,'Second','23',1)");
$dbi->send("INSERT INTO SubTab VALUES (3,'Third','12',2)");

# Test fmt with SubTab relations
test(comp('SubTest', "<node><fld Name> Start<fmt Sub><node>\n".
	  "  <fld Name></node></fmt>\n<fld Name> End\n</node>", 
	  undef, 'order by SubTest.id') eq 'Hi Start
  First
  Second
Hi End
Ho Start
  Third
Ho End

');

# Test fmt with SubTab relations containing head and foot text
test(comp('SubTest', "<node><fld Name> <fmt Sub>Start<node>\n".
	  "  <fld Name></node>\n</fmt><fld Name> End\n</node>", 
	  undef, 'order by SubTest.id') eq 'Hi Start
  First
  Second
Hi End
Ho Start
  Third
Ho End

');

# Test fmt with SubTab emthy relations
$dbi->send("INSERT INTO SubTest VALUES (3,'Yo')");
test(comp('SubTest', "<node><fld Name> <fmt Sub>Start<node>\n".
	  "  <fld Name></node>\n</fmt><fld Name> End\n</node>", 
	  undef, 'order by SubTest.id') eq 'Hi Start
  First
  Second
Hi End
Ho Start
  Third
Ho End
Yo Start
Yo End

');

# Test fmt with SubTab and simple serach
test(comp('SubTest', "<node><fld Name> <fmt Sub>Start<node>\n".
	  "  <fld Name></node>\n</fmt><fld Name> End\n</node>", 
	  "Name='Hi'", 'order by SubTest.id') eq 'Hi Start
  First
  Second
Hi End

');

# Test fmt with SubTab and serach on related data
test(comp('SubTest', "<node><fld Name> <fmt Sub>Start<node>\n".
	  "  <fld Name></node>\n</fmt><fld Name> End\n</node>", 
	  "Sub->Year=23", 'order by SubTest.id') eq 'Hi Start
  First
  Second
Hi End

');

# Test fmt with N2N Relation
test(comp('Test1', "<node><fld id>: <fmt Lnk1><node><fld id>, </node></fmt>\n".
	  "</node>", undef, 'order by Test1.id') eq '1: 3, 
2: 1, 
3: 2, 3, 

');

# Test fmt with N2N Relation with select on related data
test(comp('Test1', "<node><fld id>: <fmt Lnk1><node><fld id>, </node></fmt>\n".
	  "</node>", "Lnk1->id>2", 'order by Test1.id') eq '1: 3, 
3: 2, 3, 

');

# Test fmt with multileve Relations
test(comp('Test4', "<node><fld id>: <fmt Link><node><fld str> ".
                    "<fmt Lnk><node><fld testf>, </node></fmt>\n</node></fmt>\n".
                    "</node>", 
	   undef, 'order by Test4.id desc') eq '2: A test post 42, 13, 
Another test post 77, 
 42, 8, 

1: 

');

# Test fmt with multileve Relations and select on multilevel rel data
test(comp('Test4', "<node><fld id>: <fmt Link><node><fld str> ".
                    "<fmt Lnk><node><fld testf>, </node></fmt>\n</node></fmt>\n".
                    "</node>", 
	  'Link->Lnk->testf>8', 'order by Test4.id desc') eq '2: A test post 42, 13, 
Another test post 77, 
 42, 8, 


');

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

sub comp {
  my ($tab, $fmt, $sel, $extra)=@_;
  $sel=~s/\'/\'\"\'\"\'/g;
  $fmt=~s/\'/\'\"\'\"\'/g;
  $extra=~s/\'/\'\"\'\"\'/g;

  return `echo '$fmt' | ./comp.pl $tab - '$sel' '$extra'| perl -Iblib/arch -Iblib/lib`;
}

#  LocalWords:  ListView's sql nstr nnr nLnk

# Bool, Modified bool, modified sql size, modified edit size

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
