package BB::Parser::BBO;
use Moose;

extends 'BB::Parser';

use Data::Dumper;

sub _get_pages
{
	my $self 	= shift;
	my $dom		= $self->dom;
	my $user	= $self->_user;

	my $pages;

	my $boards  = $dom->find('tr[class=tourney], tr[class=mbc], tr[class=team]')->to_array;
	for my $board ( @$boards ) {
		my $nr  		= $self->_t( $board->find('td[class=handnum]') ) || next;
		my $url		 	= $self->_board_url ( $board );
		my $ns			= $self->_player( $board, 'north' ) . ' - ' . $self->_player( $board, 'south' );
		my $ew			= $self->_player( $board, 'east' ) . ' - ' . $self->_player( $board, 'west' );
		my $line		= ( $ns =~ /^$user / or $ns =~ / $user$/ ) ? 'NS' : 'EW';
		my $points		= $self->_points ( $board, $line );
		my $score		= $self->_score( $board );

		my ( $contract, $declarer, $result ) = $self->_contract( $board );

		my $html_contract 	= $contract =~ /^\d/ ? $self->_html_suits( $contract ) : $contract;

		my $caption	= ''
			. '<table>'
			. '<tr><th>Board&nbsp;&nbsp;&nbsp;</th><th>Score&nbsp;&nbsp;&nbsp;</th></tr>'
			. '<tr>' 
				.	'<td>' . $nr	. '</td>'
				.	'<td>' . $points. '</td>'
			. '</tr></table>'
			;
		
		my $text_res = join ( '', ( map { "<td>$_&nbsp;&nbsp;</td>" } ( $html_contract, $declarer, $result, $score ) ) );

		push @$pages, {
			address 	=> $url,
			name		=> "Board $nr $contract $points",
			comments 	=> [ 
				{
					author 	=> 'BridgeBoards.com',
					comment => ''
						. '<table>'
						. "<tr><th>NS&nbsp;&nbsp;</th><td>$ns</td></tr>"
						. "<tr><th>EW&nbsp;&nbsp;</th><td>$ew</td></tr>"
						. '</table>'
						. "<br><div><b>$caption</b></div>"
						. "<br><table><tr>$text_res</tr></table>",
				},
			],
		};
	}
	return $pages;
}

#	ELEMENTY WYNIKU

sub _points
{
	my ( $self, $board ) = @_;
	my $p = $board->find( "td[class=score], td[class=negscore]" );
	return $p->first->next->text;
}

sub _score
{
	my ( $self, $board ) = @_;
	my $p = $board->find( "td[class=score], td[class=negscore]" );
	return $p->first->text;
}


sub _player
{
	my ( $self, $board, $pos ) = @_;
	my $player = $self->_t( $board->find("td[class=$pos]") );
	return $player;
}

sub _user
{
	my $self = shift;
	my $dom  = $self->dom;
	my $user = $self->_t( $dom->find('th span[class=username]') );
	return $user;
}

sub _board_url
{
	my ( $self, $board ) = @_;
	return $board->find('td[class=movie]')->first->find('a')->first->attr('href');
}

sub _contract
{
	my ( $self, $board ) = @_;
	my $c = $board->find('td[class=result]')->first->all_text;

	#	pass
	return ($c, '', '') if lc $c eq 'pass';

	#	wysokość
	my $height = substr $c, 0, 1;
	substr($c, 0, 1) = '';

	#	miano
	my $suit;
	if ( $c =~ /^N/ ) {
		$suit = 'N';
		substr($c, 0, 1) = '';
	}
	else {
		$suit = $self->_unicode_to_text_suits( substr($c, 0, 1) );
		substr($c, 0, 1) = '';
	}
	
	my $dbl = '';
	for ( 0, 1 ) {
		if ( $c =~ /^x/ ) {
			$dbl .= 'x';
			substr($c, 0, 1) = '';
		}
	}

	my $contract = join '', $height, $suit, $dbl;
	
	my $declarer = substr $c, 0, 1;
	substr($c, 0, 1) = '';

	my $result = $c;

	return $contract, $declarer, $result;
}

#	NAZWA GALERII

sub _get_gallery_name
{
	my $self 	= shift;
	my $name	= $self->dom->find('th[colspan=11]')->first->all_text || $self->url;
	return $name;
}

#	FUNKCJA ZWRACAJĄCA TEKST PIERWSZEGO ELEMENTU KOLEKCJI ALBO ''
#	(zadziwiająco często przydatne :P)

sub _t
{
	my ( $self, $col ) = @_;
	my $c = $col->first;
	return $c ? $c->text : '';
}
1;
