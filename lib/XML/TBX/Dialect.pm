package XML::TBX::Dialect;
use strict;
use warnings;
use feature 'state';
use File::Slurp;
use Path::Tiny;
use autodie;
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
	my $application = bless {}, $class;
	$application->_init;
	return $application;
}

sub _init {
	my ($application) = @_;
	$application->{output_fh} = \*STDOUT;
	$application->{input_fh} = \*STDIN;
	return;
}

=head2 C<output_fh>

Input: filehandle or filename

Sets the filehandle for this object to print to.

=cut

sub output_fh {
	my ( $application, $fh ) = @_;
	if ($fh) {
		if(ref($fh) eq 'GLOB'){
			$application->{output_fh} = $fh;
		}
		else{
			open my $fh2, '>', $fh;
			$application->{output_fh} = $fh2;
		}
	}
	return $application->{output_fh};
}

=head2 C<input_fh>

Input: filehandle or filename

Sets the filehandle for this object to read from.

=cut

sub input_fh {
	my ( $application, $fh ) = @_;
	if ($fh) {
		if(ref($fh) eq 'GLOB'){
			$application->{input_fh} = $fh;
		}
		else{
			open my $fh2, '<', $fh;
			$application->{input_fh} = $fh2;
		}
	}
	return $application->{input_fh};
}

=head2 C<core_structure_rng>

Returns a pointer to a string containing the TBX core structure (version 2) RNG.

=cut

sub core_structure_rng {
	my $rng = read_file(path(dist_dir('XML-TBX-Dialect'),'TBXcoreStructV02.rng'));
	return \$rng;
}

1;

