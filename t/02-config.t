#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Cwd qw(abs_path);
use FindBin;
use lib "$FindBin::Bin/../lib";
use BFF::Config;

# Test BEACON::Config module.
use_ok('BFF::Config');

# Test parse_yaml_file by creating a temporary YAML file.
my ( $fh, $yaml_file ) = tempfile();
print $fh "key1: value1\nkey2: 2\n";
close $fh;
my %yaml_data = Config::parse_yaml_file($yaml_file);
is( $yaml_data{key1}, 'value1', 'parse_yaml_file reads key1 correctly' );
is( $yaml_data{key2},   2,        'parse_yaml_file reads key2 correctly' );

# Test validate_config: it should die if a required key is missing.
{
    my $hashref = { a => 1, b => 2 };
    my $error;
    {
        local $@;
        eval { Config::validate_config( $hashref, [ 'a', 'c' ] ); };
        $error = $@;
    }
    like( $error, qr/Missing required parameter <c>/,
        'validate_config dies when a required key is missing' );
}

# Test read_param_file: with minimal arguments (defaults will be used).
{
    my $args = { mode => 'vcf' };
    my $param = Config::read_param_file($args);
    ok( exists $param->{jobid}, 'read_param_file returns a jobid' );
    ok( exists $param->{log},   'read_param_file returns a log file path' );
    ok( ref($param) eq 'HASH',   'read_param_file returns a hash reference' );
}

done_testing();
