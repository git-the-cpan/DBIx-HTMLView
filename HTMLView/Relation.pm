#!/usr/bin/perl

#  Relation.pm - A relation base class
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

  DBIx::HTMLView::Relation - A relation base class

=head1 SYNOPSIS

  $fld=$post->fld('id');
  print $fld->view_html;

=head1 DESCRIPTION

This is a subcalss of DBIx::HTMLView::Fld used to represent relations
between tables in the databse as well as the data contained in them.
Se the DBIx::HTMLView:.Fld manpage for info on the methods of this class.

=cut

package DBIx::HTMLView::Relation;
use strict;

use vars qw(@ISA);
require DBIx::HTMLView::Fld;
@ISA = qw(DBIx::HTMLView::Fld);

1;
