#!/usr/bin/perl

#  SubTab.pm - A table included as a part of a post in another table
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

  DBIx::HTMLView::SubTab - A table included as a part of a post in another table

=cut

package DBIx::HTMLView::SubTab;
use strict;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::N2N;
@ISA = qw(DBIx::HTMLView::N2N);

sub new {DBIx::HTMLView::Fld::new(@_)}

sub default_fmt {
    my ($self, $kind)=@_;
    if ($kind eq 'view_html') {
      my $flds=$self->lnk_tab->opt('flds_to_view');
      return $self->lnk_tab->list_fmt("view_html",undef,$flds);
    }
    if ($kind eq 'edit_html') {
      # FIXME: Allow user to specify script
      if ($self->got_id) {
	return '<a target="SubEdit" href="' . $self->db->viewer->script . '?_Table=' . 
	     $self->lnk_tab_name . 
	     '&_Command='.$self->from_field_name.'->'.
	     $self->tab->id->name."%3D".$self->id .
	     '&_SubEditFld='.$self->from_field_name.
	     '&_SubEditVal='.$self->id .
	     '">Edit</a>';
      } else {
	return '<i>Cant edit untill post in db</i>';
	# FIXME: Allow editing here too
      }
    }

    return DBIx::HTMLView::Relation::default_fmt(@_);
}

sub sql_create {return undef;}

sub post_set {
  my ($self)=@_;

  if (!$self->got_post_set) {    
    if ($self->got_id) {
      my $ex=undef;
      $ex=$self->data('extra_sql') if ($self->got_data('extra_sql'));
      $self->{'posts'}=$self->lnk_tab->list($self->from_field_name."=".
					    $self->id,$ex);
    } else {
      $self->{'posts'}=DBIx::HTMLView::PostSet->new($self->lnk_tab);
    }
  }
  return $self->{'posts'};
}

sub lnk_tab {
  my ($self)=@_;
  $self->db->tab($self->lnk_tab_name);
}

sub sql_data {
  my ($self, $sel, $sub)=@_;
  my $nxt=shift(@$sub);

  #my $ltn="Serach_" . $self->lnk_tab_name;
  my $ltn=$self->lnk_tab_name;

  $sel->add_tab($self->lnk_tab_name . " as $ltn"); 
  #$sel->add_fld("$ltn." . $self->from_field_name);
  return "$ltn." . $self->from_field_name .
         "=" . $self->tab->name . "." . $self->tab->id->name . " AND ".
	   $self->lnk_tab->fld($nxt)->sql_data($sel, $sub);
}

sub compiled_fmt {
  my ($self, $fmt_name, $fmt, $sel, $opt)=@_;
  if (!defined $fmt) {$fmt=$self->fmt($fmt_name)}  

  if ($fmt =~ /^<InRel>(.*)$/i) {
    $fmt=$1;
    my $p=DBIx::HTMLView::Fmt->new;
    return $p->compile_fmt($self, $fmt_name, $fmt);
  } else {
    my $tableid='<Value ' . $self->tab->name . '.' . $self->tab->id->name . '>';
    my $psel=DBIx::HTMLView::Selection->new($self->lnk_tab,
					    $self->from_field_name."=?",
					    []);    

    my $postfmt=DBIx::HTMLView::PostSet->new($self->lnk_tab)->compiled_fmt($fmt_name, $fmt, $psel, $opt);
    my $extra_select = $self->data('extra_select') if ($self->got_data('extra_select'));
    my $extra_from = $self->data('extra_from') if ($self->got_data('extra_from'));
    my $extra_where = $self->data('extra_where') if ($self->got_data('extra_where'));
    my $sql=$psel->sql_select($extra_select, $extra_from, $extra_where);

    $sql=~s/\'/\\\'/g;

    $sql.=" " . $self->data('extra_sql') if ($self->got_data('extra_sql'));
    $postfmt=~s/<Value ([^>]+)>/'$row->['.$psel->field_pos($psel->view_fld($1)).']'/ge;

    return '; {
my $sth=$dbi->prepare(\''.$sql.'\');
if (!defined $sth) {die $sth->errstr}
my $hits=$sth->execute('.$tableid.');

my $row=$sth->fetchrow_arrayref;

'.$postfmt.'

} $res=$res';

  }
}

1;

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
