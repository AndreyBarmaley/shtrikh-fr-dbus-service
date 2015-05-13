#!/usr/bin/perl
 
use Net::DBus;
 
my $dbus = Net::DBus->system();
die("error: $!\n") unless($dbus);

my $service = $dbus->get_service("ru.shtrih_m.fr.kassa1");
die("error: $!\n") unless($service);

my $object = $service->get_object("/ru/shtrih_m/fr/kassa1/object", "ru.shtrih_m.fr.kassa1.interface");
die("error: $!\n") unless($object);

my $pass = 30;
my $res = $object->device_get_type();
print "$_: ", $res->{$_}, "\n" for ( keys %{$res} );
if($res->{ERROR_CODE}){ print "error: ", $object->device_get_error(), "\n"; exit 1; }

$res = $object->device_get_communication_params($pass, 0);
print "$_: ", $res->{$_}, "\n" for ( keys %{$res} );
if($res->{ERROR_CODE}){ print "error: ", $object->device_get_error(), "\n"; exit 1; }

$res = $object->device_get_status($pass);
print "$_: ", $res->{$_}, "\n" for ( keys %{$res} );
if($res->{ERROR_CODE}){ print "error: ", $object->device_get_error(), "\n"; exit 1; }

$object->emit_signal("service_shutdown");
