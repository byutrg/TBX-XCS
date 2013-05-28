#Check that XCS.pm creates proper structure from an XCS file
use strict;
use warnings;
use Test::More 0.88;
plan tests => 6;
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

#test languages, ref objects, and data categories
sub test_xcs_data {
    my ($type, $data) = @_;
    $xcs->parse($type=>$data);

    is_deeply(
        $xcs->get_languages(),
        {en => 'English', fr => 'French', 'de' => 'German'},
        "Languages extracted from $type"
    ) or note explain $xcs->get_languages();

    is_deeply(
        $xcs->get_ref_objects(),
        { Foo => ['data'] },
        "Ref objects extracted from $type"
    ) or note explain $xcs->get_ref_objects();

    is_deeply(
        $xcs->get_data_cats(),
        get_expected_data_cat(),
        "Data categories extracted from $type"
    ) or note explain $xcs->get_data_cats();
}

sub get_expected_data_cat {
    return
    {
      'descrip' =>
      [
        {
          'datatype' => 'noteText',
          'datcatId' => 'ISO12620A-0503',
          'levels' => ['term'],
          'name' => 'context'
        },
        {
          'datatype' => 'noteText',
          'datcatId' => '',
          'levels' => ['langSet', 'termEntry', 'term'],
          'name' => 'descripFoo'
        }
      ],
      'termNote' => [{
          'choices' => ['animate', 'inanimate', 'otherAnimacy'],
          'datatype' => 'picklist',
          'datcatId' => 'ISO12620A-020204',
          'forTermComp' => 1,
          'name' => 'animacy'
        }],
      'xref' => [{
          'datatype' => 'plainText',
          'datcatId' => '',
          'name' => 'xrefFoo',
          'targetType' => 'external'
        }]
    };
}

#TODO: test termCompLits warnings; test datatype warnings