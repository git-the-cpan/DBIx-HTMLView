#!/usr/bin/perl

#  CGIView.pm - Common CGI functions for the viewers
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

  DBIx::HTMLView::CGIView - Common CGI functions for the viewers

=head1 SYNOPSIS

package MyCGIViewer

require DBIx::HTMLView::CGIView;
@ISA = qw(DBIx::HTMLView::CGIView);

sub new {
  my $self=DBIx::HTMLView::CGIView::new(@_);

  # ...
}

=head1 DESCRIPTION

This class some basic functions that can be used to create cgi
interfaces to a HTMLView database. And is therefor suited as a base
class for viewr or edit classes.

=head1 METHODS
=cut

package DBIx::HTMLView::CGIView;
use strict;
use Carp;
use URI::Escape;

=head2 $view=DBIx::HTMLView::CGIView->new($script, $db, $cgi)

Creates a new CGIView object that will use the url $script for future
requests to the database $db (a DBIx::HTMLVIew::DB object) and $cgi is
the CGI object containing the request we got from the user.

=cut


sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self=       bless {}, $class;

  my ($script, $db, $cgi)=@_;
  $self->{'script'}=$script;
  $self->{'db'}=$db;
  $self->{'cgi'}=$cgi;

  $self->{'pres_param'}=['_usr', '_pw', '_Page', '_Order',
			 '_Command', '_SubEditFld', '_SubEditVal', '_Maxrows',
			 '_Orderby', '_Thenby1', '_Thenby2',
			 ];
  my $i=0; foreach ($db->tab($self->tab_name)->fld_names()) {
    push @{$self->{'pres_param'}}, "_Ord".$i;
  }

  $self;
}

=head2 $view->script
=head2 $view->script_name

Returns the name of the script we should use for future calls as set
by the $script param to the constructor.

=cut

sub script {shift->script_name(@_)}
sub script_name {
  my $self=shift;
  confess ("No script defined") if (!defined $self->{'script'});
  $self->{'script'};
}

=head2 $view->lnk
=head2 $view->link_data

Returns a string that can be included in a link that will set the
params that is supposed to be presistand between requests. Curent that
is: _Table, the name of the table we are currently working on, _usr, 
the user name, and _pw, the password used to access the database.

=cut

sub lnk {shift->link_data(@_)}
sub link_data {
  my $self=shift;
  my $ret="_Table=" . $self->tab->name;

  if ($self->got_cgi) {
    foreach (@{$self->{'pres_param'}}) {
      if (defined $self->cgi->param($_)) {
				my $val=$self->cgi->param($_);
				$ret.="&$_=" . uri_escape($val, "^A-Za-z0-9");
      }
    }
  }
  $ret;
}

=head2 $view->form_data

Will return the same data as $view->link_data but in form of <input
type=hidden ...> tags to be included in a html form instead.

=cut

sub form_data {
  my $self=shift;
  my $ret='<input type=hidden name="_Table" value="'.$self->tab->name.'">';
  
  if ($self->got_cgi) {
    foreach (@{$self->{'pres_param'}}) {
      if (defined $self->cgi->param($_)) {
	my $val=$self->cgi->param($_);
	$ret.='<input type=hidden name="'.$_.
	  '" value="'. $val.'">';
      }
    }
  }
  $ret;
}

=head2 $view->db

Returns the database (a DBIx::HTMLView::DB object) we'r using, as set
by the $db parameter to the constructor.

=cut

sub db {
  my $self=shift;
  confess "No db defined!" if (!defined $self->{'db'});
  $self->{'db'};
}

=head2 $view->cgi

Returns the CGI object as set by the $cgi parameter to the constructor.

=cut

sub cgi {
  my $self=shift;
  confess "No cgi defined!" if (!defined $self->{'cgi'});
  $self->{'cgi'};
}

=head2 $view->got_cgi

Returns true if the CGI object was set by the $cgi parameter to the 
constructor.

=cut

sub got_cgi {
  my $self=shift;
  defined $self->{'cgi'};
}

=head2 $view->tab

Returns the table (a DBIx::HTMLView::Table object) we're currently
working with. Either as specified in the CGI query or the first table
found in the database if none was defined.

=cut

sub tab_name {
  my $self=shift;
  my $tab=$self->cgi->param('_Table');
  if (!defined $tab) {
    my @t=$self->db->tabs();
    $tab=$t[0]->name;
    $self->cgi->param('_Table',$tab);
  }
  $tab;
}

sub tab {
  my $self=shift;

  $self->db->tab($self->tab_name);
}

1;

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
