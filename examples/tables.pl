#!/usr/bin/perl
 
use Net::DBus;
use strict;
 
my $dbus = Net::DBus->system();
die("error: $!\n") unless($dbus);

my $service = $dbus->get_service("ru.shtrih_m.fr.kassa1");
die("error: $!\n") unless($service);

my $object = $service->get_object("/ru/shtrih_m/fr/kassa1/object", "ru.shtrih_m.fr.kassa1.interface");
die("error: $!\n") unless($object);

my $pass = 30;
my @tables;
my $prompt = "prompt> ";

# read tables
for(1 .. 25)
{
    my $tid = $_;
    my $res = $object->device_get_structure_table($pass, $tid);
    remove_unused($res);
    push @tables, $res;
}

show_tables();
print $prompt;

while(<>)
{
    my $cmd = lc($_);
    chomp $cmd;

    if($cmd eq "exit" || $cmd eq "quit")
    {
	exit;
    }

    if($cmd =~ /help/)
    {
	print "| exit\n";
	print "| help\n";
	print "| show tables\n";
	print "| describe table <tid>\n";
	print "| select <all|fid> from table <tid>\n";
    }
    elsif($cmd =~ /show\s+tables/)
    {
	show_tables();
    }
    elsif($cmd =~ /describe\s+table\s+(\d+)/)
    {
	my $tid = $1;
	my $ref = $tables[$tid - 1];
	my $fields = $ref->{FIELD_COUNT};

	# header
	printf("| FID | TYPE | SIZE | NAME\n");
	printf("|-----+------+------+----------\n");

	# content
	for my $fid (1 .. $fields)
	{
	    my $res = $object->device_get_structure_field($pass, $tid, $fid);
    	    remove_unused($res);
	    printf("| %3d |%5s |%5d | %s\n", $fid, $res->{FIELD_TYPE}, $res->{FIELD_SIZE}, $res->{FIELD_NAME});
	}
    }
    elsif($cmd =~ /select\s+(\w*)\s*from\s+table\s+(\d+)/)
    {
        my $fid = $1;
	my $tid = $2;
	my $ref = $tables[$tid - 1];
	my $fields = $ref->{FIELD_COUNT};
	my $columns = $ref->{COLUMN_COUNT};

	if($fid =~ /(\d+)/)
        {
            select_all_from_table_field($pass, $tid, $fields, $columns, $fid);
	}
        else
        {
            select_all_from_table($pass, $tid, $fields, $columns);
        }
    }

    print $prompt;
}

sub remove_unused
{
    my $res = shift;
    delete $res->{DRIVER_VERSION};

    unless($res->{ERROR_CODE})
    {
        delete $res->{ERROR_CODE};
        delete $res->{ERROR_MESSAGE};
    }
}

sub show_tables
{
    my $tid = 1;
    foreach my $ref (@tables)
    {
	printf("|%3d | %s\n", $tid, $ref->{TABLE_NAME});
	$tid++;
    }
}

sub select_all_from_table
{
    my ($pass, $tid, $fields, $columns, undef) = @_;

    # header
    for my $fid (1 .. $fields)
    {
        my $res = $object->device_get_structure_field($pass, $tid, $fid);
	remove_unused($res);
	printf("| %s ", $res->{FIELD_NAME});
    }
    printf("\n");

    # content
    for my $col (1 .. $columns)
    {
        for my $fid (1 .. $fields)
        {
    	    my $res = $object->device_get_read_table($pass, $tid, $col, $fid);
    	    remove_unused($res);
	    printf("| %s ", $res->{VALUE});
	}
	printf("\n");
    }
}

sub select_all_from_table_field
{
    my ($pass, $tid, $fields, $columns, $fid, undef) = @_;

    # header
    my $res = $object->device_get_structure_field($pass, $tid, $fid);
    remove_unused($res);
    printf("| COLS | %s\n", $res->{FIELD_NAME});
    printf("|------+------------\n");

    # content
    for my $col (1 .. $columns)
    {
    	$res = $object->device_get_read_table($pass, $tid, $col, $fid);
    	remove_unused($res);
	printf("| %4d | %s\n", $col, $res->{VALUE});
    }
}
