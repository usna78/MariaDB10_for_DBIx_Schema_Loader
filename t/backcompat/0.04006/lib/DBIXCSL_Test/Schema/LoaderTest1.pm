package DBIXCSL_Test::Schema::LoaderTest1;
use strict;
use warnings;

sub loader_test1_classmeth { 'all is well' }

sub loader_test1_rsmeth : ResultSet { 'all is still well' }

1;
