#!/usr/bin/perl

use Socket;
use Carp;
use FileHandle;

use DBI;
use CGI;

#my $fmtdir="fmt";
my $fmtdir="/home/hakan/WWW/efunk.not/comp/fmt";
my %fmts;
my %dbis;
my $dbi;
my %actions;

my %hdr; # FIXME: Those var's has to be local to every thread/connection
my $q;

my $dbi=DBI->connect("DBI:mysql:elumni2");

# Load the compiled fmts and the htmlfile
my $fsth=fake_sth->new();
foreach (`ls $fmtdir/*`) {
	chop;
	my $name=$_;
	open(F, "<$name");
	my $con='';
	while (<F>) {$con.=$_;}
	close(F);

	$name=~s/^.*\/([^\/]+)$/$1/;

	if ($name !~ /\~$/) {
		print "$name\n";
		if ($name =~ /\.html?$/) {
			my $code='';
			while ($con=~s/^(.*?)<perl>(.*?)<\/perl>/$code.="'".escf($1)."'.eval {package fmt_code; $2}.";''/gies) {}
			$code.="'".escf($con)."'";
			$fmts{$name}=eval "sub {return $code}" || print $!;
		} elsif ($name =~ /^\_/) {
			$actions{$name}=eval($con);
		} else {
			my $fmt=eval($con);
			my $sth=$dbi->prepare($fmt->[0]);
			$fmts{$name}=sub {$fmt->[1]->($dbi, $sth, @_)};
			$fmts{'_new_'.$name}=sub {$fmt->[1]->($dbi, $fsth, @_)};
		}
	}
}

my $port = shift || 2345;
my $proto = getprotobyname('tcp');
socket(Server, PF_INET, SOCK_STREAM, $proto)        || die "socket: $!";
setsockopt(Server, SOL_SOCKET, SO_REUSEADDR,
pack("l", 1))   || die "setsockopt: $!";
bind(Server, sockaddr_in($port, INADDR_ANY))        || die "bind: $!";
listen(Server,SOMAXCONN) || die "listen: $!";

 
my $paddr;

for ( ; $paddr = accept(Client,Server); close Client) {
	autoflush Client 1;
	my($port,$iaddr) = sockaddr_in($paddr);
	
	$_=<Client>;
	my $req=$_;
	my $script;
	while (<Client>) {
		if (/^\s*$/) {last;}
		elsif (/^([^\:]+):\s*([^\n\r]+)/s) {$hdr{lc($1)}=$2;}
	}
	if ($req =~ /^(GET|POST)\s+\/([^\s]+)/i) {
		my $fmt_srv_file=$2;
		my @sel;
		$q=undef;
		if ($fmt_srv_file =~ /^([^\?]+)\?(.*)$/) {
			$fmt_srv_file=$1;
			$q=new CGI($2);

			# Make buttonspecifik param overrides overide the defaults
			if (defined $q->param('_but') && defined $q->param('_but_'.$q->param('_but'))){
				my $oq=new CGI($q->param('_but_'.$q->param('_but')));
				foreach ($oq->param) {
					if ($_ eq '_action') {
						$fmt_srv_file=$oq->param($_);
					} else {
						$q->param($_, $oq->param($_));
					}
				}
			}			
		} else {
			$q=new CGI("");
		}

		# Execute requst action
		if (defined $q && defined $q->param('_pre_action')) {
			$actions{$q->param('_pre_action')}->($dbi, $q) 
		}

		# Update database if requested
		if (defined $actions{$fmt_srv_file}) {
			$actions{$fmt_srv_file}->($dbi, $q);
			
			# Decide what to show next
			$fmt_srv_file=$q->param('_done'); # FIXME: Check which button was pressed
			if (!defined $fmt_srv_file || lc($fmt_srv_file) eq 'ref') {$fmt_srv_file=$hdr{'referer'};}

			# Send client to that fmt
			print Client "HTTP/1.0 301 Moved\nLocation: $fmt_srv_file\nConnection: close\n\n";
		} else {
			# Bring up requested fmt
			my $ctype=$q->param('_content_type');
			if (!$ctype) {$ctype='text/html';}
			print Client "HTTP/1.0 300 OK\nContent-Type: $ctype\nConnection: close\n\n";		
			if (defined $q) {@sel=split(/,\s*/,$q->param('sel'));}
			if (defined $fmts{$fmt_srv_file}) {
				print Client $fmts{$fmt_srv_file}->(\@sel, $q);
			} else {
				print Client "$fmt_srv_file not found!\n"
			}
		}
	} else {
		print Client "Bad request!\n";
	}
}

$dbi->disconnect;

sub escf {
	my ($v)=@_;
	$v=~s/\'/\\\'/g;
	$v;
}

package fmt_code;

use URI::Escape;


sub referer {
	if (defined $q->param('_poped_ref')) {
		return $q->param('_poped_ref');
	}
	return esc($hdr{'referer'});
}

sub push {
	'_history='.referer().'§'.$q->param('_history');
}

sub pop {
	my $r=uri_unescape(&referer);
	if ($r !~ /_poped_ref=/) {
		if ($q->param('_history') =~ /^([^§]+)§/) {
			my $popref="_poped_ref=$1";
			if ($r=~/\?/) {$r.='&';}
			else {$r.='?';}
			$r.=$popref;
		}
	}
	return  $r;
}

sub esc {
	my ($s)=@_;
	return uri_escape($s, "^A-Za-z0-9:.\\/");
}

package fake_sth;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self=       bless {}, $class;
}

sub execute {shift->{'first'}=1}
sub fetchrow_arrayref {
	my ($self)=@_;
	if ($self->{'first'}) {
		$self->{'first'}=0;
		$a[0]='';
		return \@a;
	}
	return [];
}
