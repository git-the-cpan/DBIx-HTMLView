#!/usr/bin/perl

#  DB.pm - A generic DBI databse with SQL interface
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

  DBIx::HTMLView::DB - A generic DBI databse with SQL interface

=head1 SYNOPSIS

use DBIx::HTMLView;
my $dbi=my $dbi=DB("DBI:mSQL:HTMLViewTester:localhost", "", "", 
                   Table ('Test', Id('id'), Str('testf')));
my $hist=$dbi->tab('Test')->list();


=head1 DESCRIPTION

The DB object is usualy only used to represent the top level database
and to access the diffrent tabel objects. But all databse
communications is routed through it so if you'r databse is not acting
in the same way as mSQL (which is the database engine I've tested it
with) you could subclass this object and override the methods the
needs to be changed. Actually almost all SQL commands are generated
here too, it is only the SELECT clause that is generated elsewhere.

=head1 METHODS
=cut

package DBIx::HTMLView::DB;
use strict;

use DBI;
use Carp;

=head2 $dbi=DBIx::HTMLView::DB->new($db, $user, $pass, @tabs)
=head2 $dbi=DBIx::HTMLView::DB->new($dbh, @tabs)

Creats a new databse represenation to the databse engine represented 
by the DBI data_source $db and connect's to it using $user and $pass 
as user name and pasword. @tabs is a list of the tabels contained in 
the database in form of DBIx::HTMLView::Table objects.

If you're db needs more initialising than a DBI connect you can
initialise the connection yourself and then pass the dbh (as returned
by the DBI->connect call) using the second form of the constructor.

The database connection will not be closed untill this object is 
destroyed.

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self=	bless {}, $class;

	my $db=shift;
	if (ref $db) {
		$self->{'dbh'}=$db;
  } else {
		my $user=shift;
		my $pass=shift;
		$self->{'dbh'}=DBI->connect($db, $user, $pass);
		if(!$self->{'dbh'}) {croak "DBI->connect failed on $db for user $user";}
	}

	my $t;
	foreach $t (@_) {
		$self->{'tabs'}{$t->name}=$t;
		$t->set_db($self);
	}

	$self;
}

sub DESTROY {
	my $self=shift;
	$self->{'dbh'}->disconnect;
}

=head2 $dbi->send($cmd)

Vill prepare and send the SQL command $cmd to the database and it dies
on errors. The $sth is returned.

=cut

sub send {
	my $self=shift;
	my $cmd=shift;
	my $sth = $self->{'dbh'}->prepare($cmd);
	if (!$sth) {
		confess "Error preparing $cmd: " . $sth->errstr . "\n";
	}
	if (!$sth->execute) {
		confess "Error executing $cmd:" . $sth->errstr . "\n";
	}
	$sth;
}

=head2 $dbi->tab($tab)

Returns the DBIx::HTMLView::Table object representing the table named 
$tab.

=cut

sub tab {
	my ($self, $tab)=@_;
	croak "Unknown table $tab" if (!defined $self->{'tabs'}{$tab});
	$self->{'tabs'}{$tab};
}

=head2 $dbi->tabs

Returns an array of DBIx::HTMLView::Table objects representing all the 
tables in the database.

=cut

sub tabs {
	my $self=shift;
	croak "No tabels fond!" if (!defined $self->{'tabs'});
	values %{$self->{'tabs'}};
}

=head2 $dbi->del($tab, $id)

Deletes the post with id $id form the table $tab (a DBIx::HTMLView::Table
object).

=cut

sub del {
	my ($self, $tab, $id)=@_;
	if ($id =~ /^\d+$/) {$id=$tab->id->name . " = $id";}
	my $cmd="delete from " . $tab->name . " where " . $id;
	$self->send($cmd);
}

=head2 $dbi->update($tab, $post)

Updates the data in the database of the post represented by $post (a 
DBIx::HTMLView::Post object) in the table $tab (a DBIx::HTMLView::Table
object) with the data contained in the $post object.

=cut

sub update {
	my ($self, $tab, $post)=@_;
	my $cmd="update " . $tab->name . " set ";
	
	foreach my $f ($post->fld_names) {
		foreach ($post->fld($f)->name_vals) {
			$cmd.= $_->{'name'} ."=".$_->{'val'} . ", ";
		}
	}
	$cmd=~s/, $//;
	$cmd.=" where " . $tab->id->name . "=" . $post->id; 
	$self->send($cmd);
}

=head2 $dbi->insert($tab, $post)

Insert the post $post (a DBIx::HTMLView::Post object)into the table
$tab (a DBIx::HTMLView::Table object). This is the method to override
if you need to change the way new post get's there id numbers
assigned. This implementation assumes there excists a mSQL sequence on
the table $tab which is asked for the next number.

=cut

sub insert {
	my ($self, $tab, $post)=@_;
	my $id=$self->send('select _seq from ' . $tab->name)->fetchrow_arrayref->[0];
	my $values="";
	my $names="";
	my $cmd="insert into " . $tab->name;

	$post->set($tab->id->name, $id);

	foreach my $f ($post->fld_names) {
		foreach ($post->fld($f)->name_vals) {
			$names .=  $_->{'name'}.", ";
			$values .= $_->{'val'} .", ";
		}
	}
	$names =~ s/, $//;
	$values =~ s/, $//;

	$self->send($cmd . " ($names) VALUES ($values)");
}

=head2 $dbi->msql_create

Will create the tabels of the database using SQL commands that works
with msql. The databse has to be created by hand using msqladmin or
msqlconfig.

=cut

sub sql_create {
	my $self=shift;

	foreach ($self->tabs) {
		$_->sql_create;
	}
}
1;
