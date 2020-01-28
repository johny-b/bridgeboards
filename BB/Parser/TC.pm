package BB::Parser::TC;
use Moose;
use JSON;

extends 'BB::Parser';

use Data::Dumper;

has _board_url_checked  => (
    is  => 'rw',
    default => 0,
);

has _board_url_works  => (
    is  => 'rw',
    default => 0,
);

sub _get_pages
{
	my $self 	= shift;
	my $dom		= $self->dom;
	
	my $pages	= [];
	
    #   Base url and pair number (nothing is found when url is invalid)
	my ($base_url, $raw_pair_nr) = $self->_parse_url();
    my $pair_nr = $raw_pair_nr + 0;  # remove leading 0's

    #   History data
    my $history_data_url = join '', $base_url, 'h', $pair_nr, '.json';
    my $history_data = decode_json($self->ua->get( $history_data_url )->res->body);

    #   Players
    my $players = $self->_parse_players($history_data->{Participant});

    #   Parse
    for my $r (@{ $history_data->{Rounds} }) {
        my $round      = $r->{Round};
        my $opponents  = $r->{Opponents}->[0]->{Name};
        for my $b (@{ $r->{Scores} }) {
            my $board_nr    = $b->{Board};
            my $line        = $b->{Line};
            my $s           = $b->{Score};
            my ($contract, $declarer, $lead, $result, $score);
            if ($s->{WithContract}) {
                $contract    = $self->_parse_contract($s->{Denomination}, $s->{Height}, $s->{Xx});
                $declarer    = $self->_parse_declarer($s->{Declarer});
                $lead        = $self->_parse_lead($s->{Lead});
                $result      = $s->{Overtricks};
                $score       = $s->{Score};
            }
            else {
                ($contract, $declarer, $lead, $result, $score) = ('A', '', '', '', '');
            }
		    my $html_contract 	= $contract =~ /^\d/ ? $self->_html_suits( $contract ) : $contract;
            my $points      = sprintf("%.2f", $b->{Result});
            my $current_points = sprintf("%.2f", $b->{ResultAfterScore});
            my $ns          = $line eq 'NS' ? $players : $opponents;
            my $ew          = $line eq 'EW' ? $players : $opponents;
            my $url         = $self->_board_url($raw_pair_nr, $board_nr);
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
    }
	return $pages;
}

sub _board_url
{
    my ($self, $pair, $nr) = @_;
    
    #   NEW: dedicated board url
    my @url_parts = split '/', $self->url;
    my $base_url = join '/', @url_parts[0 .. @url_parts - 2];
    my $board_url = join '', $base_url, '/p', $nr, '.html';

    #   This URL might not exist, in such case we return to OLD version
    #   (we assume that if there is url for one board, there are for all, so check only once)
    if ($self->_use_board_url($board_url)) {
        return $board_url;
    }
    else {
        #   OLD: board tracking
        my $url = ($self->url =~ /^(.+)\#(\d\d\d)H.(\d\d\d)(\d\d\d)$/i)[0];
        my $padded_nr  = "0" x (3 - length($nr)) . $nr;
        return join '', $url, '#', '000', 'HB', $pair, $padded_nr;
    }
}

sub _use_board_url
{
    my $self = shift;
    my $url = shift;
    if ($self->_board_url_checked) {
        return $self->_board_url_works;
    }
    else {
        my $code = $self->ua->get( $url )->res->code;
        if ($code == '200') {
            $self->_board_url_works(1);
        }
        $self->_board_url_checked(1);

        return $self->_board_url_works;
    }
}




sub _parse_players
{
    my ($self, $p) = @_;
    my $fname_1 = $p->{_person1}->{_firstName};
    my $lname_1 = $p->{_person1}->{_lastName};
    my $fname_2 = $p->{_person2}->{_firstName};
    my $lname_2 = $p->{_person2}->{_lastName};

    return join ' ', $fname_1, $lname_1, '-', $fname_2, $lname_2;
}


sub _parse_lead
{
    my ($self, $l) = @_;
    my $suit    = ('C', 'D', 'H', 'S')[$l->{CardColor}];
    $suit = $self->_html_suits($suit);
    my $card  = (2 .. 10, 'J', 'Q', 'K', 'A')[$l->{CardHeight}];
    return join '', $card, $suit;
}

sub _parse_contract
{
    my ($self, $d, $h, $xx) = @_;
    my $suit        = ('C', 'D', 'H', 'S', 'N')[$d];
    my $modifier    = ('', 'x', 'xx')[$xx];
    my $contract    = join '', $h, $suit, $modifier;
    return $contract;
}

sub _parse_declarer
{
    return ('N', 'S', 'W', 'E')[$_[1]];
}

sub _get_gallery_name
{
	my $self 	= shift;
	my ($base_url, $raw_pair_nr) = $self->_parse_url();
    my $pair_nr = $raw_pair_nr + 0;  # remove leading 0's

    #   Settings data
    my $settings_data_url = join '', $base_url, 'settings.json';
    my $settings_data = $self->ua->get( $settings_data_url )->res->body;
    
    #   Sometimes there is BOM
	print($settings_data_url);
    use File::BOM qw( decode_from_bom );
    my $u = decode_from_bom($settings_data);
    my $name = from_json($u)->{FullName} || '[TOURNAMENT NAME MISSING]';
	return $name;
}

sub _parse_url
{
    my $self    = shift;
    my $url     = $self->url;
    my ($base_url, $tracked, $history, $board)  = $url =~ /^(.+\/).*\#(\d\d\d)H.(\d\d\d)(\d\d\d)\d*$/i;
    return $base_url, $history;
}

1;
