#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../frontend";  # Add frontend directory to @INC
use Test::More;
use Test::Mojo;

# Set Mojolicious mode to testing
BEGIN { $ENV{MOJO_MODE} = 'testing'; }

# Load the Mojolicious application from frontend/app.pl
require 'app.pl' or die $@;

# Create a Test::Mojo instance for our application
my $t = Test::Mojo->new;

# Test 1: Home page ("/") should render the index template
$t->get_ok('/')
  ->status_is(200)
  ->content_like(qr/Welcome to the MongoDB Query Interface for BFF/i); 
  # Check that the home page contains welcome message

# Test 2: Single-collection query page ("/query")
$t->get_ok('/query')
  ->status_is(200)
  ->content_like(qr/Single Collection Query/i);  
  # Check for a heading or label indicating it's the single query page

# Test 3: Cross-collection query page ("/cross-query")
$t->get_ok('/cross-query')
  ->status_is(200)
  ->content_like(qr/Cross[-\s]Collection Query/i);  
  # Updated regex to accommodate hyphen

# Test 4: Help page ("/help")
$t->get_ok('/help')
  ->status_is(200)
  ->content_like(qr/Help/i);  
  # Check for "Help" text on the page

done_testing();
