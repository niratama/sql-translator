package SQL::Translator::Producer::XML;

# -------------------------------------------------------------------
# $Id: XML.pm,v 1.8 2003-05-06 12:47:27 dlc Exp $
# -------------------------------------------------------------------
# Copyright (C) 2003 Ken Y. Clark <kclark@cpan.org>,
#                    darren chamberlain <darren@cpan.org>,
#                    Chris Mungall <cjm@fruitfly.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
# -------------------------------------------------------------------

use strict;
use vars qw[ $VERSION ];
$VERSION = sprintf "%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/;

use IO::Scalar;
use SQL::Translator::Utils qw(header_comment);
use XML::Writer;

my $sqlf_ns = 'http://sqlfairy.sourceforge.net/sqlfairy.xml';

# -------------------------------------------------------------------
sub produce {
    my ( $translator, $data ) = @_;
    #my $prargs = $translator->producer_args;
    my $prargs = { };
    my $io = IO::Scalar->new;

    my $xml = XML::Writer->new(OUTPUT      => $io,
                               NAMESPACES  => 1,
                               PREFIX_MAP  => { $sqlf_ns => 'sqlf' },
                               DATA_MODE   => 1,
                               DATA_INDENT => 2);


    $xml->xmlDecl("UTF-8");
    $xml->comment(header_comment('', ''));
    $xml->startTag([ $sqlf_ns => "schema" ]);

    for my $table ( 
        map  { $_->[1] }
        sort { $a->[0] <=> $b->[0] }
        map  { [ $_->{'order'}, $_ ] }
        values %$data
    ) {
        $xml->startTag([ $sqlf_ns => "table" ]);

        $xml->dataElement([ $sqlf_ns => "name" ], $table->{'table_name'});
        $xml->dataElement([ $sqlf_ns => "order" ], $table->{'order'});

        #
        # Fields
        #
        $xml->startTag([ $sqlf_ns => "fields" ]);
        for my $field ( 
            map  { $_->[1] }
            sort { $a->[0] <=> $b->[0] }
            map  { [ $_->{'order'}, $_ ] }
            values %{ $table->{'fields'} }
        ) {
            $xml->startTag([ $sqlf_ns => "field" ]);

            for my $key ( keys %$field ) {
                my $val = defined $field->{ $key } ? $field->{ $key } : '';
                   $val = ref $val eq 'ARRAY' ? join(',', @$val) : $val;
                $xml->dataElement([ $sqlf_ns => $key ], $val)
                    if ($val || (!$val && $prargs->{'emit_empty_tags'}));
            }

            $xml->endTag([ $sqlf_ns => "field" ]);
        }
        $xml->endTag([ $sqlf_ns => "fields" ]);

        #
        # Indices
        #
        $xml->startTag([ $sqlf_ns => "indices" ]);
        for my $index (@{$table->{'indices'}}) {
            $xml->startTag([ $sqlf_ns => "index" ]);

            for my $key (keys %$index) {
                my $val = defined $index->{ $key } ? $index->{ $key } : '';
                   $val = ref $val eq 'ARRAY' ? join(',', @$val) : $val;
                $xml->dataElement([ $sqlf_ns => $key ], $val);
            }

            $xml->endTag([ $sqlf_ns => "index" ]);
        }
        $xml->endTag([ $sqlf_ns => "indices" ]);

        $xml->endTag([ $sqlf_ns => "table" ]);
    }

    $xml->endTag([ $sqlf_ns => "schema" ]);
    $xml->end;

    return $io;
}

1;
__END__

# -------------------------------------------------------------------
# The eyes of fire, the nostrils of air,
# The mouth of water, the beard of earth.
# William Blake
# -------------------------------------------------------------------

=head1 NAME

SQL::Translator::Producer::XML - XML output

=head1 SYNOPSIS

  use SQL::Translator::Producer::XML;

=head1 DESCRIPTION

Meant to create some sort of usable XML output.

=head1 ARGS

Takes the following optional C<producer_args>:

=over 4

=item emit_empty_tags

If this is set to a true value, then tags corresponding to value-less
elements will be emitted.  For example, take this schema:

  CREATE TABLE random (
    id int auto_increment PRIMARY KEY,
    foo varchar(255) not null default '',
    updated timestamp
  );

With C<emit_empty_tags> = 1, this will be dumped with XML similar to:

  <table>
    <name>random</name>
    <order>1</order>
    <fields>
      <field>
        <is_auto_inc>1</is_auto_inc>
        <list></list>
        <is_primary_key>1</is_primary_key>
        <data_type>int</data_type>
        <name>id</name>
        <constraints></constraints>
        <null>1</null>
        <order>1</order>
        <size></size>
        <type>field</type>
      </field>

With C<emit_empty_tags> = 0, you'd get:

  <table>
    <name>random</name>
    <order>1</order>
    <fields>
      <field>
        <is_auto_inc>1</is_auto_inc>
        <is_primary_key>1</is_primary_key>
        <data_type>int</data_type>
        <name>id</name>
        <null>1</null>
        <order>1</order>
        <type>field</type>
      </field>

This can lead to dramatic size savings.

=back

=pod

=head1 AUTHOR

Ken Y. Clark E<lt>kclark@cpan.orgE<gt>

=head1 SEE ALSO

XML::Dumper;

=cut
