#!/usr/bin/perl

use config2;
use strict;

my $dbi=config2::dbi();



my ( $fmt, $tab, $sel, $extra_select, $extra_from, $extra_where, $extra, $vir, $uid)=@ARGV;
$tab=undef if ($tab eq '');
$sel=undef if ($sel eq '');
$extra_select=undef if ($extra_select eq '');
$extra_from=undef if ($extra_from eq '');
$extra_where=undef if ($extra_where eq '');
$extra=undef if ($extra eq '');
$uid=undef if ($uid eq '');


if (defined $fmt && $fmt ne '-') {
	open (F, "<$fmt")||die "Fmt '$fmt' not found\n";
	$fmt="";
	while (<F>) {$fmt.=$_}
	close(F);
} else {
	$fmt="";
	while (<STDIN>) {$fmt.=$_}
}

my %inops;

if ($fmt =~ /<default\s+(table)\s*=\s*\"?([^>\s^\"]+)\"?\s*>/i) {
	$tab=$2 if (!defined $tab && lc($1) eq "table");
}

my $fmtopt;
$fmtopt->{'table'}=$tab if (defined $tab);
$fmtopt->{'select'}=$sel if (defined $sel);
$fmtopt->{'extra_select'}=$extra_select if (defined $extra_select);
$fmtopt->{'extra_from'}=$extra_from if (defined $extra_from);
$fmtopt->{'extra_where'}=$extra_where if (defined $extra_where);
$fmtopt->{'extra_sql'}=$extra if (defined $extra);
$fmtopt->{'uid'}=$uid if (defined $uid);

if ($sel eq '') {$sel=undef;}

my $nps=DBIx::HTMLView::PostSet->new($dbi->tab($tab));
my $fmt=$nps->compiled_fmt('view_html', $fmt, undef, $fmtopt);
my $sel=$nps->fmt_sel;

my $sql=$sel->sql_select($fmtopt->{'extra_select'}, 
												 $fmtopt->{'extra_from'},
												 $fmtopt->{'extra_where'});

# Fulhack!!! Inte Bra!
if($vir eq 'nogroup')
{
$sql =~ s/group by.*$//;
}



if (defined $fmtopt->{'extra_sql'}) {$sql.=" " .$fmtopt->{'extra_sql'};}
$sql=~s/\'/\\\'/g;
$fmt=~s/<Value ([^>]+)>/'$row->['.$sel->field_pos($sel->view_fld($1)).']'/ge;



my $do = 'my $hits=$sth->execute(@$sel);
my $row=$sth->fetchrow_arrayref;';


# Fulhack!!! Inte Bra!
if($vir eq 'virtual')
{
$sql="";
$do = '
my $hits=1;
my $row=$sel;
$sth = fake_sth->new();
$sth->fetchrow_arrayref;
';
}

if($fmtopt->{'uid'} eq 'yes')
{
	$uid = ', "uid"';
}
else {$uid="";}

print '[\''.$sql.'\', sub {
my ($dbi, $sth, $sel, $q, $r)=@_;'.$do.'
my $res="";

'.$fmt.'

return $res;
}'.$uid.']';


