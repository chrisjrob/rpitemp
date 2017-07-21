package temperature;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/live/?'           => \&view_temperatures;
get '/live/json/?'      => \&json_temperatures;
get '/live/text/?'      => \&text_temperatures;

get '/history/json/?'   => \&json_history;
get '/history/?'        => \&view_history;

true;

sub view_history {
    my $history = load_json_from_file( config->{files}{history} );

    return template "history", {
        current_page        => params->{page},
        entries_per_page    => 30,
        history             => $history,
    };
}
sub json_history {
    my $history = load_json_from_file( config->{files}{history} );

    return {
        history => $history,
    };
}

sub json_temperatures {
  my $sensors = get_temperature();

  return {
    sensors => $sensors,
  };
}

sub text_temperatures {
  my $sensors = get_temperature();

  return template "text", {
    sensors => $sensors,
  }, { layout => undef };
}

sub view_temperatures {
  my $sensors = get_temperature();

  return template "html", {
    sensors => $sensors,
  };
}

sub get_temperature {
  my $sensors = list_sensors();
  
  foreach my $sensor (keys %{ $sensors }) {
    my $temperature = read_temperature($sensors->{$sensor});
    $sensors->{$sensor}{temperature} = $temperature;
  }

  use Data::Dumper;
  debug( Dumper($sensors) );

  return $sensors;
}

sub list_sensors {
  my $path  = config->{device}{path};
  my @files = glob("$path/*");
  my $name  = config->{device}{name};

  my $sensors;
  foreach my $file (@files) {
    my $sensor = $file;
    $sensor =~ s/^.*\///;

    my $filename = "$file/$name";

    if (-f $filename) {
	$sensors->{$sensor}{filename} = $filename;
    }
  }

  return $sensors;
}

sub read_temperature {
  my $sensor = shift;

  if (! -e $sensor->{filename}) {
    die "$sensor->{filename} does not exist";
  }

  my $text = read_file($sensor->{filename});

  my $temp;
  if ($text =~ /t=(\d+)\s*$/s) {
    $temp = $1;
  }

  return $temp;
}

sub read_file {
  my $file = shift;

  open(my $fh_sensor, "<", $file)
    or die "Cannot open $file for reading: $!";

  $/ = undef;

  my $text = <$fh_sensor>;

  close($fh_sensor) 
    or die "Cannot close $file: $!";

  return $text;
}

sub load_json_from_file {
    my $file = shift;

    my $json = '{}';
    if ( (defined $file) and (-e $file) ) {
        $json = read_file $file;
    }
    my $data  = from_json($json, {utf8 => 0}); 

    return $data;
}

