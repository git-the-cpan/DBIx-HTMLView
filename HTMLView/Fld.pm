#!/usr/bin/perl

#  Fld.pm - Base class for field and relation classes
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

  DBIx::HTMLView::Fld - Base class for field and relation classes

=head1 SYNOPSIS

  $fld=$post->fld('testf');
  print $fld->view_html;

=head1 DESCRIPTION

These objects are used to represent the fields and relations of a
table inside the and the DBIx::HTMLView::Table object as well as the
data contained in those fields and relations in the
DBIx::HTMLView::Post objects.

This is the base class of all field classes such as
DBIx::HTMLView::Text DBIx::HTMLView::Str and DBIx::HTMLView::Int as
well as the relations such as DBIx::HTMLView::N2N.

=head1 METHODS
=cut

package DBIx::HTMLView::Fld;
use strict;
use Carp;

=head2 $fld=DBIx::HTMLView::Fld->($name, $data)
=head2 $fld=DBIx::HTMLView::Fld->new($name, $val, $tab)

The only time you create this kind of objects is when you create the
DBIx::HTMLView::Table objects of the top level description of the
databse (se DBIx::HTMLView::DB). And in that case it is the first
version of the constructor you use preferable through the shortcuts in
DBIx::HTMLView. $name is a string naming the relation or field while
$data is a hashref with parameters specific to the field or relation
kind used. There are a few parameters that are common though:

sql_size - The size to be used to store this in the database, eg the 
  value 100 in the sql type definition CHAR(100).
sql_type - Allows you to overide the database specific default type to 
  use for a fld. If this is defined it will be used as sql type for 
  this fld.
fmt - A string specifying how this Fld should be viewed by default. It
  is the fmt string that will be used by view_fmt if no other are 
  specified, or if the one specified does not excist. The format of 
  this string depends on the type of Fld se the docs to the view_fmt 
  methods of the diffrent Fld subclasses for info on it.
fmt_* - You can give each Fld any number of custom fmts used to view
  this fld in diffrent contexts. There are a few special one: 
  fmt_view_html, fmt_edit_html, fmt_view_text that are tied to the 
  method calls view_html, edit_html, view_text respectivly (eg the
  method call view_html is the same as view_fmt('view_html'))

The second version of the constructor is used by the
DBIx::HTMLView::Table class when it creates copies of its flds, gives
them their data $val and places them in a post. $tab is the
DBIx::HTMLView::Table object the fld belongs to.

For fields data ($val) is specified as a string or as the first item
of an array referenced to by $val. Relations are represented as a
reference to an array of the id's of the posts being related to.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self=  bless {}, $class;

  my ($name, $val, $tab)=@_;

  #print "Name: $name ";
  #use Data::Dumper; print Dumper($val) . "<br>";

  if (ref $val eq "HASH") {
    $self->{'data'}=$val;
  } else {
    if (ref $val eq "ARRAY") {$val=$val->[0];}
    if (ref $this) {$self->{'data'}=$this->{'data'};}
    $self->{'val'}=$val;
  }

  $self->{'name'}=$name;
  #if (DBIx::HTMLView::Table->isa($tab)) {$self->set_table($tab);}
  $self->{'tab'}=$tab;

  $self;
}

=head2 $fld->initiate_js_onChange();
  Initalize the js of the onChange eveng looking for files with default name
=cut

sub initiate_js_onChange() {
  my $self=shift;
  my $filename=$self->name.'_'.$self->tab->name.'_onChange';
  #if (open (JSF,"</root/public_html/DBIx-HTMLView-0.7/".$filename.'.js')) {
  if (open (JSF,"<".$filename.'.js')) {
    my $r; 
    my $str=undef;
    while ($r=<JSF>) {
      $str.=$r;
    }       
       
    close(JSF);
    $self->set_onChange($str);
    $self->set_onChange_name($filename);
  }
}
 
=head2 $fld->get_onChange()
  Returns the code of the Javascript linked to the onChange event in
  edit/insert forms.
=cut
 
sub get_onChange {
  shift->{'jscodeonChange'};
}
 
=head2 $fld->get_onChange_name()
  Returns the name of the javascript function to be launched on the onChange
  event. If undef returns the default.
=cut
 
sub get_onChange_name {
  my $self=shift;
  my $ans=$self->{'jsnameonChange'};
  $ans;
}
 
 
=head2 $fld->set_onChange_name()
  Set the name of the js function to be called with onChange event
=cut
 
sub set_onChange_name() {
  my $self=shift;
  $self->{'jsnameonChange'}=shift;
}
 
 
=head2 $fld->set_onChange()
 Set the code of the js function to be called with onChange event
=cut
 
sub set_onChange() {
  my $self=shift;
  $self->{'jscodeonChange'}=shift;
}

=head2 $fld->name

Returns the name of the fld.

=cut

sub name {
  shift->{'name'};
}


=head2 $fld->data($key)

Returns the value of $key set from the $data hashref in the new
method. It dies if the data was not set.

=cut

sub data {
  my ($self,$key)=@_;
  confess ("$key not defined!") if (!defined $self->{'data'}{$key});
  $self->{'data'}{$key}
}

=head2 $fld->got_data($key)

Returns true if the value of $key was set in the $data hashref in the 
new method.

=cut

sub got_data {
  my ($self, $key)=@_;
  (defined $self->{'data'}{$key});
}

=head2 $fld->set_table($tab)

Used by DBIx::HTMLView::Table to inform the fld of which table it belongs
to. All fld belongs to either a Table or a Post.

=cut


sub set_table {
  my ($self, $tab)=@_;
  $self->{'tab'}=$tab;
  $self->initiate_js_onChange();
}

=head2 $fld->set_post($post)

Used by DBIx::HTMLView::Post to inform the fld pf which post it belongs 
to. All fld belongs to either a Table or a Post.

=cut

sub set_post {
  my ($self, $post)=@_;
  $self->{'post'}=$post;
}

=head2 $fld->tab

Return the DBIx::HTMLView::Table object this fld belongs to.

=cut

sub tab {
  my $self=shift;
  confess "Table not defined!" if (!defined $self->{'tab'});
  $self->{'tab'};
}

=head2 $fld->db

Return the DBIx::HTMLView::Db object this fld belongs to.

=cut

sub db {
  my $self=shift;
  confess "Table not defined!" if (!defined $self->{'tab'});
  $self->tab->db;
}

=head2 $fld->post

Returns the DBIx::HTMLView::Post object this fld belongs to.

=cut

sub post {
  my $self=shift;
  confess "Post not defined!" if (!defined $self->{'post'});
  $self->{'post'};
}

sub got_post {return defined shift->{'post'}}

1;

=head1 VIRTUAL METHODS

Those methods are not defined in this class, but are suposed to be
defined in all fld subclasses.

=head2 $fld->view_fmt($fmt_name,$fmt)

Returns a string used to display the contents (value) of the
fld. Usually this is just the value of the fld, but for more complex
Fld, like relations, $fmt_name can be used to specify which fmt that
should be used (the diffrent fmts are defined in the constructor, se the 
$fld->new method). If the $fmt param is defined it will be used
as the fmt string insteda of looking up a default one.

=head2 $fld->view_html

Returns a html string used to display the contents (value) of the fld.

=head2 $fld->edit_html

Returns a string that can be placed inside an html <form> section used
to edit this field or relation. It will be some sort of input tag with
the same name as the fld.

=head2 $fld->sql_data($sel)

Called if this fld is used in the selection string in a DBIx::HTMLView::Selection object $sel. It is supposed to add apropriate data to the object using $sel->add_fld and $sel->add_tab (se the DBIx::HTMLView::Selection manpage for details) and return the string to represent it in the where clause (it will usualy be the name of the field itself).

=head2 $fld->view_text

Returns a text string used to view the contents (value) of the fld
(this method is not yet implemented for all fld classes).

=head2 $fld->del($id)

Is called when a post with id $id is deleted. This is to allow the
relations of this post to clean out the data that is placed in other
tabels. The actual post will be removed from the table after all fld
object del methods has been called.

=head2 $fld->field_name

The name of the sql field in the main table representing this fld. For
a N2N relation it will be undefined as it is represented in a separate
table and not in the main one. For fields it will ofcourse be the name
of the field.

=head2 $fld->name_vals

This medthod is called whenever the data of a post are updated in the
actual database or a new post is added. It returns an
array of hashes containing the two keys name and val.  Where the value
of the name keys are the names of database fields that are supposed to
be set to the values of the val keys.  e.g.
return ( {'name' => 'Color', 'value' => 'Red'}, 
    {'name' => 'Size', 'value' => 'XXL'} );

This is the method where relations are supposed to update all
secondary tabels (eg the tables used to represent the actuall
relations).

=head2 $fld->sql_create

Will send the nesesery SQL commands to create this fld in database and
return the sql type (if any) of this field to be included in the
CREATE clause for the main table. That is normal fields will only
return their type while relations will create it's link table.

=head2 $fld->fmt($kind)

Returns the "fmt_$kind" param as passed to the constructor (se new
method for info). If that one does not excist the default one "fmt" is
used. If thatone isn't specified either the default fmt '$val' is
returned.

To allow subclasses to provide more decent defaults the
default_fmt($kind) method is called if "fmt_$kind" is not defined.
If it returns undef this method carries on as described above, 
otherwise the return value of default_fmt is returned. Then default_fmt
is called again if there was no "fmt" param speciefied, but this 
time with $kind undefined.

The default implementation here is ofcourse to always return undef, that 
will give the behaviour described in the first paragraph here.

A replacment default_fmt should never return undef but instead execute
it's supreclass version of it and return it's value if it dosn't want to
override the specified kind.

=cut

sub fmt {
  my ($self,$kind)=@_;

  if ($self->got_data("fmt_$kind")) {return $self->data("fmt_$kind");}
  
  my $d=$self->default_fmt($kind);
  if (defined $d) {return $d}
  
  if ($self->got_data("fmt")) {return $self->data("fmt");}

  $d=$self->default_fmt(undef);
  if (defined $d) {return $d}

  return '<var val>';
}

=head2 $fld->default_fmt($kind)

Used to allow subclasses to provide there own default fmts, se 
$fld->fmt($kind).

=cut

sub default_fmt {return undef;}

=head2 $fld->view_text
=head2 $fld->view_html
=head2 $fld->edit_text

For backwards compatibility those are linked to view_fmt('view_text'),
view_fmt('view_html'), view_fmt('edit:html'), respectivly.

A replacment default_fmt should never return undef but instead execute
it's supreclass version of it and return it's value if it dosn't want to
override the specified kind.

=cut

sub view_text {shift->view_fmt('view_text');}
sub view_html {shift->view_fmt('view_html');}
sub edit_html {shift->view_fmt('edit_html');}

sub view_fmt_code {
  my ($self, $fmt_name, $fmt)=@_;
  if (defined $fmt) {
   $fmt=~s/\'/\\\'/g; $fmt="'".$fmt."'";   
 } else {
   $fmt="undef";
 }
  return '$self->view_fmt('."'$fmt_name',$fmt)\;";
}

sub sql_join {return undef;}

sub delete_code{return '';}

sub sql_data_array {shift->sql_data(@_)}

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
