#!/usr/bin/perl

BEGIN {
    $|=1; 
    print "Content-Type: text/html\n\n";
    open STDERR, ">&STDOUT";
}

use DBIx::HTMLView;
use CGI;

# Config
use config;
my $dbi=config::dbi;
my $script="View.cgi";

require DBIx::HTMLView::CGIListView;
require DBIx::HTMLView::CGIReqEdit;

$q = new CGI;
my $act=$q->param('_Action');

# Update db as requested
if ($act eq 'update') {
	my $post=$dbi->tab($q->param('_Table'))->new_post($q);
	$post->update;
} elsif ($act eq "delete") {
	$dbi->tab($q->param('_Table'))->del($q->param('_id'));
}

# Bring up the next editor page
if ($act eq 'edit') {
	my $post=$dbi->tab($q->param('_Table'))->get($q->param('_id'));
	$v=new DBIx::HTMLView::CGIReqEdit($script, $post);
} elsif ($act eq 'add') {
	my $post=$dbi->tab($q->param('_Table'))->new_post();
	$v=new DBIx::HTMLView::CGIReqEdit($script, $post);	
} elsif ($act eq 'show') {
	$v=$dbi->tab($q->param('_Table'))->get($q->param('_id'));
} else {
	$v=new DBIx::HTMLView::CGIListView($script, $dbi, $q);
}

print "<html><head><title>DBI Interface</title></head><body>\n";
print $v->view_html() . "\n";
print "</body></html>\n";

