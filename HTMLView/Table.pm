#!/usr/bin/perl

#  Table.pm - A table within a generic DBI databse
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

  DBIx::HTMLView::Table - A table within a generic DBI databse

=head1 SYNOPSIS

my $table=$dbi->tab('Test');

# List all posts
my $hits=$table->list();

# Get post with id 7
my $post=$table->get(7);

=head1 DESCRIPTION

This object is supposed to be created inside a database description as
described in the DBIx::HTMLView::DB man page to represent a table and
it's fields and relations. Then it's can be used to access the posts
of that table.

=head1 METHODS
=cut

package DBIx::HTMLView::Table;
use strict;
use Carp;

require DBIx::HTMLView::Str;
require DBIx::HTMLView::Post;
require DBIx::HTMLView::PostSet;

require DBIx::HTMLView::Selection;

=head2 DBIx::HTMLView::Table->new($name, @flds)

Creates a new table representation for a table named $name. This has to
be the same name as the database engine has for the table. @flds is an 
array of DBIx::HTMLView::Fld objects which represent the separate fields
and relations of the table.

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self=	bless {}, $class;

	my ($name, @flds) = @_;
	$self->{'name'}=$name;

	foreach my $f (@flds) {
		$f->set_table($self);
		push @{$self->{'flds'}}, $f;
		if ($f->isa('DBIx::HTMLView::Id')) {$self->{'id'}=$f}
	}
	if (!defined $self->{'id'}) {
		my $fld=DBIx::HTMLView::Id('id');
		$fld->set_table($self);
		$self->{'id'}=$fld;
		push @{$self->{'flds'}}, $fld;
	}

	$self;
}

=head2 $table->id

Returns the DBIx::HTMLView::Fld object that is used as the id field for
this table.

=cut

sub id {
	my $self=shift;
	confess "Id not defined!" if (!defined $self->{'id'});
	$self->{'id'};
}

=head2 $table->name

Returns the name of this table.

=cut

sub name {
	my $self=shift;
	die "Name not defined!" if (!defined $self->{'name'});
	$self->{'name'};
}

=head2 $table->set_db($db)

Use by the parent DBIx::HTMLView::DB object to inform this object
which databse it belongs to ($db). It should not be used elsewhere.

=cut

sub set_db {
	my ($self, $db)=@_;
	$self->{'db'}=$db;
}

=head2 $table->list($search, $extra, $flds)

Returns a DBIx::HTMLView::PostSet object with the posts matching the
$search string (see the DBIx::HTMLView::Selection man page for a 
description of the search language, it is close to SQL). $extra will
be apended to the SQL select command before it is sent to the databse
it can be used to specify a ORDER BY clause for example.

$flds is for optimisations. If it is not defined all fileds of the 
posts are retrieved from the datbase. If it is an array ref only the 
fields who's names are listed in there are retrieved. If a search 
string is specied the fields used in that string will also be 
retrieved.

The PostSet object return is placed in no-save mode, which means
that you will be able to itterate through the posts once and then
they are gone. This is becaue there can be quite a lot of data
returned from the database server and there is usualy no reason to
store it all in memory.

To create a PostSet object in save mode with the result you could do
something like:

$post_set=$table->list;
$post_set_save=DBIx::HTMLView::PostSet->new;
while (defined $post=$self->get_next) {
  $post_set_save->add($post);
}


=cut

sub list {
	my ($self, $search, $extra, $flds)=@_;
	my $select;

	if (defined $search) {
		my $sel=DBIx::HTMLView::Selection->new($self,$search,$flds);
		$select=$sel->sql_select;
	} else {
		my $fld='';
		if (defined $flds) {
			$fld=$self->id->name;
			foreach (@$flds) {
				my $n=$self->fld($_)->field_name;
				if (defined $n){$fld.=", $n" ;}
			}
		} else {
			$fld='*';
		}
		$select="select $fld from " . $self->name;
	}

	if (defined $extra) {$select.=" " .$extra;}
	$self->sql_list($select);
}

=head2 $table->sql_list($select)

Sends $select, which should be a select clause on this table,to the 
database and turns the result into a DBIx::HTMLView::PostSet object.
You should use the list method insted. It gives you a smooter interface.

=cut

sub sql_list {			
	my ($self, $select)=@_;

 	my $sth=$self->db->send($select);	

	DBIx::HTMLView::PostSet->new($self, $sth,0);
}

=head2 $table->new_post(...)

Creates a new DBIx::HTMLView::Post object linked to this table (all 
posts must be linked to a table). All arguments are passed on to the 
new method.

=cut

sub new_post {
	my $self=shift;
	DBIx::HTMLView::Post->new($self, @_);
}

=head2 $table->new_fld($fld,$val)

Creates a copy of the DBIx::HTMLView::Fld object named $fld and gives 
it the value $val. It is used by the DBIx::HTMLView::Post objects to
create objects representing the diffrent values of the fields and does 
not make much sense elsewhere.

For fields data ($val) is specified as a string or as the first item
of a array referenced to by $val. Relations are represented as a
reference to an array of the id's of the posts being related to.

=cut

sub new_fld {
	my ($self, $fld, $val)=@_;
	if ($self->got_fld($fld)) {
		return $self->fld($fld)->new($fld,$val,$self); 
	} else {
		return DBIx::HTMLView::Str->new($fld,$val,$self);
	}
}

=head2 $table->fld_names

Returns an array of the names of all the fields and relation in this 
table.

=cut


sub fld_names {
	my $self=shift;
	my @names;
	die "No fealds found!" if (!defined $self->{'flds'});
	foreach (@{$self->{'flds'}}) {push @names, $_->name;}
	@names;
}

=head2 $table->fld($fld)

Returns the DBIx::HTMLView::Fld object of the field or relation named 
$fld.

=cut

sub fld {
	my ($self, $fld) =@_;
	die "No fealds found!" if (!defined $self->{'flds'});
	foreach (@{$self->{'flds'}}) {
		if ($_->name eq $fld) {return $_;}
	}
	die "Field not found: $fld";
}

=head2 $table->got_fld($fld)

Returns true if this table has a field or relation named $fld.

=cut

sub got_fld {
	my ($self, $fld) =@_;
	return 0 if (!defined $self->{'flds'});
	foreach (@{$self->{'flds'}}) {
		if ($_->name eq $fld) {return 1;}
	}
	return 0;
}

=head2 $table->fld($fld)

Returns an array of DBIx::HTMLView::Fld objects of all the fields and
relations in this table.

=cut

sub flds {
	my $self=shift;
	die "No fealds found!" if (!defined $self->{'flds'});
	@{$self->{'flds'}};
}

=head2 $table->db

Returns the DBIx::HTMLView::DB object this table belongs to.

=cut

sub db {
	my $self=shift;
	die "No db defined!" if (!defined $self->{'db'});
	$self->{'db'};
}

=head2 $table->del($id)

Deletes the post with id $id.

=cut

sub del {
	my ($self, $id)=@_;
	foreach ($self->flds) {
		$_->del($id);
	}
	$self->db->del($self, $id);
}

=head2 $table->update($post)
=head2 $table->change($post)

Updates the data in the database of the post represented by $post (a 
DBIx::HTMLView::Post object) with the data contained in the object.

=cut


sub update {shift->chnage(@_);}
sub change {
	my ($self, $post)=@_;
	$self->db->update($self, $post);
}

=head2 $table->add($post)
=head2 $table->insert($post)

Inserts the post $post (a DBIx::HTMLView::Post object) into the 
database.

=cut

sub add {shift->insert(@_);}
sub insert {
	my ($self, $post)=@_;
	$self->db->insert($self, $post);
}

=head2 $table->get($id)

Returns a DBIx::HTMLView::Post object representing the post with id 
$id.

=cut

sub get {
  my ($self, $id)=@_;
  $self->list($self->id->name . "=" . $id)->first;
}

=head2 $table->msql_create

Will create the tabel using SQL commands that works with msql.

=cut

sub sql_create {
	my $self=shift;
	$self->db->sql_create_table($self)
}

1;

