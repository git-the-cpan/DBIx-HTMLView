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

require DBIx::HTMLView::Fmt;

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
   will be replaced with the data of the post beeing viewed. Obsolete, use 
   the fmt param instead.
join_str - As a post can be related to several other and each will be 
   viewed using the view string above and then joined together using this 
   string as glue. Default is ", ".  Obsolete, use the fmt param instead.
fmt - Specifies the fmt string to be passed to view_fmt of the PostSet 
   object representing the posts we are related to. For backwards 
   compatibility it defaults to "<node join="$join_str">$view</node>", 
   if $view is defined. $view and $join_str are the var defined above.
extra_sql - Extra sql code passe to the list method when listing related 
   posts. This can for example be used to specify in which order related 
   posts should be viewed. Default is "ORDER BY <to table id name>".
no_create - Set to one if the link table is craeted elsewhere and thus 
   should not be created automatically.


As you se, it is only tab that does not have any default value, 
so it has to be defined within the table declaration, it's usually also a
good idea to specify fmt to something decent as well.
 
=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self=  bless {}, $class;

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

sub got_id {return shift->post->got_id;}

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
    $self->{'posts'}->usepages(0);
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

=head2 $fld->view_fmt_edit_html($postfmt_name, $postfmt)

Used by the default edit_html fmt. It will return a string containing 
"<input type=checkbox ...>" constructs to allow the user to specify
which posts we should be related to. All posts in the to table will 
be listed here and viewed with view_fmt($postfmt_name,$postfmt).

$postfmt_name will default to 'view_html'. If $postfmt isn't defined 
some decent default is tried to be derived from the default fmt for
$postfmt_name.

The $postfmt should contain a <Var Edit> tag that will be raplaced by
the checkbox button.

=cut

sub view_fmt_edit_html {
  my ($self, $postfmt_name, $postfmt)=@_;
  my $res="";
  my $foot;

  if (!defined $postfmt_name) {
    $postfmt_name='view_html';
  }
  if (!defined $postfmt) { # Try to construc some nice default from fmt
    $postfmt=$self->fmt($postfmt_name);
    $postfmt =~ s/(.*?)<node[^\>]*(\"[^\"]*\")?[^\>]*>(.*?)<\/node>(.*)$/$3/i;
    $res.=$1; $foot=$4;
    if ($postfmt !~ /<Var\s+Edit>/i) {
      $postfmt = "<Var Edit> $postfmt<br>";
    }
  }

  my @ids;
  foreach ($self->posts) {
    push @ids, $_->id;
  }

  my $posts=$self->to_tab->list;
  my $p;
  my ($fmt,$edit);
  while (defined ($p=$posts->get_next)) {
    my $got_it="";
    foreach (@ids) {
      if ($p->id == $_) {
        $got_it="checked";
        last;
      }
    }
    $edit="<input type=checkbox name=\"" . $self->name ."\" value=".
          $p->id . " $got_it>";
    $fmt=$postfmt; $fmt=~s/<Var\s+Edit>/$edit/i;
    $res.=$p->view_fmt($postfmt_name, $fmt);
  }
  $res.="<input type=hidden name=\"" . $self->name ."\" value=do_edit>";
  $res.=$foot;
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

sub sql_data_array {
  my ($self, $sel, $sub)=@_;
  my $nxt=shift(@$sub);

  $sel->add_tab($self->lnk_tab_name);
  $sel->add_tab($self->to_tab_name);


  my $a= $self->lnk_tab_name . "." . $self->from_field_name .
	  "=" . $self->tab->name . "." . $self->tab->id->name . 
	  " AND " . $self->lnk_tab_name . "." . $self->to_field_name .
	  "=" . $self->to_tab_name . "." .$self->to_tab->id->name;
  my $b = $self->to_tab->fld($nxt)->sql_data_array($sel, $sub);
  if (ref $b) {
    $a="$a AND " . $b->[0];
    $b=$b->[1];
  }
  return [$a,$b];
}

sub sql_data {
  my ($self, $sel, $sub)=@_;
  my $a=$self->sql_data_array($sel,$sub);
  return $a->[0] . " AND " . $a->[1];
}

sub compiled_fmt {
  my ($self, $fmt_name, $fmt, $sel, $opt)=@_;
  if (!defined $fmt) {$fmt=$self->fmt($fmt_name)}  
  
  if ($fmt =~ /^<InRel>(.*)$/i) {
    $fmt=$1;
    my $p=DBIx::HTMLView::Fmt->new;
    return $p->compile_fmt($self, $fmt_name, $fmt, $opt);
  } else {
    my $tableid='<Value ' . $self->tab->name . '.' . $self->tab->id->name . '>';
    my $psel=DBIx::HTMLView::Selection->new($self->to_tab,'',[]);    
    $psel->add_tab($self->lnk_tab_name);
    $psel->add_fld($self->lnk_tab_name . "." . $self->from_field_name);
    $psel->add_fld($self->lnk_tab_name . "." . $self->to_field_name);
    $psel->add_to_where('('.$self->lnk_tab_name . "." . $self->from_field_name .
			"=?".
			" AND " . $self->lnk_tab_name . "." . $self->to_field_name .
			"=" . $self->to_tab_name . "." .$self->to_tab->id->name . ")");

    my $postfmt=DBIx::HTMLView::PostSet->new($self->to_tab)->compiled_fmt($fmt_name, $fmt, $psel, $opt);
    my $sql=$psel->sql_select;
    $sql=~s/\'/\\\'/g;
    $sql.=" " . $self->data('extra_sql') if ($self->got_data('extra_sql'));
    $postfmt=~s/<Value ([^>]+)>/'$row->['.$psel->field_pos($psel->view_fld($1)).']'/ge;
    
    return '; {
my $sth=$dbi->prepare(\''.$sql.'\');
if (!defined $sth) {die $sth->errstr}
my $hits=$sth->execute('.$tableid.');

my $row=$sth->fetchrow_arrayref;

'.$postfmt.'

} $res=$res';
  }
}

=head2 $fld->field_name

Returns undef as we've not got any field in the main table. Se 
DBIx::HTMLView::Fld.

=cut

sub field_name{undef}

sub sql_create {
  my $self=shift;
	
	if (!($self->got_data('no_create'))) {
		$self->lnk_tab->sql_create;
	}
  undef;
}

=head2 $fld->view_fmt($fmt_name, $fmt)

Will call view_fmt($fmt_name, $fmt) on the postset containing all 
the posts this relation is pointing to and return the result, see 
DBIx::HTMLView::PostSet for info on the $fmt format.

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
    return "No match!" if !defined($self->post);
    return $self->post_set->view_fmt($fmt_name, $fmt);
  }
}

sub default_fmt {
  my ($self, $kind)=@_;
  if (!defined $kind) {
    if ($self->got_data('view')) { # For backwards compatibility
      my $v=$self->data('view');
      foreach ($self->to_tab->fld_names) {
        $v =~ s/\$$_/<fld $_>/g;
      }
      my $res= '<node join="'.$self->join_str.'">'. $v;
      $res.="</node>";
      $self->{'data'}{'fmt'}=$res; #FIXME: Use an accessor method
      return $res;
    }
  }
  if ($kind eq 'edit_html') {
    return '<InRel><perl>$self->view_fmt_edit_html("view_html")</perl>';
  }
  
  return DBIx::HTMLView::Relation::default_fmt(@_)
}

sub delete_code {
  my ($self)=@_;

  return '$dbi->prepare("delete from '.$self->lnk_tab_name.
         ' where '.$self->from_field_name.'=".$q->param("id"))->execute;';
}



1;


# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
