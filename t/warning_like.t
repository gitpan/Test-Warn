#!/usr/bin/perl

use strict;
use warnings;

use Carp;

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
use constant SUBTESTS_PER_TESTS  => 8;

use constant EXTRA_TESTS         => 1;

use Test::Builder::Tester tests  => TESTS() * SUBTESTS_PER_TESTS + EXTRA_TESTS;
use Test::Exception;
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
test_warning_like(@$_) foreach TESTS();
dies_ok (sub {warning_like {warn "no regexes should be found"} 'no regex'}, 
         "Tried to call warning_like as regex");

sub test_warning_like {
    my ($ok, $msg, $exp_warning, $testname) = @_;
    for my $do_carp (0,1) {
        *_found_msg         = $do_carp ? *_found_carp_msg : *_found_warn_msg;
        *_exp_msg           = $do_carp ? *_exp_carp_msg   : *_exp_warn_msg;
        *_make_warn_or_carp = $do_carp ? *_make_carp      : *_make_warn;
        for my $t (undef, $testname) {
            my @regexes = $exp_warning ? (qr/$exp_warning/, "/$exp_warning/")
                                       : (undef, undef);  # simpler to count the tests
            for my $regex (@regexes) {
                test_out "$ok 1" . ($t ? " - $t" : "");
                if ($ok =~ /not/) {
                    test_fail +4;
                    test_diag  _found_msg($_) for ($msg ? (split m-\|-, $msg) : $msg);
                    test_diag  _exp_msg($regex);
                }
                warning_like {_make_warn_or_carp($msg)} (($do_carp && $regex) ? {carped => $regex} : $regex), $t;
                test_test  "$testname (with" . ($_ ? "" : "out") . " a testname)";
            }
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
