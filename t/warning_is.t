#!/usr/bin/perl

use strict;
use warnings;

use Carp;

use constant SUBTESTS_PER_TESTS  => 4;

use constant TESTS =>(
    ["ok", "my warning", "my warning", "standard warning to find"],
    ["not ok", "my warning", "another warning", "another warning instead of my warning"],
    ["not ok", "warning general not", "warning general", "quite only a sub warning"],
    ["not ok", undef, "a warning", "no warning, but expected one"],
    ["not ok", "a warning", undef, "warning, but didn't expected on"],
    ["ok", undef, undef, "no warning"],
    ["ok", '$!"%&/()=', '$!"%&/()=', "warning with crazy letters"],
    ["not ok", "warning 1|warning 2", "warning1", "more than one warning"]
);

use Test::Builder::Tester tests  => TESTS() * SUBTESTS_PER_TESTS;
use Test::Warn;

Test::Builder::Tester::color 'on';

use constant WARN_LINE => line_num +2; 
sub _make_warn {
    warn $_ for grep $_, split m:\|:, (shift() || "");
}

use constant CARP_LINE => line_num +2;
sub _make_carp {
    carp $_ for grep $_, split m:\|:, (shift() || "");
}

my $i = 0;
test_warning_is(@$_) foreach  TESTS();

sub test_warning_is {
    my ($ok, $msg, $exp_warning, $testname) = @_;
    for my $do_carp (0,1) {
        *_found_msg         = $do_carp ? *_found_carp_msg : *_found_warn_msg;
        *_exp_msg           = $do_carp ? *_exp_carp_msg   : *_exp_warn_msg;
        *_make_warn_or_carp = $do_carp ? *_make_carp      : *_make_warn;
        for my $t (undef, $testname) {
            test_out "$ok 1" . ($t ? " - $t" : "");
            if ($ok =~ /not/) {
                test_fail +4;
                test_diag  _found_msg($_) for ($msg ? (split m-\|-, $msg) : $msg);
                test_diag  _exp_msg($exp_warning);
            }
            warning_is {_make_warn_or_carp($msg)} (($do_carp && $exp_warning) ? {carped => $exp_warning} : $exp_warning), $t;
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

sub _found_carp_msg {
    defined($_[0]) 
        ? ( join " " => ("found carped warning:",
                         $_[0],
                         "at",
                         __FILE__,
                         "line",
                         CARP_LINE) )     # Note the difference, that carp msg
        : "didn't found a warning";       # aren't finished by '.'
}

sub _exp_carp_msg {
    defined($_[0]) 
        ? "expected to find carped warning: $_[0]"
        : "didn't expect to find a warning";
}
