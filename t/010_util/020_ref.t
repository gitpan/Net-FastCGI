#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 20;

BEGIN {
    use_ok('Net::FastCGI::Util', ':predicate');
}

sub TRUE  () { !!1 };
sub FALSE () { !!0 };

foreach my $test ( undef, 0, 'STDOUT' ) {
    my $label = defined($test) ? $test : 'undef';
    is( is_cvref($test),  FALSE, qq/is_cvref($label) = false/);
    is( is_hvref($test),  FALSE, qq/is_hvref($label) = false/);
    is( is_handle($test), FALSE, qq/is_handle($label) = false/);
}

{
    my $test = sub {};
    is( is_cvref($test), TRUE, qq/is_cvref($test) = true/);
}

{
    my $test = bless( sub {}, 'BlessedSubRef' );
    is( is_cvref($test), FALSE, qq/is_cvref($test) = flase/);
}

{
    my $test = {};
    is( is_hvref($test), TRUE, qq/is_hvref($test) = true/);
}

{
    my $test = bless( {}, 'BlessedHvRef' );
    is( is_hvref($test), FALSE, qq/is_hvref($test) = flase/);
}

{
    require Symbol;

    my @tests = (
        Symbol::gensym(),
        Symbol::geniosym(),
        \*STDOUT, 
        \*STDIN, 
        *STDOUT{IO},
        *STDIN
    );

    foreach my $test ( @tests ) {
        is( is_handle($test), TRUE, qq/is_handle($test) = true/);
    }
}


