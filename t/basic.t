use 5.008001;
use strict;
use warnings;
use Cwd qw/abs_path/;
use File::Copy qw/copy/;
use Test::More;

# make Capture::Tiny optional
BEGIN {
    my $class = "Capture::Tiny"; # hide from scanners
    eval "use $class 'capture'"; ## no critic
    if ($@) {
        *capture = sub(&) {
            diag "START SUBTEST OUTPUT";
            shift->();
            diag "END SUBTEST OUTPUT";
            return '(not captured)';
        };
    }
}

# dogfood
use Test::TempDir::Tiny;

plan tests => 10;

my $cwd  = abs_path('.');
my $lib  = abs_path('lib');
my $perl = abs_path($^X);

# default directory
my $dir  = tempdir();
my $root = Test::TempDir::Tiny::_root_dir();
ok( -d $root, "root dir exists" );
like( $dir, qr{$root/t_basic_t/default_1$}, "default directory created" );

my $dir2 = tempdir();
like( $dir2, qr{$root/t_basic_t/default_2$}, "second default directory created" );

# non-word chars
my $bang = tempdir("!!bang!!");
like( $bang, qr{$root/t_basic_t/_bang__1$}, "!!bang!! directory created" );

# set up pass/fail dirs
my $passing = tempdir("passing");
mkdir "$passing/t";
copy "corpus/01-pass.t", "$passing/t/01-pass.t";
like( $passing, qr{$root/t_basic_t/passing_1$}, "passing directory created" );

my $failing = tempdir("failing");
mkdir "$failing/t";
copy "corpus/01-fail.t", "$failing/t/01-fail.t" or die $!;
like( $failing, qr{$root/t_basic_t/failing_1$}, "failing directory created" );

# passing

chdir $passing;
my ( $out, $err, $rc ) = capture {
    system( $perl, "-I$lib", qw/-MTest::Harness -e runtests(@ARGV)/, 't/01-pass.t' )
};
chdir $cwd;

ok( !-d "$passing/tmp/t_01-pass_t", "passing test directory was cleaned up" )
  or diag "OUT: $out";
ok( !-d "$passing/tmp", "passing root directory was cleaned up" );

# failing

chdir $failing;
( $out, $err, $rc ) = capture {
    system( $perl, "-I$lib", qw/-MTest::Harness -e runtests(@ARGV)/, 't/01-fail.t' )
};
chdir $cwd;

ok( -d "$failing/tmp/t_01-fail_t", "failing test directory was not cleaned up" )
  or diag "OUT: $out";
ok( -d "$failing/tmp", "failing root directory was not cleaned up" );

# COPYRIGHT

# vim: ts=4 sts=4 sw=4 et:
