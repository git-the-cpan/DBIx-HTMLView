#!/usr/bin/perl

#  Selection.pm - A kriteria used to select posts
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

  DBIx::HTMLView::Selection - A kriteria used to select posts

=cut

package DBIx::HTMLView::Selection;
use strict;
use Carp;

=head1 SYNOPSIS

  $sel=DBIx::HTMLView::Selection->new($table, $search_string);
  print $sel->sql_select

=head1 DESCRIPTION

This class is used to parse search query strings and generate SQL
select queries out of them. You usually don't use this class itself,
but simply pass the strings to methods like list in
DBIx::HTMLView::Table, which then uses this class to parse them.

The format of the search strings looks very much like the SQL select
querys, but with some modifications. All fields are supposed to belong
to the table $tab passed to the constructor and fields in related
posts are accessed using the string <relation_name>-><field_name> (eg
group->name). It's even possible (not yet implemeted though) to access
fields through several relations (eg rel1->rel2->field).

Here is a more precise definition of the language useed:

  <expr>       = <bool_value> (("AND" | "OR") <bool_value>)?
  <bool_value> = <fld_spec> <opperator> <value> | "(" <expr> ")"
  <fld_spec>   = <fld_name> ("->" <fld_name>)*
  <fld_name>   = <word>
  <value>      = <literal>|<fld_spec>
  <literal>    = \d+ | "'" <string> "'" 
  <string>     = [^']*
  <word>       = [a-zA-Z0-9_.]+
  <operator>   = "<" | ">" | "=" | "<=" | ">=" | "<>" | "LIKE" | ...

=head1 METHODS
=cut

# FIXME: Multilevel relations searching (rel->rel->fld), update docs

=head2 $sel=DBIx::HTMLView::Selection->new($table, $str, $flds, $opps); 

Creats a new selection for posts in the table $table (a
DBIx::HTMLView::Table object) selecting posts matching the search
string $str (in the format described above).

$flds is for optimisations. If it is definied it is supposed to be a
reference to an array with the names of the extra fields to select
from the database server. All fields used in the $str query will
ofcourse also be selected. If this parameter is not defined, all
fields of the table will be selected.

$opps is an array ref listing all the opperations your SQL server
supports and you wish to be able to use in your search query. Deault
is: ['<=', '>=', '<>', '<', '>', '=', 'LIKE', 'RLIKE', 'CLIKE',
'SLIKE']. Note that the opperator <= must be placed before the 
opperators < and = otherwise <= in a serach string will be 
interpreted as the two opperators < and = next to eachother and
generate a syntax error.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self=  bless {}, $class;
  
  my ($tab, $str, $flds, $opps, $order) =@_;
  if (defined $opps) {
    $self->{'opps'}=$opps;
  } else {
    $self->{'opps'}=['<=', '>=', '<>', '<', '>', '=', 'LIKE', 'RLIKE', 
                     'CLIKE'];
  }
  croak("Bad table: $tab") if (!$tab->isa('DBIx::HTMLView::Table'));
  $self->{'tab'}=$tab;
  $self->{'str'}=$str if (defined $str);
  $self->{'where'}="";
  $self->{'join'}="";
  $self->{'flds'}={};
  $self->{'tabs'}={};

  #$self->add_tab($self->tab->name ." as Search_".$self->tab->name);
  $self->add_tab($self->tab->name);
  if (defined $flds) {
    $self->add_fld($self->tab->name . "." . $self->tab->id->name);
    foreach (@$flds) {
      my $fname=$self->tab->fld($_)->field_name;
      if (defined $fname) {
				$self->add_fld($self->tab->name . "." . $fname);
      }
    }
  } else {
    foreach ($self->tab->flds) {
			my $fname=$_->field_name;
      if (defined $fname) {
				$self->add_fld($self->tab->name . "." . $fname);
      }
    }
  }

	if (defined $str) {
		$self->next_token;
		$self->expr;
	}

	# Parse order request
	if (defined $order) {
		foreach (split(/\s*,\s*/,$order)) {
			my $dir="";
			if (/^([^\s]+)\s+(.*)$/) {$_=$1; $dir=$2}
			$self->{'str'}=$_;
			$self->next_token;
			$self->{'order'}.=$self->fld_spec('ORDER'). " $dir, ";
		}		
		$self->{'order'} =~ s/, $//;
	}


  $self;
}

=head2 $sel->sql_select

Returns a SQL select query mathing the posts described in the search
query passed to the constructor.

=cut

sub sql_select {
  my ($self,$extra_select, $extra_from, $extra_where)=@_;
  my $tab=$self->tab->name;
  my $flds="";

  # Place the fields from this tbale first so that the post objects
  # created later wont get fields from the related tabels in case those
  # tabels have fields with the same name
  foreach (keys %{$self->{'flds'}}) {
    if (/^$tab\./) {
      $flds = $_ . ", " . $flds;
    } else {
      $flds .= $_ . ", ";
    }
  }
  $flds =~ s/, $//;
  $flds .= ", $extra_select" if (defined $extra_select);
  @{$self->{'fld_order'}}=split(/, /, $flds);


  my $res="select $flds from " . 
          join(', ', keys %{$self->{'tabs'}});
  $res.=", $extra_from" if (defined $extra_from);
  $res.= " " .$self->{'join'};
  if (defined $self->{'where'} && $self->{'where'} ne '') {
    $self->{'where'} =~ s/^\s*and//i;
    $res.= " where " . $self->{'where'};
    $res.="AND ($extra_where)" if (defined $extra_where);
  } else {
    $res.=" where $extra_where" if (defined $extra_where);
  }

  $res.= " group by " . $tab . "." . $self->tab->id->name;
  if (defined $self->{'order'}) {
    $res.=" order by " . $self->{'order'}
  }
  return $res;  
}

sub field_pos {
  my ($self, $fldname) =@_;
  my $i=0;
  if (defined $self->{'fld_order'}) {
    foreach (@{$self->{'fld_order'}}) {
      if ($_ eq $fldname) {
        return $i;
      }
      $i++;
    }
    confess ("Field $fldname not selected.");
  } else {
    confess ("You must call sql_select or sql_cout before fld_order");
  }
}

=head2 $sel->sql_count

Returns a SQL select query counting the posts described in the search
query passed to the constructor.

=cut

sub sql_count {
  my $self=shift;
  my $tab=$self->tab->name;
  my $flds="";

  # Place the fields from this tbale first so that the post objects
  # created later wont get fields from the related tabels in case those
  # tabels have fields with the same name
  foreach (keys %{$self->{'flds'}}) {
    if (/^$tab\./) {
      $flds = $_ . ", " . $flds;
    } else {
      $flds .= $_ . ", ";
    }
  }
  $flds =~ s/, $//;
  $self->{'fld_order'}=split(/, /, $flds);

  return "select count(*) from " . 
               join(', ', keys %{$self->{'tabs'}}) . " where " . 
              $self->{'where'};
}

=head2 $sel->tab

Returns the table we're selecting posts from (a DBIx::HTMLView::Table
object).

=cut

sub tab {shift->{'tab'}}

=head2 $sel->add_to_where($str)

Add $str to the end of the string that will be the where clause of the
slect query.

=cut

sub add_to_where {shift->{'where'} .= shift(@_) . " ";}

=head2 $sel->add_to_join($str)

Add $str to the end of the string that will be the join clause of the
slect query.

=cut

sub add_to_join {shift->{'join'} .= shift(@_) . " ";}

=head2 $sel->add_fld($field_name)

Adds the field named $field_name to the list of fields selected.

=cut

sub add_fld  {
  my ($self, $fld)=@_;
  #if ($fld eq 'SubTab.') {confess ('Mjäk!');}
  $self->{'flds'}{$fld}=1;
}

=head2 $sel->add_tab($table_name)

Adds the table named $table_name to the list of tabels selected from.

=cut

sub add_tab  {shift->{'tabs'}{shift(@_)}=1;}

=head2 $sel->opps

Returns an array of comparation opperation recognised as specified by
the $opps parameter to the constructor.

=cut

sub opps {
  @{shift->{'opps'}};
}

=head2 $sel->token

Returns the current token.

=head2 $sel->token($kind)

Returns true if the current token is of the kind $kind.

=head2 $sel->token($kind,$val)

Set $val as the curent token, and $kind as the kind of that token.

=cut

sub token {
  my ($self, $kind, $val)=@_;
  if (defined $val) {
    $self->{'token_kind'}=$kind;
    $self->{'token_val'}=$val;
  } elsif (defined $kind) {
    return ($kind eq $self->{'token_kind'});
  } else {
    return $self->{'token_val'};
  }
}

=head2 $sel->next_token

Get's the next token from the string, determins it's type and makes it
the current token using $self->token.

=cut

sub next_token {
  my $self=shift;

  # <operator>
  $self->{'str'} =~ s/^\s+//;
  foreach ($self->opps) {
    if ($self->{'str'} =~ s/^$_//) {
      $self->token("opp",$_);
      return;
    }
  }

  # "->"
  if ($self->{'str'} =~ s/^->//) {
    $self->token("fld_separator", "->");
    return;
  }

  # (, )
  if ($self->{'str'} =~ s/^(\()// ||
      $self->{'str'} =~ s/^(\))//
     ) {
    $self->token("par", $1);
    return;
  }

  # "'" <string> "'"
  if ($self->{'str'} =~ s/^(\'.*?[^\\]\')// || 
      $self->{'str'} =~ s/^(\'\')//
     ) {
    $self->token("string", $1);
    return;
  }

  # \d+
  if ($self->{'str'} =~ s/^(-?\d*\.?\d+|\?)//) {
    $self->token("number", $1);
    return;
  }

  # <fld_name>, "AND" | "OR", 
  if ($self->{'str'} =~ s/^([a-zåäöÅÄÖA-Z0-9_\.]+)//) {
    $self->token("word", $1);
    return;
  }

  # end of string
  if ($self->{'str'} eq "") {
    $self->token("end", "");
    return;
  }

  confess("Bad string: " . $self->{'str'});
}

=head2 $sel->expr
=head2 $sel->bool_value
=head2 $sel->fld_spec
=head2 $sel->value

All those reads and parsers a specifik sub expretions as defined in
the description.

=cut

sub expr {
  my $self=shift;

  $self->bool_value;
  while (!$self->token("end") && !$self->token('par')) {
    if ($self->token("word") && ($self->token =~ /^and$/i || 
                                 $self->token =~ /^or$/i )) {

      $self->add_to_where(uc($self->token));
      $self->next_token;
      $self->bool_value;
    } else {
      confess ("Syntax error at: " . $self->{'str'});
    }
  }
}

sub bool_value {
  my $self=shift;

  # "(" <expr> ")"
  if ($self->token("par") && $self->token eq '(') {
    $self->add_to_where('(');
    $self->next_token;
    $self->expr;
    if ($self->token("par") && $self->token eq ')') {
      $self->add_to_where(')');
      $self->next_token;
    } else {
      confess ("Syntax error at: " . $self->{'str'});
    }
  } 
  
  # <fld_spec> <opperator> <value> 
  elsif ($self->token("word")) {
    $self->fld_spec;
    if ($self->token("opp")) {
      $self->add_to_where($self->token);
      #print "opp: " . $self->token . "\n";
      $self->next_token;
    } else {
      confess ("Syntax error at: " . $self->{'str'});
    }
    $self->value
  }
}

sub fld_spec {
  my ($self,$mode)=@_;

  if ($self->token("word")) {
    my $base=$self->token;
    my @sub;
    $self->next_token;
    while ($self->token("fld_separator")) {
      $self->next_token;
      if ($self->token("word")) {
        push @sub, $self->token;
      } else {
        confess ("Syntax error at: " . $self->{'str'});
      }
      $self->next_token;
    }
    #print "Fld: $base -> @sub<br>\n";
		if ($mode eq 'ORDER') {
			my $a=$self->tab->fld($base)->sql_data_array($self, \@sub);
			if (ref $a) {
				$self->add_to_where("(" . $a->[0] .  ")");
				$a=$a->[1];
			}
			return $a;
		} else {
			$self->add_to_where("(". $self->tab->fld($base)->sql_data($self, \@sub));
		}
  } else {
    confess ("Syntax error at: " . $self->{'str'});
  }
}

sub value {
  my $self=shift;

  # <literal>
  if ($self->token("string") || $self->token("number")) {
    $self->add_to_where($self->token . ")");
    #print "Value: " . $self->token . "\n";
    $self->next_token;
  }

  # <fld_spec>
  elsif ($self->token("word")) {
    $self->fld_spec;
  }
  else {
    confess ("Syntax error at: " . $self->{'str'});
  }
}

sub view_tab {
  my ($self, $tab, $view_name)=@_;
  if (defined $view_name) {
    $self->{'view_tab'}{$tab}=$view_name;
    return $view_name;
  } else {
    if (defined $self->{'view_tab'}{$tab}) {
      return $self->{'view_tab'}{$tab};
    } else {
      return $tab;
    }
  }
}

sub view_fld {
  my ($self, $fld)=@_;
  if ($fld =~ /^([^\.]+)(\.[^\.]+)$/) {
    return $self->view_tab($1).$2;
  } else {
    return $fld;
  }
}

=head2 get_str
  
  Return $str;

=cut
 
sub get_str {
  shift->{'str'};
}


1;

# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
