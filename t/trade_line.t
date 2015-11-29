#!/usr/bin/perl

use warnings;
use strict;

use Test::More;

use TradeLine;

my $test_line = TradeLine->new();

isa_ok($test_line, 'TradeLine');

$test_line->client('test client');
$test_line->trade_or_return('T');
$test_line->client_reference('ABC123');
$test_line->security('GB111222333');
$test_line->quantity(5000);
$test_line->parent('');

is( $test_line->client, 'test client', "client value works OK" );



done_testing();