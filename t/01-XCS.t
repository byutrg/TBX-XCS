#make sure that the core structure RNG validates a TBX file
use strict;
use warnings;
use Test::More;
plan tests => 1;
use XML::TBX::Dialect::XCS;
use Path::Tiny;
use FindBin qw($Bin);
use File::Slurp;

my $corpus_dir = path($Bin, 'corpus');
my $rng_file = path($corpus_dir, 'small.xcs');

my $xcs = XML::TBX::Dialect::XCS->new();
$xcs->parse(file=>$rng_file);

is_deeply(
	$xcs->get_languages(),
	{en => 'English', fr => 'French', 'de' => 'German'},
	'Languages extracted from file'
);
