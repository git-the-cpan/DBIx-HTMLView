#!/usr/bin/perl

#  Log.pm - Keep trace of modifics of table
#  Use: log('sql command','user','name_of_file')
#  (c) Copyright 2000 Costantino Giuseppe <costanti@cs.unibo.it>
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

package DBIx::HTMLView::Log;
require Exporter;

use vars qw(@ISA @EXPORT);
@ISA=qw(Exporter);
@EXPORT=qw(make_log);

=head2 make_log ($writecmd,$user,$filename);
 
 write into the file named $filename the log of the operation committed to
 the database. The sql statement is in $writecmd and the user name in $user.
 This function also add other things like date and time.
 
=cut


sub make_log {
	my ($writecmd,$user,$filename)=@_;
	#$filename="/tmp/tstlog";
	if (($filename cmp "")) { 
		if ($writecmd !~ /^\s*select/i) { # skip if cmd is a select
			if (open (LOGF,">>".$filename)) { 
				my ($sec,$min,$hour,$mday,$mon,$year)=localtime();
				print LOGF ("\n");
				print LOGF ($hour.':');
				print LOGF ($min.':');
				print LOGF ($sec.' ');
				print LOGF ($mday.'-');
				print LOGF (($mon+1).'-');
				print LOGF (($year+1900).' ');
				print LOGF ('USER='.$user.' ');
				print LOGF ('COMMAND='.$writecmd);
				close (LOGF);
			}
		}
	}
}

1;
