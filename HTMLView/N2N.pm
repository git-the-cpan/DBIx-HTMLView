#!/usr/bin/perl

#  N2N.pm - A many to many relation between two tabels
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

  DBIx::HTMLView::N2N - A many to many relation between two tabels

=head1 SYNOPSIS

  $fld=$post->fld('testf');
  print $fld->view_html;

=head1 DESCRIPTION

This is a subcalss of DBIx::HTMLView::Relation used to represent N2N
relations in the databse as well as the data contained in them. Se the
DBIx::HTMLView::Relation and DBIx::HTMLView:.Fld (the superclass of
Relation) manpage for info on the methods of this class.

A N2N relation as where each post in one table can be related to any
number of posts in an other table. As for example in the User/Group
table pair example described in the tutorial where each user can be
part of several groups.

A third table, called link table, will be used to represent the
relations. It should contain three fields. One id field (as all
tabels), one from id (eg user id) and one to id (eg group id). Now one
relation consists of a set of posts in this table each linking one
from post (eg user) to one to post (eg group).

As for the overall operation this kind of Flds should wokr like any
other Fld, but you can also do a few extra things, as described below.

=head1 METHODS
=cut

package DBIx::HTMLView::N2N;
use strict;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::Relation;
@ISA = qw(DBIx::HTMLView::Relation);

=head2 $fld=DBIx::HTMLView::N2N->($name, $data)
=head2 $fld=DBIx::HTMLView::N2N->new($name, $val, $tab)

The constructor works in the exakt same way as for 
DBIx::HTMLView::Fld, se it's man page for details. 

The following parameters passed within the $data has is recognised:

tab - The table this table is related to (to table)
from_field - The field name of the link table where the from table post 
   id is stored. Default is "<from table>_id".
to_field - The field name of the link table where the to table post 
   id is stored. Default is "<to table>_id".
lnk_tab - The name of the link table. Default is "<from table>_to_<to table>".
id_name - The name of the link post id field in the link table. Default 
   is "id".
view - String used when viewing a related post withing the post being 
   viewed (eg the groups list of a user post). All $<fld name> constructs 
   will be replaced with the data of the post beeing viewed.
join_str - As a post can be related to several other and each will be 
   viewed using the view string above and then joined together using this 
   string as glue. Default is ", ".
extra_sql - Extra sql code passe to the list method when listing related 
   posts. This can for example be used to specify in which order related 
   posts should be viewed. Default is "ORDER BY <to table id name>".

As you se, it is only tab and view that does not have any default valu, 
so those two has to be defined within the table declaration.
 
=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self=	bless {}, $class;

	my ($name, $data, $tab)=@_;
	$self->{'name'}=$name;
	$self->{'tab'}=$tab;
	
	if (ref $data eq "HASH") {
		$self->{'data'}=$data;
	} elsif (ref $data eq "ARRAY") {
		if (ref $this) {$self->{'data'}=$this->{'data'};}
		$self->{'posts'}=DBIx::HTMLView::PostSet->new($self->to_tab);
		foreach (@$data) {
			if ($_ ne "do_edit") {
				$self->{'posts'}->add($self->to_tab->new_post({$self->tab->id->name=>$_}));
			}
		}
	} else {
		$self->{'id'}=$data;
		if (ref $this) {$self->{'data'}=$this->{'data'};}
	}
	
	$self;
}

=head2 $fld->db

Returns the database handle of the tabels.

=cut

sub db {
	my $self=shift;
	$self->tab->db;
}

=head2 $fld->id

Returns the id of the post this relation belongs to.

=cut

sub id {
	my $self=shift;

	if (!defined $self->{'id'}) {
		$self->{'id'}=$self->post->id;
	}
	$self->{'id'};
}

=head2 $fld->to_tab_name

Returns the name of the to table.

=cut

sub to_tab_name {
	shift->data('tab')
}

=head2 $fld->to_tab

Returns the DBIx::HTMLView::Table object representing the to table.

=cut

sub to_tab {
	my $self=shift;
	$self->tab->db->tab($self->to_tab_name);
}

=head2 $fld->from_field_name

Returns the name of the from field in the link table as specified in the 
$data param to the constructor.

=cut

sub from_field_name {
	my $self=shift;
	if ($self->got_data('from_field')) {
		return $self->data('from_field');
	} else {
		return $self->tab->name . "_id";
	}
}

=head2 $fld->to_field_name

Returns the name of the to field in the link table as specified in the 
$data param to the constructor.

=cut

sub to_field_name {
	my $self=shift;
	if ($self->got_data('to_field')) {
		return $self->data('to_field');
	} else {
		return $self->to_tab_name . "_id";
	}
}

=head2 $fld->lnk_tab_name

Returns the name of the link table as specified in the $data param to 
the constructor.

=cut


sub lnk_tab_name {
	my $self=shift;
	if ($self->got_data('lnk_tab')) {
		return $self->data('lnk_tab');
	} else {
		return $self->tab->name . "_to_" . $self->to_tab_name;
	}
}

=head2 $fld->id_name

Returns the name of the link post id field in the link table as specified 
in the $data param to the constructor.

=cut

sub id_name {
	my $self=shift;
	if ($self->got_data('id_name')) {
		return $self->data('id_name');
	} else {
		return "id";
	}
}

=head2 $fld->lnk_tab

Creates and returns a DBIx::HTMLView::Table object representing the link 
table.

=cut

use DBIx::HTMLView;

sub lnk_tab {
	my $self=shift;
	if (!defined $self->{'lnk_tab'}) {
		$self->{'lnk_tab'}=DBIx::HTMLView::Table($self->lnk_tab_name,
													   DBIx::HTMLView::Id($self->id_name), 
														 DBIx::HTMLView::Int($self->from_field_name), 
														 DBIx::HTMLView::Int($self->to_field_name));
		$self->{'lnk_tab'}->set_db($self->db);
	}
	$self->{'lnk_tab'};
}

=head2 $fld->join_str

Returns the join_str parameter as specified in the $data param to the 
constructor.

=cut
 
sub join_str {
	my $self=shift;
	if ($self->got_data('join_str')) {
		return $self->data('join_str');
	} else {
		return ", ";
	}
}

=head2 $fld->extra_sql

Returns the extra_sql parameter as specified in the $data param to the 
constructor.

=cut
 
sub extra_sql {
	my $self=shift;
	if ($self->got_data('extra_sql')) {
		return $self->data('extra_sql');
	} else {
		return "ORDER BY ".$self->lnk_tab_name . "." . $self->to_field_name;
	}
}


=head2 $fld->got_post_set

Returns true if we have a post set. Se the post_set method.

=cut

sub got_post_set {
	my $self=shift;
	(defined $self->{'posts'});
}

=head2 $fld->post_set

When this object is used to represent the data of a relation that can
be done in two ways. Either we just know the id of the post we belong
to and can look up the related posts from the db whenever needed. When
such a post lookup is done the (parts of the) posts returned are
stored in a DBIx::HTMLView::PostSet object.

This method will return such an object after selecting it from the
server if nesessery. You can use the got_post_set method to check if
it was already donwloaded. If this Fld did not belong to a specifik
post, eg no id was defiedn it will die with "Post not defined!".

=cut

sub post_set {
	my $self=shift;
	my $tab=$self->lnk_tab_name;
	my $from=$self->from_field_name;
	my $to=$self->to_field_name;
	my $totab=$self->to_tab_name;

	if (!$self->got_post_set) {		
		$self->{'posts'}=DBIx::HTMLView::PostSet->new($self->to_tab);
		# FIXME: Do we relay need to get the entire related post?
		my $to_flds="";
		foreach ($self->to_tab->flds) {
			if ($_->isa('DBIx::HTMLView::Field')) {
				$to_flds .= $totab . "." . $_->name . ", ";
			}
		}

		my $sth=$self->db->send("select distinct $to_flds $tab.$from, $tab.$to ".
														"from $tab," . $self->to_tab_name . " " .
														"where $tab.$from=" . $self->id . " AND " . 
														"$tab.$to=$totab." . $self->to_tab->id->name . " ".
														$self->extra_sql);
		while (my $ref = $sth->fetchrow_arrayref) {
			my %f;
			my $cnt=0;
			foreach ($self->to_tab->flds) {
				if ($_->isa('DBIx::HTMLView::Field')) {
								$f{$_->name}=$ref->[$cnt];
					$cnt++;
				}
			}

			my $p=$self->to_tab->new_post(\%f);
			$self->{'posts'}->add($p);
		}
	}
	#use Data::Dumper; print Dumper($self->{'posts'})."<p>";

	return $self->{'posts'};
}

=head2 $fld->posts

Will return an array of the posts after calling the post_set
method. If there are no related posts it will not die, but return an
empthy array.

=cut

sub posts {
	my  @posts;
	my $t=eval {
		@posts=shift->post_set->posts;
	}; die unless ($t || $@ =~ /^(No posts!|No id defined)/);
	@posts;
}

=head2 $fld->rel_post_view($p)

Will generate a view of the post $p, as described by the view
parameter specified in the $data parameter to the constructor.

=cut

sub rel_post_view {
	my ($self, $p)=@_;
	my $view=$self->data('view');
	foreach ($p->tab->fld_names) {
		$view =~ s/\$$_/$p->fld($_)->view_html/ge;			
	}
	$view;
}

=head2 $fld->view_text
=head2 $fld->view_html

Will view the related posts as defined by the view and join_str 
parameters specified in the $data parameter to the constructor

=cut

sub view_text {shift->view_html(@_)}
sub view_html {
	my $self=shift;
	my @views;
	
	foreach ($self->posts) {
		push @views, $self->rel_post_view($_);
	}
	join ($self->join_str, @views);
}



=head2 $fld->edit_html

Returns a string containing "<input type=checkbox ...>" constructs to
allow the user to specify which posts we should be related to. All
posts in the to table will be listed here.

=cut

sub edit_html {
	my $self=shift;
	my $res="";

	# FIXME: This is very db access inefficient as it lists to_tab in full
	#        once for every post in it and once agian for every post in the
  #        relation.
	my $posts=$self->to_tab->list;
	my $p;
	while (defined ($p=$posts->get_next)) {
		my $got_it="";
		foreach ($self->posts) {
			if ($p->id == $_->id) {
				$got_it="checked";
				last;
			}
		}
		$res.="<input type=checkbox name=\"" . $self->name ."\" value=".
			    $p->id . " $got_it> " . $self->rel_post_view($p) . "<br>";
	}
	$res.="<input type=hidden name=\"" . $self->name ."\" value=do_edit>";
	$res;
}

=head2 $fld->del($id)

Will remove the relation from post $id. Eg it will no longer be related 
to any posts.

=cut

sub del {
	my ($self, $id)=@_;

	$self->lnk_tab->del($self->from_field_name . "=" . $id);
}

=head2 $fld->name_vals

Returns an empthy array as no fields in the from table should be modifed.

=cut

sub name_vals {();}

=head2 $fld->post_updated

Updates the relation data in the db.

=cut

sub post_updated {
	my $self=shift;

	if ($self->got_post_set) {
		# FIXME: Those db accesses can be optimised by not deleting and readding
		#        relations that's not chnaged.
		
		# Remove old relations
		$self->del($self->id);
		
		# Add the new ones
		foreach ($self->posts) {
			my $post=$self->lnk_tab->new_post({$self->from_field_name => $self->id,
																				 $self->to_field_name => $_->id});
			$post->update;
		}
	}
		
	
}

=head2 $fld->sql_data($sel, $sub)

Used by the DBIx::HTMLView::Selection object $sel when it finds a
relation->field construct in a search string that should be evaled
into an sql select expretion. $sub will be a refference to an array of
all names after the -> signs, eg for rel1->rel2->rel3->field $sub
would contain ("rel2", "rel3", "field") and this would be the rel1
relation.

=cut

sub sql_data {
	my ($self, $sel, $sub)=@_;
	# FIXME: Won't work if relation is second argument
	# FIXME: Make sure this works for several levels, advanced selects, ...

	$sel->add_tab($self->lnk_tab_name);
	$sel->add_tab($self->to_tab_name);
	$sel->add_fld($self->lnk_tab_name . "." . $self->from_field_name);
	$sel->add_fld($self->lnk_tab_name . "." . $self->to_field_name);
	$sel->add_fld($self->to_tab_name . "." . $sub->[0]); # !!

	return $self->lnk_tab_name . "." . $self->from_field_name .
		     "=" . $self->tab->name . "." . $self->tab->id->name . 
				 " AND " . $self->lnk_tab_name . "." . $self->to_field_name .
				 "=" . $self->to_tab_name . "." .$self->to_tab->id->name . 
				 " AND " .  $self->to_tab_name . "." . $sub->[0];
}

=head2 $fld->field_name

Returns undef as we've not got any field in the main table. Se 
DBIx::HTMLView::Fld.

=cut

sub field_name{undef}

sub sql_create {
	my $self=shift;

	$self->lnk_tab->sql_create;
	undef;
}

1;

