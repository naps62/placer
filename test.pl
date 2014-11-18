#!/usr/bin/perl -w
use strict;
use warnings;

use Time::HiRes qw(usleep);

use constant SLEEP_ON_DESKTOP_MOVE => 0.3;
use constant SLEEP_WAIT_FOR_WINDOW => 0.2;

my @resolutions = map { $_ =~ /([0-9]+)x/; $1 } grep(/[*]/, `xrandr`);

sub my_usleep {
  usleep(@_ * 1000000);
}

sub move_to_desktop {
  `wmctrl -s @_`;
  my_usleep(SLEEP_ON_DESKTOP_MOVE);
}

sub move_window_to_desktop {
  my ($window, $desktop) = @_;
  `wmctrl -r "$window" -t $desktop`;
  my_usleep(SLEEP_ON_DESKTOP_MOVE);
}

sub open_program {
  print @_, "\n";
  my ($cmd) = @_;
  # `$cmd 2> /dev/null`;
  `firefox-aurora &`;
  print "opened";
}

sub window_exists {
  `wmctrl -l` =~ /@_/
}

sub wait_for_window {
  print "wait_for_window\n";
  my ($regex) = @_;
  print $regex, "\n";
  until (window_exists($regex)) {
    my_usleep(SLEEP_WAIT_FOR_WINDOW);
  }
  print "waited\n";
}

sub place_window {
  print "place_window\n";
  my ($window, $screen, $position) = @_;
  if ($position =~ /fullscreen/) {
    `wmctrl -r "$window" -b add,fullscreen`;
  } elsif (!($position =~ /default/)) {
    `wmctrl -r "$window" -b remove,fullscreen`;
  }

  # offset x position according to screen
  # sum up width of all previous screens
  my @coords = split(',', $position);
  for(0 .. $screen-1) {
    $coords[0] += $resolutions[$_]
  }
  $position = join(',', @coords);
  `wmctrl -r "$window" -e 0,$position`;
}

sub run {
  my ($cmd, $regex, $desktop, $screen, $position) = @_;
  if (!window_exists($regex)) {
    print "window doesn't exist yet\n";
    move_to_desktop($desktop);
    open_program($cmd);
    wait_for_window($regex);
  } else {
    print "window already exists\n";
    move_window_to_desktop($cmd, $desktop);
  }
  place_window($cmd, $screen, $position);
}

# run("skype", "Skype", 0, "0,300,300,300");

my %config = do 'placer.yml';
my ($app, $args, $subkey, $subvalue);
while (($app, $args) = each %config) {
  my ($cmd, $regex, $desktop, $screen, $position);
  $cmd      = $args->{'cmd'}      || $app;
  $regex    = $args->{'regex'}    || $app;
  $desktop  = $args->{'desktop'}  || 0;
  $screen   = $args->{'screen'}   || 0;
  $position = $args->{'position'} || 'default';

  run($cmd, $regex, $desktop, $screen, $position);
}
