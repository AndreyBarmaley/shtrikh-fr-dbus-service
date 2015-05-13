#!/usr/bin/perl
#
# Shtrih FR protocol module
# Copyright (C) 2015 by shtrikh.fr.dbus team <shtrikh.fr.dbus.service@gmail.com>
# License: under the same terms as Perl itself (Artistic-1.0 or GPL-1.0+)
#

package CashRegister::ShtrihFR;

use CashRegister::ShtrihFR::Messages::Russian;
use Device::SerialPort;
use POSIX qw(strftime);
use Time::HiRes qw(usleep);
use Math::BigInt;
use Encode;

use strict;

use constant
{
    MY_DRIVER_VERSION => 20150513,
    FR_PROTOCOL_VERSION	=> 1.11
};

use constant
{
    GET_DUMP			=> 0x01,
    GET_DATA			=> 0x02,
    SET_BREAK			=> 0x03,
    SET_FISCALIZATION_LONG_RNM	=> 0x0D,
    SET_LONG_SERIAL_NUMBER	=> 0x0E,
    GET_LONG_SERIAL_NUMBER_RNM	=> 0x0F,
    GET_SHORT_STATUS		=> 0x10,
    GET_DEVICE_STATUS		=> 0x11,
    SET_PRINT_BOLD_STRING	=> 0x12,
    SET_BEEP			=> 0x13,
    SET_RS232_PARAM		=> 0x14,
    GET_RS232_PARAM		=> 0x15,
    SET_TECHNICAL_ZERO		=> 0x16,
    SET_PRINT_STRING		=> 0x17,
    SET_PRINT_HEADER		=> 0x18,
    SET_TEST_RUN		=> 0x19,
    GET_CASHE_REGISTER		=> 0x1A,
    GET_OPERATIONAL_REGISTER	=> 0x1B,
    SET_LICENSE			=> 0x1C,
    GET_LICENSE			=> 0x1D,
    SET_WRITE_TABLE		=> 0x1E,
    GET_READ_TABLE		=> 0x1F,
    SET_DECIMAL_POINT		=> 0x20,
    SET_CURRENT_TIME		=> 0x21,
    SET_CURRENT_DATE		=> 0x22,
    SET_DATE_CONFIRM		=> 0x23,
    SET_INIT_TABLES		=> 0x24,
    SET_CUT_CHECK		=> 0x25,
    GET_FONT_PARAMS		=> 0x26,
    SET_TOTAL_DAMPING		=> 0x27,
    SET_OPEN_MONEY_BOX		=> 0x28,
    SET_SCROLL			=> 0x29,
    SET_GETOUT_BACKFILLING_DOC	=> 0x2A,
    SET_BREAK_TEST_RUN		=> 0x2B,
    GET_REGISTERS_VALUES	=> 0x2C,
    GET_STRUCTURE_TABLE		=> 0x2D,
    GET_STRUCTURE_FIELD		=> 0x2E,
    SET_PRINT_FONT_STRING	=> 0x2F,
    GET_DAILY_REPORT		=> 0x40,
    GET_DAILY_REPORT_DAMP	=> 0x41,
    GET_SECTIONS_REPORT		=> 0x42,
    GET_TAXES_REPORT		=> 0x43,
    SET_ADDING_AMOUNT		=> 0x50,
    GET_PAYMENT_AMOUNT		=> 0x51,
    SET_PRINT_CLICHE		=> 0x52,
    SET_DOCUMENT_END		=> 0x53,
    SET_PRINT_AD_TEXT		=> 0x54,
    SET_SERIAL_NUMBER		=> 0x60,
    SET_FP_INIT			=> 0x61,
    GET_FP_SUM_RECORDS		=> 0x62,
    GET_FP_LAST_RECORD_DATE	=> 0x63,
    GET_QUERY_DATE_RANGE_TOUR	=> 0x64,
    SET_FISCALIZATION		=> 0x65,
    GET_FISCAL_REPORT_BY_DATE	=> 0x66,
    GET_FISCAL_REPORT_BY_TOUR	=> 0x67,
    SET_BREAK_FULL_REPORT	=> 0x68,
    GET_FISCALIZATION_PARAMS	=> 0x69,
    SET_OPEN_FISCAL_UNDERDOC	=> 0x70,
    SET_OPEN_STD_FISCAL_UNDERDOC	=> 0x71,
    SET_FORMING_OPERATION_UNDERDOC	=> 0x72,
    SET_FORMING_STD_OPERATION_UNDERDOC	=> 0x73,
    SET_FORMING_DISCOUNT_UNDERDOC	=> 0x74,
    SET_FORMING_STD_DISCOUNT_UNDERDOC	=> 0x75,
    SET_FORMING_CLOSE_CHECK_UNDERDOC	=> 0x76,
    SET_FORMING_STD_CLOSE_CHECK_UNDERDOC=> 0x77,
    SET_CONFIGURATION_UNDERDOC		=> 0x78,
    SET_STD_CONFIGURATION_UNDERDOC	=> 0x79,
    SET_FILL_BUFFER_UNDERDOC		=> 0x7A,
    SET_CLEAR_STRING_UNDERDOC		=> 0x7B,
    SET_CLEAR_BUFFER_UNDERDOC		=> 0x7C,
    SET_PRINT_UNDERDOC			=> 0x7D,
    GET_GENERAL_CONFIGURATION_UNDERDOC	=> 0x7E,
    SET_SELL			=> 0x80,
    SET_BUY			=> 0x81,
    SET_RETURNS_SALE		=> 0x82,
    SET_RETURNS_PURCHASES	=> 0x83,
    SET_REVERSAL		=> 0x84,
    SET_CHECK_CLOSE		=> 0x85,
    SET_DISCOUT			=> 0x86,
    SET_ALLOWANCE		=> 0x87,
    SET_CHECK_CANCELLATION	=> 0x88,
    GET_CHECK_SUBTOTAL		=> 0x89,
    SET_REVERSAL_DISCOUNT	=> 0x8A,
    SET_REVERSAL_ALLOWANCE	=> 0x8B,
    GET_DOCUMENT_REPEAT		=> 0x8C,
    SET_CHECK_OPEN		=> 0x8D,

    #
    # skip commands: 0x90 - 0x9F
    #

    SET_PRINT_CONTINUE		=> 0xB0,
    SET_LOAD_GRAPHICS		=> 0xC0,
    SET_PRINT_GRAPHICS		=> 0xC1,
    SET_PRINT_BARCODE		=> 0xC2,
    SET_LOAD_EXT_GRAPHICS	=> 0xC3,
    SET_PRINT_EXT_GRAPHICS	=> 0xC4,
    SET_PRINT_LINE		=> 0xC5,
    GET_ROWCOUNT_PRINTBUF	=> 0xC8,
    GET_STRING_PRINTBUF		=> 0xC9,
    SET_CLEAR_PRINTBUF		=> 0xCA,
    GET_FR_IBM_STATUS_LONG	=> 0xD0,
    GET_FR_IBM_STATUS		=> 0xD1,
    SET_FLAP_CONTROL		=> 0xF0,
    SET_CHECK_GETOUT		=> 0xF1,
    SET_PASSWORD_CTO		=> 0xF3,
    GET_DEVICE_TYPE		=> 0xFC,
    SET_EXT_DEVICE_COMMAND	=> 0xFD,
};

use constant
{
    CMD_STX     => 0x02,
    CMD_ENQ     => 0x05,
    CMD_ACK     => 0x06,
    CMD_NAK     => 0x15,
};

sub new
{
    my $root = {};

    shift;

    my $port = shift;
    my $speed = shift;
    my $debug = shift;

    my $obj = new Device::SerialPort($port);
    unless($obj)
    {
	warn(__PACKAGE__, ": $!: ", $port) if($debug);
	return undef;
    }

    $obj->baudrate($speed);
    $obj->parity("none");
    $obj->databits(8);
    $obj->stopbits(1);
    $obj->handshake("none");
    $obj->reset_error();
    $obj->user_msg(1);
    $obj->error_msg(1);
    $obj->write_settings();

    $root->{OBJ} = $obj;
    $root->{DEBUG} = $debug;
    $root->{SPEED} = $speed;
    $root->{PORT} = $port;
    $root->{TIMEOUT} = 150000; # 150 ms
    $root->{ERROR_CODE} = 0;
    $root->{ERROR_MESSAGE} = "";
    $root->{MESSAGE} = new CashRegister::ShtrihFR::Messages::Russian();
    $root->{DRIVER_VERSION} = MY_DRIVER_VERSION;

    bless($root);
    return $root;
}

sub find_device
{
    my ($class, @devices) = @_;
    my @speeds = ( 2400, 4800, 9600, 19200, 38400, 57600, 115200 );

    foreach my $file ( @devices )
    {
	if(-r $file && -w $file)
	{
	    foreach my $speed ( @speeds )
	    {
		my $device = CashRegister::ShtrihFR->new($file, $speed);
		last unless($device);
		return $device if($device->is_online());
	    }
	}
    }

    return 0;
}

sub get_message_error
{
    my ($self, $code, undef) = @_;
    return $self->{MESSAGE}->get_error($code);
}

sub get_message_fr_mode
{
    my ($self, $code, undef) = @_;
    return $self->{MESSAGE}->get_fr_mode($code);
}

sub get_message_fr_submode
{
    my ($self, $code, undef) = @_;
    return $self->{MESSAGE}->get_fr_submode($code);
}

sub get_message_fr_flags
{
    my ($self, $flags, undef) = @_;
    return $self->{MESSAGE}->get_fr_flags($flags);
}

sub get_message_fp_flags
{
    my ($self, $flags, undef) = @_;
    return $self->{MESSAGE}->get_fp_flags($flags);
}

sub is_online
{
    my $self = shift;

    if($self->{OBJ}->write(enq()))
    {
	return nak() eq $self->read_byte();
    }

    return 0;
}

sub printing_wait
{
    my ($self, $pass, undef) = @_;

    usleep($self->{TIMEOUT} * 2);

    if($self->is_online())
    {
	while(1)
	{
	    my $res = $self->get_short_status($pass);

	    if($res->{FR_SUBMODE} == 5 || $res->{FR_SUBMODE} == 4)
	    {
		usleep($self->{TIMEOUT} * 2);
	    }
	    else
	    {
		last;
	    }
	}
    }
}

# protocol commands
sub get_dump
{
    my ($self, $pass, $subsystem, undef) = @_;
    my $buf = pack_stx(6, GET_DUMP, "LC", $pass, $subsystem);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($count, undef) = unpack("C", $buf);
		$res->{BLOCK_COUNT} = $count;
	    }
	}
    }

    return $res;
}

sub get_data
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_DATA, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($subsystem, $blocknum, $data) = unpack("Cva32", $buf);

		$res->{SUBSYSTEM} = $subsystem;
		$res->{BLOCK_NUMBER} = $blocknum;
		$res->{DATA} = get_hexdump($data);
	    }
	}
    }

    return $res;
}

sub set_break
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_BREAK, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub set_fiscalization_long_rnm
{
    # rnm is 7 byte: "00000000000000"
    # inn is 6 byte: "000000000000"
    my ($self, $pass_old, $pass_new, $rnm, $inn, undef) = @_;
    my $buf = pack_stx(22, SET_FISCALIZATION_LONG_RNM, "LL(H2)7(H2)6", $pass_old, $pass_new, unpack("(A2)7", $rnm), unpack("(A2)6", $inn));
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($fiscal_number, $fiscal_last, $last_tour, $date_day, $date_month, $date_year, undef) = unpack("CCvCCC", $buf);

		$res->{FISCAL_NUMBER} = $fiscal_number;
		$res->{FISCAL_LAST} = $fiscal_last;
		$res->{FISCAL_DATE} = format_date(2000 + $date_year, $date_month, $date_day);
		$res->{LAST_TOUR_NUMBER} = $last_tour;
	    }
	}
    }

    return $res;
}

sub set_long_serial_number
{
    # serial is 7 byte: "00000000000000"
    my ($self, $pass, $serial, undef) = @_;
    my $buf = pack_stx(12, SET_LONG_SERIAL_NUMBER, "L(H2)7", $pass, unpack("(A2)7", $serial));
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub get_long_serial_number_rnm
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_LONG_SERIAL_NUMBER_RNM, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($num, $rnm, undef) = unpack("a7a7", $buf);

		$res->{SERIAL_NUMBER} = get_hexnum_from_binary_le($num);
		$res->{RNM_NUMBER} = get_hexnum_from_binary_le($rnm);
	    }
	}
    }

    return $res;
}

sub get_short_status
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_SHORT_STATUS, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $flags, $mode, $submode, $count_lo, $battery,
			$power, $err_fp, $err_eklz, $count_hi, $rez, undef) = unpack("CvCCCCCCCCC3", $buf);

		$res->{OPERATOR} = $oper;
		$res->{FR_FLAGS} = $flags;
		$res->{FR_MODE} = $mode;
		$res->{FR_SUBMODE} = $submode;
		$res->{TICKET_OPERATION_COUNT} = $count_hi << 8 | $count_lo;
		$res->{POWER_MAIN} = $power;
		$res->{POWER_BATTERY} = $battery;
		$res->{ERROR_FP} = $err_fp;
		$res->{ERROR_EKLZ} = $err_eklz;

		$res->{MESSAGE_FR_MODE} = $self->get_message_fr_mode($res->{FR_MODE});
		$res->{MESSAGE_FR_SUBMODE} = $self->get_message_fr_submode($res->{FR_SUBMODE});
		$res->{MESSAGE_FR_FLAGS} = join(', ', $self->get_message_fr_flags($res->{FR_FLAGS}));
	    }
	}
    }

    return $res;
}

sub get_device_status
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_DEVICE_STATUS, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $progfr_ver_hi, $progfr_ver_lo, $buildfr_ver, $datefr_day, $datefr_month, $datefr_year,
			$hall_number, $cur_doc, $flagfr, $mode, $submode, $port,
			$progfp_ver_lo, $progfp_ver_hi, $buildfp, $datefp_day, $datefp_month, $datefp_year,
			$date_day, $date_month, $date_year, $time_hour, $time_min, $time_sec, $flag_fp, $serial,
			$last_tour, $open_rec, $fiscal_number, $fiscal_last, $inn, undef) = unpack("CCCvCCCCvvCCCCCvCCCCCCCCCCVvvCCa6", $buf);

		$res->{OPERATOR} = $oper;
		$res->{FR_PROG_VERSION} = join('.', $progfr_ver_hi, $progfr_ver_lo);
		$res->{FR_BUILD_VERSION} = $buildfr_ver;
		$res->{FR_DATE} = format_date(2000 + $datefr_year, $datefr_month, $datefr_day);
		$res->{HALL_NUMBER} = $hall_number;
		$res->{CURRENT_DOC_NUMBER} = $cur_doc;
		$res->{FR_FLAGS} = $flagfr;
		$res->{FR_MODE} = $mode;
		$res->{FR_SUBMODE} = $submode;
		$res->{FR_PORT} = $port;
		$res->{FP_PROG_VERSION} = join('.', $progfp_ver_hi, $progfp_ver_lo);
		$res->{FP_BUILD_VERSION} = $buildfp;
		$res->{FP_DATE} = format_date(2000 + $datefp_year, $datefp_month, $datefp_day);
		$res->{DATE} = format_date(2000 + $date_year, $date_month, $date_day);
		$res->{TIME} = format_time($time_hour, $time_min, $time_sec);
		$res->{FP_FLAGS} = $flag_fp;
		$res->{SERIAL_NUMBER} = $serial;
		$res->{LAST_TOUR_NUMBER} = $last_tour;
		$res->{FP_OPEN_RECORDS} = $open_rec;
		$res->{FISCAL_NUMBER} = $fiscal_number;
		$res->{FISCAL_LAST} = $fiscal_last;
		$res->{INN_NUMBER} = get_hexstr_from_binary_le($inn);

		$res->{MESSAGE_FR_MODE} = $self->get_message_fr_mode($res->{FR_MODE});
		$res->{MESSAGE_SUBMODE} = $self->get_message_fr_submode($res->{FR_SUBMODE});
		$res->{MESSAGE_FR_FLAGS} = join(', ', $self->get_message_fr_flags($res->{FR_FLAGS}));
		$res->{MESSAGE_FP_FLAGS} = join(', ', $self->get_message_fp_flags($res->{FP_FLAGS}));
	    }
	}
    }

    return $res;
}

sub set_print_bold_string
{
    my ($self, $pass, $flag, $str, $wait, undef) = @_;
    Encode::from_to($str, "utf8", "cp1251");
    my $buf = pack_stx(26, SET_PRINT_BOLD_STRING, "LCA20", $pass, $flag, $str);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_beep
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_BEEP, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_communication_params
{
    my ($self, $pass, $portnum, $bod, $timeout, undef) = @_;

    my @bods = (2400, 4800, 9600, 19200, 38400, 57600, 115200);
    my ($bod_index, undef) = grep { $bods[$_] eq $bod } 0 .. $#bods;
       $bod_index = 1 unless($bod_index);

    if(30000 <= $timeout && $timeout < 105000)
    {
	$timeout = int(250 + (30000 - $timeout) / 15000);
    }
    elsif(300 <= $timeout && $timeout < 15000)
    {
	$timeout = int(151 + (300 - $timeout) / 150);
    }
    elsif(0 <= $timeout && $timeout < 300)
    {
	# $timeout = $timeout;
    }
    else
    {
	$timeout = 100;
    }

    my $buf = pack_stx(6, SET_RS232_PARAM, "LCCC", $pass, $portnum, $bod_index, $timeout);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    unless($res->{ERROR_CODE})
	    {
		$self->{TIMEOUT} = $timeout * 1000; # ms
	    }
	}
    }

    return $res;
}

sub get_communication_params
{
    my ($self, $pass, $portnum, undef) = @_;
    my $buf = pack_stx(6, GET_RS232_PARAM, "LC", $pass, $portnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($code, $timeout, undef) = unpack("CC", $buf);
		my $bods = [ 2400, 4800, 9600, 19200, 38400, 57600, 115200 ];

	        $res->{SPEED} = $bods->[$code];
		$res->{TIMEOUT} = $timeout;

		if(151 <= $timeout && $timeout <= 249)
		{
		    $res->{TIMEOUT} = 300 + ($timeout - 151) * 150;
		}
		elsif(250 <= $timeout && $timeout <= 255)
		{
		    $res->{TIMEOUT} = 30000 + ($timeout - 250) * 15000;
		}

		# apply timeout
		$self->{TIMEOUT} = $res->{TIMEOUT} * 1000; # ms
	    }
	}
    }

    return $res;
}

sub set_technical_zero
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(1, SET_TECHNICAL_ZERO, "");
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub set_print_string
{
    my ($self, $pass, $flag, $str, $wait, undef) = @_;
    Encode::from_to($str, "utf8", "cp1251");
    my $buf = pack_stx(46, SET_PRINT_STRING, "LCA40", $pass, $flag, $str);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_print_header
{
    my ($self, $pass, $docname, $docnum, $wait, undef) = @_;
    Encode::from_to($docname, "utf8", "cp1251");
    my $buf = pack_stx(37, SET_PRINT_HEADER, "LA30v", $pass, $docname, $docnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $through_doc, undef) = unpack("Cv", $buf);

		$res->{OPERATOR} = $oper;
		$res->{THROUGH_DOC_NUMBER} = $through_doc;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_test_run
{
    my ($self, $pass, $period, undef) = @_;
    my $buf = pack_stx(6, SET_TEST_RUN, "LC", $pass, $period);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub get_cache_register
{
    my ($self, $pass, $regnum, undef) = @_;
    my $buf = pack_stx(6, GET_CASHE_REGISTER, "LC", $pass, $regnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $value, undef) = unpack("Ca6", $buf);
		$res->{OPERATOR} = $oper;
		$res->{REGISTER} = get_hexnum_from_binary_le($value);
	    }
	}
    }

    return $res;
}

sub get_operational_register
{
    my ($self, $pass, $regnum, undef) = @_;
    my $buf = pack_stx(6, GET_OPERATIONAL_REGISTER, "LC", $pass, $regnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $value, undef) = unpack("Cv", $buf);
		$res->{OPERATOR} = $oper;
		$res->{REGISTER} = $value;
	    }
	}
    }

    return $res;
}

sub set_license
{
    # license is 5 byte: "0000000000"
    my ($self, $pass, $license, undef) = @_;
    my $buf = pack_stx(10, SET_LICENSE, "L(H2)5", $pass, unpack("(A2)5", $license));
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub get_license
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_LICENSE, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($license, undef) = unpack("a5", $buf);
		$res->{LICENSE} = get_hexnum_from_binary_le($license);
	    }
	}
    }

    return $res;
}

sub set_write_table
{
    my ($self, $pass, $table, $col, $field, $data, undef) = @_;
    my $buf = pack_stx(9 + length($data), SET_WRITE_TABLE, "LCvCa*", $pass, $table, $col, $field, $data);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub get_read_table
{
    my ($self, $pass, $table, $col, $field, undef) = @_;
    my $buf = pack_stx(9, GET_READ_TABLE, "LCvC", $pass, $table, $col, $field);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		$res->{VALUE} = get_hexdump($buf);
	    }
	}
    }

    return $res;
}

sub set_decimal_point
{
    my ($self, $pass, $pos, undef) = @_;
    my $buf = pack_stx(6, SET_DECIMAL_POINT, "LC", $pass, $pos);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub set_current_time
{
    my ($self, $pass, $hour, $min, $sec, undef) = @_;
    my $buf = pack_stx(8, SET_CURRENT_TIME, "LCCC", $pass, $hour, $min, $sec);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub set_current_date
{
    my ($self, $pass, $year, $mon, $day, undef) = @_;
    my $buf = pack_stx(8, SET_CURRENT_DATE, "LCCC", $pass, $day, $mon, $year);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub set_date_confirm
{
    my ($self, $pass, $year, $mon, $day, undef) = @_;
    my $buf = pack_stx(8, SET_DATE_CONFIRM, "LCCC", $pass, $day, $mon, $year);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub set_init_tables
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_INIT_TABLES, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub set_cut_check
{
    my ($self, $pass, $type, undef) = @_;
    my $buf = pack_stx(6, SET_CUT_CHECK, "LC", $pass, $type);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub get_font_params
{
    my ($self, $pass, $fontnum, undef) = @_;
    my $buf = pack_stx(6, GET_FONT_PARAMS, "LC", $pass, $fontnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($area_width, $char_width, $char_height, $count, undef) = unpack("vCCC", $buf);
		$res->{PRINT_AREA_WIDTH} = $area_width;
		$res->{SYMBOL_WIDTH} = $char_width;
		$res->{SYMBOL_HEIGHT} = $char_height;
		$res->{FONT_COUNT} = $count;
	    }
	}
    }

    return $res;
}

sub set_total_damping
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_TOTAL_DAMPING, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub set_open_money_box
{
    my ($self, $pass, $boxnum, undef) = @_;
    my $buf = pack_stx(6, SET_OPEN_MONEY_BOX, "LC", $pass, $boxnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_scroll
{
    my ($self, $pass, $flags, $rows, undef) = @_;
    my $buf = pack_stx(7, SET_SCROLL, "LCC", $pass, $flags, $rows);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_getout_backfilling_document
{
    my ($self, $pass, $direct, undef) = @_;
    my $buf = pack_stx(6, SET_GETOUT_BACKFILLING_DOC, "LC", $pass, $direct);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_break_test_run
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_BREAK_TEST_RUN, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub get_registers_values
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_REGISTERS_VALUES, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub get_structure_table
{
    my ($self, $pass, $tabnum, undef) = @_;
    my $buf = pack_stx(6, GET_STRUCTURE_TABLE, "LC", $pass, $tabnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($name, $colnum, $fieldnum, undef) = unpack("a40vC", $buf);
		$res->{TABLE_NAME} = Encode::decode("cp1251", $name);
		$res->{COLUMN_COUNT} = $colnum;
		$res->{FIELD_COUNT} = $fieldnum;
	    }
	}
    }

    return $res;
}

sub get_structure_field
{
    my ($self, $pass, $tabnum, $fieldnum, undef) = @_;
    my $buf = pack_stx(7, GET_STRUCTURE_FIELD, "LCC", $pass, $tabnum, $fieldnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($name, $type, $count, $last, undef) = unpack("a40CCa*", $buf);

		$res->{TABLE_NAME} = Encode::decode("cp1251", $name);
		$res->{FIELD_TYPE} = $type;
		$res->{FIELD_SIZE} = $count;
		$res->{FIELD_MIN_VALUE} = get_hexstr_from_binary_le(substr($last, 0, $count));
		$res->{FIELD_MAX_VALUE} = get_hexstr_from_binary_le(substr($last, $count, $count));
	    }
	}
    }

    return $res;
}

sub set_print_font_string
{
    my ($self, $pass, $flag, $fontnum, $str, $wait, undef) = @_;
    Encode::from_to($str, "utf8", "cp1251");
    my $buf = pack_stx(47, SET_PRINT_FONT_STRING, "LCCA40", $pass, $flag, $fontnum, $str);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub get_daily_report
{
    my ($self, $pass, $wait, undef) = @_;
    my $buf = pack_stx(5, GET_DAILY_REPORT, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub get_daily_report_with_damp
{
    my ($self, $pass, $wait, undef) = @_;
    my $buf = pack_stx(5, GET_DAILY_REPORT_DAMP, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub get_sections_report
{
    my ($self, $pass, $wait, undef) = @_;
    my $buf = pack_stx(5, GET_SECTIONS_REPORT, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub get_taxes_report
{
    my ($self, $pass, $wait, undef) = @_;
    my $buf = pack_stx(5, GET_TAXES_REPORT, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_adding_amount
{
    # amount is big int string
    my ($self, $pass, $amount, undef) = @_;
    my $buf = pack_stx(10, SET_ADDING_AMOUNT, "La5", $pass, get_le_bigint5_from_string($amount));
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $through_doc, undef) = unpack("Cv", $buf);
		$res->{OPERATOR} = $oper;
		$res->{THROUGH_DOC_NUMBER} = $through_doc;
	    }
	}
    }

    return $res;
}

sub get_payment_amount
{
    # amount is big int string
    my ($self, $pass, $amount, undef) = @_;
    my $buf = pack_stx(10, GET_PAYMENT_AMOUNT, "La5", $pass, get_le_bigint5_from_string($amount));
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $through_doc, undef) = unpack("Cv", $buf);
		$res->{OPERATOR} = $oper;
		$res->{THROUGH_DOC_NUMBER} = $through_doc;
	    }
	}
    }

    return $res;
}

sub set_print_cliche
{
    my ($self, $pass, $wait, undef) = @_;
    my $buf = pack_stx(5, SET_PRINT_CLICHE, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_document_end
{
    my ($self, $pass, $param, undef) = @_;
    my $buf = pack_stx(6, SET_DOCUMENT_END, "LC", $pass, $param);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_print_ad_text
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_PRINT_AD_TEXT, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_serial_number
{
    # serial is 4 byte: "00000000"
    my ($self, $pass, $serial, undef) = @_;
    my $buf = pack_stx(9, SET_SERIAL_NUMBER, "L(H2)4", $pass, unpack("(A2)4", $serial));
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub set_fp_init
{
    my $self = shift;
    my $buf = pack_stx(1, SET_FP_INIT, "");
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub get_fp_sum_records
{
    my ($self, $pass, $type, undef) = @_;
    my $buf = pack_stx(6, GET_FP_SUM_RECORDS, "LC", $pass, $type);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $salesum, $buysum, $salesum_returns, $buysum_returns, undef) = unpack("Ca8a6a6a6", $buf);

		$res->{OPERATOR} = $oper;
		$res->{SUM_SALE_TOTAL} = get_hexnum_from_binary_le($salesum);
		$res->{SUM_BUY_TOTAL} = get_hexnum_from_binary_le($buysum);
		$res->{SUM_SALE_RETURNS} = get_hexnum_from_binary_le($salesum_returns);
		$res->{SUM_BUY_TOTAL} = get_hexnum_from_binary_le($buysum_returns);
	    }
	}
    }

    return $res;
}

sub get_fp_last_record_date
{
    my ($self, $pass, $type, undef) = @_;
    my $buf = pack_stx(5, GET_FP_LAST_RECORD_DATE, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $type, $date_day, $date_month, $date_year, undef) = unpack("CCCCC", $buf);

		$res->{OPERATOR} = $oper;
		$res->{LAST_RECORD_TYPE} = $type;
		$res->{LAST_RECORD_DATE} = format_date(2000 + $date_year, $date_month, $date_day);
	    }
	}
    }

    return $res;
}

sub get_query_date_range_tour
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_QUERY_DATE_RANGE_TOUR, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($first_day, $first_month, $first_year,
		    $last_day, $last_month, $last_year, $first_number, $last_number,  undef) = unpack("CCCCCCvv", $buf);

		$res->{FIRST_TOUR_DATE} = format_date(2000 + $first_year, $first_month, $first_day);
		$res->{LAST_TOUR_DATE} = format_date(2000 + $last_year, $last_month, $last_day);
		$res->{FIRST_TOUR_NUMBER} = $first_number;
		$res->{LAST_TOUR_NUMBER} = $last_number;
	    }
	}
    }

    return $res;
}

sub set_fiscalization
{
    # rnm is 5 byte: "0000000000"
    # inn is 6 byte: "000000000000"
    my ($self, $pass_old, $pass_new, $rnm, $inn, undef) = @_;
    my $buf = pack_stx(20, SET_FISCALIZATION, "LL(H2)5(H2)6", $pass_old, $pass_new, unpack("(A2)5", $rnm), unpack("(A2)6", $inn));
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($fiscal_number, $fiscal_last, $last_tour, $last_day, $last_month, $last_year, undef) = unpack("CCvCCC", $buf);

                $res->{FISCAL_NUMBER} = $fiscal_number;
                $res->{FISCAL_LAST} = $fiscal_last;
                $res->{FISCAL_DATE} = format_date(2000 + $last_year, $last_month, $last_day);
                $res->{LAST_TOUR_NUMBER} = $last_tour;
	    }
	}
    }

    return $res;
}

sub get_fiscal_report_by_date
{
    my ($self, $pass, $type, $year1, $month1, $day1, $year2, $month2, $day2, undef) = @_;
    my $buf = pack_stx(12, GET_FISCAL_REPORT_BY_DATE, "LCCCCCCC", $pass, $type, $day1, $month1, substr($year1, -2, 2), $day2, $month2, substr($year2, -2, 2));
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($first_day, $first_month, $first_year,
		    $last_day, $last_month, $last_year, $first_number, $last_number,  undef) = unpack("CCCCCCvv", $buf);

		$res->{FIRST_TOUR_DATE} = format_date(2000 + $first_year, $first_month, $first_day);
		$res->{LAST_TOUR_DATE} = format_date(2000 + $last_year, $last_month, $last_day);
		$res->{FIRST_TOUR_NUMBER} = $first_number;
		$res->{LAST_TOUR_NUMBER} = $last_number;
	    }
	}
    }

    return $res;
}

sub get_fiscal_report_by_tour
{
    my ($self, $pass, $type, $firstnum, $lastnum, undef) = @_;
    my $buf = pack_stx(10, GET_FISCAL_REPORT_BY_TOUR, "LCvv", $pass, $type, $firstnum, $lastnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($first_day, $first_month, $first_year,
		    $last_day, $last_month, $last_year, $first_number, $last_number,  undef) = unpack("CCCCCCvv", $buf);

		$res->{FIRST_TOUR_DATE} = format_date(2000 + $first_year, $first_month, $first_day);
		$res->{LAST_TOUR_DATE} = format_date(2000 + $last_year, $last_month, $last_day);
		$res->{FIRST_TOUR_NUMBER} = $first_number;
		$res->{LAST_TOUR_NUMBER} = $last_number;
	    }
	}
    }

    return $res;
}

sub set_break_full_report
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_BREAK_FULL_REPORT, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub get_fiscalization_params
{
    my ($self, $pass, $fiscalnum, undef) = @_;
    my $buf = pack_stx(6, GET_FISCALIZATION_PARAMS, "LC", $pass, $fiscalnum);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($rnm, $inn, $tour_number, $fiscal_day, $fiscal_month, $fiscal_year, undef) = unpack("a5a6vCCC", $buf);

		$res->{RNM_NUMBER} = get_hexnum_from_binary_le($rnm);
		$res->{INN_NUMBER} = get_hexnum_from_binary_le($inn);
		$res->{TOUR_NUMBER_AFTER_FICAL} = $tour_number;
		$res->{FIRST_TOUR_DATE} = format_date(2000 + $fiscal_year, $fiscal_month, $fiscal_day);
	    }
	}
    }

    return $res;
}

sub set_open_fiscal_underdoc
{
    my ($self, $pass, $type, $print_doubles, $count_doubles, $offset_orig_first, $offset_first_second, $offset_second_third, $offset_third_fourth, $offset_fourth_fifth,
	$font_number_cliche, $font_number_header, $font_number_eklz, $font_number_kpk, $string_number_cliche, $string_number_header, $string_number_eklz, $string_number_repeat,
	$offset_cliche, $offset_header, $offset_eklz, $offset_kpk, $offset_repeat, undef) = @_;
    my $buf = pack_stx(26, SET_OPEN_FISCAL_UNDERDOC, "LCCCCCCCCCCCCCCCCCCCCC", $pass, $type, $print_doubles, $count_doubles, $offset_orig_first, $offset_first_second, $offset_second_third, $offset_third_fourth, $offset_fourth_fifth,
	$font_number_cliche, $font_number_header, $font_number_eklz, $font_number_kpk, $string_number_cliche, $string_number_header, $string_number_eklz, $string_number_repeat,
	$offset_cliche, $offset_header, $offset_eklz, $offset_kpk, $offset_repeat);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $through_doc, undef) = unpack("Cv", $buf);
		$res->{OPERATOR} = $oper;
		$res->{THROUGH_DOC_NUMBER} = $through_doc;
	    }
	}
    }

    return $res;
}

sub set_open_standard_fiscal_underdoc
{
    my ($self, $pass, $type, $print_doubles, $count_doubles, $offset_orig_first, $offset_first_second, $offset_second_third, $offset_third_fourth, $offset_fourth_fifth, undef) = @_;
    my $buf = pack_stx(13, SET_OPEN_STD_FISCAL_UNDERDOC, "LCCCCCCCC", $pass, $type, $print_doubles, $count_doubles, $offset_orig_first, $offset_first_second, $offset_second_third, $offset_third_fourth, $offset_fourth_fifth);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $through_doc, undef) = unpack("Cv", $buf);
		$res->{OPERATOR} = $oper;
		$res->{THROUGH_DOC_NUMBER} = $through_doc;
	    }
	}
    }

    return $res;
}

sub set_forming_operation_underdoc
{
    # amount is big int string
    # price is big int string
    # text is 40 byte
    my ($self, $pass, $number_format, $string_count, $string_number, $string_number_mul, $string_number_sum, $string_number_dep,
	$font_number_str, $font_number_count, $font_number_mul, $font_number_price, $font_number_sum, $font_number_dep,
	$count_sym_field_str, $count_sym_field_count, $count_sym_field_price, $count_sym_field_sum, $count_sym_field_dep,
	$offset_field_str, $offset_field_mul, $offset_field_sum, $offset_field_dep,
	$number_string_pd, $amount, $price, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $buf = pack_stx(82, SET_FORMING_OPERATION_UNDERDOC, "LCCCCCCCCCCCCCCCCCCCCCCa5a5CCCCCA40", $pass,
	$number_format, $string_count, $string_number, $string_number_mul, $string_number_sum, $string_number_dep,
	$font_number_str, $font_number_count, $font_number_mul, $font_number_price, $font_number_sum, $font_number_dep,
	$count_sym_field_str, $count_sym_field_count, $count_sym_field_price, $count_sym_field_sum, $count_sym_field_dep,
	$offset_field_str, $offset_field_mul, $offset_field_sum, $offset_field_dep,
	$number_string_pd, get_le_bigint5_from_string($amount), get_le_bigint5_from_string($price), $department, $tax1, $tax2, $tax3, $tax4, $text);

    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_forming_standard_operation_underdoc
{
    # amount is big int string
    # price is big int string
    # text is 40 byte
    my ($self, $pass, 
	$number_string_pd, $amount, $price, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $buf = pack_stx(61, SET_FORMING_STD_OPERATION_UNDERDOC, "LCa5a5CCCCCA40", $pass,
	$number_string_pd, get_le_bigint5_from_string($amount), get_le_bigint5_from_string($price), $department, $tax1, $tax2, $tax3, $tax4, $text);

    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_forming_discount_underdoc
{
    # amount is big int string
    # text is 40 byte
    my ($self, $pass, $string_count, $string_number_str, $string_number_name, $string_number_sum, $font_number_str, $font_number_name, $font_number_sum,
	$count_sym_field_str, $count_sym_field_sum, $offset_field_str, $offset_field_name, $offset_field_sum, $operation_type, $number_string_pd,
	$amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $buf = pack_stx(68, SET_FORMING_DISCOUNT_UNDERDOC, "LCCCCCCCCCCCCCCa5CCCCA40", $pass,
	$string_count, $string_number_str, $string_number_name, $string_number_sum, $font_number_str, $font_number_name, $font_number_sum,
	$count_sym_field_str, $count_sym_field_sum, $offset_field_str, $offset_field_name, $offset_field_sum, $operation_type, $number_string_pd,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $text);

    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_forming_std_discount_underdoc
{
    # amount is big int string
    # text is 40 byte
    my ($self, $pass, $operation_type, $string_number_pd,
	$amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $buf = pack_stx(56, SET_FORMING_STD_DISCOUNT_UNDERDOC, "LCCa5CCCCA40", $pass,
	$operation_type, $string_number_pd, get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $text);

    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_forming_close_check_underdoc
{
    # amount, amount_type2, amount_type3, amount_type4 is big int string
    # discout_on_check is double: 0 - 99,99
    # text is 40 byte
    my ($self, $pass, $string_count, $string_number_amount, $string_number_str, $string_number_cash,
	$string_number_payment_type2, $string_number_payment_type3, $string_number_payment_type4, $string_number_short_change,
	$string_number_return_tax_a, $string_number_return_tax_b, $string_number_return_tax_v, $string_number_return_tax_g, 
	$string_number_sum_tax_a, $string_number_sum_tax_b, $string_number_sum_tax_v, $string_number_sum_tax_g, $string_number_sum_accrual_discount,
	$string_number_sum_discount, $font_number_str, $font_number_itog, $font_number_itog_sum, $font_number_cash,
	$font_number_cash_sum, $font_number_payment_name2, $font_number_payment_sum2, $font_number_payment_name3, $font_number_payment_sum3,
	$font_number_payment_name4, $font_number_payment_sum4, $font_number_change, $font_number_change_sum,
	$font_number_tax_name_a, $font_number_tax_return_a, $font_number_tax_rate_a, $font_number_tax_sum_a,
	$font_number_tax_name_b, $font_number_tax_return_b, $font_number_tax_rate_b, $font_number_tax_sum_b,
	$font_number_tax_name_v, $font_number_tax_return_v, $font_number_tax_rate_v, $font_number_tax_sum_v,
	$font_number_tax_name_g, $font_number_tax_return_g, $font_number_tax_rate_g, $font_number_tax_sum_g,
	$font_number_total, $font_number_sum_discount, $font_number_discount_xx, $font_number_sum_discount_check, $count_sym_field_str,
	$count_sym_field_sum_itog, $count_sym_field_sum_cash, $count_sym_field_type2, $count_sym_field_type3, $count_sym_field_type4, $count_sym_field_change, 
	$count_sym_field_tax_name_a, $count_sym_field_tax_return_a, $count_sym_field_tax_rate_a, $count_sym_field_tax_sum_a,
	$count_sym_field_tax_name_b, $count_sym_field_tax_return_b, $count_sym_field_tax_rate_b, $count_sym_field_tax_sum_b,
	$count_sym_field_tax_name_v, $count_sym_field_tax_return_v, $count_sym_field_tax_rate_v, $count_sym_field_tax_sum_v,
	$count_sym_field_tax_name_g, $count_sym_field_tax_return_g, $count_sym_field_tax_rate_g, $count_sym_field_tax_sum_g,
	$count_sym_field_sum_discount, $count_sym_field_sum_procent_check, $count_sym_field_sum_discount_check, 
	$offset_field_str, $offset_field_itog, $offset_field_itog_sum, $offset_field_cash, $offset_field_cash_sum,
	$offset_field_payment_name2, $offset_field_payment_sum2, $offset_field_payment_name3, $offset_field_payment_sum3, $offset_field_payment_name4,
	$offset_field_payment_sum4, $offset_field_change, $offset_field_change_sum,
	$offset_field_tax_name_a, $offset_field_tax_return_a, $offset_field_tax_rate_a, $offset_field_tax_sum_a,
	$offset_field_tax_name_b, $offset_field_tax_return_b, $offset_field_tax_rate_b, $offset_field_tax_sum_b,
	$offset_field_tax_name_v, $offset_field_tax_return_v, $offset_field_tax_rate_v, $offset_field_tax_sum_v,
	$offset_field_tax_name_g, $offset_field_tax_return_g, $offset_field_tax_rate_g, $offset_field_tax_sum_g,
	$offset_field_total, $offset_field_sum_accrual_discount, $offset_field_discount_xx, $offset_field_sum_discount,
	$number_string_pd, $amount, $amount_type2, $amount_type3, $amount_type4, $discout_on_check, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $buf = pack_stx(182, SET_FORMING_CLOSE_CHECK_UNDERDOC, "LCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCa5a5a5a5vCCCCA40", $pass,
	$string_count, $string_number_amount, $string_number_str, $string_number_cash,
	$string_number_payment_type2, $string_number_payment_type3, $string_number_payment_type4, $string_number_short_change,
	$string_number_return_tax_a, $string_number_return_tax_b, $string_number_return_tax_v, $string_number_return_tax_g, 
	$string_number_sum_tax_a, $string_number_sum_tax_b, $string_number_sum_tax_v, $string_number_sum_tax_g, $string_number_sum_accrual_discount,
	$string_number_sum_discount, $font_number_str, $font_number_itog, $font_number_itog_sum, $font_number_cash,
	$font_number_cash_sum, $font_number_payment_name2, $font_number_payment_sum2, $font_number_payment_name3, $font_number_payment_sum3,
	$font_number_payment_name4, $font_number_payment_sum4, $font_number_change, $font_number_change_sum,
	$font_number_tax_name_a, $font_number_tax_return_a, $font_number_tax_rate_a, $font_number_tax_sum_a,
	$font_number_tax_name_b, $font_number_tax_return_b, $font_number_tax_rate_b, $font_number_tax_sum_b,
	$font_number_tax_name_v, $font_number_tax_return_v, $font_number_tax_rate_v, $font_number_tax_sum_v,
	$font_number_tax_name_g, $font_number_tax_return_g, $font_number_tax_rate_g, $font_number_tax_sum_g,
	$font_number_total, $font_number_sum_discount, $font_number_discount_xx, $font_number_sum_discount_check, $count_sym_field_str,
	$count_sym_field_sum_itog, $count_sym_field_sum_cash, $count_sym_field_type2, $count_sym_field_type3, $count_sym_field_type4, $count_sym_field_change, 
	$count_sym_field_tax_name_a, $count_sym_field_tax_return_a, $count_sym_field_tax_rate_a, $count_sym_field_tax_sum_a,
	$count_sym_field_tax_name_b, $count_sym_field_tax_return_b, $count_sym_field_tax_rate_b, $count_sym_field_tax_sum_b,
	$count_sym_field_tax_name_v, $count_sym_field_tax_return_v, $count_sym_field_tax_rate_v, $count_sym_field_tax_sum_v,
	$count_sym_field_tax_name_g, $count_sym_field_tax_return_g, $count_sym_field_tax_rate_g, $count_sym_field_tax_sum_g,
	$count_sym_field_sum_discount, $count_sym_field_sum_procent_check, $count_sym_field_sum_discount_check, 
	$offset_field_str, $offset_field_itog, $offset_field_itog_sum, $offset_field_cash, $offset_field_cash_sum,
	$offset_field_payment_name2, $offset_field_payment_sum2, $offset_field_payment_name3, $offset_field_payment_sum3, $offset_field_payment_name4,
	$offset_field_payment_sum4, $offset_field_change, $offset_field_change_sum,
	$offset_field_tax_name_a, $offset_field_tax_return_a, $offset_field_tax_rate_a, $offset_field_tax_sum_a,
	$offset_field_tax_name_b, $offset_field_tax_return_b, $offset_field_tax_rate_b, $offset_field_tax_sum_b,
	$offset_field_tax_name_v, $offset_field_tax_return_v, $offset_field_tax_rate_v, $offset_field_tax_sum_v,
	$offset_field_tax_name_g, $offset_field_tax_return_g, $offset_field_tax_rate_g, $offset_field_tax_sum_g,
	$offset_field_total, $offset_field_sum_accrual_discount, $offset_field_discount_xx, $offset_field_sum_discount, $number_string_pd,
	get_le_bigint5_from_string($amount), get_le_bigint5_from_string($amount_type2), get_le_bigint5_from_string($amount_type3), get_le_bigint5_from_string($amount_type4),
	get_binary_discout_check($discout_on_check), $tax1, $tax2, $tax3, $tax4, $text);

    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $change, undef) = unpack("Ca5", $buf);
		$res->{OPERATOR} = $oper;
		$res->{SHORT_CHANGE} = get_string_from_le_bigint5($change);
	    }
	}
    }

    return $res;
}

sub set_forming_std_close_check_underdoc
{
    # amount, amount_type2, amount_type3, amount_type4 is big int string
    # discout_on_check is double: 0 - 99,99
    # text is 40 byte
    my ($self, $pass, $number_string_pd, $amount, $amount_type2, $amount_type3, $amount_type4,
	$discout_on_check, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $buf = pack_stx(72, SET_FORMING_STD_CLOSE_CHECK_UNDERDOC, "LCa5a5a5a5vCCCCA40", $pass, $number_string_pd,
	get_le_bigint5_from_string($amount), get_le_bigint5_from_string($amount_type2), get_le_bigint5_from_string($amount_type3), get_le_bigint5_from_string($amount_type4),
	get_binary_discout_check($discout_on_check), $tax1, $tax2, $tax3, $tax4, $text);

    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $change, undef) = unpack("Ca5", $buf);
		$res->{OPERATOR} = $oper;
		$res->{SHORT_CHANGE} = get_string_from_le_bigint5($change);
	    }
	}
    }

    return $res;
}

sub set_configuration_underdoc
{
    my ($self, $pass, $width_underdoc, $length_underdoc, $print_direction, $array_ref, undef) = @_;
    my $buf = pack_stx(209, SET_CONFIGURATION_UNDERDOC, "LvvCa199", $pass, $width_underdoc, $length_underdoc, $print_direction, @{$array_ref});
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_std_configuration_underdoc
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_STD_CONFIGURATION_UNDERDOC, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_fill_buffer_underdoc
{
    my ($self, $pass, $string_number, $data, undef) = @_;
    my $buf = pack_stx(6 + length($data), SET_FILL_BUFFER_UNDERDOC, "LCa*", $pass, $string_number, $data);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_clear_string_underdoc
{
    my ($self, $pass, $string_number, undef) = @_;
    my $buf = pack_stx(6, SET_CLEAR_STRING_UNDERDOC, "LC", $pass, $string_number);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_clear_buffer_underdoc
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_CLEAR_BUFFER_UNDERDOC, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_print_underdoc
{
    my ($self, $pass, $clear, $type, $wait, undef) = @_;
    my $buf = pack_stx(7, SET_PRINT_UNDERDOC, "LCC", $pass, $clear, $type);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub get_general_configuration_underdoc
{
    my ($self, $pass, $width, $length, $direction, $spacing, $wait, undef) = @_;
    my $buf = pack_stx(7, GET_GENERAL_CONFIGURATION_UNDERDOC, "LvvCC", $pass, $width, $length, $direction, $spacing);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_sell
{
    # quality, price is big int string
    my ($self, $pass, $quality, $price, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(60, SET_SELL, "La5a5CCCCCa40", $pass,
	get_le_bigint5_from_string($quality), get_le_bigint5_from_string($price), $department, $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_buy
{
    # quality, price is big int string
    my ($self, $pass, $quality, $price, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(60, SET_BUY, "La5a5CCCCCa40", $pass,
	get_le_bigint5_from_string($quality), get_le_bigint5_from_string($price), $department, $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_returns_sale
{
    # quality, price is big int string
    my ($self, $pass, $quality, $price, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(60, SET_RETURNS_SALE, "La5a5CCCCCa40", $pass,
	get_le_bigint5_from_string($quality), get_le_bigint5_from_string($price), $department, $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_returns_purchases
{
    # quality, price is big int string
    my ($self, $pass, $quality, $price, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(60, SET_RETURNS_PURCHASES, "La5a5CCCCCa40", $pass,
	get_le_bigint5_from_string($quality), get_le_bigint5_from_string($price), $department, $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_reversal
{
    # quality, price is big int string
    my ($self, $pass, $quality, $price, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(60, SET_REVERSAL, "La5a5CCCCCa40", $pass,
	get_le_bigint5_from_string($quality), get_le_bigint5_from_string($price), $department, $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_check_close
{
    # cash_sum, sum_type2, sum_type3, sum_type4 is big int string
    my ($self, $pass, $cash_sum, $sum_type2, $sum_type3, $sum_type4, $discount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(71, SET_CHECK_CLOSE, "La5a5a5a5vCCCCa40", $pass,
	get_le_bigint5_from_string($cash_sum), get_le_bigint5_from_string($sum_type2), get_le_bigint5_from_string($sum_type3), get_le_bigint5_from_string($sum_type4),
	get_binary_discout_check($discount), $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
                my ($oper, $change, undef) = unpack("Ca5", $buf);
                $res->{OPERATOR} = $oper;
                $res->{SHORT_CHANGE} = get_string_from_le_bigint5($change);
            }
	}
    }

    return $res;
}

sub set_discount
{
    # amount is big int string
    my ($self, $pass, $amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(54, SET_DISCOUT, "La5CCCCa40", $pass,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
                my ($oper, undef) = unpack("C", $buf);
                $res->{OPERATOR} = $oper;
            }
	}
    }

    return $res;
}

sub set_allowance
{
    # amount is big int string
    my ($self, $pass, $amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(54, SET_ALLOWANCE, "La5CCCCa40", $pass,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
                my ($oper, undef) = unpack("C", $buf);
                $res->{OPERATOR} = $oper;
            }
	}
    }

    return $res;
}

sub set_check_cancellation
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, SET_CHECK_CANCELLATION, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
                my ($oper, undef) = unpack("C", $buf);
                $res->{OPERATOR} = $oper;
            }
	}
    }

    return $res;
}

sub get_check_subtotal
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_CHECK_SUBTOTAL, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
                my ($oper, $subtotal, undef) = unpack("Ca5", $buf);
                $res->{OPERATOR} = $oper;
                $res->{CHECK_SUBTOTAL} = get_string_from_le_bigint5($subtotal);
            }
	}
    }

    return $res;
}

sub set_reversal_discount
{
    # amount is big int string
    my ($self, $pass, $amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(54, SET_REVERSAL_DISCOUNT, "La5CCCCa40", $pass,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
                my ($oper, undef) = unpack("C", $buf);
                $res->{OPERATOR} = $oper;
            }
	}
    }

    return $res;
}

sub set_reversal_allowance
{
    # amount is big int string
    my ($self, $pass, $amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;
    my $buf = pack_stx(54, SET_REVERSAL_ALLOWANCE, "La5CCCCa40", $pass,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $text);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
                my ($oper, undef) = unpack("C", $buf);
                $res->{OPERATOR} = $oper;
            }
	}
    }

    return $res;
}

sub get_document_repeat
{
    my ($self, $pass, $wait, undef) = @_;
    my $buf = pack_stx(5, GET_DOCUMENT_REPEAT, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
                my ($oper, undef) = unpack("C", $buf);
                $res->{OPERATOR} = $oper;
            }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_check_open
{
    my ($self, $pass, $type, undef) = @_;
    my $buf = pack_stx(6, SET_CHECK_OPEN, "LC", $pass, $type);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();

	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
                my ($oper, undef) = unpack("C", $buf);
                $res->{OPERATOR} = $oper;
            }
	}
    }

    return $res;
}


























sub set_print_continue
{
    my ($self, $pass, $wait, undef) = @_;
    my $buf = pack_stx(5, SET_PRINT_CONTINUE, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_load_graphics
{
    my ($self, $pass, $linenum, $data, undef) = @_;
    my $buf = pack_stx(46, SET_LOAD_GRAPHICS, "LCa40", $pass, $linenum, @{$data});
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_print_graphics
{
    my ($self, $pass, $first, $last, $wait, undef) = @_;
    my $buf = pack_stx(7, SET_PRINT_GRAPHICS, "LCC", $pass, $first, $last);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_print_barcode
{
    # barcode is big int string
    my ($self, $pass, $barcode, $wait, undef) = @_;
    my $buf = pack_stx(10, SET_PRINT_BARCODE, "La5", $pass, get_le_bigint5_from_string($barcode));
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_load_ext_graphics
{
    my ($self, $pass, $linenum, $data, undef) = @_;
    my $buf = pack_stx(47, SET_LOAD_EXT_GRAPHICS, "Lva40", $pass, $linenum, @{$data});
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_print_ext_graphics
{
    my ($self, $pass, $first, $last, $wait, undef) = @_;
    my $buf = pack_stx(9, SET_PRINT_EXT_GRAPHICS, "Lvv", $pass, $first, $last);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub set_print_line
{
    my ($self, $pass, $repeats, $data, $wait, undef) = @_;
    my $buf = pack_stx(7 + scalar @{$data}, SET_PRINT_LINE, "Lva*", $pass, $repeats, @{$data});
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    $self->printing_wait($pass) if($wait);

    return $res;
}

sub get_rowcount_printbuf
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_ROWCOUNT_PRINTBUF, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($count1, $count2, undef) = unpack("vv", $buf);
		$res->{ROW_COUNT_PRINTBUF} = $count1;
		$res->{ROW_COUNT_PRINTED} = $count2;
	    }
	}
    }

    return $res;
}

sub get_string_printbuf
{
    my ($self, $pass, $numstr, undef) = @_;
    my $buf = pack_stx(7, GET_STRING_PRINTBUF, "Lv", $pass, $numstr);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($data, undef) = unpack("a*", $buf);
		$res->{DATA_STRING} = get_hexdump($data);
	    }
	}
    }

    return $res;
}

sub set_clear_printbuf
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(7, SET_CLEAR_PRINTBUF, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub get_fr_ibm_status_long
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_FR_IBM_STATUS_LONG, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $cur_year, $cur_month, $cur_day, $cur_hour, $cur_min, $cur_sec,
		    $last_tour, $last_docnum, $checks_sale, $checks_buy, $checks_sale_returns, $checks_buy_returns,
		    $open_year, $open_month, $open_day, $open_hour, $open_min, $open_sec,
		    $cash, $status, $flags, undef) = unpack("CCCCCCCvVvvvvCCCCCCa6a8C", $buf);

		$res->{OPERATOR} = $oper;
		$res->{CURRENT_DATE} = format_date(2000 + $cur_year, $cur_month, $cur_day);
		$res->{CURRENT_TIME} = format_time($cur_hour, $cur_min, $cur_sec);
		$res->{LAST_TOUR_NUMBER} = $last_tour;
		$res->{LAST_DOCNUM} = $last_docnum;
		$res->{COUNT_CHECKS_SALE} = $checks_sale;
		$res->{COUNT_CHECKS_BUY} = $checks_buy;
		$res->{COUNT_CHECKS_SALE_RETURNS} = $checks_sale_returns;
		$res->{COUNT_CHECKS_BUY_RETURNS} = $checks_buy_returns;
		$res->{OPEN_TOUR_DATE} = format_date(2000 + $open_year, $open_month, $open_day);
		$res->{OPEN_TOUR_TIME} = format_time($open_hour, $open_min, $open_sec);
		$res->{CASH} = get_hexdump($cash);
		$res->{STATUS} = get_hexdump($status);
		$res->{FLAGS} = $flags;
	    }
	}
    }

    return $res;
}

sub get_fr_ibm_status
{
    my ($self, $pass, undef) = @_;
    my $buf = pack_stx(5, GET_FR_IBM_STATUS, "L", $pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, $status, $flags, undef) = unpack("Ca8C", $buf);
		$res->{OPERATOR} = $oper;
		$res->{STATUS} = get_hexdump($status);
		$res->{FLAGS} = $flags;
	    }
	}
    }

    return $res;
}

sub set_flap_control
{
    my ($self, $pass, $status, undef) = @_;
    my $buf = pack_stx(6, SET_FLAP_CONTROL, "LC", $pass, $status);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_check_getout
{
    my ($self, $pass, $type, undef) = @_;
    my $buf = pack_stx(6, SET_CHECK_GETOUT, "LC", $pass, $type);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

sub set_password_cto
{
    my ($self, $old_pass, $new_pass, undef) = @_;
    my $buf = pack_stx(9, SET_PASSWORD_CTO, "LL", $old_pass, $new_pass);
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};
	}
    }

    return $res;
}

sub get_device_type
{
    my $self = shift;
    my $buf = pack_stx(1, GET_DEVICE_TYPE);
    
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($type, $subtype, $version, $subversion, $model, $language, $name) = unpack("CCCCCCA*", $buf);

		$res->{TYPE} = $type;
		$res->{SUBTYPE} = $subtype;
		$res->{VERSION} = $version;
		$res->{SUBVERSION} = $subversion;
		$res->{MODEL} = $model;
		$res->{LANGUAGE} = $language;
		$res->{NAME} = Encode::decode("cp1251", $name);
	    }
	}
    }

    return $res;
}

sub set_extdev_command
{
    my ($self, $pass, $portnum, $data, undef) = @_;
    my $buf = pack_stx(6 + length($data), SET_EXT_DEVICE_COMMAND, "LCC*", $pass, $portnum, unpack("C*", $data));
    
    my $res = ();

    if($self->write_buf($buf))
    {
	if($self->wait_ack())
	{
	    my $buf = $self->wait_stx();
	    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
	    $res->{ERROR_CODE} = $self->{ERROR_CODE};
	    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

	    if($buf)
	    {
		my ($oper, undef) = unpack("C", $buf);
		$res->{OPERATOR} = $oper;
	    }
	}
    }

    return $res;
}

#
# private
#

sub write_byte
{
    my $self = shift;
    my $byte = shift;
    my $count = $self->{OBJ}->write($byte);
    if($count != 1)
    {
	warn(__PACKAGE__, ": $!: ", $self->{PORT});
	return 0;
    }
    return 1;
}

sub write_buf
{
    my $self = shift;
    my $data = join('', @_);
    my $count = $self->{OBJ}->write($data);
    if($count != length($data))
    {
	warn(__PACKAGE__, ": $!: ", $self->{PORT});
	return 0;
    }
    return $count;
}

sub read_byte
{
    my $self = shift;
    my $timeout = $self->{TIMEOUT} / 1000;
    if (@_) { $timeout = shift; }

    while(0 < $timeout)
    {
	my ($count, $byte) = $self->{OBJ}->read(1);
	return $byte if(0 < $count);

	# sleep: 1 ms
	usleep(1000);
	$timeout--;
    }

    return 0;
}

sub read_buf
{
    my $self = shift;
    my $len = shift;
    my $res = "";

    $res .= $self->read_byte() for(1..$len);

    return $res;
}

sub stx
{
    return pack("C", CMD_STX);
}

sub enq
{
    return pack("C", CMD_ENQ);
}

sub ack
{
    return pack("C", CMD_ACK);
}

sub nak
{
    return pack("C", CMD_NAK);
}

sub wait_default
{
    my $self = shift;
    usleep($self->{TIMEOUT});
}

sub wait_ack
{
    my $self = shift;
    my $res = $self->read_byte($self->{TIMEOUT} * 2);
    return 1 if(ack() eq $res);
    warn(__PACKAGE__, ": invalid ack: ", get_hexstr2(ord(ack())), " != ", get_hexstr2(ord($res)));
    return 0;
}

sub wait_stx
{
    my $self = shift;

rep:
    if(stx() eq $self->read_byte($self->{TIMEOUT} * 2))
    {
	my $len = $self->read_byte($self->{TIMEOUT} * 2);
	my $cmd = $self->read_byte($self->{TIMEOUT} * 2);
	my $err = $self->read_byte($self->{TIMEOUT} * 2);
	my $res = 2 < ord($len) ? $self->read_buf(ord($len) - 2) : "";
	my $crc1 = $self->read_byte();
	$self->wait_default();
	# calc crc
	my $crc2 = $len ^ $cmd ^ $err;
	   $crc2 ^= $_ foreach(split('', $res));
	# check crc
	if($crc1 == $crc2)
	{
	    $self->write_buf(ack());
	    $self->wait_default();
	    $self->{ERROR_CODE} = ord($err);
	    $self->{ERROR_MESSAGE} = 0 < ord($err) ? $self->get_message_error(ord($err)) : "";

	    return $res;
	}
	else
	{
	    warn(__PACKAGE__, ": crc error: ", "repeat: send NAQ and ENQ");
	    $self->write_buf(naq());
	    $self->wait_default();
	    $self->write_buf(enq());
	    $self->wait_default();
	    goto rep;
	}
    }

    return 0;
}

sub pack_stx
{
    my ($len, $cmd, $str, @param) = @_;
    my $res = pack("CC" . $str, $len, $cmd, @param);
    # and crc to tail
    my $crc = 0;
       $crc ^= $_ foreach(unpack("C*", $res));
    return  stx() . $res . chr($crc);
}

sub format_date
{
    return join('-', map(sprintf("%.2u", $_), @_));
}

sub format_time
{
    return join(':', map(sprintf("%.2u", $_), @_));
}

sub get_hexstr2
{
    return "0x" . sprintf("%.2X", shift);
}

sub get_hexstr4
{
    return "0x" . sprintf("%.4X", shift);
}

sub get_hexstr8
{
    return "0x" . sprintf("%.8X", shift);
}

sub get_le_bigint5_from_string
{
    my $number = Math::BigInt->new(shift);
    my @bytes = ();

    for(0 .. 4)
    {
        my $byte = 0xFF & ($number >> (8 * $_));
        push @bytes, $byte;
    }

    return pack("c5", @bytes);
}

sub get_string_from_le_bigint5
{
    return Math::BigInt->new(get_hexnum_from_binary_le(shift));
}

sub get_binary_discout_check
{
    my $numb = shift;
    my $res1 = int($numb);
    my $res2 = abs(int($numb * 100 - $res1 * 100));
    return ($res1 * 100 + $res2);
}

sub get_hexstr_from_binary_le
{
    return join('', map(sprintf("%.2X", ord($_)), reverse(split('', shift))));
}

sub get_hexnum_from_binary_le
{
    return "0x" . get_hexstr_from_binary_le(shift);
}

sub get_hexdump
{
    return join(", ", map(get_hexstr2(ord($_)), split('', shift)));
}

sub get_time
{
    return strftime("%H:%M:%S", localtime);
}

sub get_date
{
    return strftime("%Y-%m-%d", localtime);
}

sub get_datetime
{
    return get_date() . " " . get_time();
}

return 1;
