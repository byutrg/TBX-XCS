package XML::TBX::Dialect;
use strict;
use warnings;
use XML::TBX::Dialect::XCS;
use feature 'state';
use File::Slurp;
use Path::Tiny;
use autodie;
use Carp;
use Data::Dumper;
use File::ShareDir 'dist_dir';
use Exporter::Easy (
	OK => [ qw(core_structure_rng) ],#TODO: add others
);

# VERSION


# ABSTRACT: Create new TBX dialects
=head1 SYNOPSIS

	my $dialect = XML::TBX::Dialect->new(
		xcs => '/path/to/xcs'
	);
	print $dialect->as_rng();

=head1 DESCRIPTION

This module allows you to create new resources to work with TBX dialects. Currently it only provides RNG generation from XCS information, but
in the future we plan to add XSD generation and to allow tweaking the core structure DTD.

=cut

__PACKAGE__->new->_run unless caller;

sub _run {
	my ($application) = @_;
	print { $application->{output_fh} }
		$application->message;
}

=head1 METHODS

=head2 C<new>

Creates a new instance of XML::TBX::Dialect.

=cut

sub new {
	my ($class) = @_;
	my $self = bless {}, $class;
	return $self;
}

=head2 C<new>

Sets the XCS of this dialect. Arguments are identical to those in C<XML::TBX::Dialect::XCS::parse>.

=cut

sub set_xcs {
	my ($self, @xcs_args) = @_;
	my $xcs = XML::TBX::Dialect::XCS->new();
	# print join ':', @xcs_args;
	$xcs->parse(@xcs_args);
	$self->{xcs} = $xcs;
	# print Dumper $self->{xcs}->get_languages();
	return;
}

=head2 C<new>

Creates an RNG representation of this dialect and returns it in a string pointer. The XCS must already be set.

=cut

sub as_rng {
	my ($self) = @_;
	my $xcs = $self->{xcs};
	if(!$xcs){
		croak "No XCS set yet! Can't create an RNG.";
	}

	my $languages = $xcs->get_languages();
	croak "No languages specified in XCS!"
		unless(keys %$languages);

	my $rng = core_structure_rng();
	_add_rng_languages($rng, $languages);

	return $rng;
}

#add the language choices to the xml:lang attribute section
sub _add_rng_languages {
	my ($rng, $languages) = @_;

	my $xml_lang_att = qq{<attribute name="xml:lang">\n};
	$xml_lang_att .= "\t\t<choice>\n";
	# print Dumper $languages;
	# print join ':', keys %$languages;
	for my $abbrv(sort keys %$languages){
		$xml_lang_att .= "\t\t\t<value>$abbrv</value>\n"
	}
	$xml_lang_att .= "\t\t</choice>\n";
	$xml_lang_att .= "\t</attribute>";
	$$rng =~ s{<attribute name="xml:lang"/>}{$xml_lang_att};
	return;
}

=head2 C<core_structure_rng>

Returns a pointer to a string containing the TBX core structure (version 2) RNG.

=cut

sub core_structure_rng {
	my $rng = read_file(path(dist_dir('XML-TBX-Dialect'),'TBXcoreStructV02.rng'));
	return \$rng;
}

1;

