#!/usr/bin/perl

BEGIN {
    $|=1;
    print "Content-Type: text/html\n\n";
    open STDERR, ">&STDOUT";
}

use config;
use  DBIx::HTMLView;
require CGI;

# Config
my $db=config::dbi;
my $default_table='Artiklar';
my $fmt_path='/home/hakan/src/HTMLView/';
# End of Config

my $q=new CGI;
my $tab=$q->param('Tab');
if (!defined $tab) {$tab=$q->param('tab')}
if (!$tab) {$tab=$default_table};

my $fmt=$q->param('fmt');
if (!defined $fmt) {$fmt=$tab}
if ($fmt != /^[A-Za-z]+$/) {
    print "Illegal fmt: $fmt<br>\n";
    exit(0);
}
#open (F, "</home/interaf/public_html/pub/$fmt.fmt")||print "$fmt not found\n";
#open (F, "</home/hakan/src/HTMLView/$fmt.fmt")||print "$fmt not found\n";
open (F, "<$fmt_path/$fmt.fmt")||die "Fmt '$fmt' not found\n";

$cur=undef;
while (<F>) {
    if (/^Set\s+([A-Za-z]+)\s*$/) {$cur=$1;}
    elsif ($cur) {
        $var{uc($cur)}.=$_;
    }
}

my $max=$var{MAX};
if ($max=~ /^\s*(\d+)/) {$max=$1;}

if ($var{HEAD}) {print eval($var{HEAD});}

if (defined $q->param('query')) {
	my @flds=split(/,\s*/, $q->param('flds'));
	$sel="";
	foreach (@flds) {
		$sel.= "$_ CLIKE '%" . $q->param('query') . "%' OR ";
	}
	$sel =~ s/OR $//;
} elsif (defined $q->param('sel')) {
	$sel=$q->param('sel');
} else {
	$sel=undef;
}

my $f=undef;
if (defined $var{FLDS}) {
	$var{FLDS} =~ s/[\s\n]//gs;
	my @flds=split(/\s*,\s*/, $var{FLDS});
	$f=\@flds;
}

my $posts=$db->tab($tab)->list($sel,$var{EXTRA},$f);
while (defined ($_=$posts->get_next)) {
	$res=eval($var{NODE});
	die if (!$res);
	print $res;

	$max--;
	last if($max==0);
}

if ($var{FOOT}) {print eval($var{FOOT});}
