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

ANY: VAR | FLD | FMT | PERL | TXT
VAR: "<VAR " ... ">"
FLD: "<FLD " ... ">"
FMT: "<FMT " ... ">" ANY "</FTM>"
PERL: "<PERL " ... ">" ... "</PERL>"
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
           };

use Carp;

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self=	bless {}, $class;

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
                                        # not $slef as the evals needs $self
                                        # to be something else.
	my ($val1, $val2, $val3, $val4, $val5); #FIXME: those vars to be used in the fmt evals, should not have to be defined here like this

  my $res="";
  my $r;

  $me->{'fmt'}=$fmt;

  $me->next_token;
  while (! $me->token('end')) {
    $r=$me->any;
  #  print $r->[0] . ": " . $r->[1] . "\n";
    if ($r->[0] eq 'txt') {$res.=$r->[1];}
    if ($r->[0] eq 'perl') {$res.=eval($r->[1]);}
    if ($r->[0] eq 'var') {$res.=$self->var($r->[1])}
    if ($r->[0] eq 'fld') {$res.=$self->fld($r->[1])->view_fmt($fmt_name, 
                                                               $r->[2]);}
  }
  return $res;
}

sub next_token {
  my $self=shift;

  if ($self->{'fmt'} eq "") {$self->token('end', ''); return;}

  foreach (keys %$tags) {
    if ($self->{'fmt'} =~ s/^(<$_\s*)([^>]*)>//i) {
      $self->token($tags->{$_}, $2); 
      $self->{'text_token'}="$1$2>";
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
  confess "Bad token: " . $self->token;
}

# Escapes "'s
sub js_escape {
    my $str = shift;
    $str =~ s/"/&quot;/g;
    return $str;
}

sub fmt {
  my $self=shift;
  my $str="";
  my $d=1;

  while ($d>0) {
    $self->next_token;
    if ($self->token('fmtstart')) {$d++}
    if ($self->token('fmtend')) {$d--}
    if ($self->token('end')) {confess "Unexpekted end of string in fmt"}
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
    if ($self->token('end')) {confess "Unexpekted end of string in perl"}
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
1;
