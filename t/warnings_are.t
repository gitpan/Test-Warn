#!/usr/bin/perl

use strict;
use warnings;

use Carp;

use constant SUBTESTS_PER_TESTS  => 8;

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
sub _make_warn {
    warn $_ for @_;
}

use constant CARP_LINE => line_num +2;
sub _make_carp {
    carp $_ for @_;
}

my $i = 0;
test_warnings_are(@$_) foreach TESTS();

sub test_warnings_are {
    my ($ok, $msg, $exp_warning, $testname) = @_;
    for my $do_carp (0,1) {
        *_found_msg         = $do_carp ? *_found_carp_msg : *_found_warn_msg;
        *_exp_msg           = $do_carp ? *_exp_carp_msg   : *_exp_warn_msg;
        *_make_warn_or_carp = $do_carp ? *_make_carp      : *_make_warn;
        for my $t (undef, $testname) {
            for my $is_or_are (qw/is are/) {
                test_out "$ok 1" . ($t ? " - $t" : "");
                if ($ok =~ /not/) {
                    test_fail +5;
                    test_diag  _found_msg(@$msg);
                    test_diag  _exp_msg(@$exp_warning);
                }
                my $ew = $do_carp ? [map { +{carped => $_} } @$exp_warning ] : $exp_warning;
                $is_or_are eq 'is' ? warning_is {_make_warn_or_carp(@$msg)} $ew, $t : warnings_are {_make_warn_or_carp(@$msg)} $ew, $t;
                test_test  "$testname (with" . ($_ ? "" : "out") . " a testname)";
            }
        }
    }
}

sub _found_warn_msg {
    @_ ? map({"found warning: $_ at ". __FILE__ . " line " . WARN_LINE . "." } @_)
       : "didn't found a warning";
}

sub _found_carp_msg {
    @_ ? map({"found carped warning: $_ at ". __FILE__ . " line " . CARP_LINE} @_)
       : "didn't found a warning";
}


sub _exp_warn_msg {
    @_ ? map({"expected to find warning: $_" } @_)
       : "didn't expect to find a warning";
}

sub _exp_carp_msg {
    @_ ? map({"expected to find carped warning: $_" } @_)
       : "didn't expect to find a warning";
}
