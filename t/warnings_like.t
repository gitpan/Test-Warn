#!/usr/bin/perl

use strict;
use warnings;

use Test::Exception;


use constant TESTS =>(
    [    "ok", ["my warning"], ["my"], "standard warning to find"],
    ["not ok", ["my warning"], ["another"], "another warning instead of my warning"],
    ["not ok", ["warning general not"], ["^(?!warning general)"], "quite only a sub warning"],
    ["not ok", [], ["a warning"], "no warning, but expected one"],
    ["not ok", ["a warning"], [], "warning, but didn't expected on"],
    [    "ok", [], [], "no warning"],
    [    "ok", ['$!"%&/()='], ['\$\!\"\%\&\/\(\)\='], "warning with crazy letters"],
    ["not ok", ["warning 1","warning 2"], ["warning 1"], "more than one warning (1)"],
    ["not ok", ["warning 1","warning 2"], ["warning 2"], "more than one warning (2)"],
    [    "ok", ["warning 1","warning 2"], ["warning 1", "warning 2"], "more than one warning (standard ok)"],
    [    "ok", ["warning 1","warning 1"], ["warning 1", "warning 1"], "more than one warning (two similar warnings)"],
    ["not ok", ["warning 1","warning 2"], ["warning 2", "warning 1"], "more than one warning (different order)"],
    [    "ok", [('01' .. '99')], [('01' .. '99')], "many warnings ok"],
    ["not ok", [('01' .. '99')], [('01' .. '99'), '100'], "many, but diff. warnings"]
);
use constant SUBTESTS_PER_TESTS  => 8;

use constant EXTRA_TESTS         => 2;

use Test::Builder::Tester tests  => TESTS() * SUBTESTS_PER_TESTS + EXTRA_TESTS;
use Test::Warn;

Test::Builder::Tester::color 'on';

use constant WARN_LINE => line_num +2; 
sub make_warn {
    warn $_ for @{$_[0]};
}

test_warnings_like(@$_) for TESTS();
dies_ok {warnings_like {warn "1";} ["1"]} "no regexes used";
dies_ok {warnings_like {warn "1"; warn "2";} ["1","2"]} "no regexes used";


sub test_warnings_like {
    my ($ok, $msg, $exp_warning, $testname) = @_;
    for my $regexes ([map {qr/$_/} @$exp_warning], [map {"/$_/"} @$exp_warning]) {
        for (undef, $testname) {
            for my $is_or_are (qw/is are/) {
                test_out "$ok 1" . ($_ ? " - $_" : "");
                if ($ok =~ /not/) {
                    test_fail +4;
                    test_diag  _found_warn_msg(@$msg);
                    test_diag  _exp_warn_msg(@$regexes);
                }
                $is_or_are eq 'is' ? warning_like {make_warn($msg)} $regexes, $_ : warnings_like {make_warn($msg)} $regexes, $_;
                test_test  "$testname (with" . ($_ ? "" : "out") . " a testname)";
            }
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
