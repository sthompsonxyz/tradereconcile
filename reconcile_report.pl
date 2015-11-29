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

p $report;

#	if has check quantity
#		if eq no probs, just store matched returns
#		if quantity diff ask lesser quantity client for diff

# report summary
print "Matched Trades:\n";
my @client_1_matched_trades = @{ $report->matched_trades->{client1} };
my @client_2_matched_trades = @{ $report->matched_trades->{client2} };
print
    "Client\tClient Ref\tQuantity\tSecurity\tSecurity\tQuantity\tClient Ref\tClient\n";
for ( my $i = 0; $i < ( scalar @client_1_matched_trades ); $i++ ) {

    print $client_1_matched_trades[$i]->client . "\t"
        . $client_1_matched_trades[$i]->client_reference . "\t"
        . $client_1_matched_trades[$i]->quantity . "\t\t"
        . $client_1_matched_trades[$i]->security . "\t"
        . $client_2_matched_trades[$i]->security . "\t"
        . $client_2_matched_trades[$i]->quantity . "\t\t"
        . $client_2_matched_trades[$i]->client_reference . "\t"
        . $client_2_matched_trades[$i]->client . "\n";

}

my @client_1_unmatched_trades = @{ $report->unmatched_trades->{client1} };
my @client_2_unmatched_trades = @{ $report->unmatched_trades->{client2} };
for ( my $i = 0; $i < ( scalar @client_1_unmatched_trades ); $i++ ) {
    print "unmatched\n";
}

for ( my $i = 0; $i < ( scalar @client_2_unmatched_trades ); $i++ ) {
    print "unmatched\n";
}

my @client_1_matched_returns = @{ $report->matched_returns->{client1} };
my @client_2_matched_returns = @{ $report->matched_returns->{client2} };

print "Unbalanced Returns: \n";
for ( my $i = 0; $i < ( scalar @client_1_matched_returns ); $i++ ) {

    print $client_1_matched_returns[$i]->client . "\t"
        . $client_1_matched_returns[$i]->client_reference . "\t"
        . $client_1_matched_returns[$i]->parent . "\t"
        . $client_1_matched_returns[$i]->quantity . "\t\t"
        . $client_1_matched_returns[$i]->security . "\t"
        . $client_2_matched_returns[$i]->security . "\t"
        . $client_2_matched_returns[$i]->quantity . "\t\t"
        . $client_2_matched_returns[$i]->client_reference . "\t"
        . $client_2_matched_returns[$i]->parent . "\t"
        . $client_2_matched_returns[$i]->client . "\n";

    my $client1_quantity = $client_1_matched_returns[$i]->quantity;
    my $client2_quantity = $client_2_matched_returns[$i]->quantity;
    my $security         = $client_1_matched_returns[$i]->security;
    if ( $client1_quantity > $client2_quantity ) {
        my $client2_return_ref
            = $client_2_matched_returns[$i]->client_reference;
        print
            "Client 2 supplied $client2_quantity of $security expected $client1_quantity
             on return $client2_return_ref\n";
    }
    elsif ( $client1_quantity < $client2_quantity ) {
        my $client1_return_ref
            = $client_1_matched_returns[$i]->client_reference;
        print
            "Client 1 supplied $client1_quantity of $security expected $client2_quantity
             on return $client1_return_ref\n";
    }

    else {

        #returns are matched in quantity, no report required
    }
}

print "Missing returns:\n";
my @client_1_unmatched_returns = @{ $report->unmatched_returns->{client1} };
my @client_2_unmatched_returns = @{ $report->unmatched_returns->{client2} };

for ( my $i = 0; $i < ( scalar @client_1_unmatched_returns ); $i++ ) {

    my $quantity = $client_1_unmatched_returns[$i]->quantity;
    my $security = $client_1_unmatched_returns[$i]->security;

    print "Client 2 is missing a return of $quantity for $security\n";

}

for ( my $i = 0; $i < ( scalar @client_2_unmatched_returns ); $i++ ) {

    my $quantity = $client_2_unmatched_returns[$i]->quantity;
    my $security = $client_2_unmatched_returns[$i]->security;

    print "Client 1 is missing a return of $quantity for $security\n";
}
