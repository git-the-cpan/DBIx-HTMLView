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
communications is routed through it.

This class is intended as a generic base class it is then inherited by
engine specifik classes such as DBIx::HTMLView::msqlDB and
DBIx::HTMLView::mysqlDB. If you plan to use this with another database
engine you'll probably have to atleast overide the insert sub to
handle the assignmet of id values to new posts correctly.

=head1 METHODS
=cut

package DBIx::HTMLView::DB;
use strict;
use DBIx::HTMLView::Log;

use DBI;
use Carp;

=head2 $dbi=DBIx::HTMLView::DB->new($db, $user, $pass, @tabs)
=head2 $dbi=DBIx::HTMLView::DB->new($dbh, @tabs)

Creates a new database representation to the database engine represented 
by the DBI data_source $db and connect's to it using $user and $pass 
as user name and pasword. @tabs is a list of the tables contained in 
the database in form of DBIx::HTMLView::Table objects.

If you'r db needs more initialising than a DBI connect you can
initialise the connection yourself and then pass the dbh (as returned
by the DBI->connect call) using the second form of the constructor.

The database connection will not be closed untill this object is 
destroyed.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self=  bless {}, $class;

  my $db=shift;
  if (ref $db) {
    $self->{'dbh'}=$db;
  } else {
    my $user=shift;
    my $pass=shift;
    $self->{'user'}=$user;  
    $self->{'pass'}=$pass;  
    $self->{'database'}=$db;
  }

  my $t;
  foreach $t (@_) {
    $self->{'tabs'}{$t->name}=$t;
    $t->set_db($self);
  }

  $self;
}

sub dbh {
  my ($self)=@_;
  if(!$self->{'dbh'}) {
    $self->{'dbh'}=DBI->connect($self->{'database'}, $self->{'user'}, 
				$self->{'pass'});
    if(!$self->{'dbh'}) {croak "DBI->connect failed on ",
			   $self->{'database'}, " for user ",
			   $self->{'user'}}
  } 
  return $self->{'dbh'};
}

sub database {shift->{'database'}}

sub DESTROY {
  my $self=shift;
  if(!$self->{'dbh'}) {
    $self->{'dbh'}->disconnect;
  }
}

sub getlogfile {   
  my $self=shift; 
  $self->{'logfile'};
}
 
sub setlogfile {
  my $self=shift; 
  $self->{'logfile'}=shift;
}
 
sub getname {
  my $self=shift;       
  $self->{'user'};
}

sub rows {
  my $self=shift;
  my $postset=shift;

  $postset->getsth->rows; #OK DEFAULT
}


=head2 $dbi->send($cmd)

Will prepare and send the SQL command $cmd to the database and it dies
on errors. The $sth is returned.

=cut

=head2 $dbi->print_only

After this method has been called all sql queries will be printed 
instead of sent to the database.

=cut

sub print_only {shift->{'should_print_only'}=1}

sub should_print_only {shift->{'should_print_only'}}

sub send {
  my $self=shift;
  my $cmd=shift;

  if ($self->should_print_only) {
    print "$cmd \n";
  } else {
    my $sth = $self->dbh->prepare($cmd);
    if (!$sth) {
      confess "Error preparing $cmd: " . $sth->errstr . "\n";
    }
    if (!$sth->execute) {
      confess "Error executing $cmd:" . $sth->errstr . "\n";
    }
    
    make_log($cmd,$self->getname(),$self->getlogfile());
    $sth;
  }
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
  croak "No tables fond!" if (!defined $self->{'tabs'});
  values %{$self->{'tabs'}};
}

=head2 $dbi->sql_escape

Escapes the supplied string to be valid inside an SQL command.
That is, it changes the string q[I'm a string] to q['I\'m a string'];

=cut

sub sql_escape {
  my $self=shift;
    my $str = shift;
    $str =~ s/(['\\])/\\$1/g;
    return "'$str'";
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
    my $fld=$post->fld($f);
    foreach ($fld->name_vals) {
      $cmd.= $_->{'name'} ."=". $_->{'val'} . ", ";
    }
  }
  $cmd=~s/, $//;
  $cmd.=" where " . $tab->id->name . "=" . $post->id; 
  $self->send($cmd);

  foreach my $f ($post->fld_names) {
    $post->fld($f)->post_updated;
  }
}

=head2 $dbi->insert($tab, $post)

Insert the post $post (a DBIx::HTMLView::Post object) into the table
$tab (a DBIx::HTMLView::Table object). This is the method to override
if you need to change the way new post get's their id numbers
assigned. This method should also make sure to set the id fld of $post
to the id assigned to it.

=cut

sub insert {
  my ($self, $tab, $post)=@_;
  my $values="";
  my $names="";
  my $cmd="insert into " . $tab->name;

  foreach my $f ($post->fld_names) {
    foreach ($post->fld($f)->name_vals) {
      $names .=  $_->{'name'}.", ";
      $values .= $_->{'val'} .", ";
    }
  }
   $names =~ s/, $//;
  $values =~ s/, $//;

  $self->send($cmd . " ($names) VALUES ($values)");

  foreach my $f ($post->fld_names) {
    $post->fld($f)->post_updated;
  }
}

=head2 $dbi->sql_create

Will create the tables of the database using SQL commands that works
with msql. The database has to be created by hand using msqladmin or
msqlconfig.

=cut

sub sql_create {
  my $self=shift;

  foreach ($self->tabs) {
    $_->sql_create;
  }
}

=head2 $dbi->sql_create_table($table)

Creates the table $table, a DBIx::HTMLView::Table object, using SQL 
commands that works with msql.

=cut

sub sql_create_table {
  my ($self, $table)=@_;
  my $cmd="CREATE TABLE ".$table->name . "(";

   foreach ($table->flds) {
     my $type=$_->sql_create;
     if (defined $type) {
       $cmd .= $_->name . " " . $type . ", ";
     }
   }
  $cmd =~ s/, $//;
  $self->send($cmd.")");
}

=head2 $dbi->sql_type($type, $fld)

Returns the SQL type string used for the type $type of the Fld $fld. $type 
should be one of "Id", "Int", "Str", "Text", "Bool", "Date" and $fld 
should be a DBIx::HTMLView::Fld object.

=cut

sub sql_type {
  my ($self, $type, $fld)=@_;
  my $t=lc($type);

  if ($fld->got_data('sql_type')) {return $fld->data('sql_type')}

  my $s="";
  $s="(".$fld->data('sql_size').")" if ($fld->got_data('sql_size'));
  

  if ($t eq 'id') {return "INT$s"}
  if ($t eq 'int') {return "INT$s"}
  if ($t eq 'date') {return "DATE"}
  if ($t eq 'str') {if (!$s) {$s="(100)"} return "CHAR$s"}
  if ($t eq 'text') {if (!$s) {$s="(500)"} return "CHAR$s"}
  if ($t eq 'bool') {if (!$s) {$s="(1)"} return "CHAR$s"}

  die "Bad type $t";
}

sub viewer {
  my ($self, $viewer)=@_;
  if (defined $viewer) {
    $self->{'viewer'}=$viewer;
  }
  return $self->{'viewer'}
}

1;

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
