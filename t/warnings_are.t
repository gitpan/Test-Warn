#!/usr/bin/perl

use strict;
use warnings;

use constant SUBTESTS_PER_TESTS  => 4;

use constant TESTS =>(
    [    "ok", ["my warning"], ["my warning"], "standard warning to find"],
    ["not ok", ["my warning"], ["another warning"], "another warning instead of my warning"],
    ["not ok", ["warning general not"], ["warning general"], "quite only a sub warning"],
    ["not ok", [], ["a warning"], "no warning, but expected one"],
    ["not ok", ["a warning"], [], "warning, but didn't expected on"],
    [    "ok", [], [], "no warning"],
    [    "ok", ['$!"%&/()='], ['$!"%&/()='], "warning with crazy letters"],
    ["not ok", ["warning 1","warning 2"], ["warning 1"], "more than one warning (1)"],
    ["not ok", ["warning 1","warning 2"], ["warning 2"], "more than one warning (2)"],
    [    "ok", ["warning 1","warning 2"], ["warning 1", "warning 2"], "more than one warning (standard ok)"],
    [    "ok", ["warning 1","warning 1"], ["warning 1", "warning 1"], "more than one warning (two similar warnings)"],
    ["not ok", ["warning 1","warning 2"], ["warning 2", "warning 1"], "more than one warning (different order)"],
    [    "ok", [('01' .. '99')], [('01' .. '99')], "many warnings ok"],
    ["not ok", [('01' .. '99')], [('01' .. '99'), '100'], "many, but diff. warnings"]
);

use Test::Builder::Tester tests  => TESTS() * SUBTESTS_PER_TESTS;
use Test::Warn;

Test::Builder::Tester::color 'on';

use constant WARN_LINE => line_num +2; 
sub make_warn {
    warn $_ for @{$_[0]};
}

my $i = 0;
test_warnings_are(@$_) for TESTS();

sub test_warnings_are {
    my ($ok, $msg, $exp_warning, $testname) = @_;
    for (undef, $testname) {
        for my $is_or_are (qw/is are/) {
            test_out "$ok 1" . ($_ ? " - $_" : "");
            if ($ok =~ /not/) {
                test_fail +4;
                test_diag  _found_warn_msg(@$msg);
                test_diag  _exp_warn_msg(@$exp_warning);
            }
            $is_or_are eq 'is' ? warning_is {make_warn($msg)} $exp_warning, $_ : warnings_are {make_warn($msg)} $exp_warning, $_;
            test_test  "$testname (with" . ($_ ? "" : "out") . " a testname)";
        }
    }
}

sub _found_warn_msg {
    @_ ? map({"found warning: $_ at ". __FILE__ . " line " . WARN_LINE . "." } @_)
       : "didn't found a warning";
}

sub _exp_warn_msg {
    @_ ? map({"expected to find warning: $_" } @_)
       : "didn't expect to find a warning";
}
