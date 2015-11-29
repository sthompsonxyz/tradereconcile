package ClientTradeSet;

use Moose;
use IO::File;
use TradeLine;

has trades_file => ( is => 'rw', isa => 'IO::File' );
has parse_errors => ( is => 'rw', isa => 'Str',      default => '' );
has trades       => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has returns      => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub parse_trade_file {
    my ($self) = @_;

    my $fh = $self->trades_file;

    while (<$fh>) {
        chomp $_;
        my @trade_line_fields = split "\t", $_;

        # ignore header
        next if $trade_line_fields[0] eq 'Client';

        my $client_trade_line = TradeLine->new();

        # todo: error/format checking per line (type checking caught by moose)
        $client_trade_line->client( $trade_line_fields[0] );
        $client_trade_line->trade_or_return( $trade_line_fields[1] );
        $client_trade_line->client_reference( $trade_line_fields[2] );
        $client_trade_line->security( $trade_line_fields[3] );
        $client_trade_line->quantity( int( $trade_line_fields[4] ) );
        $client_trade_line->parent( $trade_line_fields[5] )
            if $trade_line_fields[5];

        if ( $client_trade_line->trade_or_return eq 'T' ) {

            push @{ $self->trades }, $client_trade_line;
        }
        elsif ( $client_trade_line->trade_or_return eq 'R' ) {
            push @{ $self->returns }, $client_trade_line;
        }
    }



    return 0;    
}

__PACKAGE__->meta->make_immutable;
