#make sure that the core structure RNG validates a TBX file
use strict;
use warnings;
use Test::More;
plan tests => 2;
use XML::TBX::Dialect qw(core_structure_rng);
use XML::Jing;
use Path::Tiny;
use FindBin qw($Bin);
use File::Slurp;

my $corpus_dir = path($Bin, 'corpus');
my $rng_file = path($corpus_dir, 'core.rng');
my $min_tbx = path($corpus_dir, 'min.tbx');
my $tbx_basic_sample = path($corpus_dir, 'TBX-basic-sample.tbx');

#clean up previous test
unlink $rng_file
	if -e $rng_file;
write_file($rng_file, core_structure_rng())
	or die "Couldn't write $rng_file";
note "wrote $rng_file";

my $jing = XML::Jing->new($rng_file);
my $error = $jing->validate($min_tbx);
is($error, undef, 'RNG validates minimal TBX file')
	or note $error;

$error = $jing->validate($tbx_basic_sample);
is($error, undef, 'RNG validates minimal TBX file')
	or note $error;

#clean up after test
unlink $rng_file;