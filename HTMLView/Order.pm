#!/usr/bin/perl

#  Order.pm - A Field specifying one order to display the posts in
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

  DBIx::HTMLView::Order - A Field specifying one order to display the posts in

=cut

package DBIx::HTMLView::Order;
use strict;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::Int;
@ISA = qw(DBIx::HTMLView::Int);

require DBIx::HTMLView::Fmt;


=head2 $fld->view_fmt_edit_html($postfmt_name, $postfmt)

=cut

sub view_fmt_edit_html {
  my ($self, $postfmt_name, $postfmt)=@_;

  my $opts='_fld='.$self->name.
           '&_id='.$self->post->id.'&'.
	   $self->db->viewer->lnk;

  return '<A HREF="'.$self->db->viewer->script.'?_Action=move_up&'.$opts.'">Up</a>, '.
         '<A HREF="'.$self->db->viewer->script.'?_Action=move_down&'.$opts.'">Down</a>';
}

sub move_up {
  my($self)=@_;
  my $ps=$self->tab->list($self->name . "<" . $self->val, 
                         'order by ' . $self->name . ' desc');
  my $p=$ps->first;
  my $t=$p->fld($self->name)->val;
  $p->set($self->name, $self->val);
  $self->{'val'}=$t;

  $p->update;
  $self->post->update;
}

sub move_down {
  my($self)=@_;
  my $ps=$self->tab->list($self->name . ">" . $self->val, 
                         'order by ' . $self->name);
  my $p=$ps->first;
  my $t=$p->fld($self->name)->val;
  $p->set($self->name, $self->val);
  $self->{'val'}=$t;

  $p->update;
  $self->post->update;
}

sub view_fmt_code{DBIx::HTMLView::Fld::view_fmt_code(@_)}

sub default_fmt {
  my ($self, $kind)=@_;
  if (defined $kind && $kind eq 'view_html') {
    return '<InRel><perl>$self->view_fmt_edit_html("view_html")</perl>';
  }
  
  return DBIx::HTMLView::Relation::default_fmt(@_)
}

sub name_vals {
  my ($self)=@_;

  if (!$self->got_val) {
    my $maxp=$self->tab->list(undef, 'order by ' . $self->name.' desc')->first;
    if (defined $maxp) {
      $self->{'val'}=$maxp->fld($self->name)->val+1;
    } else {
      $self->{'val'}=1;
    }
  }

  DBIx::HTMLView::Int::name_vals(@_);
}

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
