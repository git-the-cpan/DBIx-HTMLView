#!/usr/bin/perl

#  Fld.pm - Base class for field and relation classes
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

  DBIx::HTMLView::Fld - Base class for field and relation classes

=head1 SYNOPSIS

  $fld=$post->fld('testf');
  print $fld->view_html;

=head1 DESCRIPTION

Those objects are used to represent the fields and relations of a
table inside the and the DBIx::HTMLView::Table object as well as the
data contained in those fields and relations in the
DBIx::HTMLView::Post objects.

This is the base class of all such field classes such as
DBIx::HTMLView::Text DBIx::HTMLView::Str and DBIx::HTMLView::Int as
well as the relations such as DBIx::HTMLView::N2N.

=head1 METHODS
=cut

package DBIx::HTMLView::Fld;
use strict;
use Carp;

=head2 $fld=DBIx::HTMLView::Fld->($name, $data)
=head2 $fld=DBIx::HTMLView::Fld->new($name, $val, $tab)

The only time you create this kind of objects is when you create the
DBIx::HTMLView::Table objects of the top level description of the
databse (se DBIx::HTMLView::DB). And in that case it is the first
version of the constructor you use preferable through the shortcuts in
DBIx::HTMLView. $name is a string naming the relation or field while
$data is a hashref with parameters specifik to the field or relation
kind used.

The second version of the constructor is used by the
DBIx::HTMLView::Table class when it creates copies of it's flds, gives
them there data $val and places them in a post. $tab is the
DBIx::HTMLView::Table object the fld belongs to.

For fields data ($val) is specified as a string or as the first item
of a array referenced to by $val. Relations are represented as a
reference to an array of the id's of the posts being related to.

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self=	bless {}, $class;

	my ($name, $val, $tab)=@_;

	#print "Name: $name ";
	#use Data::Dumper; print Dumper($val) . "<br>";

	if (ref $val eq "HASH") {
		$self->{'data'}=$val;
	} else {
		if (ref $val eq "ARRAY") {$val=$val->[0];}
		if (ref $this) {$self->{'data'}=$this->{'data'};}
		$self->{'val'}=$val;
	}

	$self->{'name'}=$name;
	$self->{'tab'}=$tab;

	$self;
}

=head2 $fld->name

Returns the name of the fld.

=cut

sub name {
	shift->{'name'};
}


=head2 $fld->data($key)

Returns the value of $key set from the $data hashref in the new
method. It dies if the data was not set.

=cut

sub data {
	my ($self,$key)=@_;
	confess ("$key not defined!") if (!defined $self->{'data'}{$key});
	$self->{'data'}{$key}
}

=head2 $fld->got_data($key)

Returns true if the value of $key was set in the $data hashref in the 
new method.

=cut

sub got_data {
	my ($self, $key)=@_;
	(defined $self->{'data'}{$key});
}

=head2 $fld->set_tab($tab)

Used by DBIx::HTMLView::Tale to inform the fld of which table it belongs
to. All fld belongs to either a Table or a Post.

=cut


sub set_table {
	my ($self, $tab)=@_;
	$self->{'tab'}=$tab;
}

=head2 $fld->set_post($post)

Used of DBIx::HTMLView::Post to inform the fld pf which post it belongs 
to. All fld belongs to either a Table or a Post.

=cut

sub set_post {
	my ($self, $post)=@_;
	$self->{'post'}=$post;
}

=head2 $fld->tab

Return the DBIx::HTMLView::Table object this fld belongs to.

=cut

sub tab {
	my $self=shift;
	confess "Table not defined!" if (!defined $self->{'tab'});
	$self->{'tab'};
}


=head2 $fld->post

Returns the DBIx::HTMLView::Post object this fld belongs to.

=cut

sub post {
	my $self=shift;
	confess "Post not defined!" if (!defined $self->{'post'});
	$self->{'post'};
}

1;

=head1 VIRTUAL METHODS

Those methods are not defined in this class, but are suposed to be
defiened in all leav fld classes.

=head2 $fld->view_html

Returns a html string used to view the contenets (value) of the fld.

=head2 $fld->edit_html

Returns a string that can be placed inside a html <form> section used
to edit this field or relation. It will be some sort of input tag with
the same name as the fld.

=head2 $fld->sql_data($sel)

Called if this fld is used in the selection string in a DBIx::HTMLView::Selection object $sel. It is supposed to add apropreate data to the object using $sel->add_fld and $sel->add_tab (se the DBIx::HTMLView::Selection manpage for details) and return the string to represent it in the where clause (it will usualy be the name of the field itself).

=head2 $fld->view_text

Returns a text string used to view the contents (value) of the fld
(this method is not yet implemented for all fld classes).

=head2 $fld->del($id)

Is called when a post with id $id is deleted. This is to allow the
relations of this post to clean out the data that is placed in other
tabels. The actual post will be removed from the table after all fld
object del methods has been called.

=head2 $fld->field_name

The name of the sql field in the main table representing this fld. For
a N2N relation it will be undefined as it is represented in a separate
table and not in the main one. For fields it will ofcourse be the name
of the field.

=head2 $fld->name_vals

This medthod is called whenever the data of a post is updated in the
actuall database or a new post is added. It is supposed to return an
array of hashes containing the two keys name and val. Where the value
of the name keys are the names of database fields that is supposed to
be set to the values of the val keys.

This is the method where relations are supposed to update all
secondary tabels (eg the tables used to represent the actuall
relations).

=head2 $fld->sql_create

Will send the nesesery SQL commands to create this fld in database and
return the sql type (if any) of this field to be included in the
CREATE clause for the main table. That is normal fields will only
return there type while relations will create it's link table.

=cut

=cut

