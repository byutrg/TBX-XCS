package TBX::XCS::JSON;
use strict;
use warnings;
use TBX::XCS;
use JSON;
use Carp;
#carp from calling package, not from here
our @CARP_NOT = qw(TBX::XCS::JSON);
use Exporter::Easy (
    OK => [qw(xcs_from_json json_from_xcs)],
);
# VERSION

# ABSTRACT: Read and write XCS data in JSON

=head1 SYNOPSIS

    use TBX::XCS;
    use TBX::XCS::JSON qw(json_from_xcs);
    my $xcs = TBX::XCS->new(file=>'/path/to/file.xcs');
    print json_from_xcs($xcs);

=head1 DESCRIPTION

This module allows you to work with XCS data in JSON format.

=cut

#default: read XCS file and dump JSON data to STDOUT
json_from_xcs(TBX::XCS->new(file => $ARGV[0]))
    unless caller;

=head1 METHODS

=head2 C<json_from_xcs>

Returns a JSON string representing the structure of the input TBX::XCS
object.

=cut

sub json_from_xcs {
    my ($xcs) = @_;
    return to_json($xcs->{data}, {utf8 => 1, pretty => 1});
}

=head2 C<xcs_from_json>

Returns a new XCS object created from an input JSON string. The JSON
structure is checked for validity; it should follow the same structure
as that created by json_from_xcs. If the input structure is invalid,
C<undef> will be returned.

=cut

sub xcs_from_json {
    my ($json) = @_;
    my $struct  = decode_json $json;
    check_structure($struct);
    my $xcs = {};
    $xcs->{data} = $struct;
    return bless $xcs, 'TBX::XCS';
}

sub _check_structure {
    my ($struct) = @_;
    if(exists $struct->{constraints}){
        _check_refObjects($struct->{constraints});
        _check_languages($struct->{constraints});
        _check_datCatSet($struct->{constraints});
    }else{
        croak "no constraints key specified";
    }
    if(ref $struct->{name}){
        croak 'name value should be a plain string';
    }
    if(ref $struct->{title}){
        croak 'title value should be a plain string';
    }
    return;
}

sub _check_languages {
    my ($constraints) = @_;
    if(exists $constraints->{languages}){
        ref $constraints->{languages} eq 'HASH'
            or croak '"languages" value should be a hash of ' .
                'language abbreviations and names';
    }else{
        croak 'no "languages key in constraints value';
    }
    return;
}

sub _check_refObjects {
    my ($constraints) = @_;
    #if they don't exist, fine; we don't check them anyway
    exists $constraints->{refObjects} or return;
    my $refObjects = $constraints->{refObjects};
    if('HASH' ne ref $refObjects){
        croak "refObjects should be a hash";
    };
    for (keys %$refObjects) {
        croak "Reference object '$_' is not an array"
            unless 'ARRAY' eq ref $refObjects->{$_};
        for(@{ $refObjects->{$_} }){
            croak "Reference object $_ should refer to an array of strings";
        }
    }
    return;
}

sub _check_datCatSet {
    my ($constraints) = @_;
    if(!exists $constraints->{datCatSet}){
        croak 'Missing key "datCatSet"';
    }
    my $datCatSet = $constraints->{datCatSet};
    for (keys %$datCatSet){
        if(ref $datCatSet->{$_} ne 'ARRAY'){
            croak "data category '$_' should be an array";
            _check_data_category($_, $datCatSet->{$_});
        }
    }
}

sub _check_data_category {
    my ($meta_cat, $data_cat) = @_;
    TBX::XCS::_check_meta_cat($meta_cat);
    if(!exists $data_cat->{name}){
        croak "missing name in data category '$_'";
    }
    _check_datatype($meta_cat, $data_cat);
    if($data_cat eq 'descrip'){
        TBX::XCS::_check_levels($data_cat);
    }
    if(exists $data_cat->{targetType}){
        croak "targetType of $data_cat->{name} should be a string"
            if(ref $data_cat->{targetType});
    }
    if(exists $data_cat->{forTermComp}){
        croak "only termNote data categories can have 'forTermComp'";
        if($data_cat->{forTermComp} != 1 and
            $data_cat->{forTermComp} != 0){
            croak "forTermComp should be either true or false"
        }
    }
}

sub _check_datatype {
    my ($meta_cat, $data_cat) = @_;
    my $datatype = $data_cat->{datatype};
    if($meta_cat eq 'termCompList'){
        croak "termCompList cannot contain datatype"
            if $datatype;
    }else{
        croak "$meta_cat must contain datatype"
            unless $datatype;
        TBX::XCS::_check_datatype($meta_cat, $datatype);
        _check_picklist($data_cat)
            if($datatype eq 'picklist');
    }

}

sub _check_picklist {
    my ($data_cat) = @_;
    if(! exists $data_cat->{choices}){
        croak "need choices for picklist in $data_cat->{name}";
    }
    my $choices = $data_cat->{choices};
    if(ref $choices ne 'ARRAY'){
        croak "$data_cat->{name} choices should be an array"
    }
    for(@$choices){
        croak "$data_cat->{name} choices should be an array of strings"
            if(ref $_);
    }
}

1;

__END__