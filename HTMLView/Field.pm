#!/usr/bin/perl

#  Field.pm - Base class for field classes
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

  DBIx::HTMLView::Field - Base class for field classes

=head1 SYNOPSIS

  $fld=$post->fld('testf');
  print $fld->view_html;

=head1 DESCRIPTION

This is a subcalss of DBIx::HTMLView::Fld used to represent fields in
the databse as well as the data contained in it. Except for the
methods decsribed in the DBIx::HTMLView::Fld man page this class
contains some methods for handling the data contain in the field. They
are described below. 

It also contains default implementations of all the virtual methods
except name_vals described in that man page. For viewing this means
the value is used without any formating (both for text and html), and
for the edit_html method a standard <input size=80 ...> tag is used.

The size 80 can be changed by setting the edit_size key to the wanted 
size in the $data hash passed to the new method, see 
DBIx::HTMLView::Fld.

=head1 METHODS
=cut

package DBIx::HTMLView::Field;
use strict;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::Fld;
@ISA = qw(DBIx::HTMLView::Fld);

=head2 $fld->val

Returns the value of this field if it's value is set. otherwise it
dies with "Field conatins no data".

=cut

sub edit_size  {
  my $self=shift;
  if ($self->got_data('edit_size')) {return $self->data('edit_size')}
  return 80;
}


sub val {
	my $self=shift;

	croak "Field contains no data" if (!defined $self->{'val'});
	$self->{'val'};
}

=head2 $fld->got_val

Return true if the value of this field is set (defiend).

=cut

sub got_val {
	(defined shift->{'val'});
}

sub view_text {
	my $self=shift;
	if ($self->got_val) {
		return $self->val
	} else {
		return "";
	}
}

sub view_html {
	shift->view_text(@_);
}

sub edit_html {
	my $self=shift;
	my $val="";

 	$val=$self->val if ($self->got_val);
	'<input name="' . $self->name . '" value="'. js_escape($val) .'" size='.
	$self->edit_size . '>';
}

# FIXME: Move this to a different module!
# Escapes "'s
sub js_escape {
    my $str = shift;
    $str =~ s/"/&quot;/g;
    return $str;
}

sub sql_data {
	my ($self, $sel)=@_;
	my $fld=$self->tab->name . "." . $self->name;
	$sel->add_fld($fld);
	$fld;
}

sub del {}

sub field_name{shift->name}

sub post_updated{}
1;

