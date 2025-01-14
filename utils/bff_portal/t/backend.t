#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../backend";  # Add backend directory to @INC
use Test::More;
use Test::Mojo;

# Set Mojolicious mode to testing
BEGIN { $ENV{MOJO_MODE} = 'testing'; }

# Load the Mojolicious application
require 'api.pl' or die $@;

# Create a Test::Mojo instance for our application
my $t = Test::Mojo->new;

# Helper for checking JSON response headers and status
sub check_json_response {
  my ($tx) = @_;
  my $result = $tx->result;
  is($result->code, 200, 'Response code 200');
  like($result->headers->content_type, qr{application/json}, 'Content-Type includes application/json');
}

# Test 1: GET '/' - should return list of databases as JSON.
$t->get_ok('/');
my $tx = $t->tx;
check_json_response($tx);
{
  my $json = $tx->result->json;
  ok(ref($json) eq 'ARRAY', 'Databases list returned as array');
}

# Test 2: GET '/:db' - list collections in a database.
$t->get_ok('/beacon');
$tx = $t->tx;
check_json_response($tx);
{
  my $json = $tx->result->json;
  ok(ref($json) eq 'ARRAY', 'Collections list returned as array');
}

# Test 3: GET '/:db/:collection' - return collection items.
$t->get_ok('/beacon/analyses');
$tx = $t->tx;
check_json_response($tx);
{
  my $json = $tx->result->json;
  ok(ref($json) eq 'ARRAY', 'Items returned as array');
}

# Test 4: GET '/:db/:collection/:key/:value'
$t->get_ok('/beacon/individuals/id/HG02600');
$tx = $t->tx;
check_json_response($tx);
{
  my $json = $tx->result->json;
  ok(ref($json) eq 'ARRAY', 'Filtered items returned as array');
}

# Test 5: Pagination test example
$t->get_ok('/beacon/individuals?limit=20&skip=40');
$tx = $t->tx;
check_json_response($tx);
{
  my $json = $tx->result->json;
  ok(ref($json) eq 'ARRAY', 'Paginated items returned as array');
  # Additional checks for array length or content can be added here.
}

# Test 6: Cross-collection query with pagination
$t->get_ok('/beacon/cross/individuals/HG00096/genomicVariations?limit=5&skip=10');
$tx = $t->tx;
check_json_response($tx);
{
  my $json = $tx->result->json;
  ok(ref($json) eq 'ARRAY', 'Cross-collection items returned as array');
}

# Test 7: Cross-collection query with missing document (simulate error scenario)
$t->get_ok('/beacon/cross/unknown/HG99999/genomicVariations');
$tx = $t->tx;
check_json_response($tx);
{
  my $json = $tx->result->json;
  ok(exists $json->{error}, 'Error message returned for missing document');
}

done_testing();
