#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 42;

BEGIN {
    use_ok('Net::FastCGI::Util', ':predicate');
}

sub TRUE  () { !!1 };
sub FALSE () { !!0 };

foreach my $test ( undef, {}, [], \"", *STDIN, \*STDIN ) {
    is(  is_octets($test),       FALSE,    qq/is_octets(@{[ defined($test) ? $test : 'undef' ]})/    );
    is(  is_octets_le($test, 1), FALSE, qq/is_octets_le(@{[ defined($test) ? $test : 'undef' ]}, 1)/ );
    is(  is_octets_ge($test, 1), FALSE, qq/is_octets_ge(@{[ defined($test) ? $test : 'undef' ]}, 1)/ );
}

foreach my $test ( "", "foo", 0, 1, 1.1 ) {
    is(  is_octets($test),        TRUE,    qq/is_octets($test)/     );
    is(  is_octets_le($test, 10), TRUE, qq/is_octets_le($test, 10)/ );
    is(  is_octets_ge($test, 0),  TRUE, qq/is_octets_ge($test, 0)/  );

    if ( length($test) == 1 ) {
        is(  is_octets_le($test, 1),   TRUE, qq/is_octets_le($test, 1)/  );
        is(  is_octets_ge($test, 1),   TRUE, qq/is_octets_ge($test, 1)/  );
        is(  is_octets_le($test, 0),  FALSE, qq/is_octets_le($test, 0)/  );
        is(  is_octets_ge($test, 2),  FALSE, qq/is_octets_ge($test, 2)/  );
    }
}
