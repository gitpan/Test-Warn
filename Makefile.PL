use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Test::Warn',
    'VERSION_FROM'	=> 'Warn.pm', # finds $VERSION
    'PREREQ_PM'		=> {    
                            Array::Compare        => 0,
                            Test::Exception       => 0,
                            Test::Builder         => 0.13,
                            Test::Builder::Tester => 0,
                            Sub::Uplevel          => 0,
                            Tree::DAG_Node        => 0
                            }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Warn.pm', # retrieve abstract from module
       AUTHOR     => 'Janek Schleicher <bigj@kamelfreund.de>') : ()),
);
