#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More tests => 3;
use File::Temp qw(tempdir tempfile);
use File::Spec;

BEGIN {
    # Override exit so that calls to exit cause a die.
    *CORE::GLOBAL::exit = sub { die "exit called" };
}

use BFF::Help;

# After loading BEACON::Help, override both Help::pod2usage and Pod::Usage::pod2usage.
{
    no warnings 'redefine';
    *Help::pod2usage = sub {
        my %args = @_;
        die $args{-message} || 'pod2usage called';
    };
    *Pod::Usage::pod2usage = sub {
        my %args = @_;
        die $args{-message} || 'pod2usage called';
    };
}

# Test 1: info() subroutine should not print anything for a non-help flag.
{
    local @ARGV = ('dummy_mode');
    my $version = '2.0.7';
    my $output;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        Help::info($version, 'not_help');
    }
    like($output, qr/^$/, 'info subroutine does not print for a non-help flag');
}

# Test 2: usage_params() should die with the expected message when the config file is missing.
{
    my %args = (
        configfile => 'non_existent_config.yaml',
        paramfile  => 'non_existent_param.yaml'
    );
    my $err;
    {
        local $@;
        eval { Help::usage_params(\%args); };
        $err = $@;
    }
    like($err, qr/Option --c requires a config file/, 'usage_params dies on missing config file');
}

# Test 3: Verify that GoodBye->say_goodbye returns a non-empty string.
{
    my $goodbye = GoodBye->new();
    my $msg     = $goodbye->say_goodbye();
    ok($msg, 'GoodBye->say_goodbye returns a non-empty string');
}

done_testing();
