package ReconciliationReport;

use TradeLine;
use ClientTradeSet;
use Moose;

use DDP;

has client1_trade_set => ( is => 'rw', isa => 'ClientTradeSet' );
has client2_trade_set => ( is => 'rw', isa => 'ClientTradeSet' );

has matched_trades => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { client1 => [], client2 => [] } }
);

has matched_returns => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { client1 => [], client2 => [] } }
);

has unmatched_trades => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { client1 => [], client2 => [] } }
);

has unmatched_returns => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { client1 => [], client2 => [] } }
);

sub trade_match {
    my ($self) = @_;

    my $client1_trades = $self->client1_trade_set->trades;
    my $client2_trades = $self->client2_trade_set->trades;

    # match trades by security name
    for ( my $i = 0; $i < scalar @{$client1_trades}; $i++ ) {

        for ( my $j = 0; $j < scalar @{$client2_trades}; $j++ ) {

            if ( $client1_trades->[$i]->security eq
                $client2_trades->[$j]->security )
            {
                my $matched_trade1 = TradeLine->new;
                $matched_trade1 = $client1_trades->[$i];
                my $matched_trade2 = $client2_trades->[$j];

                push @{ $self->matched_trades->{client1} }, $matched_trade1;
                push @{ $self->matched_trades->{client2} }, $matched_trade2;

            }

        }

    }

    return 0;
}

sub trade_quantity_match_check {
    my ($self) = @_;

    for (
        my $i = 0;
        $i < ( scalar @{ $self->matched_trades->{client1} } );
        $i++
        )
    {
        my $client1_quantity
            = $self->matched_trades->{client1}->[$i]->quantity;
        my $client2_quantity
            = $self->matched_trades->{client2}->[$i]->quantity;
        my $security = $self->matched_trades->{client1}->[$i]->security;
        if ( $client2_quantity > $client1_quantity ) {
            my $client1_trade_ref
                = $self->matched_trades->{client1}->[$i]->client_reference;
            print "inform client 1 they are missing "
                . ( $client2_quantity - $client1_quantity )
                . "of $security on trade $client1_trade_ref\n";
        }
        elsif ( $client1_quantity > $client2_quantity ) {
            my $client2_trade_ref
                = $self->matched_trades->{client2}->[$i]->client_reference;
            print "inform client 2 they are missing "
                . ( $client1_quantity - $client2_quantity )
                . "of $security on trade $client2_trade_ref\n";
        }
        else {

            # balanced, no problem
        }

    }

    return 0;
}

sub match_returns {
    my ($self) = @_;

    my $client1_trade_set = $self->client1_trade_set;
    my $client2_trade_set = $self->client2_trade_set;
    my @matched_return_securities;

    # foreach return:
    for ( my $i = 0; $i < ( scalar @{ $client1_trade_set->returns } ); $i++ )
    {
        for (
            my $j = 0;
            $j < ( scalar @{ $client1_trade_set->trades } );
            $j++
            )
        {

            #  find parent trade
            if ( $client1_trade_set->returns->[$i]->parent eq
                $client1_trade_set->trades->[$j]->client_reference )
            {

                #   see if corresponding client's trade has return
                my $client_2_trade = $client2_trade_set->trades->[$j];
                my $matched_return;
                for (
                    my $k = 0;
                    $k < ( scalar @{ $client2_trade_set->returns } );
                    $k++
                    )
                {
                    if ( $client2_trade_set->returns->[$k]->parent eq
                        $client_2_trade->client_reference )
                    {
                        $matched_return = $client2_trade_set->returns->[$k];
                    }

                    if ($matched_return) {
                        my $matched_client1_return = TradeLine->new();
                        $matched_client1_return
                            = $client1_trade_set->returns->[$i];
                        push @{ $self->matched_returns->{client1} },
                            $matched_client1_return;
                        my $matched_client2_return = TradeLine->new();
                        $matched_client2_return = $matched_return;
                        push @{ $self->matched_returns->{client2} },
                            $matched_client2_return;
                        push @matched_return_securities,
                            $matched_return->security;
                    }
                    else {

                        #   if not report missing return requirements
                        push @{ $self->unmatched_returns->{client2} },
                            {
                            clientref => $client2_trade_set->trades->[$j]
                                ->client_reference,
                            security =>
                                $client2_trade_set->trades->[$j]->security,
                            quantity =>
                                $client1_trade_set->returns->[$i]->quantity,
                            };
                    }
                }
            }

        }
    }

    # foreach return:
    for ( my $i = 0; $i < ( scalar @{ $client2_trade_set->returns } ); $i++ )
    {
        next
            if $client2_trade_set->returns->[$i]->security ~~
                @matched_return_securities;
        for (
            my $j = 0;
            $j < ( scalar @{ $client2_trade_set->trades } );
            $j++
            )
        {

            #  find parent trade
            if ( $client2_trade_set->returns->[$i]->parent eq
                $client2_trade_set->trades->[$j]->client_reference )
            {

                #   see if corresponding client's trade has return
                my $client_1_trade = $client1_trade_set->trades->[$j];
                my $matched_return;
                for (
                    my $k = 0;
                    $k < ( scalar @{ $client1_trade_set->returns } );
                    $k++
                    )
                {
                    if ( $client1_trade_set->returns->[$k]->parent eq
                        $client_1_trade->client_reference )
                    {
                        $matched_return = $client1_trade_set->returns->[$k];
                    }
                }
                if ($matched_return) {
                    my $matched_client2_return = TradeLine->new();
                    $matched_client2_return
                        = $client2_trade_set->returns->[$i];
                    push @{ $self->matched_returns->{client2} },
                        $matched_client2_return;
                    my $matched_client1_return = TradeLine->new();
                    $matched_client1_return = $matched_return;
                    push @{ $self->matched_returns->{client1} },
                        $matched_client1_return;
                    push @{ $self->matched_return_securities },
                        $matched_return->security;
                }
                else {

                    #   if not report missing return
                    push @{ $self->unmatched_returns->{client2} },
                        {
                        clientref => $client1_trade_set->trades->[$j]
                            ->client_reference,
                        security =>
                            $client1_trade_set->trades->[$j]->security,
                        quantity =>
                            $client2_trade_set->returns->[$i]->quantity,
                        };
                }

            }

        }
    }

    return 0;

}

sub trade_and_return_report {
    my ($self) = @_;

    # report summary
    my @client_1_matched_trades = @{ $self->matched_trades->{client1} };
    my @client_2_matched_trades = @{ $self->matched_trades->{client2} };
    if ( @client_1_matched_trades || @client_2_matched_trades ) {
        print "Matched Trades:\n";
    }
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

    my @client_1_matched_returns = @{ $self->matched_returns->{client1} };
    my @client_2_matched_returns = @{ $self->matched_returns->{client2} };

    if ( @client_1_matched_returns || @client_2_matched_returns ) {
        print "Unbalanced Returns: \n";
    }
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
                "Client 2 supplied $client2_quantity of $security expected $client1_quantity on return $client2_return_ref\n";
        }
        elsif ( $client1_quantity < $client2_quantity ) {
            my $client1_return_ref
                = $client_1_matched_returns[$i]->client_reference;
            print
                "Client 1 supplied $client1_quantity of $security expected $client2_quantity on return $client1_return_ref\n";
        }

        else {

            #returns are matched in quantity, no report required
        }
    }

    my @client_1_unmatched_returns = @{ $self->unmatched_returns->{client1} };
    my @client_2_unmatched_returns = @{ $self->unmatched_returns->{client2} };
    if ( @client_1_unmatched_returns || @client_2_unmatched_returns ) {
        print "Missing returns:\n";
    }
    for ( my $i = 0; $i < ( scalar @client_1_unmatched_returns ); $i++ ) {

        my $quantity = $client_1_unmatched_returns[$i]->{quantity};
        my $security = $client_1_unmatched_returns[$i]->{security};
        my $client_reference = $client_1_unmatched_returns[$i]->{clientref};

        print "Client 1 is missing a return of $quantity for security: $security client 1 ref: $client_reference\n";
   
    }

    for ( my $i = 0; $i < ( scalar @client_2_unmatched_returns ); $i++ ) {

        my $quantity = $client_2_unmatched_returns[$i]->{quantity};
        my $security = $client_2_unmatched_returns[$i]->{security};
        my $client_reference = $client_2_unmatched_returns[$i]->{clientref};

        print "Client 2 is missing a return of $quantity for security: $security client 2 ref: $client_reference\n";
    }


    return 0;
}

__PACKAGE__->meta->make_immutable;

