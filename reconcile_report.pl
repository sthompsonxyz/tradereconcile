#!/usr/bin/perl

use warnings;
use strict;

use ReconciliationReport;

use DDP;

# trade reconciliation process

# load data files and parse their contents
# into suitable in memory data structs
# (assume tab separated?)
# client 1
my $client1_trade_set = ClientTradeSet->new();
$client1_trade_set->trades_file( new IO::File );
$client1_trade_set->trades_file->open("< ./client1_trades.tsv")
    || die "could not open client 1's trade file: $!";
$client1_trade_set->parse_trade_file;

# client 2
my $client2_trade_set = ClientTradeSet->new();
$client2_trade_set->trades_file( new IO::File );
$client2_trade_set->trades_file->open("< ./client2_trades.tsv")
    || die "could not open client 2's trade file: $!";
$client2_trade_set->parse_trade_file;

$client1_trade_set->trades_file->close();
$client2_trade_set->trades_file->close();

# create reconciliation report and add ClientTradeSets
my $report = ReconciliationReport->new();
$report->client1_trade_set($client1_trade_set);
$report->client2_trade_set($client2_trade_set);
$report->trade_match;

# identify client with smaller quantity and report the
# quantity they should have to meet difference
$report->trade_quantity_match_check;

# report trades where one side is missing a return
# (which has been reported by counter party)
$report->match_returns;

#p $report;

# report summary
$report->trade_and_return_report;

