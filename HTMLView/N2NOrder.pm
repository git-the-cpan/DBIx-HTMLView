#!/usr/bin/perl

#  N2NOrder.pm - A relation to a set of posts in a specific order
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

  DBIx::HTMLView::N2NOrder - A relation to a set of posts in a specific order

=cut

package DBIx::HTMLView::N2NOrder;
use strict;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::N2N;
@ISA = qw(DBIx::HTMLView::N2N);

require DBIx::HTMLView::Fmt;

sub new {
  my $self=DBIx::HTMLView::N2N::new(@_);
  my $sql='order by '.$self->order_field_name . " desc";

  if (!$self->got_data('extra_sql')) {
    $self->{'data'}{'extra_sql'}=$sql
  } else {
    if ($self->data('extra_sql') ne $sql) {
      warn "Using the extra_sql param (".$self->data('extra_sql').") with a N2NOrder and we ".
           "won't be able to inflict the specified order";
    }
  }
  $self;
}

sub order_field_name {
  my $self=shift;
  if ($self->got_data('order_field')) {
    return $self->data('order_field');
  } else {
    return "ord";
  }
}

use DBIx::HTMLView;

sub lnk_tab {
  my $self=shift;
  if (!defined $self->{'lnk_tab'}) {
    $self->{'lnk_tab'}=DBIx::HTMLView::Table($self->lnk_tab_name,
					     DBIx::HTMLView::Id($self->id_name), 
					     DBIx::HTMLView::Int($self->from_field_name), 
					     DBIx::HTMLView::Int($self->to_field_name),
					     DBIx::HTMLView::Order($self->order_field_name)
					    );
    $self->{'lnk_tab'}->set_db($self->db);
  }
  $self->{'lnk_tab'};
}

sub move_up {
  my($self, $toid)=@_;
  my $lpost=$self->lnk_tab->list($self->from_field_name.'='.$self->id. ' AND '.
                                 $self->to_field_name.'='.$toid)->first;
  my $ord=$lpost->fld($self->order_field_name)->val;
                                 

  my $ps=$self->lnk_tab->list($self->order_field_name . "<" . $ord . ' AND '.
                              $self->from_field_name.'='.$self->id, 
                              'order by ' . $self->order_field_name . ' desc');
  my $p=$ps->first;
  my $t=$p->fld($self->order_field_name)->val;
  $p->set($self->order_field_name, $ord);
  $lpost->set($self->order_field_name, $t);

  $p->update;
  $lpost->update;
}

sub move_down {
  my($self, $toid)=@_;
  my $lpost=$self->lnk_tab->list($self->from_field_name.'='.$self->id. ' AND '.
                                 $self->to_field_name.'='.$toid)->first;
  my $ord=$lpost->fld($self->order_field_name)->val;
                                 

  my $ps=$self->lnk_tab->list($self->order_field_name . ">" . $ord . ' AND '.
                              $self->from_field_name.'='.$self->id, 
                              'order by ' . $self->order_field_name );
  my $p=$ps->first;
  my $t=$p->fld($self->order_field_name)->val;
  $p->set($self->order_field_name, $ord);
  $lpost->set($self->order_field_name, $t);

  $p->update;
  $lpost->update;
}

sub view_fmt {
  my ($self, $fmt_name, $fmt)=@_;  
  if (!defined $fmt) {$fmt=$self->fmt($fmt_name)}  
  
  if (defined $self->db->viewer && $self->got_id) {
    my $s=$self->db->viewer->script;
    my $q=$self->db->viewer->lnk.
      "&_id=" . $self->post->id .
      "&_fld=" . $self->name .
      "&_to_id=<fld " . $self->to_tab->id->name . ">";
    
    $fmt =~ s/<Order MoveUp>/<a href="$s?$q&_Action=move_up">Up<\/a>/gi;
    $fmt =~ s/<Order MoveDown>/<a href="$s?$q&_Action=move_down">Down<\/a>/gi;
  }

  DBIx::HTMLView::N2N::view_fmt($self, $fmt_name, $fmt);
}

sub view_fmt_code{DBIx::HTMLView::Fld::view_fmt_code(@_)}

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
