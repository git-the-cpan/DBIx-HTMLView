#!/usr/bin/perl

#  mysqlDB.pm - HTMLView database object for mysql databases
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 NAME

  DBIx::HTMLView::mysqlDB - interface for mysql databases through DBI

=head1 SYNOPSIS

use DBIx::HTMLView;
my $dbi=my $dbi=mysqlDB("DBI:mysql:HTMLViewTester", "", "", 
                   Table ('Test', Id('id'), Str('testf')));
my $list=$dbi->tab('Test')->list();


=head1 DESCRIPTION

This is a customized DB object for mysql databases.  Most methods
are inherited from the superclass: DBIx::HTMLView::DB -- only 
those that are specific to mysql are overridden.

=head1 METHODS

=cut

package DBIx::HTMLView::mysqlDB;
use strict;

use DBI;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::DB;
@ISA = qw(DBIx::HTMLView::DB);

sub insert {
  my ($self, $tab, $post)=@_;
  my $values="";
  my $names="";
  my $cmd="insert into " . $tab->name;

  foreach my $f ($post->fld_names) {
    foreach ($post->fld($f)->name_vals) {
      $names .=  $_->{'name'}.", ";
      $values .= $_->{'val'}.", ";
    }
  }

  # Add id as it might be the only field
  $names .= $post->tab->id->name;
  $values .= "NULL";

  my $sth=$self->send($cmd . " ($names) VALUES ($values)");
    my $insid;
  if (defined $sth->{'mysql_insertid'}) {
    $insid=$sth->{'mysql_insertid'};
  } else {
    $insid=$sth->{'insertid'};
  }      
  $post->set($tab->id->name, $insid);

  foreach my $f ($post->fld_names) {
    $post->fld($f)->post_updated;
  }
}

sub sql_type {
  my ($self, $type, $fld)=@_;
  my $t=lc($type);

  if ($fld->got_data('sql_type')) {return $fld->data('sql_type')}

  my $s="";
  $s="(".$fld->data('sql_size').")" if ($fld->got_data('sql_size'));

  if ($t eq 'id') {return "INT$s NOT NULL auto_increment, PRIMARY KEY (" .
                     $fld->name . ')'}
  if ($t eq 'int') {return "INT$s"}
  if ($t eq 'date') {return "DATE"}
  if ($t eq 'str') {if (!$s) {$s="(100)"} return "CHAR$s"}
  if ($t eq 'text') {return "TEXT$s"}
  if ($t eq 'bool') {if (!$s) {$s="(1)"} return "CHAR$s"}

  die "Bad type $t";
}

1;

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
