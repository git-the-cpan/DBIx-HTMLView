#!/usr/bin/perl

#  PostSet.pm - A set posts as in a search result for example
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

  DBIx::HTMLView::PostSet - A set posts as in a search result for example

=head1 SYNOPSIS

my $post_set=$table->list;  # Get a PostSet
$post_set->view_html;       # view it

$post_set=$table->list;     # Get a new one as the old now is used
while (defined $post=$self->get_next) {
  # Process $post...
}

$post_set=DBIx::HTMLView::PostSet->new($table) # Create a PostSet in save mode
$post_set->add($post);

=head1 DESCRIPTION

This a class representing a set of object as for example a result of a
search. The object can either be in save mode or in no-save mode. A
PostSet object in no-save mode will be able to itterate through the
posts once and then they are gone. The posts are never stored, but
retrieved from the db when you ask for the next one and then trashed
if you don't save them. In save mode this class will star by
dowbloading all the posts from the db into memory to allow more
advanced manipulations.

=cut

#FIXME: Make sure methods like add chek if we are in save mode

package DBIx::HTMLView::PostSet;
use strict;
use Carp;


=head2 $post_set=DBIx:.HTMLView::PostSet->new($tab, $sth, $save)

Creates a new PostSet object for posts from the table $tab (a
DBIx::HTMlView::Table object). If $sth is a refrenc it's supposed to
be the result of a DBI execute call with a select command. The posts
returned from the db will be the ones represented by this set.

If $save is defined to a false value the object will be created in
no-save mode, otherview in save mode. Se the DESCRIPTION.

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self=	bless {}, $class;

	my ($tab, $sth, $save) = @_;
	$self->{'next_post'}=0;
	$self->{'tab'}=$tab;

	if (defined $save) {
		$self->{'save'}=$save;
	} else {
		$self->{'save'}=1;
	}
	$self->{'sth'}=$sth;

	if (ref $sth) {
		if ($self->save_mode) {
# FIXME: Separate into a into_save_mode method and update Table::list docs.
			while (my $ref = $sth->fetchrow_arrayref) {
				my $post=$tab->new_post($ref,$sth);
				if (!$self->got_post($post)) {
					$self->do_got_post($post);
					$self->add($post);
				}
			}
		}
	}

	$self;
}


=head2 $post_set->rows

Returns the number of rows (posts) in this PostSet as reported by the
$sth->rows DBI function.

=cut

sub rows {
    shift->{'sth'}->rows;
}

=head2 $post_set->got_post($post)

Returns true if $post has been returned erlier in this set (in which
case we won't return it again). Or if we are in save mode returns true
if the post is within the set. $post should be a DBIx::HTMLView::Post
object.

=cut
sub got_post {(defined shift->{'post_ids'}{shift->id})}


=head2 $post_set->do_got_post

Marks $post (a DBIx::HTMLView::Post object) as a returned post. See 
$post_set->got_post.

=cut

sub do_got_post {shift->{'post_ids'}{shift->id}=1}

=head2 $post_set->tab

Returns the table (a DBIx::HTMLView::Table object) this set of posts 
belongs to.

=cut

sub tab {shift->{'tab'}}

=head2 $post_set->get_next

Returns the next post (a DBIx::HTMLView::Post object) in the set. The
first one will be returned if this method has not been called before.

=cut

sub get_next {
	my $self=shift;
	$self->{'next_post'}++;
	if ($self->save_mode) {
		return $self->{'posts'}[$self->{'next_post'}-1];
	} else {
		my $ref;
		if ($ref= $self->{'sth'}->fetchrow_arrayref) {
			my $post=$self->tab->new_post($ref,$self->{'sth'});
			if (!$self->got_post($post)) {
				$self->do_got_post($post);
				return $post;
			} else {
				return $self->get_next;
			}
		} else {
			return undef;
		}
	}
}

=head2 $post_set->save_mode

Returns true if we are in save mode.

=cut

sub save_mode {shift->{'save'}}

=head2 $post_set->add($post)

Adds the post $post (a DBIx::HTMLView::Post object) to the set.

=cut

sub add {
	my ($self, $post)=@_;

	push @{$self->{'posts'}}, $post;
}

=head2 $post_set->posts

Returns an array of DBIx::HTMLView::Post object representing the posts
in the set or dies if there is no posts or if we are not in save mode
with "No posts!" and "Not in save mode" respectivly.

=cut

sub posts {
	my $self=shift;
	croak "Not in save mode" if (!$self->save_mode);
	croak "No posts!" if (!defined $self->{'posts'});
	@{$self->{'posts'}};
}

=head2 $post_set->first

Returns the first post of this set, or dies with "No posts!" if there is no posts. If we are in no-save mode it can be called once before any next_post calls are done, after that it will die with "Not in save mode".

=cut

sub first {
	my $self=shift;
	if ($self->save_mode) {
		my $p=$self->{'posts'}[0];
		croak "No posts!" if (!defined $p);
		$self->{'next_post'}=1;
		return $p;
	} else {
		croak "Not in save mode" if ($self->{'next_post'} != 0);
		my $p=$self->get_next;
		croak "No posts!" if (!defined $p);		
		return $p;
	}
}

=head2 $post_set->view_html

Returns a string that can be used to view the entire set of posts in 
html format.

=cut

#FIXME: We here shourtcust the calls to tab->list_fmt in order to pass params to it, noot good...

sub view_html {
	my ($self,$butt,$flds)=@_;
	$self->view_fmt("view_html", $self->tab->list_fmt("view_html",$butt,$flds));
}

=head2 $post->view_fmt($fmt_name, $fmt)

Returns a string represeting this set of posts in the format named by
$fmt_name. as returned by DBIx::HTMLView::list_fmt($fmt_name). If $fmt 
is specified it will be used as the fmt strings instead of looking up 
a default one.

If the fmt stringit contains a <node>...</node> contrsuct the ... part
will be repeated once for every post and passed as $fmt param to 
view_fmt of DBIx::HTMLView::Post. Curretly we only support one
<node>...</node>  construct in the fmt. If ... is "", undef will
be passed as fmt to the Post, thereby using default Post fmts.

$fmt_name is passed on to the Post objects who the passes it on to the
fld objects, so it can be used to specify how the flds should be
represented  even if you use a custom fmt passed to $fmt.

=cut

sub view_fmt {
	my ($self, $fmt_name, $fmt)=@_;
	my ($head, $node, $foot);
	my $join=undef;
	my $res;
	my $p;

	if (!defined $fmt) {$fmt=$self->tab->list_fmt($fmt_name)}

	#FIXME: Use a real XML parser or some template package
#	while ($fmt =~ s/^(.*?)<perl>(.*?)<\/perl>/$1.eval($2)/geis) {}
	if ($fmt =~ /^(.*?)<node\s*(.*?)>(.*)<\/node>(.*)$/s) {
		$head=$1; $node=$3; $foot=$4;
		if ($2 =~ /^join\s*=\s*[\"\']?(.*?)[\"\']?$/s) {$join=$1}
		if ($node eq "") {$node=undef;}
	} else {
		return $fmt;
	}
	$res=$head;
	my $t=eval {
		$p=$self->first;
	}; die unless ($t || $@ =~ /^(No posts!)/);
	if ($t) {
		$res.=$p->view_fmt($fmt_name, $node);
		while (defined ($p=$self->get_next)) {
			if (defined $join) {$res.=$join}
#			print "hej\n";
			$res.=$p->view_fmt($fmt_name, $node);
		}
	}
	$res.=$foot;

	$res;
}

sub view_text {shift->view_fmt('view_text')}

1;

