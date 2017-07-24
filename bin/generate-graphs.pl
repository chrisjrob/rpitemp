#!/usr/bin/perl
#
#

use strict;
use warnings;

my $filename = 'readings-valid.json';

if (not -e $filename) {
    die "$filename does not exist";
}

my $data = get_graph_data( $filename );

foreach my $week (sort keys %{ $data }) {
    produce_graph_for_week($week, $data->{ $week });
}

exit;

sub produce_graph_for_week {
    my ($week, $data) = @_;

    use GD::Graph::lines;

    my $graph = GD::Graph::lines->new(800, 400);
    $graph->set( 
        title               => "Server Room Temperature - Week $week",
        bgclr               => 'white',
        transparent         => 0,
        x_label             => 'Time',
        x_labels_vertical   => 1,
        x_label_skip        => 24,
        x_last_label_skip   => 1,
        y_label             => 'Temperature',
    ) or die $graph->error;

    my $gd = $graph->plot($data) or die $graph->error;

    open(IMG, '>', "graphs/$week.png") or die $!;
    binmode IMG;
    print IMG $gd->png;

}

sub get_graph_data {
    my $filename = shift;

    my $history_ref = load_json_from_file( $filename );

    my $data;
    foreach my $timestamp (sort keys %{ $history_ref } ) {
        my ($week, $date) = date_from_epoch($timestamp);
        push(@{ $data->{ $week }[0] }, $date);
        push(@{ $data->{ $week }[1] }, 30);
        push(@{ $data->{ $week }[2] }, 28);
        my $index = 3;
        foreach my $sensor (sort keys %{ $history_ref->{ $timestamp } }) {
            push(@{ $data->{ $week }[ $index ] }, $history_ref->{ $timestamp }{ $sensor });
            $index++;
        }
    }

    return $data;
}

sub date_from_epoch {
    my $epoch = shift;

    use DateTime;

    my $dt = DateTime->from_epoch( epoch => $epoch );

    return(
        $dt->year() . '-' . $dt->week(),
        $dt->ymd('-') . ' ' . substr($dt->hms(':'),0,5)
    );
}

sub load_json_from_file {
    my $file = shift;

    use JSON;

    my $json = '{}';
    if ( (defined $file) and (-e $file) ) {
        $json = read_file($file);
    }
    my $data  = from_json($json, {utf8 => 0}); 

    return $data;
}

sub read_file {
  my $file = shift;

  open(my $fh, "<", $file)
    or die "Cannot open $file for reading: $!";

  local $/ = undef;

  my $text = <$fh>;

  close($fh) 
    or die "Cannot close $file: $!";

  return $text;
}

