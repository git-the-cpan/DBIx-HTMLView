#!/usr/bin/perl

#  Post.pm - A post in a DBI database
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

  DBIx::HTMLView::Post - A post in a DBI database

=head1 SYNOPSIS

  $post=$post_set->first;
  print $post->view_html;   # View a post

  $post->set('testf', 7);   # Set the testf field to 7
  $post->update;            # Update the database with the modified post

  $post=DBIx::HTMLView::Post->new($tab)   # Create a new post
  $post->set('testf', 7);   # Set the testf field to 7
  $post->update;            # Insert the new post in the databse

=head1 DESCRIPTION

This object represents a single post in a specific table in the
database. It has methods to view post as well as to modify it's data
and to reflect those modifications in the database.

=cut

package DBIx::HTMLView::Post;
use strict;
use Carp;
require DBIx::HTMLView::Fmt;

=head2 $post=DBIx::HTMLView::Post->new($tab, $data, $sth)

Creates a new post belonging to the table $tab (a DBIx::HTMLview::Table
object). $data and $sth is used to initialize the post with it's fields,
which can be done in several ways:

1. To create a new empty post with no data set, simply don't specify 
   those arguments.
2. If $data is an array reference, $sth is supposed to be the object 
   returned by a DBI execude call with a select command, and $data should 
   be the array ref with the data you want to create a post object of. If
   the same fieldname apperas twice in the select the first one is 
   presumed to be the one belonging to this post.
3. If $data is a hash reference, it is supposed to contain Fld/Value 
   pairs.
4. If $data is a CGI object the CGI params is supposed to be Fld/Value 
   pairs. Note that relations in this case is defined by setting the name 
   of the relation to the id's of the posts related to, eg it will be 
   defined once for every post.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self=  bless {}, $class;

  my ($tab,$data,$sth) = @_;
  croak "Bad table $tab, use DBIx::HTMLView::Table::new_post" if (!$tab->isa('DBIx::HTMLView::Table'));
  $self->{'tab'}=$tab;

  # Insert data from ctor args
  if (defined $data) {
    if (ref $data eq "ARRAY") {
      my $cnt=0;
      foreach (@{$sth->{'NAME'}}) {
        if (! $self->got_fld($_)) { # As we only want the first one
          my $a=$self->tab->new_fld($_,$data->[$cnt]);
          $self->set($_, $a);      
          $cnt++;
        }
      }
    } elsif (ref $data eq "HASH") {
      foreach (keys %$data) {
        $self->set($_, $data->{$_});
      }
    } elsif ($data->isa('CGI')) {
      foreach ($tab->fld_names) {
        my @val=$data->param($_);
        if (defined $val[0]) {
          $self->set($_,\@val); 
        }
      }
    } else {
      croak "Can't create post from: $data";
    }
  }

  # Create relation objects
  my $id=undef;
  if ($self->got_id) {$id=$self->id}
  # FIXME: Should this be done even if id is not defined?
  foreach ($self->tab->flds) {
    #if ($_->isa('DBIx::HTMLView::Relation') && !$self->got_fld($_->name)) {
    if (!$self->got_fld($_->name)) {
      my $fld;
      if ($_->isa('DBIx::HTMLView::Relation')) {
	$fld=$self->tab->new_fld($_->name,$id);
      } else {
	$fld=$self->tab->new_fld($_->name);
      }
      $self->set($_->name, $fld);
    }
  }
  $self;
}

=head2 $post->set($fld, $val)

Set's the Fld named $fld to $val. If $val is not a DBIx::HTMLView::Fld
object $post->tab->new_fld($fld,$val) is called to create the Fld
object to represent this fld and it's data.

For fields data ($val) is specified as a string or as the first item
of a array referenced to by $val. Relations are represented as a
reference to an array of the id's of the posts being related to.

=cut

sub set {
  my ($self, $fld, $val)=@_;

  if (!UNIVERSAL::isa($val,'DBIx::HTMLView::Fld')) {
    $val=$self->tab->new_fld($fld,$val);
  }
  $val->set_post($self);
  $self->{'data'}{$fld}=$val;
}

=head2 $post->got_fld($fld_name)

Returns true if we have data specified for the fld named $fld_name.

=cut

sub got_fld {
  #FIXME: Will this work for relations?
  my ($self, $fld_name)=@_;
  (defined $self->{'data'}{$fld_name});
}

 
=head2 $post->pairs
 
 Return an array of 2*N element where eache element is the name of the field
 and his value.
 Can be used to easily make perl controls on the
 integrity of the data.
 
=cut
 
sub pairs {
  my $self=shift;
  my @res;
  my $cmd;
  my $post=$self;
  my $i=0;
  
  foreach my $f ($post->fld_names) {   
    foreach ($post->fld($f)->name_vals) {
      $res[$i++]=$_->{'name'};
      $res[$i++]=$_->{'val'};
    }
  }
  @res;
}

=head2 $post->view_text

Returns a string that could be used to view this post in text format

=cut

sub view_text {
  my $self=shift;
  $self->view_fmt("view_text");
}

=head2 $post->view_html

Returns a string that could be used to view this post in html format.

=cut


sub view_html {
  my $self=shift;
  $self->view_fmt("view_html");
}

=head2 $post->view_fmt($fmt_name, $fmt)

Returns a string represeting this post in the format named by $fmt_name
as returned by DBIx::HTMLView::post_fmt($fmt_name). If $fmt is specified
it will be used as the fmt strings instead of looking up a default one.

All <Var ...> will be replaced with there corisponding values or removed
if they are not know, currently no such values are know here (eg all is
remeved).

To include the value of an Fld in output simply put $<fld_name>
in the desired place in the $fmt string. (eg $name will be replaced
with the outpit of $self->fld('name')->view_fmt($fmt_name)).

If $fmt is not specified the default post fmt will be used as returned
by post_fmt in DBIx::HTMLView::Table.

$fmt_name is passed on to fld objects, so it can be used to specify 
how the flds should be represented even if you use a custom fmt passed
to $fmt.

=cut

sub view_fmt {
  my ($self, $fmt_name,  $fmt)=@_;

  if (!defined $fmt) {$fmt=$self->tab->post_fmt($fmt_name)}

  my $p=DBIx::HTMLView::Fmt->new;
  return $p->parse_fmt($self, $fmt_name, $fmt);
}

sub compiled_fmt {
  my ($self, $fmt_name,  $fmt, $sel, $opt)=@_;

  if (!defined $fmt) {$fmt=$self->tab->post_fmt($fmt_name)}

  my $p=DBIx::HTMLView::Fmt->new;
  my $r=$p->compiled_fmt($self, $fmt_name, $fmt, $sel, $opt);

  $self->{'fmt_select'}=$p->{'select'};

  return $r;
}

sub view_fmt_code {
  my ($self, $fmt_name,  $fmt)=@_;

  if (!defined $fmt) {$fmt=$self->tab->post_fmt($fmt_name)}

  my $p=DBIx::HTMLView::Fmt->new;
  return $p->parse_fmt_to_code($self, $fmt_name, $fmt);
}

=head2 $post->fld_names

Returns an array of the fld names currently specified in this post,
use $post->tab->fld_names to list all Fld of the post.

=cut

#FIXME: Check where thisone is used.
sub fld_names {
  my $self=shift;
  confess "No fields found!" if (!defined $self->{'data'});
  keys %{$self->{'data'}};
}

=head2 $post->fld($fld_name)
=head2 $post->val($fld_name)

Returns the Fld representing that data of the Fld named $fld_name.

=cut

sub fld {shift->val(@_);}
sub val {
  my ($self, $fld)=@_;
  if (!defined   $self->{'data'}{$fld}) {
    if ($self->got_id) {
      confess ("Getting not implemented yet");
    } else {
      return $self->tab->fld($fld);
    }
  } else {
    return $self->{'data'}{$fld};
  }
}

=head2 $post->tab

Returns the table this post belongs to (a DBIx::HTMLView::Table object).

=cut


sub tab {
  my $self=shift;
  confess "No table defined!" if (!defined $self->{'tab'});
  $self->{'tab'};
}

=head2 $post->got_id

Returns true if the id of this post is defined, which is the same as that the post is represented in the database as well (which is not true for new posts that not yet have been added to the datbase, using $post->update).

=cut

sub got_id {
  my $self=shift;
  (defined $self->{'data'}{$self->tab->id->name} && $self->{'data'}{$self->tab->id->name}->got_val);
}


=head2 $post->id

Returns the id of this post or dies with "No id defined" if it is not defined. Se $post->got_id.

=cut

sub id {
  my $self=shift;
  my $val=$self->val($self->tab->id->name);
  confess "No id defined" if (!defined $val || !$val->got_val);
  $val->val;
}

=head2 $post->update

Updates the database with the data found in this object or creats a new post in the database with that data if the id is not defined. Se $post->got_id.

=cut

#FIXME: Make sure the new id we get are assigned properly to this object
#       as well 
sub update {
  my $self=shift;
  if ($self->got_id) {
    $self->tab->change($self);
  } else {
    $self->tab->insert($self);
  }
}

sub var {
  my ($self, $var)=@_;
  return "";
}

1;


# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
