package BB::Parser::BSPary::XML;
use Moose;

use Data::Dumper;
use Mojo::DOM;

use Encode qw/decode_utf8/;

has url => (
	is			=> 'ro',
	required	=> 1,
);

has ua => (
	is			=> 'ro',
	required	=> 1,
);

has pair_nr => (
	is			=> 'ro',
	required	=> 1,
);

has raw_xml => (
	is		=> 'ro',
	lazy	=> 1,
	builder	=> '_build_raw_xml',
);

sub get_dom
{
	my $self = shift;
	#	Potrzebne jest
	#		1.	Cała sekcja 'results' (są tam nazwiska zawodników)
	#		2.	Historia tej pary
	#		3.	Zawartość title
	#		4.	Zawartość date
	#		5.	Zawaryość scoringMethod
	#	(nie zmieniam układu xml'a, ale wybieram tylko istotne informacje)
	my $ranking 	= $self->_ranking;
	my $pair_hist	= $self->_pair_hist;
	my $title		= $self->_title;
	my $date		= $self->_date;
	my $scoring		= $self->_scoring;
	my $xml 		= join '',
		'<tournamentResults>',
			$ranking,
			'<histories>',
				$pair_hist,
			'</histories>',
			$title,
			$date,
			$scoring,
		'</torunamentResults>'
	;

	#	poprawienie kodowania
	$xml 	= decode_utf8( $xml );

	my $dom = Mojo::DOM->new( $xml );
	$dom->xml(1);

	return $dom;
}

sub _ranking
{
	my $self = shift;
	my $raw  = $self->raw_xml;
	my @res;
	my $ranking = 0;
	for my $line (split /^/, $raw) {
		#	początek rankingów
		$ranking = 1 if $line =~ /<ranking>/;
	
		#	zapisanie linii, jeżeli jesteśmy w rankingach
		push @res, $line if $ranking;
	
		#	koniec rankingów
		last if $line =~ /<\/ranking>/;
	}
	return join '', @res;
}

sub _pair_hist
{
	my $self = shift;
	my $raw  = $self->raw_xml;
	my $nr	 = $self->pair_nr;
	my @res;
	my $histories 	 = 0;
	my $pair_history = 0;
	for my $line (split /^/, $raw) {
		#	początek historii
		$histories = 1 if $line =~ /<histories>/;
	
		#	początek historii pary
		if ( $histories and $line =~ /<participantNumber>$nr<\/participantNumber>/ ) {
			push @res, '<history>';
			$pair_history = 1;
		}
	
		#	zapisanie linii, jeżeli jesteśmy w historii pary
		push @res, $line if $pair_history;
	
		#	koniec historii pary
		last if $pair_history and $line =~ /<\/history>/;
	}
	return join '', @res;
}

sub _title
{
	my $self = shift;
	my $raw  = $self->raw_xml;
	for my $line (split /^/, $raw) {
		return $line if $line =~ /<title>/;
	}
}

sub _date
{
	my $self = shift;
	my $raw  = $self->raw_xml;
	for my $line (split /^/, $raw) {
		return $line if $line =~ /<date>/;
	}
}

sub _scoring
{
	my $self = shift;
	my $raw  = $self->raw_xml;
	for my $line (split /^/, $raw) {
		return $line if $line =~ /<scoringMethod>/;
	}
}

sub _build_raw_xml
{
	my $self = shift;
	my $tx 	 = $self->ua->get($self->url);
	if ( $tx->error ) {
		die $tx->error;
	}
	return $tx->res->body;
}


1;
