#!/usr/bin/perl

#  Fmt.pm - Basic parser for fmt strings and files
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

  DBIx::HTMLView::Fld - Basic parser for fmt strings and files

=head1 SYNOPSIS
=head1 DESCRIPTION

ANY: VAR | FLD | FMT | PERL | TXT | SELECT
VAR: "<VAR " ... ">"
FLD: "<FLD " ... ">"
FMT: "<FMT " ... ">" ANY "</FTM>"
PERL: "<PERL " ... ">" ... "</PERL>"
SELECT: "<SQL_SELECT " ... ">" (... | SELECT) "</SQL_SELECT>"
DEFAULT: "<DEFAULT " OPTIONS ">"
OPTIONS: OPT (\s+ OPT)*
OPT: VALUE \s* "=" \s* VALUE
VALUE: (LVAL | FVAL | FFVAL)
LVAL: [^\s\>\=]+
FVAL: \' [^\']+ \'
FFVAL: \" [^\"]+ \"
SQL_VAL: "<SQL_VAL" OPTIONS ">"
TXT: Anything else

=cut

package DBIx::HTMLView::Fmt;
use strict;

my $tags = {'var'=>'var',
            'fld'=>'fld',
            'fmt'=>'fmtstart',
            '/fmt'=>'fmtend',
            'perl'=>'perlstart',
            '/perl'=>'perlend',
	    'sql_select'=>'selectstart',
	    '/sql_select'=>'selectend',
	    'default'=>'default',
	    'sql_val'=>'sql_val',
           };

use Carp;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self=  bless {}, $class;

  $self;
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


sub parse_fmt {
  my ($me, $self, $fmt_name, $fmt)=@_;  # NOTE: this object is named $me, 
                                        # not $self as the evals needs $self
                                        # to be something else.

  my $res="";
  my $r;

  $me->{'fmt'}=$fmt;

  $me->next_token;
  while (! $me->token('end')) {
    $r=$me->any;
  #  print $r->[0] . ": " . $r->[1] . "\n";
    if ($r->[0] eq 'txt') {$res.=$r->[1];}
    if ($r->[0] eq 'perl') {$res.=eval('package fmt_code;no strict "vars"; '.$r->[1]);warn $@ if $@;}
    if ($r->[0] eq 'var') {$res.=$self->var($r->[1])}
    if ($r->[0] eq 'fld') {$res.=$self->fld($r->[1])->view_fmt($fmt_name, 
                                                               $r->[2]);}
  }
  return $res;
}

# NOTE: the code returned by this object presumes $self points to the 
#       post/fld being displayed

sub parse_fmt_to_code {
  my ($me, $post, $fmt_name, $fmt)=@_;  
  my $res='';
  $res.='my $res="";'."\n";
  my ($r,$t);

  $me->{'fmt'}=$fmt;

  $me->next_token;
  while (! $me->token('end')) {
    $r=$me->any;
    $t=$r->[1]; $t=~s/\'/\\\'/g; $t="'".$t."'"; 
    
    if ($r->[0] eq 'txt') {$res.='$res.='.$t.";\n";}
    if ($r->[0] eq 'perl') {$res.='$res.=eval{'."\n".$r->[1]."\n".'};warn $@ if $@;'."\n";}
    if ($r->[0] eq 'var') {$res.='$res.=$self->var('.$t.');'."\n"}
    if ($r->[0] eq 'fld') {
      $res.='{my $self=$self->fld('.$t.');'."\n";
      $res.='$res.=eval{package fmt_code; no strict "vars"; '."\n".$post->fld($r->[1])->view_fmt_code($fmt_name, $r->[2],1)."\n".'};warn $@ if $@;'."\n";
      $res.='}'."\n";
    }
  }
  $res.='return $res;'."\n";
  return $res;
}

sub ins_fld {
  my ($self, $fld, $sel)=@_;
  my $fn=$fld->field_name;
  if (defined $fn) {
    my $n=$sel->view_tab($fld->tab->name) .'.'.$fn;
    $sel->add_fld($n);
    return '<Value '.$n.'>';
  } else {
    warn "Don't know how to view " . $self->name;
  }
}

sub db {
  my ($self)=@_;
  die "No table defined!" if (!defined $self->{'tab'});
  $self->{'tab'}->db;
}

sub sel {
  my ($self)=@_;
  if (!defined $self->{'select'}) {
    $self->{'select'}=DBIx::HTMLView::Selection->new($self->tab,undef,[]);
  }
  return $self->{'select'};
}

sub tab {shift->{'tab'}}

sub compiled_fmt {
  my ($me, $self, $fmt_name, $fmt, $selobj, $opt)=@_;  # NOTE: this object is named $me, 
                                        # not $self as the evals needs $self
                                        # to be something else.
  my $res="";
  my $r;
  my $default_select_overrided=0;

  $me->{'fmt'}=$fmt;
  $me->{'tab'}=$self->tab;
  $me->{'options'}={};
  $me->{'options'}=$opt if (defined $opt);
  $me->{'fmt_name'}=$fmt_name;

  if (defined $selobj) {$default_select_overrided=1;}
  elsif (defined $opt->{'select'}) {
    $selobj=DBIx::HTMLView::Selection->new($me->tab,$opt->{'select'},[]);
    $default_select_overrided=1;
  }
  $me->{'select'}=$selobj;

  $me->next_token;
  while (! $me->token('end')) {
    $r=$me->any;
    if ($r->[0] eq 'txt') {
      $r->[1]=~s/\'/\\\'/g; 
      $res.=".'".$r->[1]."'"; 
    }
    if ($r->[0] eq 'perl') {
      if (defined $me->sel) {
	$r->[1] =~ s/\$self->val/$me->ins_fld($self, $me->sel)/ge;
	$r->[1] =~ s/<fld ([^>]+)>/$me->ins_fld($self->fld($1), $me->sel)/gei;
	$r->[1] =~ s/<var ([^>]+)>/$me->get_var($self, $me->sel, $1)/gei;
      }
      $res.='. eval {package fmt_code; no strict "vars"; '.$r->[1].'}; warn $@ if $@; $res=$res';
    }
    if ($r->[0] eq 'var') {
      my $t=$me->get_var($self, $me->sel, lc($r->[1]));
      if (defined $t) {
	$res.=".".$t;
      }
    }
    if ($r->[0] eq 'fld') {
      #my $w=$self->fld($r->[1])->sql_join($me->sel);
      #if (defined $w) {$me->sel->add_to_where($w);}
      my %fld_opt=%{$me->{'options'}};
      my $tag_opt=$me->{'fmt_options'};
      if (defined $tag_opt) {
	foreach (keys %$tag_opt) {
	  $fld_opt{$_}=$tag_opt->{$_};
	}
      }
      my $this_fmt_name=$fmt_name;
      $this_fmt_name=$fld_opt{'name'};
      
      my $fmt_str=$r->[2];
      if (defined $fld_opt{'file'}) {
	my $fn=undef;
	if (-f $fld_opt{'file'}) {$fn=$fld_opt{'file'};}
	elsif (-f $fld_opt{'file'}.'.fmt') {$fn=$fld_opt{'file'}.'.fmt';}
	if (defined $fn) {
	  $fmt_str="";
	  open(F, "<$fn") || warn "Unable to open $fn";
	  while (<F>) {$fmt_str.=$_;}
	  close(F);
	  $fld_opt{fmt}=$r->[2];
	} else {
	  warn "File not found: ",$fld_opt{'file'},"\n";
	}
      }
      delete $fld_opt{'file'};

      my $sub_fld;
      if (defined $r->[1] && $r->[1] !~ /^\s*$/) {
	$sub_fld=$self->fld($r->[1]);
      } else {
	$sub_fld=$self;
      }
      if ($sub_fld->isa('DBIx::HTMLView::PostSet')) {
	my $f=DBIx::HTMLView::Fmt->new;
	$res.=$f->compiled_fmt($self, $this_fmt_name, $fmt_str, $me->{'select'}, \%fld_opt);
	# Bring up top level defaults (except table which must be set)
	foreach ('select', 'extra_select', 'extra_from', 'extra_where', 'extra_sql') {
	  if (!defined $me->{'options'}{$_}) {
	    $me->{'options'}{$_}=$fld_opt{$_};
	    if ($_ eq 'select' && defined $fld_opt{$_} && !defined $me->{'select'}) {
	      $me->{'select'}=DBIx::HTMLView::Selection->new($me->tab,$fld_opt{$_},[]);
	    }
	  }
	}
      } else {
	$res.=$sub_fld->compiled_fmt($this_fmt_name, 
				     $fmt_str,$me->sel,\%fld_opt);
      }
    }
    if ($r->[0] eq 'select') {
      $res.= $r->[1];
    }
    if ($r->[0] eq 'sql_val') {
      $me->sel->add_fld($r->[1]);
      $res.=".<Value " . $r->[1] . ">";
    }
    if ($r->[0] eq 'default') {
      foreach (keys %{$r->[1]}) {
	if (! defined $me->{'options'}{lc($_)}) {
	  $me->{'options'}{lc($_)}=$r->[1]{$_};
	  if (lc($_) eq 'select') {
	    if (! defined $me->{'select'}) {
	      $me->{'select'}=DBIx::HTMLView::Selection->new($me->tab,$r->[1]{$_},[]);
	    } elsif (!$default_select_overrided) {
	      warn "Ignored <default select=...> as it did not appear before all other",
	           " special tags. Please place it at top of file\n";
	    }
	  } 
	}
      }
    }
  }
  return $res;
}

sub get_var {
  my ($me, $self, $sel, $var)=@_;
  $var=lc($var);
  
  if ($var eq 'val') {
    return $me->ins_fld($self, $sel);
  } elsif (defined $me->{'options'}{$var}) {
    my $t=$me->{'options'}{$var};
    #$t=~s/\'/\\\'/g;
    #return "'$t'";
    my $f=DBIx::HTMLView::Fmt->new;
    my $r=$f->compiled_fmt($self, $me->{'fmt_name'}, $t, $sel, $me->{'options'});
    $r=~s/^\s*\.//;
    return $r;
  } else {
    warn "Unknown var " . $var ." ignored";
    return undef;
  }
  return undef;
}

sub next_token {
  my $self=shift;

  if ($self->{'fmt'} eq "") {$self->token('end', ''); return;}

  foreach (keys %$tags) {
    if ($self->{'fmt'} =~ s/^(<$_\s*)//i) {      
      $self->{'text_token'}="$1";
      $self->token($tags->{$_}, $self->get_options); 
      return;
    }
  }
  if ($self->{'fmt'} =~ s/^(<?[^<]*)//i) {
    $self->{'text_token'}=$1;
    $self->token('txt', $self->{'text_token'});
    return;
  }
  confess "Spooky string: " . $self->{'fmt'};
}

sub any {
  my $self=shift;
  if ($self->token('var')) {
    my $t=$self->token;
    $self->next_token;
    return ['var', $t];
  }
  if ($self->token('fld')) {
    $self->{'fmt_options'}=$self->options;
    my $t=$self->token;
    $self->next_token;
    return ['fld', $t];
  }
  if ($self->token('fmtstart')) {
    my $t=$self->token;
    return ['fld', $t, $self->fmt];
  }
  if ($self->token('perlstart')) {return ['perl', $self->perl];}
  if ($self->token('txt')) {return ['txt', $self->txt];}
  if ($self->token('selectstart')) {return ['select', $self->sql_select]}
  if ($self->token('default')) {return ['default', $self->default];}
  if ($self->token('sql_val')) {return ['sql_val', $self->sql_val];}
  confess "Bad token: " . $self->token;
}

sub default {
  my ($self)=@_;
  my $o=$self->options;
  $self->next_token;
  return $o;
}

sub sql_val {
  my ($self)=@_;
  my $t=$self->token;
  $self->next_token;
  return $t;
}

sub options {shift->{'tag_options'}}

sub get_options {
  my ($self)=@_;
  my $opt={};
  my ($name, $value);
  my $nonopt="";

  while (1) {
    # Check if we reached end of tag
    if ($self->{'fmt'} =~ s/^(\s*>)//) {
      $self->{'text_token'}.=$1;
      $self->{'tag_options'}=$opt; 
      return $nonopt;
    }
    $self->{'fmt'} =~ s/^(\s*)//;
    $self->{'text_token'}.=$1;
    
    # Get variable name
    $name=$self->get_value;
    if ($self->{'fmt'} =~ s/^(\s+)//) {
      $self->{'text_token'}.=$1;
    }
    
    # Get name/value separator
    # If it is not there we have found the non options vlaue
    if ($self->{'fmt'} !~ s/^(=\s*)//) {
      $nonopt=$name;
      next;
    } else {
      $self->{'text_token'}.=$1;
    }
    
    $value=$self->get_value;
    
    $opt->{$name}=$value;
  }
}

sub get_value {
  my ($self)=@_;
  my $value;

  # Get value
  if ($self->{'fmt'} =~ s/^\"([^\"]+)\"//) {
    $value=$1;
    $self->{'text_token'}.='"'.$1.'"';
  }
  elsif ($self->{'fmt'} =~ s/^\'([^\']+)\'//) {
    $value=$1;
    $self->{'text_token'}.="'".$1."'";
  }
  elsif ($self->{'fmt'} =~ s/^([^\s\>\<\=]+)//) {
    $value=$1;
    $self->{'text_token'}.=$1;
  }
  else {confess "Parse error at: " . $self->{'fmt'}}
  return $value;
}

sub sql_select {
  my ($self)=@_;
  my $op=$self->options;
  my $res='';
  
  # Get table name
  my $tab=$op->{'from'};
  if (!defined $tab) {$tab=$op->{'table'}}
  if (!defined $tab) {$tab=$op->{'tab'}}

  # Get where clause
  my $sel=$op->{'where'};
  if (!defined $sel) {$sel=$op->{'sel'}}

  # Get the exec list 
  my $exec_list="";
  if (defined $op->{'param'}) {$exec_list='('.$op->{'param'}.')';}

  # Get fmt
  my $cnt=1;
  my $fmt='';
  while ($cnt>0) {
    $self->next_token;
    $cnt++ if ($self->token('selectstart'));
    $cnt-- if ($self->token('selectend'));
    if ($self->token('end')) {confess "Unexpected end of string in fmt"}
    $fmt.=$self->{'text_token'} if ($cnt>0);
  }
  $self->next_token;

  my $sel=DBIx::HTMLView::Selection->new($self->db->tab($tab),$sel,[]);
  my $nps=DBIx::HTMLView::PostSet->new($self->db->tab($tab));
  my $fmt=$nps->compiled_fmt('view_html', $fmt, $sel, $self->{'options'});
  my $sql=$sel->sql_select . " " . $op->{'extra_sql'};
  $sql=~s/\'/\\\'/g;
  $fmt=~s/<Value ([^>]+)>/'$row->['.$sel->field_pos($sel->view_fld($1)).']'/ge;

    return '; {
my $sth=$dbi->prepare(\''.$sql.'\');
if (!defined $sth) {die $sth->errstr}
{
  package fmt_code;
  my $hits=$sth->execute'.$exec_list.';
}

my $row=$sth->fetchrow_arrayref;

'.$fmt.'

} $res=$res';

}

# Escapes "'s

sub fmt {
  my $self=shift;
  my $str="";
  my $d=1;

  $self->{'fmt_options'}=$self->options;
  while ($d>0) {
    $self->next_token;
    if ($self->token('fmtstart')) {$d++}
    if ($self->token('fmtend')) {$d--}
    if ($self->token('end')) {confess "Unexpected end of string in fmt"}
    if ($d>0) {$str.=$self->{'text_token'}}
  }
  $self->next_token;
  return $str;
}

sub perl  {
  my $self=shift;
  my $str="";

  $self->next_token;
  while (! $self->token('perlend')) {
    $str.=$self->{'text_token'};
    $self->next_token;
    if ($self->token('end')) {confess "Unexpected end of string in perl"}
  }
  $self->next_token;
  return $str;
}

sub txt {
  my $self=shift;
  my $str="";

  while ($self->token('txt')) {
    $str.=$self->token;
    $self->next_token;
  }
  return $str;
}

package fmt_code;
sub js_escape {
    my $str = shift;
    $str =~ s/"/&quot;/g;
    return $str;
}


1;



# Local Variables:
# mode:              perl
# tab-width:         8
# perl-indent-level: 2
# End:
