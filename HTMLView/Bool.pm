#!/usr/bin/perl

#  Bool.pm - A multi line string filed
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

  DBIx::HTMLView::Bool - A boolean field

=head1 SYNOPSIS

  $fld=$post->fld('testf');
  print $fld->view_html;

=head1 DESCRIPTION

This is a subclass of DBIx::HTMLView::Str used to represent boolean 
data (eg true or false). It is represented by a one character field 
that is default wither Y or N. The main difference from a Str is that 
the default edit_html editor uses a two  <input type=radio ...> buttons 
to construct the editor.

$data of the constructor (see the new method of DBIx::HTMLView::Fld)
can have the following values specified:

true - the value stored in the databse when this field should represent
  true, default Y.  
false - the value stored in the databse when this field should represent 
  false, default N.  
view_true - the value used to view a true value for the view_html, 
  edit_html and view_text methods, defaule Yes.
view_false - the value used to view a false value for the view_html, 
  edit_html and view_text methods, defaule No.

=head1 METHODS
=cut

package DBIx::HTMLView::Bool;
use strict;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::Bool;
@ISA = qw(DBIx::HTMLView::Str);

sub true {
  my $self=shift;
  if ($self->got_data('true')) {return $self->data('true')}
  return 'Y';
}
sub false {
  my $self=shift;
  if ($self->got_data('false')) {return $self->data('false')}
  return 'N';
}
sub view_true {
  my $self=shift;
  if ($self->got_data('view_true')) {return $self->data('view_true')}
  return 'Yes';
}
sub view_false {
  my $self=shift;
  if ($self->got_data('view_false')) {return $self->data('view_false')}
  return 'No';
}

sub edit_html {
	my ($self)=@_;

	my $name = $self->name;

	my $val="";
	$val=$self->val if ($self->got_val);

	my $val1="";
	my $val2="checked";
    if( $val eq $self->true ) {
        $val1="checked";
        $val2="";
    }

    return "<input type='radio' name='$name' value='" . $self->true .
				   "' $val1 >" . $self->view_true . "&nbsp;&nbsp;" . 
           "<input type='radio' name='$name' value='" . $self->false .
					 "' $val2>" . $self->view_false;
}

sub view_text {
  my $self=shift;
	my $val="";
	$val=$self->val if ($self->got_val);
  if( $val eq $self->true ) {
    return $self->view_true;
  } else {
    return $self->view_false;
  }
}

sub sql_create {my$self=shift;$self->db->sql_type("Bool",$self)}

1;
