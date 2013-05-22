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
my $xcs_file = path($corpus_dir, 'small.xcs');

my $dialect = XML::TBX::Dialect->new();
$dialect->set_xcs(file => $xcs_file);
my $rng = $dialect->as_rng;
print $$rng;