#!/usr/bin/perl

use warnings;
use strict;

use Test::More;

use ReconciliationReport;

my $test_report = ReconciliationReport->new();
isa_ok($test_report, 'ReconciliationReport');

my $client1_trade_set = ClientTradeSet->new();
$client1_trade_set->trades_file( new IO::File );
$client1_trade_set->trades_file->open("< ./t/data/client1_trades.tsv")
    || die "could not open client 1's trade file: $!";
is($client1_trade_set->parse_trade_file, 0, "Parses first OK");

# client 2
my $client2_trade_set = ClientTradeSet->new();
$client2_trade_set->trades_file( new IO::File );
$client2_trade_set->trades_file->open("< ./t/data/client2_trades.tsv")
    || die "could not open client 2's trade file: $!";
is($client2_trade_set->parse_trade_file, 0, "Parses second OK");

$client1_trade_set->trades_file->close();
$client2_trade_set->trades_file->close();

my $report = ReconciliationReport->new();
$report->client1_trade_set($client1_trade_set);
$report->client2_trade_set($client2_trade_set);
is($report->trade_match, 0, "Trade matching ran OK");
is($report->trade_quantity_match_check, 0, "Trade quantity matching ran OK");
is($report->match_returns, 0, "Matching returns ran OK");

is($report->trade_and_return_report, 0, "Ran reporting OK");







done_testing();