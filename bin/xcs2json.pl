#!/usr/bin/env perl
# TODO: test this
# VERSION
# ABSTRACT: Print a JSON representation of the input XCS file
use TBX::XCS;
use TBX::XCS::JSON qw(json_from_xcs);
print json_from_xcs(TBX::XCS->new(file => $ARGV[0]));