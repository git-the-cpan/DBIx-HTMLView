#!/usr/bin/perl

#  CGIListView.pm - A List user interface for DBI databases
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

  DBIx::HTMLView::CGIListView - A List user interface for DBI databases

=head1 SYNOPSIS

  $view=new DBIx::HTMLView::CGIReqEdit($script, $dbi, $cgi);
  print $view->view_html;

=head1 DESCRIPTION

This is a database viewer/editer using the CGI interface and HTML
forms to present the user interface to the user. It's a very simple
interface. At the top all the tables of the database are listed to
allow the user to select which one to edit (including a + sign for
adding a new post, and at the bottom the selected table is listed. 
If the table has more than defined in {'rows'}, output is split into pages.
Every post has a link to allow you to show, edit or delete them. 
There is also a link to add new posts to the table. 

To be able to use this you need a cgi script that sets up a few things
and decides which editor to use to edit single posts and to insert
default values and so on... For a simple such script see View.cgi.

This is a subclass to DBIx::HTMLView::CGIView. 
=head1 METHODS
=cut

package DBIx::HTMLView::CGIListView;
use strict;

use vars qw(@ISA);
require DBIx::HTMLView::CGIView;
@ISA = qw(DBIx::HTMLView::CGIView);

sub new {
  my $self=DBIx::HTMLView::CGIView::new(@_);

  $self->{'view_flds'}=undef;
  $self->{'extra_sql'}=undef;
  $self->{'page'}=1;
  $self->{'rows'}=$self->tab->opt('rows');

	my $ftv=$self->tab->opt('flds_to_view');
  if (defined $ftv) {
		$self->flds_to_view(@$ftv);
	}

  $self;
}

=head2 $view->rows($nr)

Specifies how many rows should be displayed on one page. Default is 50.

=cut

sub rows {
  my ($self, $rows)=@_;
  $self->{'rows'}=$rows;
}

=head2 $view->flds_to_view(@flds)

Specifies which flds to view by listing there names. Default is to view
all fields of a post but none of the relations.

=cut

sub flds_to_view {
  my $self=shift;
  my @flds=@_;
  $self->{'view_flds'}=\@flds;
}

sub get_flds_to_view {
  my $self=shift;
  my @names;
  my $a=0;
  $a=1 if defined $self->{'view_flds'};
  if ($a==1){  
  foreach (@{$self->{'view_flds'}}) {push @names, $_;}
  }
  @names;
}

=head2 $view->extra_sql($extra)

If you want to add some extra SQL clauses to the end of the select
command they can be given here. This can be used to specify in which
order the posts should appear by giving an ORDER clause.

=cut

sub extra_sql {
  my $self=shift;
  $self->{'extra_sql'}=shift;
}
#move to SUPERCLASS?
=head2 $view->restrict_tabs($tabs_to_show)

If you don't want all tabels to show up at the top of the editor you
can here specify which you want there by letting $tabs_to_show be an
array ref to an array liste the names of those tables.

Note that this is not a secure way to prevent users from getting
access to the tables as some simple tampering with the html forms
passed to the user will bring up the other tables as well for editing.

=cut

sub restrict_tabs {
  my $self=shift;
  $self->{'restrict_tabs'}=shift;
  if (!defined $self->cgi->param('_Table')) {
    $self->cgi->param('_Table',  $self->{'restrict_tabs'}[0]);
  }
}

=head2 $view->view_html

Returns the html code for the editor as specified by previous methods.

=cut

sub view_html {
  my ($self)=@_;
  my $q=$self->cgi;
  my $script=$self->script_name;
  my $tab=$self->tab->name;
	my $cmd=$q->param('_Command');
	if (!defined $cmd) {$cmd=""}
	my $res="";
	my @culomns;

	if (!defined $self->cgi->param('_SubEditFld')) {
		my @rowsoptions=(5,10,25,50,100,250,500,1000,2500,5000);
		my $i=0;
		$res .=  << "EOF";
<h1>Current table: $tab</h1>

<b>Change table</b>: 
EOF

	  #$res .= "<form method=POST action=\"$script\">";
    #my $data = $self->form_data;
    #$data =~ s/<input type=hidden name="_Table" value="[^\"]+">//;
    #$res.=$data;

	  if (defined $self->{'restrict_tabs'}) {
			foreach (@{$self->{'restrict_tabs'}}) {
				#$res .= '<input type=submit name=_Table value="' . $_ . '">';
				$res .= "<a href=\"$script?_Table=$_&"
					.'">'.$_. '</a> ';
				$res .= '<a href="'.$script.'?_Table='.$_.
					'&_Action=add&'.'">+</a>, ';
			}
		} else {
			foreach ($self->db->tabs) {
				#$res .= '<input type=submit name=_Table value="' . $_->name . '">';
				$res .= "<a href=\"$script?_Table=".$_->name."&"
					.'">'.$_->name. '</a> ';
				$res .= '<a href="'.$script.'?_Table='.$_->name.
					'&_Action=add&'.'">+</a>, ';
			}
		}
		$res .= '<p>';

		my $abspath=$q->url();
		my $relpath=$q->url(-relative=>1);
		my $path;
		($path=$abspath)=~s/$relpath$//;
		foreach ($self->db->tabs){
			$_->initiate_js_onSubmit($path);
		}

		if($q->param('_Maxrows')!=0) { # update number of lines per page
			$self->{'rows'}=$q->param('_Maxrows');
		}

		$res.='<hr>';

	my $hits;
	my $lst=undef;
	my $first=0;

	my $order=$q->param('_Order');
  $order.=" DESC" if defined $order;
	if (!$order) {
		$order.=$q->param('_Orderby').','.
			$q->param('_Thenby1').','.$q->param('_Thenby2');
	}

	$self->{'page'}=$q->param('_Page')||1;

		my @all_culomns=$self->db->tab($tab)->fld_names();
		if ($self->get_flds_to_view) {
			@all_culomns=$self->get_flds_to_view;
		}
		my $i=0;
		foreach (@all_culomns) { #find real columns and not relations N2N
			if (!($self->db->tab($tab)->fld($_)->field_name() cmp 
						$self->db->tab($tab)->fld($_)->name())) {
				$culomns[$i]=$_;
				$i++;
			}
		}

	
	my $act=$q->param('_Action');
	if (defined $act && $act eq 'search') {
		if ($cmd ne "") {
			$lst='('.$cmd.')';
		}
		my $i=0;

		for ($i=0;$i<@culomns;$i++) {
			my $pn='_Ord'.$i;
			if ($q->param($pn)) {
				if (defined $lst) {$lst.=' and ';}
				$lst.=$culomns[$i].' '.$q->param($pn);
			}
		}

	}

  $hits=$self->db->tab($tab)->list($lst,$self->{'extra_sql'},
																	 $self->{'view_flds'},$order);
  my $pages = int(($hits->rows-1)/$self->{'rows'})+1;
  my $id_name = $self->tab->id->name;
	$res.="<BR><B>Field(s) found: </B>".$hits->rows."<BR><BR>";
	
  for (1..$pages) { 
    if ($_ != $self->{'page'}) {
      $res .= '<a href="'.$script.'?_Page='.$_;
      $res .= "&_Action=search&_Command=".$self->cgi->escape($lst) if defined $lst; 
      $res .=  '&'.$self->lnk."\">$_</a> ";
    } else {
      $res .= "$_ ";
    }
  }

	$hits->usepages(1);
  $res .= $hits->view_html(
    '<a href="'.$script.'?_id=<fld '. $id_name .
                           '>&_Action=show&'.$self->lnk.'">Show</a> '.
    '<a href="'.$script.'?_id=<fld '. $id_name .
                           '>&_Action=edit&'.$self->lnk.'">Edit</a> '.
    '<a href="'.$script.'?_id=<fld '. $id_name .
                           '>&_Action=delete&'.$self->lnk.'">Delete</a> ',
                           $self->{'view_flds'},
													);

	if (defined $self->tab->opt('short_add') ) {
		my $p=$self->tab->new_post;
	  $res .= "\n<form method=POST action=\"$script\">";
		$res .= "<input type=hidden name=_Action value=update>";
    $res .= $self->form_data;
		$res.= '<input type=hidden name="'.$self->cgi->param('_SubEditFld').
			'" value="'.$self->cgi->param('_SubEditVal').'">';
		$res.=$p->view_fmt('edit_html', $self->tab->opt('short_add'));
		$res .= '<input type=submit value="Add"></form>'."\n";
	}
  $res .= '<a href="'.$script.'?_Action=add&'.$self->lnk.'">Add</a> ';
	if (defined $self->cgi->param('_SubEditFld')) {
		$res .= '<form><INPUT TYPE="BUTTON" VALUE="OK" ONCLICK="window.close();return true;"></form>';
	}

		$res .= << "EOF";
<p>
<form method=GET action="$script">
	<input type=hidden name="_Action"  value="search">
	<hr>

  <hr>
		<center>
  <TABLE align=center><TR><TD align="center"><B>Show max</B></TD>
             <TD align="center"><B>Order by</B></TD>
             <TD align="center"><B>Then by</B></TD>
             <TD align="center"><B>Then by</B></TD></TR><TR><TD>
  <SELECT name="_Maxrows">
    <OPTGROUP label="Nrows">
EOF

	  for ($i=0;$i<@rowsoptions;$i++)	{
			if ($rowsoptions[$i]!=$self->{'rows'}){    
				$res.='<OPTION label="'.$rowsoptions[$i].'" value="'.
					$rowsoptions[$i].'">'.$rowsoptions[$i].' rows for page'; 
			}	else {
				$res.='<OPTION label="'.$rowsoptions[$i].'"value="'
					. $rowsoptions[$i].'" selected=1 >'.$rowsoptions[$i]
						. ' rows for page';
			}
		} 
		$res.=" </OPTGROUP> </SELECT>";

		$res.="</TD><TD>";
 
		#             STARTING ORDERING BUTTONS


		$res.='<SELECT name="_Orderby">';
		$res.='<OPTGROUP label="Orderby">';
		for ($i=0;$i<@culomns;$i++) {
			if (!(($culomns[$i].' ASC') cmp $q->param('_Orderby'))) {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' ASC" selected=1>'.$culomns[$i].' ASC';
			} else {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' ASC">'.$culomns[$i].' ASC';
			}
			if (!(($culomns[$i].' DESC') cmp $q->param('_Orderby'))){
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' DESC" selected=1>'.$culomns[$i].' DESC';
			} else {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' DESC">'.$culomns[$i].' DESC';
			}
		}
		$res.="</OPTGROUP> </SELECT>";
		$res.="</TD><TD>";
       
		$res.='<SELECT name="_Thenby1">';
		$res.='<OPTGROUP label="Thenby1">';
		for ($i=0;$i<@culomns;$i++) {
			if (!(($culomns[$i].' ASC') cmp $q->param('_Thenby1'))) {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' ASC" selected=1>'.$culomns[$i].' ASC';
			} else {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' ASC">'.$culomns[$i].' ASC';
			}
			if (!(($culomns[$i].' DESC') cmp $q->param('_Thenby1'))) {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' DESC" selected=1>'.$culomns[$i].' DESC';
			} else {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' DESC">'.$culomns[$i].' DESC';}
		}
		$res.="</OPTGROUP> </SELECT>";
		$res.="</TD><TD>";

		$res.='<SELECT name="_Thenby2">';
		$res.='<OPTGROUP label="Thenby2">';
		for ($i=0;$i<@culomns;$i++) {
			if (!(($culomns[$i].' ASC') cmp $q->param('_Thenby2'))) {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' ASC" selected=1>'.$culomns[$i].' ASC';
			} else {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' ASC">'.$culomns[$i].' ASC';};
			if (!(($culomns[$i].' DESC') cmp $q->param('_Thenby2'))) {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' DESC" selected=1>'.$culomns[$i].' DESC';
			} else {
				$res.='<OPTION label="'.$culomns[$i].'"value="'.
					$culomns[$i].' DESC">'.$culomns[$i].' DESC';
			}
		}
		$res.="</OPTGROUP> </SELECT>";
		$res.="</TD></TR></TABLE></center>";

		#             ENDED ORDERING BUTTONS


		$res.="<center><b>Filter By:<b>";
		$res.="\n<TABLE><TR>";
		
		foreach(@culomns) {
			$res.="<TD align=center><B>".$_."</B>";
		}
		$res.="</TR><TR>";

		my $lc=0;my $pn;
		foreach(@culomns) {
			$pn='_Ord'.$lc;
			$res.='<TD colspan=1 align=center><INPUT type="text" value="'.
				$q->param($pn).'" name="_Ord'.$lc.'" size=15></TD>';
			$lc++;
		}

		$res.=
			"</tr></table>\n".
			"AND <input name=\"_Command\" SIZE=50 VALUE=\"$cmd\"><p>".
			'<p><input type=submit value="OK">';
    $res .= $self->form_data . "\n</center></form><hr>\n";
	}

  $res;
}

1;



# Local Variables:
# perl-mode:              perl
# perl-tab-width:         8
# perl-indent-level: 2
# End:
