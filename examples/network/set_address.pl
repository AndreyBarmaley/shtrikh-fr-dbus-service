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

my @tables = ();

for my $table (1 .. 24)
{
    $res = $object->device_get_structure_table($pass, $table);
    unless($res->{ERROR_CODE})
    {
	$res->{TABLE_ID} = $table;
	push @tables, $res;
    }
    else
    {
	print "table id: ", $table, ", error: ", $object->device_get_error(), "\n";
    }
}

print "IP ADDRESS: ", get_ipaddress($object), "\n";
print "NETMASK: ", get_netmask($object), "\n";
print "GATEWAY: ", get_gateway($object), "\n";
print "DNS: ", get_dns($object), "\n";
print "OFD: ", get_ofd($object), "\n";

print "---------------------------------\n";

set_ipaddress($object, "192.168.7.102");
set_netmask($object, "255.255.255.0");
set_gateway($object, "192.168.7.1");
set_dns($object, "10.0.0.4");
set_ofd($object, "193.0.214.11", 7777);

print "IP ADDRESS: ", get_ipaddress($object), "\n";
print "NETMASK: ", get_netmask($object), "\n";
print "GATEWAY: ", get_gateway($object), "\n";
print "DNS: ", get_dns($object), "\n";
print "OFD: ", get_ofd($object), "\n";

sub set_ofd
{
    my $obj = shift;
    my $addr = shift;
    my $port = shift;
    my $res = 0;

    $res = $obj->device_set_write_table($pass, 19, 1, 1, [ (0) x 64 ]);
    if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }

    $res = $obj->device_set_write_table($pass, 19, 1, 1, [ unpack("C*", $addr) ]);
    if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }

    $res = $obj->device_set_write_table($pass, 19, 1, 2, [ unpack("CC", pack("v", $port)) ]);
    if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
}

sub set_ipaddress
{
    my $obj = shift;
    my @ipaddr = split(/\./, shift);
    my $res = 0;

    foreach my $field (3 .. 6)
    {
	my $val = shift @ipaddr;
	$res = $obj->device_set_write_table($pass, 16, 1, $field, [ $val ]);
	if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
    }
}

sub set_netmask
{
    my $obj = shift;
    my @mask = split(/\./, shift);
    my $res = 0;

    foreach my $field (11 .. 14)
    {
	my $val = shift @mask;
	$res = $obj->device_set_write_table($pass, 16, 1, $field, [ $val ]);
	if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
    }
}

sub set_gateway
{
    my $obj = shift;
    my @ipaddr = split(/\./, shift);
    my $res = 0;

    foreach my $field (7 .. 10)
    {
	my $val = shift @ipaddr;
	$res = $obj->device_set_write_table($pass, 16, 1, $field, [ $val ]);
	if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
    }
}

sub set_dns
{
    my $obj = shift;
    my @ipaddr = split(/\./, shift);
    my $res = 0;

    foreach my $field (15 .. 18)
    {
	my $val = shift @ipaddr;
	$res = $obj->device_set_write_table($pass, 16, 1, $field, [ $val ]);
	if($res->{ERROR_CODE}){ print "error: ", $obj->device_get_error(), "\n"; exit 1; }
    }
}

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

sub get_hexstr2
{
    return "0x" . sprintf("%.2X", shift);
}

sub get_hexdump
{
    return join(", ", map(get_hexstr2(ord($_)), split('', shift)));
}
