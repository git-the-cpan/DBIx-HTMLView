#!/usr/bin/perl

#  Text.pm - A multi line string filed
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

  DBIx::HTMLView::Text - A multi line string filed



=head1 SYNOPSIS

  $fld=$post->fld('testf');
  print $fld->view_html;

=head1 DESCRIPTION

This is a subclass of DBIx::HTMLView::Str used to represent larger
texts. The main difference from a Str is that the default edit_html
editor uses a <textarea>...</textarea> construct instead of an 
<input ...> tag.

This fld also has two parameters that are specified in the $data hash
passed to the constructor (see the DBIx::HTMLView::Fld manpage). They
are 'width', the width of the <textarea> editor in characters
(defaults is 80) and 'height', the height of the <textarea> editor in
characters (default is 50).

Except for the methods described in the superclasses
(DBIx::HTMLView::Fld, DBIx::HTMLView::Field, DBIx::HTMLView::Str)
there are also the following methods.

=head1 METHODS
=cut

package DBIx::HTMLView::Text;
use strict;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::Text;
@ISA = qw(DBIx::HTMLView::Str);

=head2 $fld->width

Returns the witdh in characters of the default edit_html editor.

=cut

sub width {
  my $self=shift;
  if (!$self->got_data('width')) {
    return 80;
  } else {
    return $self->data('width');
  }
}

=head2 $fld->height

Returns the height in characters of the default edit_html editor.

=cut

sub height {
  my $self=shift;
  if (!$self->got_data('height')) {
    return 10;
  } else {
    return $self->data('height');
  }
}

sub default_fmt {
  my ($self, $kind)=@_;
  if ($kind eq 'edit_html') {
    return     '<textarea wrap=soft cols=' . $self->width . ' rows='.
      $self->height.' name="<var name>"><var val></textarea>';
  }
  return DBIx::HTMLView::Field::default_fmt(@_);
}

sub sql_create {my $self=shift;$self->db->sql_type("Text",$self)}

1;

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
