#!/usr/bin/perl

BEGIN {
    $|=1; 
    print "Content-Type: text/html\n\n";
    open STDERR, ">&STDOUT";
}

# Config
my @tabels = ("Test", "Test2");
my $db="DBI:mSQL:HTMLViewTester:athena.af.lu.se:1114";
my $script="View.cgi";

require DBIx::HTMLView::CGIListView;
require DBIx::HTMLView::CGIReqView;

$q = new CGI;
if (DBIx::HTMLView::CGIReqView::Handles($q)) {
	$v=new DBIx::HTMLView::CGIReqView($db, {}, $q);
} else {
	$v=new DBIx::HTMLView::CGIListView($db, {}, $q, \@tabels);
}

$v->PrintPage($script);
