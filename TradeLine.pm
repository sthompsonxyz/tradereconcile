
package TradeLine;

use Moose;

has client           => ( is => 'rw', isa => 'Str', default => '' );
has trade_or_return  => ( is => 'rw', isa => 'Str', default => '' );
has client_reference => ( is => 'rw', isa => 'Str', default => '' );
has security         => ( is => 'rw', isa => 'Str', default => '' );
has quantity         => ( is => 'rw', isa => 'Int', default => 0 );
has parent           => ( is => 'rw', isa => 'Str', default => '' )
    ;    #could be another TradeLine

__PACKAGE__->meta->make_immutable;

