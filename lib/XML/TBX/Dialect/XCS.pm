package XML::TBX::Dialect::XCS;
use strict;
use warnings;
use XML::Twig;
use feature 'say';
use Carp;
use Data::Dumper;
# VERSION

# ABSTRACT: Extract data from an XCS file
=head1 SYNOPSIS

	my $xcs = XML::Dialect::XCS->new(file=>'/path/to/file.xcs')

	my $languages = $xcs->get_languages();
	my $ref_objects = $xcs->get_ref_objects();
	my $data_cats = $xcs->get_data_cats();

=head1 DESCRIPTION

This module allows you to extract and edit the information contained in an XCS file. In the future, it may also
be able to serialize the contained information into a new XCS file.

=cut

#default: read XCS file and dump data to STDOUT
__PACKAGE__->new()->_run unless caller;

=head2 C<new>

Creates a new XML::TBX::Dialect::XCS object.

=cut

sub new {
	my ($class) = @_;
	my $self = bless {}, $class;
	return $self;
}

=head2 C<parse>

Takes a named argument, either C<file> for a filename or C<string> for a string pointer.

This method parses the XCS content given by the specified file or string pointer. The contents
of the XCS can then be accessed via C<get_ref_objects>, C<get_languages>, and C<get_data_cats>.

=cut

sub parse {
	my ($self, %args) = @_;

	$self->_init;
	if(exists $args{file}){
		unless(-e $args{file}){
			croak "file does not exist: $args{file}";
		}
		$self->{twig}->parsefile( $args{file} );
	}elsif(exists $args{string}){
		$self->{twig}->parsefile( ${$args{string}} );
	}
	$self->{xcs_constraints} = $self->{twig}->{xcs_constraints};
	return;
}

sub get_languages {
	my ($self) = @_;
	return $self->{xcs_constraints}->{languages};
}

sub _init {
	my ($self) = @_;
	$self->{twig}->{xcs_constraints} = {};
	$self->{twig} = _init_twig();
	return;
}

sub _run {
	my ($self, $file) = @_;
	$self->parse(file => $file);
	print Dumper $self->{twig}->{xcs_constraints};
	return;
}

# these are taken from the core structure DTD
# the types are listed on pg 12 of TBX_spec_OSCAR.pdf
# TODO: maybe they should be extracted
my %default_datatype = (
	adminNote	=> 'plainText',
	admin		=> 'noteText',
	descripNote	=> 'plainText',
	descrip		=> 'noteText',
	hi			=> 'plainText',
	ref			=> 'plainText',
	#I don't think XCS will ever mess with this one in a complicated way
	#TODO: maybe change this to be shown as 'termCompList' type
	#TODO: how will we allow users to subset this?
	termCompList=> 'auxInfo, (termComp | termCompGrp)+',
	termNote	=> 'noteText',
	transacNote	=> 'plainText',
	transac		=> 'plainText',
	xref		=> 'plainText',
);

# these are taken from page 10 of TBX_spec_OSCAR.pdf
# changing these will require MAJOR RNG changes, since auxInfo is used all over
# Levels: term = <tig> and <ntig>, termEntry = <termEntry>, langSet = <langSet>
my %default_levels = (
	# auxInfo items allowed at all three levels
	adminNote	=>
		[
			'langSet',
			'termEntry',
			'term'
		],
	admin	=>
		[
			'langSet',
			'termEntry',
			'term'
		],
	# adminGrp
	descrip	=>
		[
			'langSet',
			'termEntry',
			'term'
		],
	# descripGrp
	ref		=>
		[
			'langSet',
			'termEntry',
			'term'
		],
	xref	=>
		[
			'langSet',
			'termEntry',
			'term'
		],
	# transacGrp

	# term level only
	# tig
	# ntig
	# termGrp
	# termNoteGrp
	termNote	=> ['term'],
	# termCompGrp
	termCompList=> ['term'],

	#these ones don't occur at at of the three levels
	# descripNote
	# hi
	# transacNote
	# transac
);

#return an XML::Twig object which will extract data from an XCS file
sub _init_twig {
	return new XML::Twig(
		pretty_print			=> 'indented',
		# keep_original_prefix	=> 1, #maybe; this may be bad because the JS code doesn't process namespaces yet
		output_encoding			=> 'UTF-8',
		do_not_chain_handlers	=> 1, #can be important when things get complicated
		keep_spaces				=> 0,
		TwigHandlers			=> {
			TBXXCS			=> sub {},
			title			=> sub {},
			header			=> sub {},

			languages		=> \&_languages,
			langCode		=> sub {},
			langInfo		=> sub {},
			langName		=> sub {},

			refObjectDefSet	=> \&_refObjectDefSet,
			refObjectDef	=> sub {},
			refObjectType	=> sub {},
			itemSpecSet		=> sub {},
			itemSpec		=> sub {},

			adminNoteSpec	=> \&_dataCat,
			adminSpec		=> \&_dataCat,
			descripNoteSpec	=> \&_dataCat,
			descripSpec		=> \&_dataCat,
			hiSpec			=> \&_dataCat,
			refSpec			=> \&_dataCat,
			termCompListSpec=> \&_dataCat,
			termNoteSpec	=> \&_dataCat,
			transacNoteSpec	=> \&_dataCat,
			transacSpec		=> \&_dataCat,
			xrefSpec		=> \&_dataCat,
			contents		=> sub {},
			levels			=> sub {},
			datCatSet		=> sub {},

			'_default_'		=> sub {croak 'unknown tag: ' . $_->tag},
		},
	);
}

###HANDLERS

#the languages allowed to be used in the document
sub _languages {
	my ($twig, $el) = @_;
	my %languages;
	#make list of allowed languages and store it on the twig
	foreach my $language($el->children('langInfo')){
		$languages{$language->first_child('langCode')->text} =
			$language->first_child('langName')->text;
	}
	$twig->{xcs_constraints}->{languages} = \%languages;
}

#the reference objects that can be contained in the <back> tag
sub _refObjectDefSet {
	my ($twig, $el) = @_;
	my %defSet;
		#make list of allowed reference object types and store it on the twig
	foreach my $def ($el->children('refObjectDef')){
		$defSet{$def->first_child('refObjectType')->text} =
			[
				map {$_->text}
					$def->first_child('itemSpecSet')->children('itemSpec')
			];
	}

	$twig->{xcs_constraints}->{refObjects} = \%defSet;
}

# all children of dataCatset
sub _dataCat {
	my ($twig, $el) = @_;
	(my $type = $el->tag) =~ s/Spec$//;
	my $data = {};
	$data->{name} = $el->att('name');
	$data->{datcatId} = $el->att('datcatId');
	#If the data-category does not take a picklist,
	#if its data type is the same as that defined for the meta data element in the core-structure DTD,
	#if its meta data element does not take a target attribute, and
	#if it does not apply to term components,
	#this element will be empty and have no attributes specified.
	my $contents = $el->first_child('contents');

	#use default datatypes where not provided
	#
	$data->{datatype} =
		($contents->att('datatype') || $default_datatype{$type});

	$data->{choices} = [split ' ', $contents->text]
		if($data->{datatype} && $data->{datatype} eq 'picklist');

	$data->{forTermComp} = $contents->att('forTermComp') eq 'yes' ? 1 : 0
		if $contents->att('forTermComp');

	$data->{targetType} = $contents->att('targetType')
		if $contents->att('targetType');

	my $levels = $el->first_child('levels');
	if($levels){
		$data->{levels} = [split ' ', $levels->text];
	}else{
		$data->{levels} = $default_levels{$type};
	}
	#also, check page 10 of the OSCAR PDF for elements that can occur at multiple levels
	push @{ $twig->{xcs_constraints}->{datCatSet}->{$type} }, $data;
}