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
use Test::Builder;

my ( $root_dir, $test_dir );

my %COUNTER;

=func tempdir

    $dir = tempdir();          # .../default_1/
    $dir = tempdir("label");   # .../label_1/
    $dir = tempdir("label");   # .../label_2/
    $dir = tempdir("a space"); # .../a_space_1/

Creates a directory underneath a test-file-specific temporary directory and
returns the absolute path to it.

The function takes a single argument as a label for the directory or defaults
to "default".  The label will have everything except C<<[a-zA-Z0-9_=]>>
replaced with '_' and then an incrementing counter value will be appended.
This allows use of a labeled directory in loops:

    for ( 1 .. 3 ) {
        tempdir("in loop");
    }

    # creates:
    #   .../in_loop_1
    #   .../in_loop_2
    #   .../in_loop_3

The test-file-specific directory will be cleaned up in and END block if the
current test file is passing.

=cut

sub tempdir {
    my $label = @_ ? shift : 'default';
    $label =~ tr{a-zA-Z0-9_-}{_}cs;

    _init() unless $root_dir && $test_dir;
    my $suffix = ++$COUNTER{$label};
    my $subdir = "$test_dir/${label}_${suffix}";
    mkdir $subdir or die $!;
    return $subdir;
}

sub _init {
    # root_dir is t/tmp or a File::Temp object
    if ( -w 't' ) {
        $root_dir = abs_path('t/tmp');
        if ( -e $root_dir ) {
            croak("$root_dir is not a directory")
              unless -d $root_dir;
        }
        else {
            mkdir $root_dir or die $!;
        }
    }
    else {
        $root_dir = File::Temp->newdir( TMPDIR => 1 );
    }

    # test_dir is based on .t path under root_dir
    ( my $dirname = $0 ) =~ tr{\\/.}{_};
    $test_dir = "$root_dir/$dirname";
    if ( !-d $test_dir ) {
        mkdir $test_dir or die $!;
    }
    else {
        remove_tree( $test_dir, { safe => 0, keep_root => 1 } );
    }
    return;
}

END {
    # cleanup logic only if we have a non-File::Temp root
    if ( $root_dir && !ref $root_dir ) {
        my $tb = Test::Builder->new;
        if ( $tb->is_passing ) {
            remove_tree( $test_dir, { safe => 0 } ) if -d $test_dir;
        }
        # will fail if there are any children, but we don't care
        rmdir $root_dir;
    }
}

1;

=head1 SYNOPSIS

    use Test::TempDir::Tiny;

    $dir = tempdir();          # .../default_1/
    $dir = tempdir("label");   # .../label_1/
    $dir = tempdir("label");   # .../label_2/

=head1 DESCRIPTION

This module works with L<Test::More> to create temporary directories for
testing that stick around if tests fail.  It is loosely based on
L<Test::TempDir>, but with less complexity and zero non-core dependencies.  For
example, Test::TempDir::Tiny uses multiple subdirectories to allow parallel
testing without un-portable locking.

The L</tempdir> function is exported by default.  When called, it constructs a
directory tree to hold temporary directories.  If the F<t> directory is
writable, the root for directories will be F<t/tmp>.  Otherwise, a
L<File::Temp> directory will be created wherever temporary directories are
stored for your system.

Every F<*.t> file gets its own subdirectory under the root, based on the
filename, but with slashes and periods replaced with underscores.  For example,
F<t/foo.t> would get a test-file-specfic subdirectory F<t/tmp/t_foo_t/>.  Then
any directories created by L</tempdir> get put in that directory.  For example,
a plain C<tempdir()> call winds up as F<t/tmp/t_foo_t/default_1/>.  This makes
it very easy to find temporary files later.

If the root is F<t/tmp>, then when the test file exits, if all tests passed,
then the test-file-specific directory is recursively removed.  Otherwise, it
sticks around for inspection.

If nothing is left in F<t/tmp> (i.e. no other tests failed), then F<t/tmp>
is cleaned up as well.

=head1 SEE ALSO

=for :list
* L<File::Temp>
* L<Path::Tiny>

=cut

# vim: ts=4 sts=4 sw=4 et:
