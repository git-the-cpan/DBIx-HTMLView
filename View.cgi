#!/usr/bin/perl

BEGIN {
    $|=1; 
    print "Content-Type: text/html\n\n";
    open STDERR, ">&STDOUT";
}

# Config
my @tabels = ("Artiklar", "Forfattare", "Kategorier");
my $db="DBI:mSQL:Pub:athena.af.lu.se:1114";
my $script="View.cgi";

require DBIx::HTMLView::CGIListView;
require DBIx::HTMLView::CGIReqView;

$q = new CGI;
if (DBIx::HTMLView::CGIReqView::Handles($q)) {
	$v=new DBIx::HTMLView::CGIReqView($db, {}, $q);
} else {
	$v=new DBIx::HTMLView::CGIListView($db, {}, $q, \@tabels);
}

$v->{'editable'}="^Titel|Sokord|Ingress|Texten|Kategori|Fövrfattare\$";

$v->PrintPage($script);
