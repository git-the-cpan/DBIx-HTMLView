#!/usr/bin/perl

#  Id.pm - A index filed used to identifi posts
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

  DBIx::HTMLView::Id - A index field used to identify posts

=head1 SYNOPSIS

  $fld=$post->fld('id');
  print $fld->view_html;

=head1 DESCRIPTION

This is a subclass of DBIx::HTMLView::Field used to represent the id
fields of a table in the databse as well as the data contained in it. 
See the DBIx::HTMLView::Field and DBIx::HTMLView:.Fld (the superclass 
of Field) manpage for info on the methods of this class.

Each post must have an unique id number which the HTMLView system
uses to identify the post. The id has to be stored in the database in
a field which is specifyed by this class in the DBIx::HTMLView::Table
object used to represent the table. There should only be one Id field.

If you try to generate an html editor using the edit_html method this
Fld will return a <input type=hidden ...> field that is used in the
form to specify which post is being edited. 

This behaviour of not allowing the user to edit the id should probably
not be modified as the id might be stored in other places (for
eaxample relations) too, and has to be updated there too.

=cut

package DBIx::HTMLView::Id;
use strict;

use vars qw(@ISA);
require DBIx::HTMLView::Int;
@ISA = qw(DBIx::HTMLView::Int);

sub default_fmt {
  my ($self, $kind)=@_;
  if ($kind eq 'edit_html') {
    return   $self->fmt('view_html') . 
      '<perl>if ($self->got_val) { return ' .
        '"<input type=hidden name=\"".$self->name . "\" value=\"".$self->var("val")."\">"' . 
      '} </perl>';
  }
  return DBIx::HTMLView::Field::default_fmt(@_);
}

# FIXME: Make all Flds pass on ther $self vars like this
sub sql_create {my $self=shift; $self->db->sql_type("Id",$self)}

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
