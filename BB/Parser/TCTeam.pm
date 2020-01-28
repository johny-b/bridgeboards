package BB::Parser::TCTeam;
use Moose;
use JSON;

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
        my $board_nr = $score->{'Board'};
        my $url = $self->_board_url($board_nr);
		my $page = {
			address 	=> $url,
            name        => 'BOARD ' . $board_nr,
			comments 	=> []
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
