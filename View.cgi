#!/usr/bin/perl

BEGIN {
  use CGI;
  $q = new CGI;
  $|=1; 
  if (!defined $q->param("_done")) {print "Content-Type: text/html\n\n";}
  open STDERR, ">&STDOUT";
}

use DBIx::HTMLView;

# Config
use config;
my $script="View.cgi";
#&get_auth($q); # Uncomet this if you want to have this script to ask 
               # for user name and password
my $dbi=config::dbi($q->param('_usr'), $q->param('_pw'));

require DBIx::HTMLView::CGIListView;
require DBIx::HTMLView::CGIGermanListView;
require DBIx::HTMLView::CGIQueryListView;
require DBIx::HTMLView::CGIReqEdit;

my $act=$q->param('_Action');

# Update db as requested
if ($act eq 'update') {
  my $post=$dbi->tab($q->param('_Table'))->new_post($q);
  $post->update;
} elsif ($act eq "delete") {
  $dbi->tab($q->param('_Table'))->del($q->param('_id'));
}

# Jump to _done if defined
if (defined $q->param("_done")) {
        print "Location: " . $q->param("_done") . "\n\n";
        exit;
}

# Bring up the next editor page
if ($act eq 'edit') {
  my $post=$dbi->tab($q->param('_Table'))->get($q->param('_id'));
  $v=new DBIx::HTMLView::CGIReqEdit($script, $post, undef, $q);
} elsif ($act eq 'add') {
  my $post=$dbi->tab($q->param('_Table'))->new_post();
  $v=new DBIx::HTMLView::CGIReqEdit($script, $post, undef, $q);  
} elsif ($act eq 'show') {
  $v=$dbi->tab($q->param('_Table'))->get($q->param('_id'));
} elsif ($act eq 'query') {
  $v=new DBIx::HTMLView::CGIQueryListView($script, $dbi, $q);
} else {
  $v=new DBIx::HTMLView::CGIListView($script, $dbi, $q);
  #$v->rows(3);
}

print "<html><head><title>DBI Interface</title></head><body>\n";
print $v->view_html() . "\n";
print "</body></html>\n";

sub get_auth {
  if (!defined $q->param('_usr')) {
    print "<html><body><form method=post action=\"$script\"><table>\n";
    print "<tr><td>Name: </td><td><input name=_usr></td></td>\n";
    print "<tr><td>Password: </td><td><input type=password name=_pw></td></td>\n";
    print "<tr><td><input type=submit value=login></td></tr>\n";
    print "</table></form></body></html>\n";
    exit;
  }
}

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
