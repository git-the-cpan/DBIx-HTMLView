#!/usr/bin/perl

#  CGIQueryListView.pm - A List user interface for DBI databases
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

  DBIx::HTMLView::CGIQueryListView - A List user interface for DBI databases

=head1 SYNOPSIS

  $view=new DBIx::HTMLView::CGIQueryListView($script, $dbi, $cgi);
  print $view->view_html;

=head1 DESCRIPTION

This is a database viewer/editer using the CGI interface and HTML
forms to present the user interface to the user. It's a very simple
interface. At the top all the tabels of the database is listed to
allow the user to select which one to edit, and at the botom the
selected table is listed. Every post has a link to allow you to show,
edit or delete them. There is also a link to add new posts to the
table. 

To be able to use this you need a cgi script that sets up a few things
and decides which editor to use to edit single posts and to insert
default values and so on... For a simple such script see View.cgi.

This is a subclass to DBIx::HTMLView::CGIView. 
=head1 METHODS
=cut

package DBIx::HTMLView::CGIQueryListView;
use strict;

use vars qw(@ISA);
require DBIx::HTMLView::CGIView;
@ISA = qw(DBIx::HTMLView::CGIView);

sub new {
  my $self=DBIx::HTMLView::CGIView::new(@_);

  $self->{'view_flds'}=undef;
  $self->{'extra_sql'}=undef;
  $self;
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

=head2 $view->view_html

Returns the html code for the editor as specified by previous methods.

=cut

sub view_html {
  my ($self)=@_;
  my $q=$self->cgi;
  my $p;
  my $script=$self->script_name;
  my $res;

  my $id=$q->param('_id');
  if (defined($id)) {
    $res.='<h1>'.$q->param("B").'</h1>';
    my $p1=$q->param('_P1');
    my $p2=$q->param('_P2');
#use Data::Dumper; print Dumper($q)."<p>";
    my $hits=$self->db->tab("Abfragen")->get($id);
    my $sql=$hits->val('SQL')->view_text;
    $sql =~ s/_P1/$p1/e;
    $sql =~ s/_P2/$p2/e;
    print "$id $p1 $p2 $sql";
    my $sth=$self->db->send($sql);  

    $p=DBIx::HTMLView::PostSet->new($self->db->tab("Abfragen"), $sth,0);
    my @flds=$p->get_next->fld_names;
#FIXME: have to send $sql twice to get fld_names ?, 
    $sth->finish;
    $sth=$self->db->send($sql);
    $p=DBIx::HTMLView::PostSet->new($self->db->tab("Abfragen"), $sth,0);
$res.= $p->view_html(undef,\@flds) . "<br>\n";

#print "ID:$sql";  
  } else {
  my $hits=$self->db->tab("Abfragen")->list();
  
  my $fmt .= << "EOF";
<tr><td colspan=3><br><fld Bemerkung></td></tr><tr align=RIGHT>
    <form method=POST action="$script">
  <td><fld Parameter1>
    <input name="_P1" size=10></td>
    <td><fld Parameter2>
    <input name="_P2" size=10></td>
    <td><input type=hidden name="_Action"  value="query">
    <input type=hidden name="_id"  value="<fld id>">
    <input type=submit name="B" value="<fld Name>"></td></tr>
EOF
  $fmt.=$self->form_data .'</form>'; 
        $res.='<table width="100%" border=0 cellspacing=1 cellpadding=2 bgcolor=#cccccc>';
  while (defined ($p=$hits->get_next)) {
    $res.=$p->view_fmt('view_html', $fmt);
  }
  
  }
  $res.='</td></tr></table>';
  $res;
}

1;



# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
