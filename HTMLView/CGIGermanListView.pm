#!/usr/bin/perl

#  CGIGermanListView.pm - A List user interface for DBI databases
#  (c) Copyright 1999 Hakan Ardo <hakan@debian.org>
#  (c) Copyright 2000 Konrad Riedel <k.riedel@gmx.de> 
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

  DBIx::HTMLView::CGIGermanListView - A List user interface for DBI databases

=head1 SYNOPSIS

  $view=new DBIx::HTMLView::CGIGermanListView($script, $dbi, $cgi);
  print $view->view_html;

=head1 DESCRIPTION

This is a database viewer/editer using the CGI interface and HTML
forms to present the user interface to the user. It's a very simple
interface. At the top all the tables of the database are listed to
allow the user to select which one to edit (including a + sign for
adding a new post, and at the bottom the selected table is listed. 
If the table has more than defined in {'rows'}, output is split into pages.
Every post has a link to allow you to show, edit or delete them. 
There is also a link to add new posts to the table. 

To be able to use this you need a cgi script that sets up a few things
and decides which editor to use to edit single posts and to insert
default values and so on... For a simple such script see View.cgi.

This is a subclass to DBIx::HTMLView::CGIView. 
=head1 METHODS
=cut

package DBIx::HTMLView::CGIGermanListView;
use strict;

use vars qw(@ISA);
require DBIx::HTMLView::CGIView;
@ISA = qw(DBIx::HTMLView::CGIView);

sub new {
  my $self=DBIx::HTMLView::CGIView::new(@_);
#pass rows via new HOWTO?
  $self->{'view_flds'}=undef;
  $self->{'extra_sql'}=undef;
  $self->{'page'}=1;
  $self->{'rows'}=50;
  $self;
}

=head2 $view->flds_to_view(@flds)

Specifys which flds to view by listing there names. Default is to view
all fields of a post but none of the relations.

=cut

sub flds_to_view {
  my $self=shift;
  my @flds=@_;
  $self->{'view_flds'}=\@flds;
}

=head2 $view->extra_sql($extra)

If you want to add some extra SQL clauses to the end of the select
command they can be given here. This can be used to specify in which
order the posts should appear by giving an ORDER clause.

=cut

sub extra_sql {
  my $self=shift;
  $self->{'extra_sql'}=shift;
}
#move to SUPERCLASS?
=head2 $view->restrict_tabs($tabs_to_show)

If you don't want all tabels to show up at the top of the editor you
can here specify which you want there by letting $tabs_to_show be an
array ref to an array liste the names of those tables.

Note that this is not a secure way to prevent users from getting
access to the tables as some simple tampering with the html forms
passed to the user will bring up the other tables as well for editing.

=cut

sub restrict_tabs {
  my $self=shift;
  $self->{'restrict_tabs'}=shift;
  if (!defined $self->cgi->param('_Table')) {
    $self->cgi->param('_Table',  $self->{'restrict_tabs'}[0]);
  }
}

=head2 $view->view_html

Returns the html code for the editor as specified by previous methods.

=cut

sub view_html {
  my ($self)=@_;
  my $q=$self->cgi;
  my $script=$self->script_name;
  my $tab=$self->tab->name;
  my $res =  << "EOF";
<table width="100%" border=0 cellspacing=1 cellpadding=2 bgcolor=#cccccc>
 <tr align=center>
 <td bgcolor=#cccccc
EOF

  if (defined $self->{'restrict_tabs'}) {
    foreach (@{$self->{'restrict_tabs'}}) {
      $res .= "<td><a href=\"$script?_Table=$_&"
        .$self->lnk.'">'.$_. '</a> ';
      $res .= '<a href="'.$script.'?_Table='.$_.
      '&_Action=add&'.$self->lnk.'">+</a></td> ';
    }
  } else {
    foreach ($self->db->tabs) {
      $res .= "<td><a href=\"$script?_Table=".$_->name.'&'
        .$self->lnk.'">'.$_->name. '</a> ';
      $res .= '<a href="'.$script.'?_Table='.$_->name.
      '&_Action=add&'.$self->lnk.'">+</a></td> ';
    }
  }
  $res .= '</tr></table>';

  my $cmd=$q->param('_Command');
  if (!defined $cmd) {$cmd=""}

  my $lst=undef;
  my $p;
  my $hits;
  
  my $act=$q->param('_Action');
  my $order=$q->param('_Order');
  $self->{'extra_sql'}="ORDER BY $order DESC" if defined $order;
  $self->{'page'}=$q->param('_Page')||1;
  if (defined $act && $act eq 'search') {
    $lst=$q->param('_Command');
  }  
  $hits=$self->db->tab($tab)->list($lst,$self->{'extra_sql'},
      $self->{'view_flds'});

  my $pages = int($hits->rows/$self->{'rows'})+1;
  $res.='<table width="100%" border=0 cellspacing=1 cellpadding=2>';
  $res.="<tr><td colspan=2><h2> $tab (";
  $res.=$self->{'page'}."/$pages)</h2>";
  $res .= '<a href="'.$script.'?_Action=add&'.$self->lnk.'">Datensatz hinzufügen</a> </td>';
  $res .= << "EOF";
<td colspan=3>
    <form method=POST action="$script">
    <input name="_Command" VALUE="$cmd">
    <input type=hidden name="_Action"  value="search">
    <input type=submit value="Suchen">
  <br>zBsp Name LIKE 'a%'
EOF

#use Data::Dumper; print Dumper($self)."<p>";
  $res.=$self->form_data .'</form></td>'; 
  $res.='</td></tr></table>';
  for (1..$pages) { 
    $res .= '<a href="'.$script.'?_Page='.$_;
    $res .= "&_Order=$order"if defined $order; 
    $res .= "&_Action=search&_Command=".$self->cgi->escape($lst) if defined $lst; 
    $res .=  '&'.$self->lnk."\">$_</a> ";
  }
        my $id .= $self->db->tab($tab)->id->name;
  $res .= $hits->view_html(
#'<a href="'.$script.'?_id=<fld id>&_Action=show&'.$self->lnk.'">Anz.</a> '.
      '<a href="'.$script."?_id=<fld $id>&_Action=edit&".$self->lnk.'">Bearb.</a> '.
      '<a href="'.$script."?_id=<fld $id>&_Action=delete&".$self->lnk.'">Löschen</a> ',
      $self->{'view_flds'},$self);

  $res;
}

1;



# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
