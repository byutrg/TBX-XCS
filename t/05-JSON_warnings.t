#Check that XCS.pm creates proper structure from an XCS file
use strict;
use warnings;
use Test::Base;
plan tests => 1*blocks();
use Test::Exception;
use TBX::XCS::JSON qw(xcs_from_json);
use JSON;

for my $block(blocks()){
  my $croak = $block->croak;
  throws_ok {xcs_from_json($block->json)}
  qr/$croak/,
  $block->name;
}
# {
#    "constraints" : {
#       "languages" : {
#          "en" : "English",
#          "fr" : "French",
#          "de" : "German"
#       },
#       "datCatSet" : {
#          "xref" : [
#             {
#                "name" : "xrefFoo",
#                "targetType" : "external",
#                "datatype" : "plainText"
#             }
#          ]
#       }
#    }
# }

__DATA__
=== no constraints
--- croak: no constraints key specified
--- json
{
  "name" : "foo",
  "title" : "bar"
}

=== bad name structure
--- croak: name value should be a plain string
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   },
   "name": []
}

=== bad title structure
--- croak: title value should be a plain string
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   },
   "title": []
}

=== bad language structure
--- croak: "languages" value should be a hash of language abbreviations and names
--- json
{
   "constraints" : {
      "languages" : [
        "English", "German"
      ],
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== missing languages
--- croak: no "languages" key in constraints value
--- json
{
   "constraints" : {
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== bad refObjects structure
--- croak: refObjects should be a hash
--- json
{
   "constraints" : {
      "refObjects" : [],
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== refObject not an array
--- croak: Reference object foo is not an array
--- json
{
   "constraints" : {
      "refObjects" : {
        "foo" : {}
      },
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== refObject array element not a scalar
--- croak: Reference object foo should refer to an array of strings
--- json
{
   "constraints" : {
      "refObjects" : {
        "foo" : [
          "data", {}
        ]
      },
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== missing data category set
--- croak: "constraints" is missing key "datCatSet"
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "d-cat-set" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== empty data cat set
--- croak: datCatSet should not be empty
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {}
   }
}

=== bad data category structure
--- croak: data category 'xref' should be an array
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : {}
      }
   }
}

=== bad meta data category name
--- croak: unknown meta data category: foo
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "foo" : [
            {

            }
         ]
      }
   }
}
