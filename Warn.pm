package Test::Warn;

use 5.006;
use strict;
use warnings;

use Array::Compare;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    @EXPORT	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	   warning_is   warnings_are
       warning_like warnings_like
);

our $VERSION = '0.01';

use Test::Builder;
my $Tester = Test::Builder->new;

*warning_is = *warnings_are;

sub warnings_are (&$;$) {
    my $block       = shift;
    my $exp_warning = shift() || [];
    my @exp_warning = ref($exp_warning) eq 'ARRAY' ? @$exp_warning : ($exp_warning);
    my $testname    = shift;
    my @got_warning = ();
    local $SIG{__WARN__} = sub {push @got_warning, shift()};
    &$block;
    my $ok = Array::Compare->new()->compare(
        \@exp_warning, [map {m/^(.*) at \S+ line \d+\.$/s} @got_warning]
    );
    $Tester->ok( $ok, $testname );
    $ok or _diag_found_warning(@got_warning),
           _diag_exp_warning(@exp_warning);
    return $ok;
}

*warning_like = *warnings_like;

sub warnings_like (&$;$) {
    my $block       = shift;
    my $exp_warning = shift() || [];
    my @exp_warning = ref($exp_warning) eq 'ARRAY' ? @$exp_warning : ($exp_warning);
    my $testname    = shift;
    my @got_warning = ();
    local $SIG{__WARN__} = sub {push @got_warning, shift()};
    &$block;
    my $ok = _cmp_like( \@got_warning, \@exp_warning );
    $Tester->ok( $ok, $testname );
    $ok or _diag_found_warning(@got_warning),
           _diag_exp_warning(@exp_warning);
    return $ok;
}

sub _cmp_like {
    my @got  = @{ shift() };
    my @exp  = @{ shift() };
    scalar @got == scalar @exp or return 0;
    for (0 .. $#got) {
        my $re = $Tester->maybe_regex($exp[$_]) or die "'$exp[$_]' isn't a regex";
        return 0 unless $got[$_] =~ /$re/;
    }
    return 1;
}

sub _diag_found_warning {
    $Tester->diag( "found warning: $_" ) for @_;
    $Tester->diag( "didn't found a warning" ) unless @_;
}

sub _diag_exp_warning {
    $Tester->diag( "expected to find warning: $_" ) for @_;
    $Tester->diag( "didn't expect to find a warning" ) unless @_;
}

1;
__END__
=head1 NAME

Test::Warn - Perl extension to test methods for warnings

=head1 SYNOPSIS

  use Test::Warn;

  warning_is    {foo(-dri => "/")} "Unknown Parameter 'dri'", "dri != dir gives warning";
  warnings_are  {bar(1,1)} ["Width very small", "Height very small"];
  
  warning_is    {add(2,2)} undef, "No warning to calc 2+2"; # or
  warnings_are  {add(2,2)} [],    "No warning to calc 2+2"; # what reads better :-)
  
  warning_like  {foo(-dri => "/"} qr/unknown param/i, "an unknown parameter test";
  warnings_like {bar(1,1)} [qr/width.*small/i, qr/height.*small/i];
  
  [NOT IMPLEMENTED YET]
  warning_like {foo(undef)}                'uninitialized';
  warning_like {bar(file => '/etc/passwd'} 'io';

=head1 DESCRIPTION

This module provides a few convenience methods for testing warning based code.

If you are not already familiar with the Test::More manpage 
now would be the time to go take a look.

=head2 FUNCTIONS

=over 4

=item warning_is BLOCK STRING, TEST_NAME

Tests that BLOCK gives exactly the one specificated warning.
The test fails if the BLOCK warns more then one times or doesn't warn.
If the string is undef, 
then the tests succeeds iff the BLOCK doesn't give any warning.
Another way to say that there aren't ary warnings in the block,
is C<warnings_are {foo()} [], "no warnings in">.

Note: C<warn "foo"> would print something like C<foo at -e line 1>. 
This method ignores everything after the at. That means, to match this warning
you would have to call C<warning_is {warn "foo"} "foo", "Foo succeeded">.
If you need to test for a warning at an exactly line,
try better something like C<warning_like {warn "foo"} qr/at XYZ.dat line 5/>.

warning_is and warning_are are only aliases to the same method.
So you also could write
C<warning_is {foo()} [], "no warning"> or something similar.
I decided me to give two methods to have some better readable method names.

A true value is returned if the test succeeds, false otherwise.

The test name is optional, but recommended.


=item warnings_are BLOCK ARRAYREF, TEST_NAME

Tests to see that BLOCK gives exactly the specificated warnings.
The test fails if the BLOCK warns a different number than the size of the ARRAYREf
would have expected.
If the ARRAYREF is equal to [], 
then the test succeeds iff the BLOCK doesn't give any warning.

Please read also the notes to warning_is as these methods are only aliases.

=item warning_like BLOCK REGEXP, TEST_NAME

Tests that BLOCK gives exactly one warning and it can be matched to the given regexp.
If the string is undef, 
then the tests succeeds iff the BLOCK doesn't give any warning.

The REGEXP is matched after the whole warn line,
which consists in general of "WARNING at __FILE__ line __LINE__".
So you can check for a warning in at File Foo.pm line 5 with
C<warning_like {bar()} qr/at Foo.pm line 5/, "Testname">.
I don't know whether it's sensful to do such a test :-(
However, you should be prepared as a matching with 'at', 'file', '\d'
or similar will always pass. 
Think to the qr/^foo/ if you want to test for warning "foo something" in file foo.pl.

You can also write the regexp in a string as "/.../"
instead of using the qr/.../ syntax.
Note that the slashes are important in the string,
as strings without slashes are reserved for future versions
(to match warning categories as can be seen in the perllexwarn man page).

Similar to C<warning_is>/C<warnings_are>,
C<warning_like> and C<warnings_like> are only aliases to the same methods.

A true value is returned if the test succeeds, false otherwise.

The test name is optional, but recommended.

=item warnings_like BLOCK ARRAYREF, TEST_NAME

Tests to see that BLOCK gives exactly the number of the specificated warnings
and all the warnings have to match in the defined order to the 
passed regexes.

Please read also the notes to warning_like as these methods are only aliases.

=back

=head2 EXPORT

C<warning_is>,
C<warnings_are>,
C<warning_like>,
C<warnings_like> by default.

=head1 BUGS

This bad documentation, I'll make it better the next time.

I only tested it with the simple C<warn> function.
It should work also with C<Carp::carp> method,
but I think, there will be problems using <Carp::clucks> or
any other warning that gives a devel stack.

If a method has it's own warn handler,
overwriting C<$SIG{__WARN__}>,
my test warning methods won't get these warnings.

=head1 TODO

C<warning_like BLOCK CATEGORY, TEST_NAME>
where CATEGORY is a warning category defined in perllexwarn.

Similar methods for C<Carp::carp> and C<Carp::clucks>.

Will be soon done.

Please feel free to suggest me any improvements.

=head1 SEE ALSO

Have a look to the similar L<Test::Exception> module.

=head1 AUTHOR

Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Janek Schleicher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
