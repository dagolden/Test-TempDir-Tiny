use strict;
use warnings;
use Test::More;
use Test::TempDir::Tiny;

my @cases = (
    [ undef, 'default_1' ],
    [ 'label'        => 'label_1' ],
    [ 'label'        => 'label_2' ],
    [ 'with.*!$crud' => 'with_crud_1' ],
);

plan tests => scalar @cases;

for my $c (@cases) {
    my ( $input, $dir ) = @$c;
    my $got    = tempdir($input);
    my $expect = "t_01-pass_t/$dir";
    like( $got, qr/\Q$expect\E$/, "$dir" );
}

# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
