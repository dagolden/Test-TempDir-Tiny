use 5.008001;
use strict;
use warnings;

package Test::TempDir::Tiny;
# ABSTRACT: Temporary directories that stick around when tests fail

our $VERSION = '0.001';

use Exporter 5.57 qw/import/;
our @EXPORT = qw/tempdir/;

use Carp qw/croak/;
use Cwd qw/abs_path/;
use File::Path 2.01 qw/remove_tree/;
use File::Temp;

my ( $ROOT_DIR, $TEST_DIR, %COUNTER );
my ( $ORIGINAL_PID, $ORIGINAL_CWD ) = ( $$, abs_path(".") );

=func tempdir

    $dir = tempdir();          # .../default_1/
    $dir = tempdir("label");   # .../label_1/
    $dir = tempdir("label");   # .../label_2/
    $dir = tempdir("a space"); # .../a_space_1/

Creates a directory underneath a test-file-specific temporary directory and
returns the absolute path to it.

The function takes a single argument as a label for the directory or defaults
to "default".  The label will have everything except alphanumerics, underscore
and dash replaced with underscore and then a counter value will be appended.
This allows use of a labeled directory in loops:

    for ( 1 .. 3 ) {
        tempdir("in loop");
    }

    # creates:
    #   .../in_loop_1
    #   .../in_loop_2
    #   .../in_loop_3

The test-file-specific directory will be cleaned up with an END block if the
current test file is passing.

=cut

sub tempdir {
    my $label = defined( $_[0] ) ? $_[0] : 'default';
    $label =~ tr{a-zA-Z0-9_-}{_}cs;

    _init() unless $ROOT_DIR && $TEST_DIR;
    my $suffix = ++$COUNTER{$label};
    my $subdir = "$TEST_DIR/${label}_${suffix}";
    mkdir $subdir or die $!;
    return $subdir;
}

sub _init {
    # ROOT_DIR is t/tmp or a File::Temp object
    if ( -w 't' ) {
        $ROOT_DIR = abs_path('t/tmp');
        if ( -e $ROOT_DIR ) {
            croak("$ROOT_DIR is not a directory")
              unless -d $ROOT_DIR;
        }
        else {
            mkdir $ROOT_DIR or die $!;
        }
    }
    else {
        $ROOT_DIR = File::Temp->newdir( TMPDIR => 1 );
    }

    # TEST_DIR is based on .t path under ROOT_DIR
    ( my $dirname = $0 ) =~ tr{\\/.}{_};
    $TEST_DIR = "$ROOT_DIR/$dirname";
    if ( !-d $TEST_DIR ) {
        mkdir $TEST_DIR or die $!;
    }
    else {
        remove_tree( $TEST_DIR, { safe => 0, keep_root => 1 } );
    }
    return;
}

sub _cleanup {
    # A File::Temp::Dir ROOT_DIR always gets to clean itself up
    if ( $ROOT_DIR && !ref $ROOT_DIR && -d $ROOT_DIR ) {
        if ( not $? ) {
            chdir $ORIGINAL_CWD;
            remove_tree( $TEST_DIR, { safe => 0 } ) if -d $TEST_DIR;
        }
        # will fail if there are any children, but we don't care
        rmdir $ROOT_DIR;
    }
}

# for testing
sub _root_dir { return $ROOT_DIR }

END {
    # only clean up in original process, not children
    if ( $$ == $ORIGINAL_PID ) {
        # our clean up must run after Test::More sets $? in its END block
        require B;
        push @{ B::end_av()->object_2svref }, \&_cleanup;
    }
}

1;

=head1 SYNOPSIS

    # t/foo.t
    use Test::More;
    use Test::TempDir::Tiny;

    $dir = tempdir();          # ./tmp/t_foo_t/default_1/
    $dir = tempdir("label");   # ./tmp/t_foo_t/label_1/
    $dir = tempdir("label");   # ./tmp/t_foo_t/label_2/

=head1 DESCRIPTION

This module works with L<Test::More> to create temporary directories that stick
around if tests fail.

It is loosely based on L<Test::TempDir>, but with less complexity, greater
portability and zero non-core dependencies.

The L</tempdir> function is exported by default.  When called, it constructs a
directory tree to hold temporary directories.

If the F<t> directory is writable, the root for directories will be F<t/tmp>.
Otherwise, a L<File::Temp> directory will be created wherever temporary
directories are stored for your system.

Every F<*.t> file gets its own subdirectory under the root based on the test
filename, but with slashes and periods replaced with underscores.  For example,
F<t/foo.t> would get a test-file-specific subdirectory F<t/tmp/t_foo_t/>.
Directories created by L</tempdir> get put in that directory.  This makes it
very easy to find files later if tests fail.

When the test file exits, if all tests passed, then the test-file-specific
directory is recursively removed.

If test failed and the root directory is F<t/tmp>, the test-file-specific
directory sticks around for inspection.  (But if the root is a L<File::Temp>
directory, it is always discarded).

If nothing is left in F<t/tmp> (i.e. no other tests failed), then F<t/tmp>
is cleaned up as well.

=head1 SEE ALSO

=for :list
* L<File::Temp>
* L<Path::Tiny>

=cut

# vim: ts=4 sts=4 sw=4 et:
