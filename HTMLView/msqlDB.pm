#!/usr/bin/perl

#  msqlDB.pm - HTMLView database object for msql databases
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

  DBIx::HTMLView::msqlDB - interface for msql databases through DBI

=head1 SYNOPSIS

use DBIx::HTMLView;
my $dbi=my $dbi=msqlDB("DBI:msql:HTMLViewTester", "", "", 
                   Table ('Test', Id('id'), Str('testf')));
my $list=$dbi->tab('Test')->list();


=head1 DESCRIPTION

This is a customized DB object for msql databases.  Most methods
are inherited from the superclass: DBIx::HTMLView::DB -- only 
those that are specific to msql are overridden.

=head1 METHODS
=cut

package DBIx::HTMLView::msqlDB;
use strict;

use DBI;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::DB;
@ISA = qw(DBIx::HTMLView::DB);

sub insert {
  my ($self, $tab, $post)=@_;
  my $id=$self->send('select _seq from ' . $tab->name)->fetchrow_arrayref->[0];
  $post->set($tab->id->name, $id);

  DBIx::HTMLView::DB::insert($self, $tab, $post);
}

sub sql_create_table {
  my ($self, $table)=@_;
  DBIx::HTMLView::DB::sql_create_table($self, $table);
   $self->send("CREATE UNIQUE  INDEX idx1 ON " . $table->name . "(" . 
              $table->id->name . ")");
  $self->send("CREATE SEQUENCE ON " . $table->name . " STEP 1");
}

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
