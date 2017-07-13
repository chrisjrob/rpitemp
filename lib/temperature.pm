package temperature;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/view' => \&view_temperatures;
get '/json' => \&json_temperatures;

true;

sub json_temperatures {
  my $sensors = get_temperature();

  return {
    sensors => $sensors,
  };
}

sub view_temperatures {
  my $sensors = get_temperature();

  return template "temperature", {
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

