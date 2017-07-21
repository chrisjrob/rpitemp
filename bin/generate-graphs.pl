#!/usr/bin/perl
#
#

use strict;
use warnings;

my $filename = '../readings-extract.json';

if (not -e $filename) {
    die "$filename does not exist";
}

my @data = get_graph_data( $filename );

use GD::Graph::lines;

my $graph = GD::Graph::lines->new(800, 600);
$graph->set( 
    title               => 'Server Room Temperature',
    bgclr               => 'white',
    transparent         => 0,
    x_label             => 'Time',
    y_label             => 'Temperature',
    x_labels_vertical   => 1,
) or die $graph->error;

my $gd = $graph->plot(\@data) or die $graph->error;

open(IMG, '>file.png') or die $!;
binmode IMG;
print IMG $gd->png;

exit;

sub get_graph_data {
    my $filename = shift;

    my $history_ref = load_json_from_file( $filename );

    my @data;
    foreach my $timestamp (sort keys %{ $history_ref } ) {
        my $date = date_from_epoch($timestamp);
        push(@{ $data[0] }, $date);
        my $index = 1;
        foreach my $sensor (sort keys %{ $history_ref->{ $timestamp } }) {
            push(@{ $data[ $index ] }, $history_ref->{ $timestamp }{ $sensor });
            $index++;
        }
    }

    return @data;
}

sub date_from_epoch {
    my $epoch = shift;

    use DateTime;

    my $dt = DateTime->from_epoch( epoch => $epoch );

    return $dt->ymd('-') . ' ' . substr($dt->hms(':'),0,5);
}

sub load_json_from_file {
    my $file = shift;

    use File::Slurp;
    use JSON;

    my $json = '{}';
    if ( (defined $file) and (-e $file) ) {
        $json = read_file $file;
    }
    my $data  = from_json($json, {utf8 => 0}); 

    return $data;
}

