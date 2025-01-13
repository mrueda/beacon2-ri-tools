#!/usr/bin/env perl
#
#   Script that enables queries to MongoDB
#   Idea from https://gist.github.com/jshy/fa209c35d54551a70060 -> from Mojolicius Wiki.
#
#   Last Modified: Jan/11/2025
#
#   $VERSION from beacon2-ri-tools
#
#   Copyright (C) 2021-2025 Manuel Rueda (manuel.rueda@cnag.eu)

use Mojolicious::Lite;
use MongoDB;

# Helper to connect to MongoDB with multiple host fallbacks
helper mongo => sub {
    my $self = shift;
    my @hosts = (
        'mongodb://root:example@127.0.0.1:27017/beacon?authSource=admin',
        'mongodb://root:example@mongo:27017/beacon?authSource=admin',
        'mongodb://root:example@beacon_mongo_1:27017/beacon?authSource=admin',
    );
    my $client;
    foreach my $host (@hosts) {
        eval {
            $client = MongoDB::MongoClient->new(host => $host);
            $client->get_database('beacon')->run_command([ ping => 1 ]);
            $self->app->log->info("Connected to MongoDB at $host");
        };
        return $client unless $@;
        $self->app->log->warn("Failed to connect to MongoDB at $host: $@");
    }
    $self->app->log->error('ERROR: Could not connect to any MongoDB instance.');
    die 'ERROR: Could not connect to any MongoDB instance.';
};

# Helper for applying pagination parameters to a query
helper paginate => sub {
    my ($self, $cursor) = @_;
    my $limit = $self->param('limit') || 10;
    my $skip  = $self->param('skip')  || 0;
    return $cursor->skip($skip)->limit($limit);
};

# Helper for fetching items from collection with optional query criteria
helper fetch_items => sub {
    my ($self, $db, $collection, $query) = @_;
    $query ||= {};
    my $cursor = $self->mongo
                     ->get_database($db)
                     ->get_collection($collection)
                     ->find($query);
    $cursor = $self->paginate($cursor);
    my @items = map { $_->{_id} = $_->{_id}->value; $_ } $cursor->all;
    return @items;
};

####################
# Beacon v2 Models #
####################

# Get database names
any '/' => sub {
    my $self = shift;
    my @names = $self->mongo->database_names;
    $self->render(json => \@names);
};

# Get collections in a database
any [qw(GET)] => '/:db' => sub {
    my $self = shift;
    my @collections = $self->mongo
                           ->get_database($self->param('db'))
                           ->collection_names;
    $self->render(json => \@collections);
};

# Return collection items with pagination
get '/:db/:collection' => sub {
    my $self = shift;
    my ($db, $coll) = ($self->param('db'), $self->param('collection'));
    my @items = $self->fetch_items($db, $coll);
    $self->render(json => \@items);
};

# Return multiple records by /:key/:value with pagination
get '/:db/:collection/:key/:value' => sub {
    my $self      = shift;
    my ($db, $coll) = ($self->param('db'), $self->param('collection'));
    (my $key = $self->param('key')) =~ tr/_/./;
    my $value = $self->param('value');
    my @items = $self->fetch_items($db, $coll, { $key => $value });
    $self->render(json => \@items);
};

# Return multiple records by /:key1/:value1/:key2/:value2 with pagination
get '/:db/:collection/:key1/:value1/:key2/:value2' => sub {
    my $self      = shift;
    my ($db, $coll) = ($self->param('db'), $self->param('collection'));
    (my $key1 = $self->param('key1')) =~ tr/_/./;
    (my $key2 = $self->param('key2')) =~ tr/_/./;
    my $value1 = $self->param('value1');
    my $value2 = $self->param('value2');
    my @items = $self->fetch_items($db, $coll, { $key1 => $value1, $key2 => $value2 });
    $self->render(json => \@items);
};

# Cross-collection query with pagination
get '/:db/cross/:collection1/:id/:collection2' => sub {
    my $self      = shift;
    my ($db, $col1, $id, $col2) = ($self->param('db'), $self->param('collection1'), $self->param('id'), $self->param('collection2'));

    # Retrieve the first matching document from the first collection
    my $first = $self->mongo
                    ->get_database($db)
                    ->get_collection($col1)
                    ->find_one({ 'id' => $id });

    unless ($first) {
        return $self->render(json => { error => "No matching document found in $col1 with id $id" });
    }

    if ($col2 ne 'genomicVariations') {
        my $query = {
            '$or' => [
                { 'id'           => $first->{id} },
                { 'individualId' => $first->{id} }
            ]
        };
        my @items = $self->fetch_items($db, $col2, $query);
        $self->render(json => \@items);
    }
    else {
        my $cursor = $self->mongo
                        ->get_database($db)
                        ->get_collection($col2)
                        ->find({ 'caseLevelData.biosampleId' => $first->{id} });
        $cursor = $self->paginate($cursor);
        my @items;
        while (my $doc = $cursor->next) {
            push @items, $doc->{variantInternalId};
        }
        $self->render(json => \@items);
    }
};

app->start;
