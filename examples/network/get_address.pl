#!/usr/bin/perl
 
use strict;
use Net::DBus;
use utf8;
 
my $dbus = Net::DBus->system();
my $res = 0;
my $pass = 30;

die("error: $!\n") unless($dbus);

my $service = $dbus->get_service("ru.shtrih_m.fr.kassa1");
die("error: $!\n") unless($service);

my $object = $service->get_object("/ru/shtrih_m/fr/kassa1/object", "ru.shtrih_m.fr.kassa1.interface");
die("error: $!\n") unless($object);

print "IP ADDRESS: ", get_ipaddress($object), "\n";
print "NETMASK: ", get_netmask($object), "\n";
print "GATEWAY: ", get_gateway($object), "\n";
print "DNS: ", get_dns($object), "\n";
print "OFD: ", get_ofd($object), "\n";

sub get_ipaddress
{
    my $obj = shift;
    my @arr = ();

    foreach my $field (3 .. 6)
    {
	my $res = $obj->device_get_read_table($pass, 16, 1, $field);
	if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
	push @arr, hex($res->{VALUE});
    }

    return join('.', @arr);
}

sub get_gateway
{
    my $obj = shift;
    my @arr = ();

    foreach my $field (7 .. 10)
    {
	my $res = $obj->device_get_read_table($pass, 16, 1, $field);
	if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
	push @arr, hex($res->{VALUE});
    }

    return join('.', @arr);
}

sub get_netmask
{
    my $obj = shift;
    my @arr = ();

    foreach my $field (11 .. 14)
    {
	my $res = $obj->device_get_read_table($pass, 16, 1, $field);
	if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
	push @arr, hex($res->{VALUE});
    }

    return join('.', @arr);
}

sub get_dns
{
    my $obj = shift;
    my @arr = ();

    foreach my $field (15 .. 18)
    {
	my $res = $obj->device_get_read_table($pass, 16, 1, $field);
	if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
	push @arr, hex($res->{VALUE});
    }

    return join('.', @arr);
}

sub get_ofd
{
    my $obj = shift;
    my $res = 0;

    $res = $obj->device_get_read_table($pass, 19, 1, 1);
    if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
    my $ipaddr = join('', map(chr(hex($_)), split(/,\s*/, $res->{VALUE})));

    $res = $obj->device_get_read_table($pass, 19, 1, 2);
    if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
    my $port = unpack("v", join('', map(chr(hex($_)), split(/,\s*/, $res->{VALUE}))));
    return join(':', $ipaddr, $port);
}
