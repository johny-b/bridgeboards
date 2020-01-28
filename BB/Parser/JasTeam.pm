package BB::Parser::JasTeam;
use Moose;

extends 'BB::Parser';
use Data::Dumper;
use Mojo::DOM;

sub _get_pages
{
	my $self 	= shift;
	my $dom		= $self->dom;
	my $as 		= $dom->find('a[target=popra]')->to_array;
	my $pages	= [];
	for my $link ( @$as ) {
		my $tds		= $link->parent->parent->find('td')->to_array;
		my $imps	= $self->_parse_imps( $tds->[11], $tds->[12] );
		my $h_imps	= $imps;
		#	długi myślnik!
		$h_imps		=~ s/^-$/&mdash;/;
		my $caption	= 'Board ' . $self->_parse_boardnr( $tds->[5] ) . ('&nbsp;' x 3) . $h_imps;
		my $open	= [
			 $self->_parse_contract	( $tds->[0] ),
			 $self->_parse_declarer	( $tds->[1] ),
			 $self->_parse_lead		( $tds->[2] ),
			 $self->_parse_result		( $tds->[3] ),
			 $self->_parse_score		( $tds->[4] ),
		];
		my $closed	= [
			 $self->_parse_contract	( $tds->[6] ),
			 $self->_parse_declarer	( $tds->[7] ),
			 $self->_parse_lead		( $tds->[8] ),
			 $self->_parse_result		( $tds->[9] ),
			 $self->_parse_score		( $tds->[10] ),
		];
		
		my $open_text 	= join ( '', ( map { "<td>$_&nbsp;&nbsp;</td>" } @$open   ) );
		my $closed_text = join ( '', ( map { "<td>$_&nbsp;&nbsp;</td>" } @$closed ) );

		my $zn		= $dom->find('td[class=znl1]');
		my $ze		= $dom->find('td[class=zel1]');
		my $ons		= substr $zn->[0]->text, 3;
		my $oew		= substr $ze->[1]->text, 3;
		my $cns		= substr $ze->[0]->text, 3;
		my $cew		= substr $zn->[1]->text, 3;
		$_ =~ s/-/<br>/ for $ons, $oew, $cns, $cew;

		my $comment	= ''
					. '<table>'
					. '<tr><th></th><th>Open</th><th>Closed</th>'
					. "<tr><th>NS&nbsp;</th><td>$ons &nbsp;&nbsp;</td><td>$cns</td></tr>"
					. "<tr><th>EW&nbsp;</th><td>$oew &nbsp;&nbsp;</td><td>$cew</td></tr>"
					. '</table>'
					
					. "<br><div><b>$caption</b></div>"
					
					. '<table>' 
					. "<tr><th>O&nbsp;</th>$open_text</tr>"
					. "<tr><th>C&nbsp;</th>$closed_text</tr>"
					. '</table>'
					;

		my $url = $self->_url_abs_p . $link->attr('href');
		my $page = {
			address 	=> $url,
			name		=> 	'Board ' . $self->_parse_boardnr( $tds->[5] )  . ' ' . 
							$self->_no_html_suits($open->[0])   . ' ' . $open->[4]   . ' | ' . 
							$self->_no_html_suits($closed->[0]) . ' ' . $closed->[4] . ' | ' .
							$imps,
			comments 	=> [
				{
					author 	=> 'BridgeBoards.com',
					comment => $comment,
				}
			],
		};
		
		#	LICYTACJA
		my $bidding1 = $self->_bidding( $tds->[0] );
		my $bidding2 = $self->_bidding( $tds->[6] );

		if ( $bidding1 or $bidding2 ) {
			push $page->{comments}, {
				author	=> 'BridgeBoards.com',
				comment	=> "OPEN <br> $bidding1 <br> CLOSED <br> $bidding2",
			};
		}
		push @$pages, $page;
	}
	return $pages;
}

sub _bidding
{
	my ( $self, $td ) = @_;
	my $a 		= $td->find( 'a' )->first   || return '';
	my $onmouse = $a->attr( 'onmouseover' ) || return '';

	#	usunięcie wywołania funkcji javascriptowej
	substr( $onmouse, 0, 5 ) = '';
	substr( $onmouse, -2 ) = '';

	#	obiekt Mojo::DOM do dalszych operacji
	my $tree = Mojo::DOM->new( $onmouse );

	#	&nbsp; -> --
	$tree->find('tr')->first->next->find('td')->each( sub {
		my $td 		= $_;
		my $text	= $td->text;
		if ( $text =~ /\x{a0}/ ) {
			$td->content( '--' );
		}
	});
	#	img -> kolor
	$tree->find('td')->each( sub {
		my $td 		= $_;
		my $img		= $td->find('img')->first 	|| return;
		my $src 	= $img->attr('src') || return;
		$src		=~ m/\/(.)\.gif/;
		my $suit	= $self->_html_suits( $1 );
		$img->remove;
		$td->append_content( "<span>$suit</span>" );
	});
	#	nasze formatowanie tabelki
	$tree->find('tr')->first->find('td')->each( sub {
		my $td 		= $_;
		my $text	= $td->text;
		$text		=~ s/\x{a0}//g;
		$text		.= '&nbsp;'x5;
		$td->content( $text );
	});
	
	my $text = $tree->to_string;
	$text	 =~ s/pass/p/g;

	return $text;
}


sub _parse_boardnr
{	
	my $self	= shift;
	my $td		= shift;
	return $td->find('a')->first->text;
}

sub _parse_imps
{
	my ( $self, $ns, $ew ) = @_;
	my $v1 = $ns->text;
	my $v2 = $ew->text;
	return '+' . $v1 if $v1 =~ /\d/;
	return '-' . $v2 if $v2 =~ /\d/;
	return '-';
}

sub _parse_contract
{
	my $self	= shift;
	my $td 		= shift;
	my $contr 	= $td->all_text;
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
	return '' if not $card;
	return '' if $card =~ /\W/;
	my $suit = $td->find('img')->first->attr('alt');
	$suit	 = $self->_parse_suit($suit);
	return $card . $suit;
}

sub _parse_result
{
	my $self	= shift;
	my $td		= shift;
	return $td->text;
}

sub _parse_score
{
	my $self	= shift;
	my $td		= shift;
	return $td->text;
}

sub _get_gallery_name
{
	my $self = shift;
	my $dom	 = $self->dom;
	
	#	CZĘŚĆ PIERWSZA, NAZWA ZAWODÓW
	my $name	= $self->_get_name_from_load_it || $self->_get_name_from_page_title || $self->url;
	
	#	CZĘŚĆ DRUGA, STÓŁ ITP
	my $table	= $dom->find('td[class=bdnt12]')->first;
	$name		= $name . ' ' . $table->find('a')->first->text . $table->text;

	return $name;
}

#	znajduje nazwę zawodów w loadIt, albo zwraca '', jak go nie ma
sub _get_name_from_load_it
{
	my $self = shift;
	my $dom	 = $self->dom;
	my $ua	 = $self->ua;
	
	my $scripts = $dom->find('script')->to_array;
	my $load_it	= (grep { $_ =~ /loadIt/ } (map { $_->text } @$scripts))[0] || return '';
	my $logo	= (split '\(|,', $load_it)[1];
	$logo		=~ s/'//g;
	my $logo_url = $self->_url_abs_p . $logo;
	my $tx		= $ua->get($logo_url);
	my $name	= $tx->res->dom->find('font[size=5]')->first->text;
	return $name;
}

#	próbuje wczytać nazwę zawodów z tytułu strony
sub _get_name_from_page_title
{
	my $self = shift;
	my $dom	 = $self->dom;
	my $name = $dom->find('title')->[0]->text;
	return $name;
}

1;
