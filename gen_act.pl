#!/usr/bin/perl

use config2;
use strict;
my $dbi=config2::dbi;

my $dir=$ARGV[0];

foreach ($dbi->tabs) {
	open (F, ">$dir/_delete_".$_->name);
	print F 'sub {my ($dbi, $q)=@_;'. "\n";
	print F $_->delete_code . "\n";
	print F "}\n";
	close(F);
}
