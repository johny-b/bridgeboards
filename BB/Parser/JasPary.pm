package BB::Parser::JasPary;
use Moose;

extends 'BB::Parser';

use Data::Dumper;

sub _get_pages
{
	my $self 	= shift;
	my $dom	 	= $self->dom;
	my $pages 	= [];

	#	gracze
	my $title 	= $self->dom->find('td[class=o1]')->first->text;
	my $players	= ( split /\d+: |,/, $title )[1];
	
	#	wszystkie wiersze
	my $rows = $dom->find('tr')->to_array;

	#	pierwsze 3 wiersze to nagłówki
	splice @$rows, 0, 3;

	#	6 kolumn jest zawsze, a wylatują końcowe wiersze podsumowania
	$rows	 = [ grep { $_->find('td')->size >=5 } @$rows ];

	my $round	= '';
	my $opps 	= '';

	for my $row ( @$rows ) {
		my $tds = $row->find('td')->to_array;
		
		#	adres strony z rozdaniem
		my $atd	= ( grep { $_->find('a')->first and $_->find('a')->first->text =~ /^\d+$/ } @$tds )[0];
		next if not $atd;
		my $a 		= $atd->find('a')->first || next;
		my $address	= $self->_url_abs_p . $a->attr('href');
		
		#	pierwsze td zawsze jest puste
		shift @$tds;

		#	przeciwnicy i runda zmieniają się w wierszach, które mają w 3. (teraz już w 2.) kolumnie link
		if  ( $tds->[1]->find('a')->size ) {
			$round	= $tds->[0]->text;
			$opps 	= $tds->[1]->find('a')->first->text;
			$opps	= ( split /\d+:|,/, $opps )[1];
			#	dostosowanie formatu, tj. zabranie dwóch już-dalej-zbędnych kolumn
			splice @$tds, 0, 2;
		}

		#	numer rozdania
		my $board_td = shift @$tds;
		my $board	 = $board_td->find('a')->first->text;

		#	linia
		my $line_td = shift @$tds;
		my ( $ns, $ew );
		my $line 	= ( $line_td->text =~ /NS/ ) ? 'NS' : 'EW';
		($ns, $ew) 	= ( $line eq 'NS' ) ?( $players, $opps ) : ( $opps, $players );
		
		#	w tym momencie zostały kolumny od 'kontrakt' w prawo, one w zależności od
		#	średnich, PASSów itp mogą się różnić, ale na pewno
		my $contract 		= $self->_parse_contract( $tds->[0] );	#	contract to może też być PASS i APP
		my $board_points 	= $tds->[-2]->text;
		my $current_points	= $tds->[-1]->text;
		
		#	oraz może
		my $declarer = ( @$tds >= 4 ) ? $self->_parse_declarer( $tds->[1] 			 ) : '';
		my $lead	 = ( @$tds >= 5 ) ? $self->_parse_lead	  ( $tds->[2] 			 ) : '';
		my $result	 = ( @$tds >= 6 ) ? $self->_parse_result  ( $tds->[3] 			 ) : '';
		my $score	 = ( @$tds >= 8 ) ? $self->_parse_score   ( $tds->[4], $tds->[5] ) : '';

		my $text_res = join ( '', ( map { "<td>$_&nbsp;&nbsp;</td>" } ( $contract, $declarer, $lead, $result, $score ) ) );

		my $caption	= ''
			. '<table>'
			. '<tr><th>Round&nbsp;&nbsp;&nbsp;</th><th>Board&nbsp;&nbsp;&nbsp;</th><th>Score&nbsp;&nbsp;&nbsp;</th><th>Current</th></tr>'
			. '<tr>' 
				.	'<td>' . $round . '</td>'
				.	'<td>' . $board. '</td>'
				.	'<td>' . $board_points. '</td>'
				.	'<td>' . $current_points . '</td>'
			. '</tr></table>'
			;

		push @$pages, {
			address 	=> $address,
			name		=> 'Board ' . $board . '   ' 
							. $self->_no_html_suits($contract) . '   ' . $result . ' | '
							. $board_points,
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
	return $pages;
}

sub _get_gallery_name
{
	my $self 	= shift;
	my $title	= $self->dom->find('td[class=o1]')->first->text;
	return $title;
}

sub _parse_contract
{
	my $self	= shift;
	my $td 		= shift;
	my $contr 	= $td->text;
	my $img		= $td->find('img')->first || return $contr;
	my $suit	= $img->attr('alt');
	$suit		= $self->_parse_suit($suit);
	$contr		= ( length $contr > 1 ) ? substr($contr, 0, 1 ) . $suit . substr($contr, 1) : $contr . $suit;
	return $contr;
}

sub _parse_declarer
{
	my $self	= shift;
	my $td 		= shift;
	return uc $td->text;
}

sub _parse_lead
{
	my $self = shift;
	my $td 	 = shift;
	my $card = $td->text;
	my $img	 = $td->find('img')->first || return '';
	my $suit = $img->attr('alt');
	$suit	 = $self->_parse_suit($suit);
	return $card . $suit;
}

sub _parse_result
{
	my $self	= shift;
	my $td		= shift;
	return '' if not $td;
	return $td->text;
}

sub _parse_score
{
	my $self	= shift;
	my $td1		= shift;
	my $td2		= shift;
	return $td1->text || $td2->text;
}

1;
