#!/usr/bin/env perl
use strict;
use warnings;
use Mojolicious::Lite;
use Mojo::UserAgent;
use Mojo::JSON 'from_json', 'to_json';

helper bff_get => sub {
    my ($c, $path, $params) = @_;
    my $ua = Mojo::UserAgent->new;
    my $bff_base = 'http://127.0.0.1:3000';  # Base URL for your API
    my $url_obj = Mojo::URL->new($bff_base . $path);
    
    # Append query parameters to the URL for debugging
    $url_obj->query(%$params);
    $c->app->log->debug("Sending request to API: " . $url_obj->to_string);
    
    my $tx = $ua->get($bff_base . $path => form => $params);
    return $tx->result;
};

####################
# Front-End Routes #
####################

# Home page with redirects/links
get '/' => sub {
  my $c = shift;
  $c->render(template => 'index');
};

# Single-collection query page
get '/query' => sub {
  my $c = shift;
  $c->render(template => 'single_query');
};

# Cross-collection query page
get '/cross-query' => sub {
  my $c = shift;
  $c->render(template => 'cross_query');
};

# Handle single-collection query form submission
get '/perform_query' => sub {
  my $c = shift;
  
  # Retrieve standard parameters
  my $db           = $c->param('db')         || 'beacon';
  my $collection   = $c->param('collection');
  my $extra_path   = $c->param('extra_path') || '';  # New field for extra path segments
  my $limit        = $c->param('limit')      || 10;
  my $skip         = $c->param('skip')       || 0;
  
  # Construct base path using db and collection
  my $path = "/$db/$collection";
  
  # Append extra path segments if provided
  $path .= "/$extra_path" if $extra_path;
  $path =~ s{//+}{/}g;  # Normalize any duplicate slashes
  
  my %params = ( limit => $limit, skip => $skip );
  
  my $res = $c->bff_get($path, \%params);
  my $result = $res->is_success 
                 ? to_json($res->json, { pretty => 1 }) 
                 : "Error: " . $res->message;
  
  $c->stash(result => $result);
  $c->render(template => 'single_query');
};

# Handle cross-collection query form submission
# Handle cross-collection query form submission
get '/perform_cross_query' => sub {
  my $c = shift;
  
  # Retrieve standard parameters
  my $db           = $c->param('db')           || 'beacon';
  my $collection1  = $c->param('collection1');
  my $id           = $c->param('id');
  my $collection2  = $c->param('collection2');
  my $extra_path   = $c->param('extra_path')   || '';  # New field for extra path segments
  my $limit        = $c->param('limit')        || 10;
  my $skip         = $c->param('skip')         || 0;
  
  # Construct base path using retrieved parameters
  my $path = "/$db/cross/$collection1/$id/$collection2";
  
  # Append extra path segments if provided
  $path .= "/$extra_path" if $extra_path;
  $path =~ s{//+}{/}g;  # Normalize any duplicate slashes
  
  my %params = ( limit => $limit, skip => $skip );
  
  my $res = $c->bff_get($path, \%params);
  my $result = $res->is_success 
               ? to_json($res->json, { pretty => 1 }) 
               : "Error: " . $res->message;
  
  $c->stash(result => $result);
  $c->render(template => 'cross_query');
};

# Display help page
get '/help' => sub {
  my $c = shift;
  $c->render(template => 'help');
};

app->start;
