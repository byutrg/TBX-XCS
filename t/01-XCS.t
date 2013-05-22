#make sure that the core structure RNG validates a TBX file
use strict;
use warnings;
use Test::More;
plan tests => 2;
use XML::TBX::Dialect::XCS;
use Path::Tiny;
use FindBin qw($Bin);
use File::Slurp;

my $corpus_dir = path($Bin, 'corpus');
my $xcs_file = path($corpus_dir, 'small.xcs');
my $xcs_contents = read_file($xcs_file);

my $xcs = XML::TBX::Dialect::XCS->new();

test_xcs_data('file',$xcs_file);
test_xcs_data('string',\$xcs_contents);


# test_xcs_data($xcs);

sub test_xcs_data {
	my ($type, $data) = @_;
	$xcs->parse($type=>$data);
	is_deeply(
		$xcs->get_languages(),
		{en => 'English', fr => 'French', 'de' => 'German'},
		"Languages extracted from $type"
	);
}

