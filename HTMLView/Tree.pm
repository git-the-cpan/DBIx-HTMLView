#!/usr/bin/perl

#  Tree.pm
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

  DBIx::HTMLView::Tree

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package DBIx::HTMLView::Tree;
use strict;
use Carp;

use vars qw(@ISA);
require DBIx::HTMLView::Int;
@ISA = qw(DBIx::HTMLView::Int);

require DBIx::HTMLView::Fmt;

=head2 $fld->to_tab_name

Returns the name of the to table.

=cut

sub to_tab_name {
  shift->data('tab')
}

sub super_name {shift->data('super_name')}

=head2 $fld->to_tab

Returns the DBIx::HTMLView::Table object representing the to table.

=cut

sub to_tab {
  my $self=shift;
  $self->db->tab($self->to_tab_name);
}

sub post {
  my $self=shift;
  $self->to_tab->get($self->val);
}

=head2 $fld->view_fmt_edit_html($postfmt_name, $postfmt)

Used by the default edit_html fmt. It will returns a string 
containing "<input type=radio ...>" constructs to allow the user to 
specify which post (chunk in the tree) we should be related to. All 
posts in the to table (tree) will be listed here in a hierarchically
list showing the tree structure and viewed with 
view_fmt($postfmt_name,$postfmt).

$postfmt_name will default to 'view_html'. If $postfmt isn't defined 
some decent default is tried to be derived from the 'view' fmt or if
that's not defined, the default fmt.

The $postfmt should contain a <Var Edit> tag that will be raplaced by
the radio button.

=cut

sub view_fmt_edit_html {
  my ($self, $postfmt_name, $postfmt)=@_;
  
  if (!defined $postfmt_name) {
    $postfmt_name='view_html';
  }
  if (!defined $postfmt) { # Try to construc some nice default
    $postfmt=$self->fmt('view');
    if ($postfmt !~ /<Var\s+Edit>/i) {
      $postfmt = "<Var Edit> $postfmt<br>";
    }
  }

  my $res="";

   my $posts=$self->to_tab->sql_list('select * from ' .$self->to_tab_name . 
                                    ' where ' . $self->super_name . 
                                    ' is null');
  $res.=$self->build_edit_tree($posts,$postfmt,$postfmt_name);
  return $res;
}

sub build_edit_tree {
  my ($self, $posts,$postfmt,$postfmt_name)=@_;
  my $res="<dl>";

  my ($p, $got, $edit, $fmt);  
  while (defined ($p=$posts->get_next)) {    
     if ($self->got_val && $p->id eq $self->val) {$got="checked"} else {$got=""}
    $edit='<dt><input type="radio" name="' . $self->name.
      '" value="' . $p->id .
        "\" $got>";
     $fmt=$postfmt; $fmt =~ s/<Var\s*Edit>/$edit/i;
    $res.=$p->view_fmt($postfmt_name, $fmt);
    $res.='</dt><dd>';
    $res.=$self->build_edit_tree($self->to_tab->list($self->super_name . "=" . 
                                                     $p->id),$postfmt,
                                 $postfmt_name);
    $res.='<dd>';
  }  
  $res."</dl>";
}

=head2 $fld->view_fmt($fmt_name, $fmt)

Will call view_fmt($fmt_name, $fmt) on the post this relation is 
pointing to and return the result, se DBIx::HTMLView::Post for info
on the $fmt format.

If $fmt is not defined the fmt parameter named $fmt_name specified
in the $data parameter to the constructor will be used as fmt string.

If the fmt string starts with "<InRel>", the rest of the fmt will
be handled by this method instead of calling the PostSet version.
Current the only supported construct here is <perl>...</perl> which
will be replaced by the returnvalue of eval(...).

=cut

sub view_fmt {
  my ($self, $fmt_name, $fmt)=@_;
  if (!defined $fmt) {$fmt=$self->fmt($fmt_name)}

  if ($fmt =~ /^<InRel>(.*)$/i) {
     $fmt=$1;
    my $p=DBIx::HTMLView::Fmt->new;
    return $p->parse_fmt($self, $fmt_name, $fmt);
  } else {
    if ($self->got_val) {
      my $p=$self->post;
      my $fld;
      foreach ($self->to_tab->fld_names) {
	if (!$p->got_fld($_)) {
	  $fmt =~ s/<\s*fld\s+$_\s*>//gi;
	}
      }
      my $res=$p->view_fmt($fmt_name, $fmt);
      return $res;
    }
    return "";
  }
}

sub view_fmt_code{DBIx::HTMLView::Fld::view_fmt_code(@_)}

sub default_fmt {
  my ($self, $kind)=@_;
  if (defined $kind && $kind eq 'edit_html') {
    return '<InRel><perl>$self->view_fmt_edit_html("view_html")</perl>';
  }

  return DBIx::HTMLView::Relation::default_fmt(@_)
}

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
