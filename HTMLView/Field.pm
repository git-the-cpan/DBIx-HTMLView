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

  confess "Field contains no data" if (!defined $self->{'val'});
  $self->{'val'};
}

=head2 $fld->got_val

Return true if the value of this field is set (defined).

=cut

sub got_val {
  (defined shift->{'val'});
}

sub default_fmt {
  my ($self, $kind)=@_;
  if ($kind eq 'edit_html') {
		my $js='';
		if ($self->get_onChange_name() ne '') {
			$js=' onChange="' . $self->get_onChange_name().'() ';
		}

		return   '<input name="<var name>"' . $js
			. '" value="<perl>js_escape($self->var("val"))</perl>" size='
			. $self->edit_size .'>';
 

  }
  return DBIx::HTMLView::Fld::default_fmt(@_);
}

sub sql_data {
  my ($self, $sel)=@_;
  #my $fld='Search_'.$self->tab->name . "." . $self->name;
  my $fld=$self->tab->name . "." . $self->name;
  $sel->add_fld($fld);
  $fld;
}

sub del {}

sub field_name{shift->name}

sub post_updated{}

=head2 $fld->view_fmt($fmt_name, $fmt)

Se DBIx::HTMLView::Fld for a general description. As for the format of
the fmt string used here, the following substrings will be replaced
with described values:

$val - The value of this field
$name - The name of this field

=cut

sub view_fmt {
  my ($self, $fmt_name, $fmt)=@_;
  my $val;

  if (!defined $fmt) {$fmt=$self->fmt($fmt_name);}

  my $p=DBIx::HTMLView::Fmt->new;
  return $p->parse_fmt($self, $fmt_name, $fmt);
}

sub compiled_fmt {
  my ($self, $fmt_name, $fmt, $sel, $opt)=@_;
  my $val;

  if (!defined $fmt) {$fmt=$self->fmt($fmt_name);}

  my $p=DBIx::HTMLView::Fmt->new;
  return $p->compiled_fmt($self, $fmt_name, $fmt, $sel, $opt);
}

sub view_fmt_code {
  my ($self, $fmt_name, $fmt)=@_;
  my $val;

  if (!defined $fmt) {$fmt=$self->fmt($fmt_name);}

  my $p=DBIx::HTMLView::Fmt->new;
  return $p->parse_fmt_to_code($self, $fmt_name, $fmt);
}

sub var {
  my ($self, $var) =@_;
  if (lc($var) eq 'val') {
    return  $self->val if ($self->got_val);
    return "";
  }
  if (lc($var) eq 'name') {
    return $self->name;
  }
  return "";
}

1;


# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
