#!/usr/bin/perl

use warnings;
use strict;

use Test::More;

use TradeLine;
use ClientTradeSet;

my $test_set = ClientTradeSet->new();
isa_ok( $test_set, 'ClientTradeSet' );

$test_set->trades_file( new IO::File );
$test_set->trades_file->open("< ./client1_trades.tsv")
    || die "could not open client 1's trade file: $!";
is($test_set->parse_trade_file, 0, "parsed file OK");


my $client_parsed_trade_line = $test_set->trades->[0];

is($client_parsed_trade_line->client, 'C1', "parsed client OK");
is($client_parsed_trade_line->trade_or_return, 'T', "parsed line type OK");
is($client_parsed_trade_line->client_reference, 'ABC12345', "parsed client reference OK");
is($client_parsed_trade_line->security, 'US012345678', "parsed security OK");
is($client_parsed_trade_line->quantity, 1000, "parsed quantity OK");
is($client_parsed_trade_line->parent, '', "parsed parent OK");




done_testing();
