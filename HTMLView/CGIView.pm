#!/usr/bin/perl

#  CGIView.pm - For creating CGI userinterfacees to DBI databases.
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

  DBIx::HTMLView::CGIView - For creating CGI userinterfacees to DBI databases.

=head1 SYNOPSIS

package MyCGIViewer;

use DBIx::HTMLView::CGIView;
@ISA = ("DBIx::HTMLView::CGIView");

sub new {
	my ($class,$db,$fmt,$query)=@_;
	my $self  = $class->SUPER::new($db,$fmt,$query);

  my $table=$self->{'Form'}{'_Table'};
	$self->InitDb($table);

	return $self;
}


sub PrintPage {
	my ($self, $script) =@_;

	# Generate page...
  foreach ($self->List("SELECT * FROM $self->{'Form'}{'_Table'}",', ')) { 
	  print "$_->[1]: ". $self->ml($script, $_->[0], "Show") . "<br>\n";
  }

  $self->Foot();
}

# Overriden and new methods follow here...

# And then to test it
use CGI;
use MyCGIViewer;

my $query=new CGI({'_Table' => 'Test'});
my $db="DBI:mSQL:HTMLViewTester:athena.af.lu.se:1114";
new MyCGIViewer($db, {}, $query)->PrintPage("View.cgi");

=head1 DESCRIPTION

This is a subclass of DBIx::HTMLView to create cgi interfaces.

=head1 METHODS

=cut

package DBIx::HTMLView::CGIView;
use CGI;

use DBIx::HTMLView;
@ISA = ("DBIx::HTMLView");


=head2 $v=new DBIx::HTMLView::CGIView($db,$fmt,$query);

Creates a new CGIView object passing $db and $fmt to the DBIx::HTMLView
constructor. It will also take care of the CGI input in $query, which 
should be a new CGI object, and place the key/value pairs in a hash in 
$v->{'Form'}, and call the $v->Head method to generate the headder.

It also makes sure thet the current table in the _Table varibale in 
$query is svaed in future calls by using SetParam.

=cut

sub new {
	my ($class,$db,$fmt,$query)=@_;
	my $self  = $class->SUPER::new($db,$fmt);
	my $form={};

	foreach ($query->param) {
		$form->{$_}=$query->param($_);
	}
	$self->{'Form'}=$form;
	$self->SetParam("_Table", $form->{'_Table'});

	$self->Head;

	bless ($self, $class);          # reconsecrate
	return $self;
}

=head2 $v->Head

Prints the page headder to stdout. The idea is to override this method if
you want to chnage the headder. 

=cut
sub Head {
	print << "EOF";
<html><head><title>DBI Interface</title></head><body>
EOF
}

=head2 $v->Foot

Prints the page footer to stdout. The idea is to override this method if
you want to chnage the footer.

=cut
sub Foot {
	print "</body></html>\n";
}

=head1 Author

  Hakan Ardo <hakan@debian.org>

=cut

1;
