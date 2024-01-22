#!/usr/bin/env perl
#
#   Script that "flattens" Beacon v2 Models Properties to CSV headers
#
#   Input: de-referenced ($ref) defaultSchema.json (JSON Schema)
#   Output: CSV with properties nested up to 4D
#   NB: Hard-coded, not using any external utility (e.g., <mongoexport>)
#
#   Last Modified: March/17/2022
#
#   Version 2.0.0
#
#   Copyright (C) 2020-2021 Manuel Rueda (manuel.rueda@crg.eu)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
#   If this program helps you in your research, please cite.

use strict;
use warnings;
use autodie;
use feature qw(say);
use Data::Dumper;
use JSON::XS;
use List::Util qw(any);
use Path::Tiny qw(path);

die "Sorry, we need a de-referenced <defaultSchema.json> as an argument\n" unless $ARGV[0];
my $debug                       = 0;
my $nested_arrays_only_up_to_1d = 1;

# Load the input file
my $str = path( $ARGV[0] )->slurp;

# Decode it to Perl data structure
my $json = decode_json($str);

# Output will be loaded into @header_fields
my @header_fields = ();

# Start with 1D
my $selection_1d = $json->{properties};
for my $property_1d ( sort keys %{$selection_1d} ) {

    #######
    # 1-D #
    #######
    my $type_1d = $property_1d eq 'variation' ? 'string' : $selection_1d->{$property_1d}{type}; # variation does not have type (anyOf)
    say_properties( 1, $type_1d, $property_1d );
    if ( $type_1d eq 'array' || $type_1d eq 'object' ) {
        my ( $selection_2d, $separator ) =
          check_type( 1, $type_1d, $selection_1d->{$property_1d} );

        #######
        # 2-D #
        #######
        for my $property_2d ( sort keys %{$selection_2d} ) {
            my $tmp_2d = $property_1d . $separator . $property_2d;
            push @header_fields, $tmp_2d;
            my $type_2d = $selection_2d->{$property_2d}{type};
            say_properties( 2, $type_2d, $property_1d, $property_2d );
            my ( $selection_3d, $separator ) =
              check_type( 2, $type_2d, $selection_2d->{$property_2d} );

            #######
            # 3-D #
            #######
            for my $property_3d ( sort keys %{$selection_3d} ) {
                my $tmp_3d = $tmp_2d . $separator . $property_3d;
                push @header_fields, $tmp_3d;
                my $type_3d = $selection_3d->{$property_3d}{type};
                say_properties( 3, $type_3d, $property_1d, $property_2d,
                    $property_3d );
                my ( $selection_4d, $separator ) =
                  check_type( 3, $type_3d, $selection_3d->{$property_3d} );

                #######
                # 4-D #
                #######
                for my $property_4d ( sort keys %{$selection_4d} ) {
                    say_properties( 4, $type_3d, $property_1d, $property_2d,
                        $property_3d, $property_4d );
                    my $tmp_4d = $tmp_3d . $separator . $property_4d;
                    push @header_fields, $tmp_4d;
                }
            }
        }
    }
    else {
        push @header_fields, $property_1d;
    }
}
say join ',', add_array_ids( $ARGV[0], \@header_fields); 

sub check_type {

    my $dim           = shift;
    my $type          = shift // 'string';
    my $data          = shift;
    my $obj_separator = ('.') x 1;
    my $arr_separator = ('_') x 1;
    $type = 'string' if ( $dim > 1 && $nested_arrays_only_up_to_1d );
    my $selection =
      $type eq 'array' ? $data->{items}{properties} : $data->{properties};
    my $separator = $type eq 'array' ? $arr_separator : $obj_separator;
    return ( $selection, $separator );
}

sub say_properties {

    my $dim  = shift;
    my $type = shift // 'string';
    my @args = @_;
    my $dot  = $dim == 1 ? '*' : '.';
    my $str  = ($dot) x $dim**2;
    say "$str $dim", 'D', "_($type) - ", ( join ' | ', @args ) if $debug;
    return 1;
}

sub delete_duplicated_elements {

    my $array  = shift;
    my @terms = @$array;
    for my $i ( reverse 0 .. $#terms ) { # Trick to keep array order after spliceing :-)
        splice( @terms, $i, 1 )
          if ( any { /^$terms[$i]\./ || /^$terms[$i]_/ } @terms ); # [\._] does not work
    }
    return wantarray ? @terms : \@terms;
}

sub add_array_ids {

    # Ad hoc term added to datasets and cohorts
    my ( $arg, $array ) = @_;
    my @terms = sort ( delete_duplicated_elements( $array ));
    my @extra_terms = qw(ids.individualIds ids.biosampleIds);
    push @terms, @extra_terms if  $arg =~ /(cohorts|datasets)\/defaultSchema.json/;
    return wantarray ? @terms : \@terms;
}
