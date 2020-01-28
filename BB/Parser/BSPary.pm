package BB::Parser::BSPary;
use Moose;

extends 'BB::Parser';

use BB::Parser::BSPary::XML;
use Data::Dumper;

has _base => (
	is		=> 'ro',
	lazy	=> 1,
	default	=> sub {
		my $self = shift;
		my $url	 = $self->url;
		$url 	 =~ s/\/hist\/.*//;
		return $url;
	},
);

has _xml_dom => (
	is		=> 'ro',
	lazy	=> 1,
	builder	=> '_build_xml_dom',
);

has _ranking => (
	is		=> 'ro',
	lazy	=> 1,
	default	=> sub {
		my $self = shift;
		return $self->_xml_dom->find('ranking')->first;
	},
);

has _pair_nr => (
	is		=> 'ro',
	lazy	=> 1,
	default => sub {
		my $self = shift;
		my $url	 = $self->url;
		#	ostatnia liczba w adresie
		return ( $url =~ /(\d+)/g )[-1];
	},
);

sub _get_pages
{
	my $self 	= shift;
	my $pair_nr	= $self->_pair_nr;

	my $pages;

	my $boards  = $self->_xml_dom->find('boardresult')->to_array;
	for my $board ( @$boards ) {
		my $nr  		= $self->_t( $board->find('boardid') ) || next;
		my $url		 	= $self->_board_url ( $nr );
		my $contract	= $self->_contract( $board );
		my $line		= $self->_line( $board, $pair_nr ); 
		my $points		= $self->_points ( $board, $line );
		my $ns			= $self->_pair( $board, 'ns' );
		my $ew			= $self->_pair( $board, 'ew' );
		my $round		= $self->_round( $board );
		my $declarer	= $self->_declarer( $board );
		my $lead		= $self->_lead( $board );
		my $result		= $self->_result( $board );
		my $score		= $self->_score( $board );

		my $html_contract 	= $contract =~ /^\d/ ? $self->_html_suits( $contract ) : $contract;
		my $html_lead		= $self->_html_suits( $lead );

		my $caption	= ''
			. '<table>'
			. '<tr><th>Round&nbsp;&nbsp;&nbsp;</th><th>Board&nbsp;&nbsp;&nbsp;</th><th>Score&nbsp;&nbsp;&nbsp;</th></tr>'
			. '<tr>' 
				.	'<td>' . $round . '</td>'
				.	'<td>' . $nr	. '</td>'
				.	'<td>' . $points. '</td>'
			. '</tr></table>'
			;
		
		my $text_res = join ( '', ( map { "<td>$_&nbsp;&nbsp;</td>" } ( $html_contract, $declarer, $html_lead, $result, $score ) ) );

		push @$pages, {
			address 	=> $self->_board_url( $nr ),
			name		=> "Board $nr $contract $points",
			comments 	=> [ 
				{
					author 	=> 'BridgeBoards.com',
					comment => ''
						. '<table>'
						. "<tr><th>NS</th><td>$ns</td></tr>"
						. "<tr><th>EW</th><td>$ew</td></tr>"
						. '</table>'
						. "<br><div><b>$caption</b></div>"
						. "<br><table><tr>$text_res</tr></table>",
				},
			],
		};
	}
	$self->_xml_dom;
	return $pages;
}

sub _score
{
	my ( $self, $board ) = @_;
	return $self->_t( $board->find('score') );
}


sub _result
{
	my ( $self, $board ) = @_;
	my $tricks 	= $self->_t( $board->find('tricks') );
	$tricks	   	= '=' 			if $tricks eq '0';
	$tricks	    = '+' . $tricks if $tricks =~ /^\d+$/;
	return $tricks;
}
	

sub _lead
{
	my ( $self, $board ) = @_;
	return $self->_t( $board->find('lead') );
}

sub _declarer
{
	my ( $self, $board ) = @_;
	return $self->_t( $board->find('declarer') );
}


sub _round
{
	my ( $self, $board ) = @_;
	return $self->_t( $board->find('round') );
}

sub _pair
{
	my ( $self, $board, $line ) = @_;
	my $pair_nr = $self->_t( $board->find("pair$line") ) || return '';
	return $self->_pair_name( $pair_nr );
}

sub _pair_name
{
	my ( $self, $pair_nr ) = @_;
	my $players	= $self->_ranking->find('number')->grep( sub { $_->text =~ /^$pair_nr$/ } )->first->parent->find('player')->to_array;
	my $p_1_n	= $self->_t( $players->[0]->find('name') );
	my $p_1_s	= $self->_t( $players->[0]->find('surname') );
	my $p_2_n	= $self->_t( $players->[1]->find('name') );
	my $p_2_s	= $self->_t( $players->[1]->find('surname') );
	return "$p_1_n $p_1_s - $p_2_n $p_2_s";
}

sub _line
{
	my ( $self, $board, $pair_nr ) = @_;
	return $self->_t( $board->find('pairns') )=~ /^$pair_nr$/ ? 'ns' : 'ew';
}

sub _points
{
	my ( $self, $board, $line ) = @_;
	my $t 		= $self->_t( $board->find("points$line") ) || return '';
	my $format 	= $self->_mp ? "%.2f%%" : "%.2f";
	return sprintf $format, $t;
}

sub _contract
{
	my ( $self, $board ) = @_;
	my $t = $self->_t( $board->find('contract') );
	$t =~ s/\s//;
	return $t;
}

sub _get_gallery_name
{
	my $self 	= shift;
	my $dom		= $self->_xml_dom;
	my $title	= $self->_t( $dom->find('title') ) || $self->url;
	my $date 	= $self->_t( $dom->find('date') );
	my $pair	= $self->_pair_name( $self->_pair_nr );
	return "$title $pair $date";
}

sub _build_xml_dom
{
	my $self = shift;
	my $url	 = join '/', $self->_base, 'xml';

	my $p = BB::Parser::BSPary::XML->new(
		url		=> $url,
		ua		=> $self->ua,
		pair_nr	=> $self->_pair_nr,
	);

	return $p->get_dom;
}

sub _board_url
{
	my ( $self, $nr ) = @_;
	return join '/', $self->_base, 'prot', $nr, '';
}

sub _mp
{
	my $self = shift;
	my $method = $self->_t ( $self->_xml_dom->find('scoringmethod') );
	return lc $method eq 'matchpoints' ? 1 : 0;
}

sub _t
{
	my ( $self, $col ) = @_;
	my $c = $col->first;
	return $c ? $c->text : '';
}

1;
