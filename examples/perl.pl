#!/usr/bin/perl
 
use Net::DBus;
 
my $dbus = Net::DBus->system();
die("error: $!\n") unless($dbus);

my $service = $dbus->get_service("ru.shtrih_m.fr");
die("error: $!\n") unless($service);

my $object = $service->get_object("/ru/shtrih_m/fr/object", "ru.shtrih_m.fr.interface");
die("error: $!\n") unless($object);

my $res = $object->device_get_type();
print "$_: ", $res->{$_}, "\n" for ( keys %{$res} );
if($res->{ERROR_CODE}){ print "error: ", $object->device_get_error(), "\n"; exit 1; }

$res = $object->device_get_communication_params(30, 0);
print "$_: ", $res->{$_}, "\n" for ( keys %{$res} );
if($res->{ERROR_CODE}){ print "error: ", $object->device_get_error(), "\n"; exit 1; }

$res = $object->device_get_status(30);
print "$_: ", $res->{$_}, "\n" for ( keys %{$res} );
if($res->{ERROR_CODE}){ print "error: ", $object->device_get_error(), "\n"; exit 1; }
