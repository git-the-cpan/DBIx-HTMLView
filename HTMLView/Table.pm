#!/usr/bin/perl

#  Table.pm - A table within a generic DBI databse
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

  DBIx::HTMLView::Table - A table within a generic DBI databse

=head1 SYNOPSIS

my $table=$dbi->tab('Test');

# List all posts
my $hits=$table->list();

# Get post with id 7
my $post=$table->get(7);

=head1 DESCRIPTION

This object is supposed to be created inside a database description as
described in the DBIx::HTMLView::DB man page to represent a table and
it's fields and relations. Then it can be used to access the posts
of that table.

=head1 METHODS
=cut

package DBIx::HTMLView::Table;
use strict;
use Carp;

require DBIx::HTMLView::Str;
require DBIx::HTMLView::Post;
require DBIx::HTMLView::PostSet;

require DBIx::HTMLView::Selection;

=head2 DBIx::HTMLView::Table->new($name, [$opt,] @flds)

Creates a new table representation for a table named $name. This has to
be the same name as the database engine has for the table. @flds is an 
array of DBIx::HTMLView::Fld objects which represent the separate fields
and relations of the table.

If $opt is a hash referencs and not a fld object its used to set a few 
options for the Table. Currently, the following options are defined:

  flds_to_view - An array specifying which Flds to view in a default 
    listing.
  rows - How many rows per page a default listing should contain.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self=  bless {}, $class;

  my ($name, @flds) = @_;
  $self->{'name'}=$name;
  
  if (!DBIx::HTMLView::Fld->isa($flds[0]) && ref $flds[0] eq 'HASH') {
    $self->{'options'}=shift(@flds);
  }
  $self->{'options'}{'rows'}=50;

  foreach my $f (@flds) {
    $f->set_table($self);
    push @{$self->{'flds'}}, $f;
    $self->{'fld_names'}{$f->name}=$#{$self->{'flds'}};
    if ($f->isa('DBIx::HTMLView::Id')) {$self->{'id'}=$f}
  }
  if (!defined $self->{'id'}) {
    my $fld=DBIx::HTMLView::Id('id');
    $fld->set_table($self);
    $self->{'id'}=$fld;
    push @{$self->{'flds'}}, $fld;
    $self->{'fld_names'}{$fld->name}=$#{$self->{'flds'}};
  }

  $self;
}

=head2 $tab->initiate_js_onSubmit();
 Initalize the js of the onSubmit looking for files with default name
 
=cut

sub initiate_js_onSubmit() {
  my $self=shift;
  my $path=shift;
  my $filename=$self->name.'_onSubmit';
  my $str=undef;
  if (open (JSF,"<".$path.$filename.'.js'))
    {
      my $r;
      while ($r=<JSF>)
	{
	  $str.=$r;
	}        
      
      close(JSF);
      $self->set_JSonSubmit($str);
      $self->set_JSonSubmit_name($filename.'()');
    }
}

=head2 $table->get_JSonSubmit()
  Returns the javascript code associated to the submit botton on edit/insert
  forms.
=cut
  
sub get_JSonSubmit() {
  shift->{'JS_onSubmit'};
}
 
=head2 $table->set_JSonSubmit()
 Set the javascript code associated to the submit botton on edit/insert
 forms.
=cut

sub set_JSonSubmit() {
  my $self=shift;
  $self->{'JS_onSubmit'}=shift;
}
 
=head2 $table->set_JSonSubmit_name()
 Set the name of the function associated to the submit botton on edit/insert
 forms.
=cut
 
sub set_JSonSubmit_name {
  my $self=shift;
  $self->{'JS_onSubmit_name'}=shift;
}
 
 
=head2 $table->get_JSonsubmit_name()
 Returns the name of the function associated to the submit botton on 
 edit/insert forms.
=cut

sub get_JSonSubmit_name() {
  shift->{'JS_onSubmit_name'};
}


sub opt {
  my ($self, $opt)=@_;
  return $self->{'options'}{$opt};
}

=head2 $table->id

Returns the DBIx::HTMLView::Fld object that is used as the id field for
this table.

=cut

sub id {
  my $self=shift;
  confess "Id not defined!" if (!defined $self->{'id'});
  $self->{'id'};
}

=head2 $table->name

Returns the name of this table.

=cut

sub name {
  my $self=shift;
  die "Name not defined!" if (!defined $self->{'name'});
  $self->{'name'};
}

=head2 $table->set_db($db)

Use by the parent DBIx::HTMLView::DB object to inform this object
which databse it belongs to ($db). It should not be used elsewhere.

=cut

sub set_db {
  my ($self, $db)=@_;
  $self->{'db'}=$db;
}

=head2 $table->list($search, $extra, $flds)

Returns a DBIx::HTMLView::PostSet object with the posts matching the
$search string (see the DBIx::HTMLView::Selection man page for a 
description of the search language, it is close to SQL). $extra will
be apended to the SQL select command before it is sent to the databse
it can be used to specify a ORDER BY clause for example.

$flds is for optimisations. If it is not defined all fileds of the 
posts are retrieved from the datbase. If it is an array ref only the 
fields who's names are listed in there are retrieved. If a search 
string is specied the fields used in that string will also be 
retrieved.

The PostSet object return is placed in no-save mode, which means
that you will be able to itterate through the posts once and then
they are gone. This is becaue there can be quite a lot of data
returned from the database server and there is usualy no reason to
store it all in memory.

To create a PostSet object in save mode with the result you could do
something like:

$post_set=$table->list;
$post_set_save=DBIx::HTMLView::PostSet->new;
while (defined $post=$self->get_next) {
  $post_set_save->add($post);
}
'

=cut

sub select_list {
  my ($self, $search, $extra, $flds, $order)=@_;
  my $select;

	my $sel=DBIx::HTMLView::Selection->new($self,$search,$flds,undef,$order);
	$select=$sel->sql_select;

  if (defined $extra) {$select.=" " .$extra;}
  return $select;
}

sub list {
  my $self=shift;
  $self->sql_list($self->select_list(@_));
}

=head2 $table->count($search, $extra)

Counts the numbers of posts matching the $search string (see the 
DBIx::HTMLView::Selection man page for a description of the search 
language, it is close to SQL). $extra will be apended to the SQL 
select command before it is sent to the databse.

=cut

sub count {
  my ($self, $search, $extra)=@_;
  my $select;
  my $fld='*';

  if (defined $search) {
    my $sel=DBIx::HTMLView::Selection->new($self,$search,undef);
    $select=$sel->sql_count;
    $fld='*';
  } else {
    $select="select distinct count($fld) from " . $self->name;
  }

  if (defined $extra) {$select.=" " .$extra;}
  return $self->sql_list($select)->get_next->fld("count($fld)")->val;
}

=head2 $table->noid_list($search, $extra, $flds)
  
Works in a similar way to $table->list, but it will not add the id
field to flds select, and it will do a distinct select. The posts
returned are some kind of pseudo posts. If you try to modify and update 
them and the new posts will be added to the db as they have no id.

Will currently not work with relations (FIXME). It will never work with 
N2N relations as they require the id selected in order to find the 
related posts.


=cut

sub noid_list {
  my ($self, $search, $extra, $flds)=@_;
  my $fld='';
  my $select;

  if (defined $flds) {
    foreach (@$flds) {
      my $n=$self->fld($_)->field_name;
      if (defined $n){$fld.="$n, " ;}
    }
  } else {
    $fld='*';
  }
  $fld =~ s/, $//g;

  $select="select distinct $fld from " . $self->name;

  if (defined $search) {
    $select.=" where " . $search;
  } 
  if (defined $extra) {$select.=" " .$extra;}
  $self->sql_list($select);
}


=head2 $table->sql_list($select)

Sends $select, which should be a select clause on this table,to the 
database and turns the result into a DBIx::HTMLView::PostSet object.
You should use the list method insted. It gives you a smoother interface.

=cut

sub sql_list {      
  my ($self, $select)=@_;

#  print "sel=$select\n";

   my $sth=$self->db->send($select);  

  DBIx::HTMLView::PostSet->new($self, $sth,0);
}

=head2 $table->new_post(...)

Creates a new DBIx::HTMLView::Post object linked to this table (all 
posts must be linked to a table). All arguments are passed on to the 
new method.

=cut

sub new_post {
  my $self=shift;
  DBIx::HTMLView::Post->new($self, @_);
}

=head2 $table->new_fld($fld,$val)

Creates a copy of the DBIx::HTMLView::Fld object named $fld and gives 
it the value $val. It is used by the DBIx::HTMLView::Post objects to
create objects representing the diffrent values of the fields and does 
not make much sense elsewhere.

For fields data ($val) is specified as a string or as the first item
of a array referenced to by $val. Relations are represented as a
reference to an array of the id's of the posts being related to.

=cut

sub new_fld {
  my ($self, $fld, $val)=@_;
  if ($self->got_fld($fld)) {
    my $newfld=$self->fld($fld)->new($fld,$val,$self);
    $newfld->initiate_js_onChange();
    return $newfld;
  } else {
    return DBIx::HTMLView::Str->new($fld,$val,$self);
  }
}

=head2 $table->fld_names

Returns an array of the names of all the fields and relation in this 
table.

=cut


sub fld_names {
  my $self=shift;
  my @names;
  die "No fields found!" if (!defined $self->{'flds'});
  foreach (@{$self->{'flds'}}) {push @names, $_->name;}
  @names;
}

=head2 $table->fld($fld)

Returns the DBIx::HTMLView::Fld object of the field or relation named 
$fld.

=cut

sub fld {
  my ($self, $fld) =@_;
  die "No fields found!" if (!defined $self->{'flds'});
  my $pos=$self->{'fld_names'}{$fld};
  if (defined $pos) {
    return $self->{'flds'}[$pos];
  } else {
    confess "Field not found: $fld";
  }
}

=head2 $table->got_fld($fld)

Returns true if this table has a field or relation named $fld.

=cut

sub got_fld {
  my ($self, $fld) =@_;
  return 0 if (!defined $self->{'flds'});
  if (defined $self->{'fld_names'}{$fld}) {
    return 1;
  } else {
    return 0;
  }
}

=head2 $table->fld($fld)

Returns an array of DBIx::HTMLView::Fld objects of all the fields and
relations in this table.

=cut

sub flds {
  my $self=shift;
  die "No fealds found!" if (!defined $self->{'flds'});
  @{$self->{'flds'}};
}

=head2 $table->db

Returns the DBIx::HTMLView::DB object this table belongs to.

=cut

sub db {
  my $self=shift;
  die "No db defined!" if (!defined $self->{'db'});
  $self->{'db'};
}

=head2 $table->del($id)

Deletes the post with id $id.

=cut

sub del {
  my ($self, $id)=@_;
  foreach ($self->flds) {
    $_->del($id);
  }
  $self->db->del($self, $id);
}

=head2 $table->update($post)
=head2 $table->change($post)

Updates the data in the database of the post represented by $post (a 
DBIx::HTMLView::Post object) with the data contained in the object.

=cut


sub update {shift->chnage(@_);}
sub change {
  my ($self, $post)=@_;
  $self->db->update($self, $post);
}

=head2 $table->add($post)
=head2 $table->insert($post)

Inserts the post $post (a DBIx::HTMLView::Post object) into the 
database.

=cut

sub add {shift->insert(@_);}
sub insert {
  my ($self, $post)=@_;
  $self->db->insert($self, $post);
}

=head2 $table->get($id)

Returns a DBIx::HTMLView::Post object representing the post with id 
$id.

=cut

sub get {
  my ($self, $id)=@_;
  $self->list($self->id->name . "=" . $id)->first;
}

=head2 $table->msql_create

Will create the tabel using SQL commands that works with msql.

=cut

sub sql_create {
  my $self=shift;
  $self->db->sql_create_table($self)
}

=head2 $table->post_fmt($kind)

Returns a fmt for viewing a post from this table in the 
$kind format. It can be specified in ... FIXME: where?

=cut

sub post_fmt {
  my ($self,$kind) =@_;
  if (defined $kind && $kind eq 'view_text') {
    my $res="";
    foreach ($self->fld_names) {
      $res.="$_: <fld $_>\n";
    }
    return $res;
  } else {
    my $res="<table>";
    foreach my $fld ($self->fld_names) {
      $res.="<tr><td valign=top><b>$fld</b></td><td><fld $fld></td></tr>\n";
    }
    $res.="</table>";
    return $res;
  }
}

=head2 $table->list_fmt($kind, $butt, $flds)

Returns a fmt for viewing a set of posts from this table in the 
$kind format. It can be specified in ... FIXME: where?

The default fmt will consist of a table with one colume per Fld specified 
in the arrayref $flds. If it is not defined all Fld will be viewed.

$butt can be used to specify the contents of an extra colum to the right 
of the rest. To for example contain the view, edit and delete buttons.

=cut

sub list_fmt {
  my ($self, $kind, $butt, $flds) = @_;

  if (defined $kind && $kind eq 'view_text') {
    return "<node join=\"\n\"></node>";
  } else {
    my $res="<table border=4 cellspacing=3 cellpadding=3>";
    my @flds;
    
    if (defined $flds) {
      @flds=@$flds;
    } else {
      @flds=$self->fld_names;
    }
    
    $res.="<tr>";
    foreach (@flds) {
      if (defined($self->db->viewer)) {
        $res.='<th><a href="'.$self->db->viewer->script_name."?_Order=$_&".
	  $self->db->viewer->lnk."\">$_</a>"."</th>";
      } else {
        $res.="<th>$_</th>";
      }
    }
    $res.="</tr>";

    $res.="<node><tr>";
    foreach (@flds) {
      $res.="<td><fld " . $_ . "></td>";
    }
    if (defined $butt) {
      $res.="<td>$butt</td>";
    }
    $res.="</tr></node>";

    $res.="</table><br>";
    return $res;
  }
}

sub delete_code {
  my ($self)=@_;
  my $res='';

  #FIXME: Removed relation links in other posts to the deleted post

  foreach ($self->flds) {$res.=$_->delete_code . "\n";}

  return $res.'$dbi->prepare("delete from '.$self->name.
         ' where id=".$q->param("id"))->execute;';
}

1;


# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
