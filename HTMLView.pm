#!/usr/bin/perl

#  HTMLView.pm - For handling DBI relation databases and web interfaces.
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

  DBIx::HTMLView - For handling DBI relation databases and web interfaces

=head1 SYNOPSIS

use DBIx::HTMLView;
my $dbi=DB("DBI:mSQL:HTMLViewTester:localhost", "", "", 
           Table ('Test', Id('id'), Str('testf')),
           Table('Test2', Id('id'), Str('str'), Int('nr'))
          );


=head1 DESCRIPTION

HTMLView is a set of modules to handle relational SQL databases
through a DBI interface and create web user interfaces to them. Among
its features are the posibility to handle relations in the same
manner as fields and it is easily extended with additional field or
relation specifications as well as custom editors and viewers.

For a general overview description of the system see the README file,
for a quick start see the test.pl script. It conatins instructions on
how to set up a simple test database and then it preforms all the
basic opperations in a comented manner. There is also a tutorial
(not yet written) describing the basics of relation databases and 
how to build web interfaces to them using HTMLView. Finaly there is 
a man page for every package describing it's methods and 
functionality.

This package contains shourtcuts for the constructors of some of the
basic objects under DBIx::HTMLView that are used to created the
database description structure. This structure describes all the
tables in the database and its fields, and is then used as an
interface to the database and the tables.

For a description of parameters to the separate functions see the
diffrent packages man pages, eg DB is actualy the new method of
DBIx::HTMLView::DB. Curently we have shourtcuts for the following
objects: 

  msqlDB
  mysqlDB
  OracleDB
  Table
  Int
  Date
  Str
  Bool
  Text
  Id
  N2N
  N2One
  Tree
  SubTab
  Order
  N2NOrder
  
For backwards compatibility there is also a DB method calling msqlDB.

=head1 METHODS
=cut


package DBIx::HTMLView;
use strict;
use vars qw(@ISA $VERSION @EXPORT);

$VERSION="0.9";

require Exporter;
require DBIx::HTMLView::DB;
require DBIx::HTMLView::mysqlDB;
require DBIx::HTMLView::msqlDB;
require DBIx::HTMLView::OracleDB;
require DBIx::HTMLView::Table;
require DBIx::HTMLView::Int;
require DBIx::HTMLView::Str;
require DBIx::HTMLView::Date;
require DBIx::HTMLView::Bool;
require DBIx::HTMLView::Text;
require DBIx::HTMLView::Id;
require DBIx::HTMLView::N2N;
require DBIx::HTMLView::N2One;
require DBIx::HTMLView::Tree;
require DBIx::HTMLView::SubTab;
require DBIx::HTMLView::Order;
require DBIx::HTMLView::N2NOrder;

@ISA         = qw(Exporter);
@EXPORT      = qw(DB OracleDB mysqlDB msqlDB Table Str Bool Text Id N2N Int N2One Date Tree SubTab Order N2NOrder);

sub DB {
  msqlDB(@_) # For backwards compatibility
}

sub mysqlDB {
  DBIx::HTMLView::mysqlDB->new(@_);
}

sub msqlDB {
  DBIx::HTMLView::msqlDB->new(@_);
}

sub OracleDB {
  DBIx::HTMLView::OracleDB->new(@_);
}

sub Table {
  DBIx::HTMLView::Table->new(@_);
}

sub Int {
  DBIx::HTMLView::Int->new(@_);
}

sub Str {
  DBIx::HTMLView::Str->new(@_);
}

sub Date {
  DBIx::HTMLView::Date->new(@_);
}

sub Bool {
  DBIx::HTMLView::Bool->new(@_);
}

sub Text {
  DBIx::HTMLView::Text->new(@_);
}

sub Id {
  DBIx::HTMLView::Id->new(@_);
}

sub N2N {
  DBIx::HTMLView::N2N->new(@_);
}

sub N2One {
  DBIx::HTMLView::N2One->new(@_);
}

sub Tree {
  DBIx::HTMLView::Tree->new(@_);
}

sub SubTab {
  DBIx::HTMLView::SubTab->new(@_);
}

sub Order {
  DBIx::HTMLView::Order->new(@_);
}

sub N2NOrder {
  DBIx::HTMLView::N2NOrder->new(@_);
}

1;

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
