#!/usr/bin/env perl
use strict;
use warnings;
use Mojolicious::Lite;
use Mojo::UserAgent;
use Mojo::JSON 'from_json', 'to_json';

helper bff_get => sub {
    my ($c, $path, $params) = @_;
    my $ua = Mojo::UserAgent->new;
    my $bff_base = 'http://127.0.0.1:3000';  # Base URL for your BFF API
    my $url = $bff_base . $path;
    my $tx = $ua->get($url => form => $params);
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
  my $db         = $c->param('db');
  my $collection = $c->param('collection');
  my $query_text = $c->param('query') || '{}';
  my $limit      = $c->param('limit') || 10;
  my $skip       = $c->param('skip')  || 0;
  my $query = eval { from_json($query_text) } // {};
  my $path = "/$db/$collection";
  my %params = ( limit => $limit, skip => $skip );
  my $res = $c->bff_get($path, \%params);
  my $result = $res->is_success ? to_json($res->json, { pretty => 1 }) : "Error: " . $res->message;
  $c->stash(result => $result);
  $c->render(template => 'single_query');
};

# Handle cross-collection query form submission
get '/perform_cross_query' => sub {
  my $c = shift;
  my $db           = $c->param('db');
  my $collection1  = $c->param('collection1');
  my $id           = $c->param('id');
  my $collection2  = $c->param('collection2');
  my $limit        = $c->param('limit') || 10;
  my $skip         = $c->param('skip')  || 0;
  my $path = "/$db/cross/$collection1/$id/$collection2";
  my %params = ( limit => $limit, skip => $skip );
  my $res = $c->bff_get($path, \%params);
  my $result = $res->is_success ? to_json($res->json, { pretty => 1 }) : "Error: " . $res->message;
  $c->stash(result => $result);
  $c->render(template => 'cross_query');
};

# Display help page
get '/help' => sub {
  my $c = shift;
  $c->render(template => 'help');
};

app->start;
