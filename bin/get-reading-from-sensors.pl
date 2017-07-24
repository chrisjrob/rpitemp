#!/usr/bin/perl
# get-reading-from-sensors.pl
#
# Gets readings from temperature sensors and writes 
# to file

# Configuration

my $device_path         = "/sys/bus/w1/devices";
my $json_valid_filename = '/home/pi/rpitemp/readings-valid.json';
my $json_rough_filename = '/home/pi/rpitemp/readings-rough.json';

# End of configuration

my $time = time;

my $readings;
$readings->{ $time } = get_readings($device_path);
append_readings_to_rough($json_rough_filename, $readings);
create_valid_json_from_rough($json_rough_filename, $json_valid_filename);

exit;

sub create_valid_json_from_rough {
    my ($json_rough_filename, $json_valid_filename) = @_;

    # Use a tempfile then copy to minimise risk
    # of another program being unable to read file
    my $tempfile = "$json_valid_filename~";

    open(my $fh_rough, "<", $json_rough_filename) 
        or die "Cannot read $json_rough_filename: $!";

    open(my $fh_valid, ">", $tempfile) 
        or die "Cannot write to $tempfile $!";

    print $fh_valid "{\n";

    my $first_line = 1;
    while (defined (my $line = <$fh_rough>) ) {
        chomp($line);

        # Must not have comma on final line, but 
        # difficult to spot final line so instead 
        # start each line by putting comma on end 
        # of last line
 
        if ($first_line == 1) {
            print $fh_valid $line;
            $first_line = 0;
        } else {
            print $fh_valid ",\n$line";
        }

    }
    print $fh_valid $line, "\n}";

    close($fh_rough) or die "Cannot close $json_rough_filename: $!";
    close($fh_valid) or die "Cannot close $tempfile $!";

    rename($tempfile, $json_valid_filename) 
        or die "Cannot rename $tempfile to $json_valid_filename: $!";

    return;
}

# Writes to an easily append-able but invalid JSON file
sub append_readings_to_rough {
    my ($filename, $readings) = @_;

    use JSON;
    my $json_text = encode_json($readings);

    # Remove as these are child entries only
    # conversion to valid will wrap whole
    # data set
    $json_text =~ s/^\{//;
    $json_text =~ s/\}$//;

    open(my $fh, ">>", $filename) 
        or die "Cannot append $filename: $!";

    print $fh $json_text, "\n";

    close($fh) or die "Cannot close $filename: $!";

    return;
}

sub get_readings {
    my $device_path = shift;

    chdir($device_path);
    my @sensors = list_sensors();

    my $readings;
    foreach my $sensor (@sensors) {
      $readings->{ $sensor } = read_temperature($sensor);
    }

    return $readings;
}

sub read_temperature {
  my $sensor = shift;

  my $filename = "$sensor/w1_slave";

  if (! -e $filename) {
    die "$filename does not exist";
  }

  my $text = read_file($filename);

  my $temp;
  if ($text =~ /t=(\d+)\s*$/s) {
    $temp = $1/1000;
  }

  return $temp;
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

sub list_sensors {
  my @files = glob("*");

  my @sensors;
  foreach my $file (@files) {
    my $filename = "$file/w1_slave";

    if (-f $filename) {
      push(@sensors, $file);
    }
  }

  return @sensors;
}
