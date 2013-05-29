package TBX::XCS;
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

=head1 METHODS

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
        if(not -e $args{file}){
            croak "file does not exist: $args{file}";
        }
        $self->{twig}->parsefile( $args{file} );
    }elsif(exists $args{string}){
        $self->{twig}->parse( ${$args{string}} );
    }else{
        croak 'Need to specify either a file or a string pointer with XCS contents';
    }
    $self->{xcs_constraints} = $self->{twig}->{xcs_constraints};
    $self->{xcs_name} = $self->{twig}->{xcs_name};
    $self->{xcs_title} = $self->{twig}->{xcs_title};
    return;
}

=head2 C<get_languages>

Returns a pointer to a hash containing the languages allowed in the C<langSet xml:lang>
attribute, as specified by the XCS C<languages> element. The keys are abbreviations, values
the full names of the languages.

=cut

sub get_languages {
    my ($self) = @_;
    return $self->{xcs_constraints}->{languages};
}

=head2 C<get_ref_objects>

Returns a pointer to a hash containing the reference objects
specified by the XCS. For example, the XML below:

    <refObjectDef>
        <refObjectType>Foo</refObjectType>
            <itemSpecSet type="validItemType">
                <itemSpec type="validItemType">data</itemSpec>
                <itemSpec type="validItemType">name</itemSpec>
            </itemSpecSet>
        </refObjectDef>
    </refObjectDefSet>

will yield the following structure:

{ Foo => ['data', 'name'] },

=cut

sub get_ref_objects {
    my ($self) = @_;
    return $self->{xcs_constraints}->{refObjects} ;
}

=head2 C<get_data_cats>

Returns a hash pointer containing the data category specifications. For example,
the XML below:

    <datCatSet>
        <descripSpec name="context" datcatId="ISO12620A-0503">
            <contents/>
            <levels>term</levels>
        </descripSpec>
        <descripSpec name="descripFoo" datcatId="">
            <contents/>
            <levels/>
        </descripSpec>
        <termNoteSpec name="animacy" datcatId="ISO12620A-020204">
            <contents datatype="picklist" forTermComp="yes">animate inanimate
            otherAnimacy</contents>
        </termNoteSpec>
        <xrefSpec name="xrefFoo" datcatId="">
            <contents targetType="external"/>
        </xrefSpec>

    </datCatSet>

would yield the data structure below:

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

=cut

sub get_data_cats {
    my ($self) = @_;
    return $self->{xcs_constraints}->{datCatSet};
}

=head2 C<get_title>

Returns the title of the document, as contained in the title element.

=cut

sub get_title {
    my ($self) = @_;
    return $self->{xcs_title};
}

=head2 C<get_name>

Returns the name of the XCS file, as found in the TBXXCS element.

=cut

sub get_name {
    my ($self) = @_;
    return $self->{xcs_name};
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
    adminNote   => 'plainText',
    admin       => 'noteText',
    descripNote => 'plainText',
    descrip     => 'noteText',
    hi          => 'plainText',
    ref         => 'plainText',
    #I don't think XCS will ever mess with this one in a complicated way
    #TODO: maybe change this to be shown as 'termCompList' type
    #TODO: how will we allow users to subset this?
    # termCompList=> 'auxInfo, (termComp | termCompGrp)+',
    termNote    => 'noteText',
    transacNote => 'plainText',
    transac     => 'plainText',
    xref        => 'plainText',
);

my $allowed_datatypes = do{

    #what datatypes can become what other datatypes?
    my %datatype_heirarchy = (
        noteText    => {
            'basicText' => 1,
            'plainText' => 1,
            'picklist'  => 1,
            },
        basicText   => {
            'plainText' => 1,
            'picklist'  => 1,
        },
        plainText   => {
            'picklist'  => 1,
        },
    );

    my $allowed_datatypes = {};
    for my $category (keys %default_datatype){
        $allowed_datatypes->{$category} = $datatype_heirarchy{ $default_datatype{$category} };
    }
    $allowed_datatypes;
};

#return an XML::Twig object which will extract data from an XCS file
sub _init_twig {
    return new XML::Twig(
        pretty_print            => 'indented',
        # keep_original_prefix  => 1, #maybe; this may be bad because the JS code doesn't process namespaces yet
        output_encoding         => 'UTF-8',
        do_not_chain_handlers   => 1, #can be important when things get complicated
        keep_spaces             => 0,
        TwigHandlers            => {
            TBXXCS          => sub {$_[0]->{xcs_name} = $_->att('name')},
            title           => sub {$_[0]->{xcs_title} = $_->text},
            header          => sub {},
            #TODO: add handlers for these
            datCatDoc       => sub {},
            datCatMap       => sub {},
            datCatDisplay   => sub {},
            datCatNote      => sub {},
            datCatToken     => sub {},

            languages       => \&_languages,
            langCode        => sub {},
            langInfo        => sub {},
            langName        => sub {},

            refObjectDefSet => \&_refObjectDefSet,
            refObjectDef    => sub {},
            refObjectType   => sub {},
            itemSpecSet     => sub {},
            itemSpec        => sub {},

            adminNoteSpec   => \&_dataCat,
            adminSpec       => \&_dataCat,
            descripNoteSpec => \&_dataCat,
            descripSpec     => \&_dataCat,
            hiSpec          => \&_dataCat,
            refSpec         => \&_dataCat,
            termCompListSpec=> \&_dataCat,
            termNoteSpec    => \&_dataCat,
            transacNoteSpec => \&_dataCat,
            transacSpec     => \&_dataCat,
            xrefSpec        => \&_dataCat,
            contents        => sub {},
            levels          => sub {},
            datCatSet       => sub {},

            '_default_'     => sub {croak 'unknown tag: ' . $_->tag},
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

    #check restrictions on datatypes
    my $datatype = $contents->att('datatype');
    if($datatype){
        if($type eq 'termCompList'){
            carp 'Ignoring datatype value in termCompList contents element';
        }
        elsif(! exists $allowed_datatypes->{$type}->{$datatype} ){
            croak "Can't set datatype of $type to $datatype. Must be " .
                join (' or ', keys %{ $allowed_datatypes->{$type}->{$datatype} }) . '.';
        }
    }else{
        $datatype = $default_datatype{$type};
    }
    $data->{datatype} = $datatype;

    if($datatype eq 'picklist'){
        $data->{choices} = [split ' ', $contents->text];
    }
    if ($contents->att('forTermComp')){
        $data->{forTermComp} = $contents->att('forTermComp') eq 'yes' ? 1 : 0;
    }

    if ($contents->att('targetType')){
        $data->{targetType} = $contents->att('targetType');
    }

    #levels can be specified for descrip data categories
    if($type eq 'descrip'){
        if(my $levels = $el->first_child('levels')->text){
            $data->{levels} = [split ' ', $levels];
        }else{
            #todo: not sure if this is the right behavior for an empty <levels/>
            $data->{levels} = [qw(langSet termEntry term)]
        }
    }
    #also, check page 10 of the OSCAR PDF for elements that can occur at multiple levels
    push @{ $twig->{xcs_constraints}->{datCatSet}->{$type} }, $data;
}

1;

__END__

=head1 FUTURE WORK

=over 2

=item * extract C<datCatDoc>

=item * extract C<refObjectDefSet>

=item * Setter methods for XCS data

=item * Print an XCS file

=back

=head1 SEE ALSO

The XCS and the TBX specification can be found on L<GitHub|https://github.com/byutrg/TBX-Spec/blob/master/TBX-Default/TBX_spec_OSCAR.pdf>.