#!/usr/bin/perl

#  CGIListView.pm - A List user interface for DBI databases
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

  DBIx::HTMLView::CGIListView - A List user interface for DBI databases

=head1 SYNOPSIS

use DBIx::HTMLView::CGIListView;
my @tabels = ("Test", "Test2");
my $db="DBI:mSQL:HTMLViewTester:athena.af.lu.se:1114";

$c=new DBIx::HTMLView::CGIListView($db, {}, new CGI(), \@tabels);
$c->PrintPage("this_file.cgi");

=head1 DESCRIPTION

This is a CGI interface based on the CGIView class (eg a subclass of) that 
allows you to select one table from a list at the top and lists the posts of
that table at the botton with Show, Edit and Delete buttons for every line
and below that a Add button allowing you to add new posts.

=head1 METHODS

=cut

package DBIx::HTMLView::CGIListView;

use DBIx::HTMLView::CGIView;
@ISA = ("DBIx::HTMLView::CGIView");


=head1 $c=new DBIx::HTMLView::CGIListView($db, $fmt, $query, $tabs)

Initiats the viewer. $db and $fmt is the database specifier and format
specification as descriped in the DBIx::HTMLView manual. $query is the 
cgi query as returned by "new CGI;". $tabs is an array reference to an 
array listing the table that should show up in list at the top. 


=cut

sub new {
	my ($class,$db,$fmt,$query,$tabs)=@_;
	my $self  = $class->SUPER::new($db,$fmt,$query);

	my $form=$self->{'Form'};

	if ($form->{'_SetTable'}) {$form->{'_Table'}=$form->{'_SetTable'};}
	if (!$form->{'_Table'}) {$form->{'_Table'}=$tabs->[0];}
	
	$self->InitDb($form->{'_Table'});
	$self->SetParam("_Table", $form->{'_Table'});
	$self->{'Lst'}="SELECT * FROM $form->{'_Table'}";
	$self->{'Tabels'}=$tabs;

	return $self;
}

=head1 $c->PrintPage($script)

Will print the html page, with links back to the cgi script $script. It is 
possible to chnage the contents of the list before calling this by chnaging
the $self->{'Lst'} variable to a diffrent select query, before calling this
method. The query has to select the table id as it's first variable. All 
other selected variables will be displayed in the list.

This method will also preform any Add, Change or Delete requests as made by 
the CGIReqView interface.

=cut

sub PrintPage {
	my ($self, $script) = @_;
	my $form=$self->{'Form'};

	$self->Preform($form);

	print << "EOF";
<h1>Current table: $form->{'_Table'}</h1>

<form method=POST>
  <b>Change table</b>: 
EOF

	foreach (@{$self->{'Tabels'}}) {
		print "<input type=submit name=_SetTable   value=\"$_\">\n";
	}

print << "EOF";
  <p>
</form>
	
<form method=POST>
  <B>SQL</b>: <input name="_Command" VALUE='$form->{'_Command'}'>
  <input type=submit name="_Search"  value="Search">
  <input type=hidden name="_Search" value="!">
        <input type=hidden name="_Table" value="$form->{'_Table'}">
</form>

<hr>
EOF

	my $lst;
	if ($form->{'_Search'}) {
		$lst=$form->{'_Command'}
	} else {
		$lst=$self->{'Lst'};
	}
	
	print "<table>\n";
	foreach ($self->List($lst,'<td>')) { 
		print "<tr><td>$_->[1]<td>" . 
			$self->ml($script, $_->[0], "Show") . 
				$self->ml($script, $_->[0], "Edit") .
					$self->ml($script, $_->[0], "Delete") .  "</tr>\n";
	}
	print "</table>\n" . $self->ml($script, -1, "New") . "\n";
	$self->Foot;
}

=head1 Author

  Hakan Ardo <hakan@debian.org>

=cut
