#!/usr/bin/perl

#  CGIReqView.pm - A Requester viewer/editor for DBI databases
#  (c) Copyright 1998 Hakan Ardo <hakan@debian.org>
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

  DBIx::HTMLView::CGIReqView - A Requester viewer/editor for DBI databases

=head1 SYNOPSIS

use DBIx::HTMLView::CGIListView;
use DBIx::HTMLView::CGIReqView;

my $db="DBI:mSQL:HTMLViewTester:athena.af.lu.se:1114";

$q = new CGI;
if (DBIx::HTMLView::CGIReqView::Handles($q)) {
	$v=new DBIx::HTMLView::CGIReqView($db, {}, $q);
} else {
  # Use some other view list CGIListView for example...
}

$v->PrintPage("this_file.cgi");

=head1 DESCRIPTION

This is a CGI interface based on the CGIView class (eg a subclass of) that 
allows you to edit or view one post in a table. Alla data is shown and all
data except the key is editable, if the $self->{'editable'} variable is 
not modified, in which case it should contain a regexp matching all editable
fields. It could be costruncted as "<field1>|<field2>|<field3>|...".

By seting the _New key in the CGI query a blank form will show upp for 
adding new posts. By setting the key _Edit together with _Id, the vaule 
of _Id will be looked up as the key of a post and that post will be 
presented for editing.

Is is also possible to show a post by setting _Show and _Id. The value of 
_New, _Edit and _Show are never used and thereby on no importance.

=head1 METHODS

=cut

package DBIx::HTMLView::CGIReqView;

use DBIx::HTMLView::CGIView;
@ISA = ("DBIx::HTMLView::CGIView");

=head1 $c=new DBIx::HTMLView::CGIReqView($db, $fmt, $query)

Initiats the viewer. $db and $fmt is the database specifier and format
specification as descriped in the DBIx::HTMLView manual. $query is the 
cgi query as returned by "new CGI;".

=cut

sub new {
	my ($class,$db,$fmt,$query,$tabs)=@_;
	my $self  = $class->SUPER::new($db,$fmt,$query);
	my $table=$self->{'Form'}->{'_Table'};

	$self->InitDb($table);

	$self->{'editable'}=".*";

	$self;
}


=head1 $c->PrintPage($script)

Will print the html page, with links back to the cgi script $script.

=cut

sub PrintPage {
	my ($self, $script) = @_;
	my $form=$self->{'Form'};
	my $v=$self;

	if ($form->{'_Show'}) { 
		print $v->DataTable($v->Get($form->{'_Id'}), '^$') . "\n";
    print $v->View($form->{'_Id'}) . "\n";
  } else {
	  print << "    EOF";
    <form method=post action="$script">
    <input type=hidden name="_Id" value="$form->{'_Id'}">
    <input type=hidden name="_Table" value="$form->{'_Table'}">
    EOF
    if ($form->{'_Edit'}) {
      print $v->DataTable($v->Get($form->{'_Id'}), $self->{'editable'}) . 
            "<input type=submit name=_Changed value=\"OK\">\n";
  	} elsif ($form->{'_New'}) {
      print $v->DataTable([], $self->{'editable'}) . 
            "<input type=submit name=_Add value=\"OK\">\n";
    }
  }

  $self->Foot();
}

=head1 DBIx::HTMLView::CGIReqView::Handles($q)

Returns 1 if this object can handle the request make by $q, otherwise 0.
$q should be an CGI object created with "new CGI";

=cut

sub Handles {
	my $q=shift;

	if (defined $q->param('_New') ||
			defined $q->param('_Edit') ||
			defined $q->param('_Show')) {
		return 1;
	} else {
		return 0;
	}
}

=head1 Author

  Hakan Ardo <hakan@debian.org>

=cut

1;
