package BB::Parser::RRB;
use Moose;

extends 'BB::Parser';

use Data::Dumper;

sub _get_pages
{
	my $self 	= shift;
	my $dom		= $self->dom;
    my $gallery_name    = $self->gallery_name;
	
	my $pages	= [];
		
	my $base_url	= $self->url;
	$base_url		=~ s/\/h\d+\.txt$//;

    my $players = $dom->find('h2')->first->text;
    $players =~ s/^[^ ]* //;
	
	my $round;
    my $opponents;

	my $rows = $dom->find('table[class=datatable]')->first->find('tbody')->first->find('tr')->to_array;
	pop @$rows;
	pop @$rows;

	for my $row ( @$rows ) {
		my $tds 	= $row->find('td')->to_array;

		#	aby pierwszy wiersz rundy miał taką strukturę jak wszystkie pozostałe
		if ( $tds->[0]->text ) {
            $round		= $tds->[0]->text;
            $opponents = $tds->[1]->all_text;

			shift @$tds;
			shift @$tds;
		}

		my $board_nr	= $tds->[0]->find('a')->first->text;
        my $line = $tds->[1]->text;
        my $contract = $self->_contract($tds->[2]);
		my $html_contract 	= $contract =~ /^\d/ ? $self->_html_suits( $contract ) : $contract;
        my $declarer = $tds->[3]->text;
        my $lead = $self->_lead($tds->[4]);
        my $result = $tds->[5]->text;
        my $score = $tds->[6]->text;
        my $points = $tds->[7]->text;
        my $current_points = $tds->[8]->text;
        my $ns = $line eq 'NS' ? $players : $opponents;
        my $ew = $line eq 'EW' ? $players : $opponents;

		my $url			= "http://bridgeboards.com:3007/ext/page?system=RRB&url=$base_url&nr=$board_nr";

		my $caption	= ''
			. '<table>'
			. '<tr><th>Round&nbsp;&nbsp;&nbsp;</th><th>Board&nbsp;&nbsp;&nbsp;</th><th>Score&nbsp;&nbsp;&nbsp;</th><th>Current</th></tr>'
			. '<tr>' 
				.	'<td>' . $round . '</td>'
				.	'<td>' . $board_nr. '</td>'
				.	'<td>' . $points. '</td>'
				.	'<td>' . $current_points . '</td>'
			. '</tr></table>'
			;
		my $text_res = join ( '', ( map { "<td>$_&nbsp;&nbsp;</td>" } ( $html_contract, $declarer, $lead, $result, $score ) ) );

		push @$pages, {
			address 	=> $url,
			name		=> 'Board ' . $board_nr . '   ' 
							. $contract . '   ' . $points . ' | '
							. $current_points,
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

sub _contract
{
	my ( $self, $td ) = @_;
    my $text = $td->text;
	return 'pass' if lc $text eq '4 pasy';

    my $height = substr($text, 0, 1);

    my $img_src = $td->find('img')->first->attr('src');
    my $suit = $self->_src_to_text_suits($img_src);

	my $dbl = '';
	for ( 0, 1 ) {
		if ( $text =~ /x$/ ) {
			$dbl .= 'x';
            chop($text);
		}
	}

	return join '', $height, $suit, $dbl;
}
sub _lead
{
	my ( $self, $td ) = @_;
    my $card = $td->text;
	return '' if $card eq '';

    my $img_src = $td->find('img')->first->attr('src');
    my $suit = $self->_html_suits($self->_src_to_text_suits($img_src));

	return join '', $card, $suit;
}

sub _get_gallery_name
{
	my $self 	= shift;
	my $name	= $self->gallery_name;
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

