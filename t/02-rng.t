#make sure that the core structure RNG validates a TBX file
use t::TestRNG;
use Test::More 0.88;
plan tests => 3;
use XML::TBX::Dialect;
use XML::Jing;
use Path::Tiny;
use FindBin qw($Bin);
use File::Slurp;

my $corpus_dir = path($Bin, 'corpus');

#TODO: should also check with TBXChecker
# for each block, create an RNG from an XCS file,
# then test it against valid and invalid TBX
for my $block(blocks){
	note $block->name;
	#create an RNG and write it to a temporary file
	my $dialect = XML::TBX::Dialect->new();
	my $xcs = $block->xcs;
	$dialect->set_xcs(file => path($corpus_dir, $xcs));
	my $rng = $dialect->as_rng;
	my $tmp = File::Temp->new();
	write_file($tmp, $rng);
	my $jing = XML::Jing->new($tmp->filename);

	for my $good( $block->good ){
		my $error = $jing->validate( path($corpus_dir, $good) );
		ok(!$error, "$good validates with $xcs RNG")
			or note($error);
	}
	for my $bad( $block->bad ){
		my $error = $jing->validate( path($corpus_dir, $bad) );
		ok($error, "$bad doesn't validate with $xcs RNG");
	}
}

__DATA__
=== Specify languages via XCS
--- xcs: small.xcs
--- good: langTestGood.tbx
--- bad lines chomp
langTestBad.tbx
langTestBad2.tbx