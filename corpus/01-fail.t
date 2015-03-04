use strict;
use warnings;
use Test::More;
use Test::TempDir::Tiny;

sub _unixify {
    (my $path = shift) =~ s{\\}{/}g;
    return $path;
}

my @cases = (
    [ undef, 'default_1' ],
    [ 'label'        => 'label_1' ],
    [ 'label'        => 'label_2' ],
    [ 'with.*!$crud' => 'with_crud_1' ],
);

plan tests => 1 + @cases;

for my $c (@cases) {
    my ( $input, $dir ) = @$c;
    my $got    = tempdir($input);
    my $expect = "t_01-fail_t/$dir";
    like( _unixify($got), qr/\Q$expect\E$/, "$dir" );
}

fail("just give up already, OK");

# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
