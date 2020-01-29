package BB::Parser::TCTeam;
use Moose;
use JSON;

use lib '.';
use BB::Board::TCTeamNS;
use BB::Board::TCTeamEW;

extends 'BB::Parser';

use Data::Dumper;

has _raw_data => (
    is      => 'rw',
    builder => '_build_raw_data',
    lazy    => 1,
);

sub _get_pages
{
	my $self 	= shift;
    $self->_raw_data;

	my $pages	= [];
    my $scores  = $self->_raw_data->{'Scores'};
    for my $score (@$scores) {
        my $nr  = $score->{'Board'};
        my $url = $self->_board_url($nr);

        my $ob = BB::Board::TCTeamNS->new($score);
        my $cb = BB::Board::TCTeamEW->new($score);

		my $comment	= ''
					. '<table>'
					. '<tr><th></th><th>Open</th><th>Closed</th>'
					. "<tr><th>NS&nbsp;</th><td>" . $ob->ns . "&nbsp;&nbsp;</td><td>" . $cb->ns . "</td></tr>"
					. "<tr><th>EW&nbsp;</th><td>" . $ob->ew . "&nbsp;&nbsp;</td><td>" . $cb->ew . "</td></tr>"
					. '</table>'
					
					. "<br><div><b>" . $ob->caption . "</b></div>"
					
					. '<table>' 
					. "<tr><th>O&nbsp;</th>" . $ob->html_summary . "</tr>"
					. "<tr><th>C&nbsp;</th>" . $cb->html_summary . "</tr>"
					. '</table>'
					;

		my $page = {
			address 	=> $url,
			name		=> 	'Board ' . $nr  . ' ' . $ob->contract . ' ' . $ob->result . ' | ' . 
							                        $cb->contract . ' ' . $cb->result . ' | ' . $ob->ns_points,
			comments 	=> [
				{
					author 	=> 'BridgeBoards.com',
					comment => $comment,
				}
			],
		};
		push @$pages, $page;
    }
	
    return $pages;
}

sub _board_url
{
    my $self = shift;
    my $nr   = shift;

    my @url_parts = split '/', $self->url;
    my $base_url = join '/', @url_parts[0 .. @url_parts - 2];
    my $board_url = join '', $base_url, '/p', $nr, '.html';

    return $board_url;
}

sub _get_gallery_name
{
	my $self 	= shift;
    return 'AAAAA';
}

sub _build_raw_data 
{
    my $self = shift;
    my $url  = $self->url;
    
    my ($base_url, $_1, $board_nr, $_2, $segment, $_3, $_4, $table) = $url =~ /^(.+\/).*\#.....(\d\d\d)(\d\d\d)(\d\d\d)(\d\d\d)(\d\d\d)(\d\d\d)(...)$/i;
    $table =~ s/^0+//g;
    my $data_url = $base_url . 's' . $table . '-' . int($_2) . '-' . int($segment) . '-' . int($_3) . '.json';

    my $data = decode_json($self->ua->get( $data_url )->res->body);
    return $data;
}

1;
