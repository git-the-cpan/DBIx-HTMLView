#!/usr/bin/perl

#  Str.pm - A single line string filed
#  (c) Copyright 1999 Hakan Ardo <hakan@debian.org>
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

  DBIx::HTMLView::Str - A single line string filed


=head1 SYNOPSIS

  $fld=$post->fld('testf');
  print $fld->view_html;

=head1 DESCRIPTION

This is a subcalss of DBIx::HTMLView::Field used to represent string
fields in the databse as well as the data contained in it. Se the
DBIx::HTMLView::Field and DBIx::HTMLView:.Fld (the superclass of
Field) manpage for info on the methods of this class.

=cut

package DBIx::HTMLView::Str;
use strict;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::Field;
@ISA = qw(DBIx::HTMLView::Field);

sub name_vals {
  my $self=shift;
  if ($self->got_val) {
    return ({name=>$self->name, val=> $self->tab->db->sql_escape($self->val) });
  } else {
    return ();
  }
}

sub sql_create {my $self=shift;$self->db->sql_type("Str",$self)}



1;

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
