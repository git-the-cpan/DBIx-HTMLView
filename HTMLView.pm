#!/usr/bin/perl

#  HTMLView.pm - For creating web userinterfaces to DBI databases.
#  (c) Copyright 1998 Hakan Ardo <hakan@debian.org>
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

  DBIx::HTMLView - For creating web userinterfaces to DBI databases.

=head1 SYNOPSIS

use DBIx::HTMLView;
use CGI;

my $table="Test";
my $v=new DBIx::HTMLView("DBI:mSQL:HTMLViewTester:athena.af.lu.se:1114", {});
$v->SetParam("_Table", $table);
$v->InitDb($table);

# Preform the actions requested by the user
$v->Preform(new CGI);

# Generate list content of $table in a html table
print "<table>\n";
foreach ($v->List("SELECT * FROM $table",'<td>')) { 
	print "<tr><td>$_->[1]<td>";
	print "<tr>" . $v->ml("View.cgi", $_->[0], "Show") . "</tr>\n";
}
print "</table>\n";

=head1 DESCRIPTION

This is a general propose module to simplify the creation of web
userinterfaces to a DBI database, currently it can list, view, add,
edit and delete entries in the databse using either <input ...> or
<textarea> to gather the info. Se the new method description for 
info on how to define the database format and how the fields should 
be edited.

It's actions is highy customizable by using a database definition 
where most things are specified and by beeing designed to easily 
allow subclassing in order to change it's behaviour.

It can also edit N2N relations between two tabels using a third table
to represent the connections. Eg if you have two tabels with say users
and usergroups like this:

      Users                 Groups
	
	|id  |Name  |       |id  |Group     |
	+----+------+       +----+----------+
	|0   |root  |       |0   |Superuser |
	|1   |jhon  |       |1   |Webauthor |
	|2   |hakan |       |2   |Mailuser  |
	|3   |tom   |

Now lets say that we have one Superuser (root), three Webauthors (tom,
jhon,root) and all four users are Mailusers. To represent this in the
databse HTMLView uses a third table, say UsersGroups, linking
uid's to gid's like this

	UsersGroups
	
	|id |uid |gid |
	+---+----+----+
	|0  |0   |0   |   root is Superuser
	|1  |0   |1   |   root is Webauthor
	|2  |0   |2   |   root is Mailuser
	|3  |1   |1   |   jhon is Webauthor
	|4  |1   |2   |   jhon is Mailuser
	|5  |2   |2   |   hakan is Mailuser
	|6  |3   |1   |   tom is Webauthor
	|7  |3   |2   |   tim is Mailuser

This kind of relations are edited using a set of checkboxes in the
post editor allowing the user to select any number of groups for each user.

Even if we have tried to make this as general as possible there are a
few properties required from the database beeing edited. The most
inportant one is that each table has to contain and unquire index
field. Since the handling of such indexes differs between databses
there is a set of methods handling them which could changed by
subclassing and overridon those. The methods are:

  GetIndex - Returns the colum name for the unquire id 
  Insert - Insert a new post and returns it's index

See the detailed method descriptions below for more info.

The default methods are designed to work with mSQL and mySQL if the
tabels are constructued in some specific ways:

As for mySQL the index field should be declaered "INT NOT NULL 
AUTO_INCREMENT" and made "PRIMARY KEY". It can be named anything as
HTMLView are able to figgure out the primary key of a table.

As for mSQL the index field has to be called id and defined as "INT NOT 
NULL" in the "CREATE TABLE" request, 
and that the table contains a sequence (eg "CREATE SEQUENCE ...") from 
which values are retreved to the index. Is is also adviceable to make an
index out of the id, eg "CREATE UNIQUE  INDEX idx1 ON Users(id)", to 
speed up the database handling, but HTMLView will probabably work anyway.

=head1 METHODS

=cut

package DBIx::HTMLView;
use DBI;

$VERSION="0.2";

=head2 $v=new DBIx::HTMLView($db, $fmt);

Creates a new HTMLView interface object representing the database $db,
which should be a DBI database specification (the string passed as first 
argument to DBI->connect). The second argument is a
hash defining how the fields of each table should be editied and which 
relations there are beteen the tabels. It could be as simple as {}, 
then all fields will be edited using the default <input ...> tag.

It is easiest explained by an example, let's get back to the Users 
example from the DESCRIPTION section. Let's say the Users table also 
contains a FingerInfo field and that the Groups table has a Description 
of each group, then $fmt could look like this:

$fmt = {
    "Groups" => {
        "Description" => "Multiline(80,20)",
    },
    "Users" => {
        "FingerInfo" => "Multiline(80,50)",
        "Group" => {
            "Type" => "N2N Relation",
            "FromTable" => "Groups",
            "LinkTable" => "UsersGroups",
            "FromField" => "gid",
            "ToField" => "uid",
            "ViewVars" => "Group",
        },
    },
}

Here we have two tables Users and Groups. Line three defines 
that the Description field should be editied using a Multiline(80,50) 
editor (which will be implemented with <textfield>...). HTMLView 
currently supports the following editor types:

  DEFAULT - If a field is not specifed in the fmt a standart html 
	input line will be used.
	
  Multiline(<W>,<H>) - A html textarea with <H> lines <W> characters 
	long.
  
The example also declears an N2N relation between the two tabels using 
the UsersGroups table for the links and it is the Group field in the 
Groups table that will be listed in the list of groups shown when 
editing a post from the user table. ViewVars can contain several 
variable names separated by , and or spaces.

"N2N Relation":s are the only kind supported right now.

Relations are specified in the same manner as filed types because in the 
user interface they look like just an other type of fields.

=cut

sub new {
	my $self= bless {}, shift;
	$self->{'Db'}=shift;
	$self->{'DbDsk'}=shift;
	$self;
}

=head2 InputF($key, $val)

Returns a html input field editing $key with default value $val. $key
will be looked up as a field-/relation-name in the fmt specification (se 
the new method) and an appropreate editor will be constructed.

=cut

sub InputF {
	my ($self,$id,$key, $val)=@_;
	my $fmt=$self->{'DbDsk'}{$self->{'table'}}{$key};
	if ($fmt->{'Type'} eq 'N2N Relation') {
		my %got;
		if (defined $id) {
	    my $sel = << "EOF";
	    
	    SELECT $fmt->{'FromField'}
			FROM  $fmt->{'LinkTable'}
			WHERE $fmt->{'ToField'}=$id
EOF
			my $sth=$self->SendCMD($sel);
	    while (my $ref=$sth->fetchrow_arrayref) {$got{$ref->[0]}=1;}
		}
		my $res="";
		my $v=$self->RelVars($fmt);
		foreach ($self->List("SELECT $v FROM $fmt->{'FromTable'}", " ")) {
	    my $lnid=$_->[0];
	    my $row=$_->[1];
	    if ($got{$lnid}) {$ch="checked"} else {$ch=""}
	    $res .= "<tr><td>".
		    "<input type=checkbox name=_$key-$lnid value=1 $ch><td>".
					$row . "</tr>\n";
		}
		$res.="<input type=hidden name=_$key-Clr value=1>\n";
		return "<table>$res</table>\n";	
	} elsif ($fmt =~ /^\s*Multiline\((\d+),(\d+)\)\s*$/i) {
		return "<textarea cols=$1 rows=$2 name=\"$key\">$val</textarea>";
	} else {
		return '<input name="'.$key.'" value="'.$val.'">';
	}
}


=head2 $v->RelVars($fmt)

Will inspect $fmt->{'ViewVars'} and return a variable list that can be 
passed to SELECT for retreval. The list will start with the table index 
and the table name will be prepended to each variablename so that the 
returned string can be used in SELECT using several tabels.

=cut

sub RelVars {
	my ($self, $fmt)=@_;
	my $table=$fmt->{'FromTable'};
	my $vars="";
	
	foreach (split(/,?\s+/, $fmt->{'ViewVars'})) {
		$vars.="$table.$_, ";
	}
	$vars=~s/, $//;
	
	my $i=$self->GetIndex($table);
	
	return "$table.$i, ".$vars;
}

=head2 $v->GetIndex($table)

Returns the id field for the table $table. The name is retreved by sending
a "SHOW INDEX FROM $table" request to the server unless it is a mSQL server,
which does not support that request, instead we presume it is named "id".

=cut

sub GetIndex {
	my ($self, $table)=@_;
	if ($self->{'Db'} =~ /^DBI:mSQL/) {
		return 'id';
	} else {
		my $sth=$self->SendCMD("SHOW INDEX FROM ".$table);
		while (my $ref = $sth->fetchrow_arrayref) {
	    if ($ref->[2] eq "PRIMARY") {
				return $ref->[4];
	    }
		}
	}    
}

=head2 $v->InitDb($table)

Initiates the interface by making the connection to the database and 
downloading the field names and deciding on which to use as id (by 
calling GetIndex). To do this you have to specify which table we are
currently viewinig ($table).

=cut

sub InitDb {
	my $self=shift;
	$self->{'table'}=shift;
	
	$self->{'dbh'}=DBI->connect($self->{'Db'}, "", "");
	if(!$self->{'dbh'}) {die "DBI->connect failed on " . $self->{'Db'}}
	
	# Get hold of index colum
	$self->{'index'}=$self->GetIndex($self->{'table'});
	
	# Get hold of colum names
  # This is a nasty litte hack:) I needed a database independed way to
	# get hold of all field names, so I make a SELECT query that matches 
	# nothing and asks for all variabels. That should return the variable 
  # names and no data... (selecting on 0=1 or alike as sugestied by the
  # mySQL people does not work on mSQL servers)

	$sth = $self->SendCMD("SELECT * FROM ".$self->{'table'}." WHERE $self->{'index'}=-1");

	$self->{'names'} = $sth->{'NAME'};
	
	$self;
}

=head2 $v->SendCMD($cmd)

Vill prepare and sned $cmd to the database and it dies on errors. The $sth 
is returned.

=cut

sub SendCMD {
	my $self=shift;
	my $cmd=shift;
	my $sth = $self->{'dbh'}->prepare($cmd);
	if (!$sth) {
		die "Error:" . $dbh->errstr . "\n";
	}
	if (!$sth->execute) {
		die "Error:" . $sth->errstr . "\n";
	}
	$sth;
}

=head2 $v->List($cmd, $join)

Will send the $cmd to the db (presumable a SELECT command) and return the
result as an array of arrayreferenses. There will be one arrayreference 
for each row returned and the array referenced to will contain 
two values. The first one is the first variable specifed in the SELECT 
statement $cmd, presumable the id, and the second is a join of the rest
using $join as glue string.

=cut


sub List {
	my ($self, $cmd, $join)=@_;
	
	my $sth = $self->SendCMD($cmd);
	my @ret;
	
	while (my $ref = $sth->fetchrow_arrayref) {
		my $row=$$ref[1];
		for(my $i=2; $i<=$#$ref; $i++){$row.=$join.$$ref[$i];}
		push @ret, [$ref->[0], $row];
	}
	
	return @ret;
}

=head2 $v->ml($file, $id, $a)

Generates a link to the script $file preserving the id parameter $id and 
the parameters specified using $v->SetParam(...). The link's anchor text 
will be $a.

=cut

sub ml {
	my ($self, $file, $id, $a)=@_;
	"<a href=\"$file?_$a=1&_Id=$id&".$self->ParamStr."\">$a</a>";
}

=head2 $v->Delete($id)

Deletes the post with id $id form the db.

=cut

sub Delete {
	my ($self, $id)=@_;
	$self->SendCMD("DELETE FROM " . $self->{'table'} . " WHERE ".
								 $self->{'index'}."=$id");
	"ok";
}

=head2 $v->Get($id)

Gets hold of the post with id $id. It is reaturned as an arrayref, with 
all it's variables.

=cut

sub Get {
	my ($self, $id)=@_;
	my $sth = $self->SendCMD("SELECT * FROM ".$self->{'table'}." WHERE ".
													 $self->{'index'}."=$id");
	$sth->fetchrow_arrayref;
}

=head2 $v->View($id, $key, $val)

Will return an HTML string viewing the $key field with value $val. $key 
is looked up as a field-/relation-name in the fmt specifed in the 
constructor to decide how that data should be retrived (in the case of
a relation) and viewed.

=cut

sub View {
	my ($self, $id, $key, $val)=@_;
	my $fmt = $self->{'DbDsk'}{$self->{'table'}}{$key};
	
	if ($fmt->{'Type'} eq "N2N Relation") {
		
		if ($id) {
			my $v=$self->RelVars($fmt);
			my $fid=$self->GetIndex($fmt->{'FromTable'});
			my $cmd = <<"EOF";
	    SELECT $v
		   FROM $fmt->{'FromTable'}, $fmt->{'LinkTable'}
		   WHERE $fmt->{'LinkTable'}.$fmt->{'FromField'}=
                                             $fmt->{'FromTable'}.$fid AND 
                         $fmt->{'LinkTable'}.$fmt->{'ToField'}=$id
EOF
			my $res="";
			foreach ($self->List($cmd, " ")) {
				$res.= $_->[1] . ", ";
			}
			return $res;
		}
		return "";
	} else {
		return $val;
	}
}

=head2 $v->DataTable($data, $edit)

Returns a html table containing all fields of the table. The fields 
will contain the data in the $data arrayref with the fields 
mathcing the regexp $edit editable. A form and a apply button has to 
be placed around it in order to use it for editing. The primary key 
will never be editable.

=cut

sub DataTable {
	my ($self, $data, $edit)=@_;
	my $res="\n<table>\n";
	my @n=@{$self->{'names'}};
	my $id;



	for(my $i=0; $i<=$#n; $i++){
		if (($n[$i] eq $self->{'index'})) {
			$id=$data->[$i];
			last;
		}
	}
	
	for(my $i=0; $i<=$#n; $i++){
		$res.="<tr><td> <b>".$n[$i]."</b><td>";
		if (($n[$i] ne $self->{'index'}) && $n[$i] =~ $edit) {
			$res.=$self->InputF($id,$n[$i],$data->[$i])."</tr>\n";
		} else {
			$res.=$self->View($id, $_, $data->[$i]);
		}
	}
	
	my $fmt=$self->{'DbDsk'}{$self->{'table'}};
	foreach (keys %$fmt) {
		if ($fmt->{$_}{'Type'} eq "N2N Relation") {
			$res.="<tr><td> <b>".$_."</b><td>";
			if ($_ =~ $edit) {
		    $res.=$self->InputF($id,$_,"")."</tr>\n";
			} else {
		    $res.=$self->View($id, $_, "");
			}
		}
	}
	$res.="</table>\n";
	$res;
}

=head2 $v->Insert($table, $k, $f)

Will make a "INSERT INTO $table ($k) VALUES ($f)" call to the database and
return the id value the post gets. In order to do this it might have to
modify the command slightly to contain the id field too.

The idea is that you can override this method in a subcalls to chnage 
the way we should handle id values. This default implementation will
handle mSQL and mySQL servers as described in the DESCRIPTION section
above.

=cut

sub Insert {
  my ($self, $table, $k, $f)=@_;
	if ($self->{'Db'} =~ /^DBI:mSQL/) {
		my $sth=$self->SendCMD("select _seq from " . $self->{'table'});
		my $id=$sth->fetchrow_arrayref->[0];

		$self->SendCMD("INSERT INTO $table ($self->{'index'}, $f) VALUES ($id, $k)");

		return $id;
	} else { # mySQL
		my $sth=$self->SendCMD("INSERT INTO $table ($f) VALUES ($k)");
		return $sth->{'insertid'};
	}
	
}




=head2 $v->Add($form)

Addes a new post to the db with the data in the hash ref $form. All it's 
keys that doesn not start with a _ char should match a column name in 
that current table. Se the UpdateRelations on how relations should be 
represented.

It will use the $v->Insert(...) method to do the actuall database call.

=cut
 
sub Add {
	my ($self, $form) = @_;
	my ($f,$k);
	
	
	foreach (keys %$form) {
		if(!/^_/) {
			$f.=", ". $_;
			if ($form->{$_} =~ /^\d+$/){
		    $k.=", ".$form->{$_};
			} else {
		    $k.=", '".$form->{$_}."'";
			}
		}
	}
	$f=~s/^, //;
	$k=~s/^, //;
	
	my $idnr = $self->Insert($self->{'table'}, $k, $f);
	
	$self->UpdateRelations($idnr, $form);

	"ok";
}

=head2 $v->UpdateRelations($idnr, $form)

This method will update $idnr's relations acording to the info found in
$form. It's keys are scaned for members of the format "_<RelationName>-#"
where <RelationName> is decleard in the fmt with Type="N2N Relation", and # 
is  the id to which should be linked to (eg the gid of our users example).

If such keys are found then all relations for $idnr's post to <RelationName> 
are cleard out and relations to each # found is recreated.

To clear things up here is a little example. Consider the relations used 
in the Users example in the DESCRIPTION section. The user root there is 
Superuser, Webauthor and Mailuser. Let's say we want to remove him from 
the Webauthor group. Then that is done by specifying the other two. That 
is  $form would contain the keys _Group-0 and __Group-2. That would first
clear all three connections and then readd the two for Superuser (gid=0) 
and Mailuser (gid=2).

Relations not mentioned at all will not be modified. The presents a 
problem if you want to clear out all connections in a relation (eg remmove
root from all groups). For this you'll have to use the speciall key 
"_<RelationName>-Clr" (eg _Group-Clr). This key will have no efect if
specifed together with a set of "_<RelationName>-#" key, eg the specified
connections will be made.

Note that the value in the hash that the key is represented never is used 
and can thereby be anytihing.

=cut

sub UpdateRelations {
	my ($self, $idnr, $form)=@_;
	my $fmt = $self->{'DbDsk'}{$self->{'table'}};
	my %cleared;
	
	foreach (keys %$form) { 
		if (/^_([^-\d]+)-(\d+|Clr)$/ &&
				$fmt->{$1}{'Type'} eq 'N2N Relation') {
			
	    if (!$cleared{$1}) {
				$self->SendCMD("DELETE FROM $fmt->{$1}{'LinkTable'} " . 
											 "WHERE $fmt->{$1}{'ToField'} = $idnr");
				$cleared{$1}=1;
	    }
			
			if ($2 ne 'Clr') {
				my $sth=$self->SendCMD("select _seq from " . 
															 $fmt->{$1}{'LinkTable'});
				my $lnkidnr=$sth->fetchrow_arrayref->[0];
				
				my $cmd = << "EOF";
				INSERT INTO $fmt->{$1}{'LinkTable'}
				(id,$fmt->{$1}{'FromField'}, $fmt->{$1}{'ToField'})
					VALUES ($lnkidnr, $2, $idnr)
EOF
	      $self->SendCMD($cmd);
			}
    }
	}
}
	
=head2 $v->Changed($form)

Changes an already excisting post in the db with the data in the hash ref 
$form used as the new data. All it's keys that doesn not start with a 
_ char should match a column name in that current table.  Se the 
UpdateRelations on how relations should be represented.

=cut


sub Changed {
	my ($self, $form)=@_;
	my $id=$form->{'_Id'};
	
	$self->UpdateRelations($id, $form);
	
	my $ch="";
	foreach (keys %$form) {
		if (!/^_/) {
			if ($form->{$_} =~ /^\d+$/){
				$ch.="$_=".$form->{$_}.", ";
			} else {
				$ch.="$_=\'".$form->{$_}."\', ";
			}
		}
	}
	$ch =~ s/, $//;
	
	$self->SendCMD("UPDATE ".$self->{'table'}." set $ch WHERE ".
								 $self->{'index'}."=$id");
	
	"ok";
}

=head2 $v->Preform($form)

Will check if _Delete, _Changed or _Add keys excists in the hasref $form and 
if so preforme that action  on the post with $form->{_Id} as id using the 
rest of the field data in $form. By calling $v->Delete, $v->Changed or 
$v->Add.

=cut

sub Preform {
	my ($self, $form) = @_;
	
	if ($form->{'_Delete'}) {$self->Delete($form->{'_Id'});}
	if ($form->{'_Changed'}) {$self->Changed($form);}
	if ($form->{'_Add'}) {$self->Add($form);}
}

=head2 $v->SetParam($key, $val)

Will set a parameter that is the passed on to the links generated by $v->ml

=cut

sub SetParam {
	my ($self, $key, $val)= @_;
	$self->{'Params'}{$key}=$val;
}

=head2 $v->ParamStr

Generates a param string to be included in the url specifying the params set
using $v->SetParam

=cut

sub ParamStr {
	my  $self=shift;
	my $str="";
	foreach (keys %{$self->{'Params'}}) {
		$str.=$_ . "=" . $self->{'Params'}{$_};
	}
	$str;
}

=head1 Author

  Hakan Ardo <hakan@debian.org>

=cut

1;
