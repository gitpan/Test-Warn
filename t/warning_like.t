#!/usr/bin/perl

use strict;
use warnings;

use constant TESTS =>(
    ["ok", "my warning", "my", "standard warning to find"],
    ["not ok", "my warning", "another", "another warning instead of my warning"],
    ["not ok", "warning general not", "^(?!warning general)", "quite only a sub warning"],
    ["not ok", undef, "a warning", "no warning, but expected one"],
    ["not ok", "a warning", undef, "warning, but didn't expected on"],
    ["ok", undef, undef, "no warning"],
    ["ok", '$!"%&/()=', '\$\!\"\%\&\/\(\)\=', "warning with crazy letters"],
    ["not ok", "warning 1|warning 2", "warning1", "more than one warning"]
);
use constant SUBTESTS_PER_TESTS  => 4;

use constant EXTRA_TESTS         => 1;

use Test::Builder::Tester tests  => TESTS() * SUBTESTS_PER_TESTS + EXTRA_TESTS;
use Test::Exception;
use Test::Warn;

Test::Builder::Tester::color 'on';

use constant WARN_LINE => line_num +2; 
sub make_warn {
    warn $_ for grep $_, split m:\|:, (shift() || "");
}

test_warning_like(@$_) for TESTS();
dies_ok (sub {warning_like {warn "no regexes should be found"} 'no regex'}, 
         "Tried to call warning_like as regex");

sub test_warning_like {
    my ($ok, $msg, $exp_warning, $testname) = @_;
    for (undef, $testname) {
        my @regexes = $exp_warning ? (qr/$exp_warning/, "/$exp_warning/")
                                   : (undef, undef);  # simpler to count the tests
        for my $regex (@regexes) {
            test_out "$ok 1" . ($_ ? " - $_" : "");
            if ($ok =~ /not/) {
                test_fail +4;
                test_diag  _found_warn_msg($_) for ($msg ? (split m-\|-, $msg) : $msg);
                test_diag  _exp_warn_msg($regex);
            }
            warning_like {make_warn($msg)} $regex, $_;
            test_test  "$testname (with" . ($_ ? "" : "out") . " a testname)";
        }
    }
}

sub _found_warn_msg {
    defined($_[0]) 
        ? ( join " " => ("found warning:",
                         $_[0],
                         "at",
                         __FILE__,
                         "line",
                         WARN_LINE . ".") )
        : "didn't found a warning";
}

sub _exp_warn_msg {
    defined($_[0]) 
        ? "expected to find warning: $_[0]"
        : "didn't expect to find a warning";
}
