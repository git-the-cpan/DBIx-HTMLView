#!/usr/bin/perl

#  CGIListView.pm - A List user interface for DBI databases
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

  DBIx::HTMLView::CGIListView - A List user interface for DBI databases

=head1 SYNOPSIS

	$view=new DBIx::HTMLView::CGIReqEdit($script, $dbi, $cgi);
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

This is a subclass to DBIx::HTMLView::CGIView so for methods defined
ther se it's manpage. 
=head1 METHODS
=cut

package DBIx::HTMLView::CGIListView;
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

If you want to add som extra SQL clauses to the end of the select
command they can be given here. This can be used to specify in which
order the posts should appear by giving an ORDER clause.

=cut

sub extra_sql {
  my $self=shift;
  $self->{'extra_sql'}=shift;
}

=head2 $view->restrict_tabs($tabs_to_show)

If you don't want all tabels to show up at the top of the editor you
can here specify which you want there by letting $tabs_to_show be an
array ref to an array liste the names of those tabels.

Note that this is not a secure way to prevent users from getting
access to the tables as some simple tampering with the html forms
passed to the user will bring up the other tabels as well for editing.

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
<h1>Current table: $tab</h1>

<b>Change table</b>: 
EOF

	$res .= "<form method=POST action=\"$script\">";
	my $data = $self->form_data;
	$data =~ s/<input type=hidden name="_Table" value="[^\"]+">//;
  $res.=$data;

  if (defined $self->{'restrict_tabs'}) {
  	foreach (@{$self->{'restrict_tabs'}}) {
  	  $res .= '<input type=submit name=_Table value="' . $_ . '">';
    }
  } else {
  	foreach ($self->db->tabs) {
	  	$res .= '<input type=submit name=_Table value="' . $_->name . '">';
  	}
  }
  $res .= '</form>';

my $cmd=$q->param('_Command');
if (!defined $cmd) {$cmd=""}
$res .= << "EOF";
<p>
<form method=POST action="$script">
  <B>Search</b>: <input name="_Command" VALUE="$cmd">
	<input type=hidden name="_Action"  value="search">
  <input type=submit value="Search">
EOF

  $res .= $self->form_data . "</from><hr>";
	
	my $hits;
  my $lst=undef;
  my $act=$q->param('_Action');
	if (defined $act && $act eq 'search') {
		$lst=$q->param('_Command');
	}  
	$hits=$self->db->tab($tab)->list($lst,$self->{'extra_sql'},
																	 $self->{'view_flds'});

	$res .= $hits->view_html(
    '<a href="'.$script.'?_id=<fld id>&_Action=show&'.$self->lnk.'">Show</a> '.
    '<a href="'.$script.'?_id=<fld id>&_Action=edit&'.$self->lnk.'">Edit</a> '.
    '<a href="'.$script.'?_id=<fld id>&_Action=delete&'.$self->lnk.'">Delete</a> ',
    $self->{'view_flds'}
  );

	$res .= '<a href="'.$script.'?_Action=add&'.$self->lnk.'">Add</a> ';
	$res;
}

1;


