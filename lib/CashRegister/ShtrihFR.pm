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
use Time::HiRes qw(usleep tv_interval gettimeofday);
use Math::BigInt;
use Encode;

use strict;

use constant
{
    MY_DRIVER_VERSION => 20190514,
    FR_PROTOCOL_VERSION	=> 1.99
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
    GET_CASHIERS_REPORT		=> 0x44,
    GET_HOURS_REPORT		=> 0x45,
    GET_GOODS_REPORT		=> 0x46,
    SET_ADD_UPDATE_GOOD		=> 0x4A,
    GET_READ_GOOD		=> 0x4B,
    SET_DELETE_GOOD		=> 0x4C,
    SET_PRINT_GRAPHICS512_SCALE	=> 0x4D,
    SET_LOAD_GRAPHICS512	=> 0x4E,
    SET_PRINT_GRAPHICS_SCALE	=> 0x4F,
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
    GET_CHECK_FP_BROKEN_RECORDS	=> 0x6A,
    GET_RETURN_ERROR_NAME	=> 0x6B,
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
    SET_CHECK_CLOSE_EXT		=> 0x8E,
    SET_CHECK_CLOSE_EXT_V2		=> 0xFF45,

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
    SET_DAILY_REPORT_DAMP_BUFFER	=> 0xC6,
    SET_PRINT_DAILY_REPORT_BUFFER	=> 0xC7,
    GET_ROWCOUNT_PRINTBUF	=> 0xC8,
    GET_STRING_PRINTBUF		=> 0xC9,
    SET_CLEAR_PRINTBUF		=> 0xCA,
    SET_PRINT_BARCODE_PRINTER	=> 0xCB,
    SET_CHECK_CLOSE_RETURN_KPK	=> 0xCC,
    GET_EKLZ_ACTIVATION_PARAMS	=> 0xCD,
    GET_RANDOM_SEQUENCE		=> 0xCE,
    SET_AUTHENTICATION		=> 0xCF,

    GET_FR_IBM_STATUS_LONG	=> 0xD0,
    GET_FR_IBM_STATUS		=> 0xD1,
    SET_OPEN_TURN		=> 0xE0,
    SET_OPEN_NONFISCAL_DOCUMENT	=> 0xE2,
    SET_CLOSE_NONFISCAL_DOCUMENT=> 0xE3,
    SET_PRINT_PROPS		=> 0xE4,
    GET_STATE_BILL_ACCEPTOR	=> 0xE5,
    GET_REGISTERS_BILL_ACCEPTOR	=> 0xE6,
    GET_REPORT_BILL_ACCEPTOR	=> 0xE7,
    GET_OPERATIONAL_REPORT_NI	=> 0xE8,
    SET_FLAP_CONTROL		=> 0xF0,
    SET_CHECK_GETOUT		=> 0xF1,
    SET_PASSWORD_CTO		=> 0xF3,
    GET_EXT_REQUEST		=> 0xF7,
    GET_DEVICE_TYPE		=> 0xFC,
    SET_EXT_DEVICE_COMMAND	=> 0xFD,
};

use constant
{
    FF_GET_FN_STATUS		=> 0x01,
    FF_GET_FN_NUMBER		=> 0x02,
    FF_GET_FN_DURATION		=> 0x03,
    FF_GET_FN_VERSION		=> 0x04,
    FF_GET_FN_TURN_STATUS  	=> 0x40,
    FF_SET_START_OPEN_TURN	=> 0x41,
    FF_SET_START_CLOSE_TURN	=> 0x42
};

use constant
{
    CMD_STX     => 0x02,
    CMD_ENQ     => 0x05,
    CMD_ACK     => 0x06,
    CMD_NAK     => 0x15,
};

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
    $root->{TIMEOUT} = 100000; # 100 ms
    $root->{ERROR_CODE} = 0;
    $root->{ERROR_MESSAGE} = "";
    $root->{MESSAGE} = new CashRegister::ShtrihFR::Messages::Russian();
    $root->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $root->{ENCODE_FROM} = "utf8";
    $root->{ENCODE_TO} = "cp1251";

    bless($root);
    return $root;
}

sub set_encode_fromto
{
    my ($self, $from, $to, undef) = @_;
    $self->{ENCODE_FROM} = $from;
    $self->{ENCODE_TO} = $to;
}

sub encode_string
{
    my ($self, $text, undef) = @_;
    Encode::from_to($text, $self->{ENCODE_FROM}, $self->{ENCODE_TO});
    return $text;
}

sub find_device
{
    my ($class, @devices) = @_;
    my @speeds = ( 2400, 4800, 9600, 19200, 38400, 57600, 115200 );

    foreach my $port ( @devices )
    {
	if(-r $port && -w $port)
	{
	    foreach my $speed ( @speeds )
	    {
		my $device = CashRegister::ShtrihFR->new($port, $speed, 0);
		last unless($device);
		if($device->is_online())
		{
		    $device->{DEBUG} = 1;
		    return $device;
		}
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

    if($self->send_enq())
    {
	my $res = $self->read_byte($self->{TIMEOUT} * 2);
	return 1 if(nak() eq $res);

	$self->{ERROR_CODE} = 255;
	$self->{ERROR_MESSAGE} = "invalid nak: " . get_hexstr2(ord($res));
	warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
    }

    return 0;
}

sub printing_wait
{
    my ($self, $pass, undef) = @_;

    $self->wait_default();

    if($self->is_online())
    {
	while(1)
	{
	    my $res = $self->get_short_status($pass);

	    if($res->{FR_SUBMODE} == 5 || $res->{FR_SUBMODE} == 4)
	    {
		$self->wait_default();
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

    my $res = {};
    my $buf = $self->send_cmd(6, GET_DUMP, "VC", $pass, $subsystem);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($count, undef) = unpack("C", $buf);
	$res->{BLOCK_COUNT} = $count;
    }

    return $res;
}

sub get_data
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_DATA, "V", $pass);

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

    return $res;
}

sub set_break
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_BREAK, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_fiscalization_long_rnm
{
    # rnm is 7 byte: "00000000000000"
    # inn is 6 byte: "000000000000"
    my ($self, $pass_old, $pass_new, $rnm, $inn, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(22, SET_FISCALIZATION_LONG_RNM, "VV(H2)7(H2)6", $pass_old, $pass_new, unpack("(A2)7", $rnm), unpack("(A2)6", $inn));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($fiscal_number, $fiscal_last, $last_tour, $date, undef) = unpack("CCva3", $buf);

	$res->{FISCAL_NUMBER} = $fiscal_number;
	$res->{FISCAL_LAST} = $fiscal_last;
	$res->{FISCAL_DATE} = format_date_decode($date);
	$res->{LAST_TOUR_NUMBER} = $last_tour;
    }

    return $res;
}

sub set_long_serial_number
{
    # serial is 7 byte: "00000000000000"
    my ($self, $pass, $serial, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(12, SET_LONG_SERIAL_NUMBER, "V(H2)7", $pass, unpack("(A2)7", $serial));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub get_long_serial_number_rnm
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_LONG_SERIAL_NUMBER_RNM, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($num, $rnm, undef) = unpack("a7a7", $buf);

	$res->{SERIAL_NUMBER} = get_hexnum_from_binary_le($num);
	$res->{RNM_NUMBER} = get_hexnum_from_binary_le($rnm);
    }

    return $res;
}

sub get_short_status
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_SHORT_STATUS, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $flags, $mode, $submode, $count_lo, $battery,
		$power, $err_fp, $err_eklz, $count_hi, $rez, $print_status, undef) = unpack("CvCCCCCCCCa3C", $buf);

	$res->{OPERATOR} = $oper;
	$res->{FR_FLAGS} = $flags;
	$res->{FR_MODE} = $mode;
	$res->{FR_SUBMODE} = $submode;
	$res->{TICKET_OPERATION_COUNT} = $count_hi << 8 | $count_lo;
	$res->{POWER_MAIN} = $power;
	$res->{POWER_BATTERY} = $battery;
	$res->{ERROR_FP} = $err_fp;
	$res->{ERROR_EKLZ} = $err_eklz;
	$res->{PRINT_STATUS} = $print_status if(defined $print_status);

	$res->{MESSAGE_FR_MODE} = $self->get_message_fr_mode($res->{FR_MODE});
	$res->{MESSAGE_FR_SUBMODE} = $self->get_message_fr_submode($res->{FR_SUBMODE});
	$res->{MESSAGE_FR_FLAGS} = join(', ', $self->get_message_fr_flags($res->{FR_FLAGS}));
    }

    return $res;
}

sub get_device_status
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_DEVICE_STATUS, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $progfr_ver_hi, $progfr_ver_lo, $buildfr_ver, $datefr,
		$hall_number, $cur_doc, $flagfr, $mode, $submode, $port,
		$progfp_ver_lo, $progfp_ver_hi, $buildfp, $datefp,
		$date, $time, $flag_fp_lo, $serial_num_lo,
		$last_tour, $open_rec, $fiscal_number, $fiscal_last, $inn,
		$flag_fp_hi, $mode_fp, $serial_num_hi, undef) = unpack("CCCva3CvvCCCCCva3a3a3CVvvCCa6CC", $buf);

	$res->{OPERATOR} = $oper;
	$res->{FR_PROG_VERSION} = uc(join('.', chr($progfr_ver_hi), chr($progfr_ver_lo)));
	$res->{FR_BUILD_VERSION} = $buildfr_ver;
	$res->{FR_DATE} = format_date_decode($datefr);
	$res->{HALL_NUMBER} = $hall_number;
	$res->{CURRENT_DOC_NUMBER} = $cur_doc;
	$res->{FR_FLAGS} = get_hexstr4($flagfr);
	$res->{FR_MODE} = get_hexstr2($mode);
	$res->{FR_SUBMODE} = get_hexstr2($submode);
	$res->{FR_PORT} = $port;
	$res->{FP_PROG_VERSION} = uc(join('.', chr($progfp_ver_hi), chr($progfp_ver_lo)));
	$res->{FP_BUILD_VERSION} = $buildfp;
	$res->{FP_DATE} = format_date_decode($datefp);
	$res->{FP_MODE} = get_hexstr2($mode_fp) if(defined $mode_fp);
	$res->{DATE} = format_date_decode($date);
	$res->{TIME} = format_time_decode($time);
	$res->{FP_FLAGS} = get_hexstr4(defined $flag_fp_hi ? ($flag_fp_hi << 8 | $flag_fp_lo) : $flag_fp_lo);
	$res->{SERIAL_NUMBER} = defined $serial_num_hi ? $serial_num_hi . $serial_num_lo : $serial_num_lo;
	$res->{LAST_TOUR_NUMBER} = $last_tour;
	$res->{FP_OPEN_RECORDS} = $open_rec;
	$res->{FISCAL_NUMBER} = $fiscal_number;
	$res->{FISCAL_LAST} = $fiscal_last;
	$res->{INN_NUMBER} = hex(get_hexnum_from_binary_le($inn));

	$res->{MESSAGE_FR_MODE} = $self->get_message_fr_mode($res->{FR_MODE});
	$res->{MESSAGE_FR_SUBMODE} = $self->get_message_fr_submode($res->{FR_SUBMODE});
	$res->{MESSAGE_FR_FLAGS} = join(', ', $self->get_message_fr_flags($res->{FR_FLAGS}));
	$res->{MESSAGE_FP_FLAGS} = join(', ', $self->get_message_fp_flags($res->{FP_FLAGS}));
    }

    return $res;
}

sub set_print_bold_string
{
    my ($self, $pass, $flag, $str, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(26, SET_PRINT_BOLD_STRING, "VCA20", $pass, $flag, $self->encode_string($str));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_beep
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_BEEP, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_communication_params
{
    my ($self, $pass, $bod, $timeout, $portnum, undef) = @_;
    $portnum = 0 unless($portnum);

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

    my $res = {};
    my $buf = $self->send_cmd(8, SET_RS232_PARAM, "VCCC", $pass, $portnum, $bod_index, $timeout);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    unless($res->{ERROR_CODE})
    {
	$self->{TIMEOUT} = $timeout * 1000; # ms
    }

    return $res;
}

sub get_communication_params
{
    my ($self, $pass, $portnum, undef) = @_;
    $portnum = 0 unless($portnum);

    my $res = {};
    my $buf = $self->send_cmd(6, GET_RS232_PARAM, "VC", $pass, $portnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($code, $timeout, undef) = unpack("CC", $buf);
	my $bods = [ 2400, 4800, 9600, 19200, 38400, 57600, 115200 ];

        $res->{SPEED} = $bods->[$code];

	if(151 <= $timeout && $timeout <= 249)
	{
	    $timeout = 300 + ($timeout - 151) * 150;
	}
	elsif(250 <= $timeout && $timeout <= 255)
	{
	    $timeout = 30000 + ($timeout - 250) * 15000;
	}

	$res->{TIMEOUT} = $timeout;
	$self->{TIMEOUT} = $timeout * 1000; # ms
    }

    return $res;
}

sub set_technical_zero
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(1, SET_TECHNICAL_ZERO, "");

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_print_string
{
    my ($self, $pass, $flag, $text, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(46, SET_PRINT_STRING, "VCA40", $pass, $flag, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_print_header
{
    my ($self, $pass, $docname, $docnum, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(37, SET_PRINT_HEADER, "VA30v", $pass, $self->encode_string($docname), $docnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $through_doc, undef) = unpack("Cv", $buf);

	$res->{OPERATOR} = $oper;
	$res->{THROUGH_DOC_NUMBER} = $through_doc;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_test_run
{
    my ($self, $pass, $period, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_TEST_RUN, "VC", $pass, $period);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub get_cache_register
{
    my ($self, $pass, $regnum, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, GET_CASHE_REGISTER, "VC", $pass, $regnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $value, undef) = unpack("Ca6", $buf);
	$res->{OPERATOR} = $oper;
	$res->{REGISTER} = get_hexnum_from_binary_le($value);
    }

    return $res;
}

sub get_operational_register
{
    my ($self, $pass, $regnum, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, GET_OPERATIONAL_REGISTER, "VC", $pass, $regnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $value, undef) = unpack("Cv", $buf);
	$res->{OPERATOR} = $oper;
	$res->{REGISTER} = $value;
    }

    return $res;
}

sub set_license
{
    # license is 5 byte: "0000000000"
    my ($self, $pass, $license, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(10, SET_LICENSE, "V(H2)5", $pass, unpack("(A2)5", $license));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub get_license
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_LICENSE, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($license, undef) = unpack("a5", $buf);
	$res->{LICENSE} = get_hexnum_from_binary_le($license);
    }

    return $res;
}

sub set_write_table
{
    my ($self, $pass, $table, $col, $field, $array_ref, undef) = @_;

    my $res = {};
    my $data = pack("C*", @{$array_ref});
    my $buf = $self->send_cmd(9 + length $data, SET_WRITE_TABLE, "VCvCa*", $pass, $table, $col, $field, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub get_read_table
{
    my ($self, $pass, $table, $col, $field, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(9, GET_READ_TABLE, "VCvC", $pass, $table, $col, $field);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	$res->{VALUE} = get_hexdump($buf);
    }

    return $res;
}

sub set_decimal_point
{
    my ($self, $pass, $pos, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_DECIMAL_POINT, "VC", $pass, $pos);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_current_time
{
    my ($self, $pass, $hour, $min, $sec, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(8, SET_CURRENT_TIME, "VCCC", $pass, $hour, $min, $sec);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_current_date
{
    my ($self, $pass, $year, $mon, $day, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(8, SET_CURRENT_DATE, "VCCC", $pass, $day, $mon, $year);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_date_confirm
{
    my ($self, $pass, $year, $mon, $day, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(8, SET_DATE_CONFIRM, "VCCC", $pass, $day, $mon, $year);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_init_tables
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_INIT_TABLES, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_cut_check
{
    my ($self, $pass, $type, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_CUT_CHECK, "VC", $pass, $type);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub get_font_params
{
    my ($self, $pass, $fontnum, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, GET_FONT_PARAMS, "VC", $pass, $fontnum);

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

    return $res;
}

sub set_total_damping
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_TOTAL_DAMPING, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_open_money_box
{
    my ($self, $pass, $boxnum, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_OPEN_MONEY_BOX, "VC", $pass, $boxnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_scroll
{
    my ($self, $pass, $flags, $rows, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(7, SET_SCROLL, "VCC", $pass, $flags, $rows);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_getout_backfilling_document
{
    my ($self, $pass, $direct, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_GETOUT_BACKFILLING_DOC, "VC", $pass, $direct);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_break_test_run
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_BREAK_TEST_RUN, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub get_registers_values
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_REGISTERS_VALUES, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub get_structure_table
{
    my ($self, $pass, $tabnum, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, GET_STRUCTURE_TABLE, "VC", $pass, $tabnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($name, $colnum, $fieldnum, undef) = unpack("a40vC", $buf);
	$res->{TABLE_NAME} = Encode::decode($self->{ENCODE_TO}, $name);
	$res->{COLUMN_COUNT} = $colnum;
	$res->{FIELD_COUNT} = $fieldnum;
    }

    return $res;
}

sub get_structure_field
{
    my ($self, $pass, $tabnum, $fieldnum, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(7, GET_STRUCTURE_FIELD, "VCC", $pass, $tabnum, $fieldnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($name, $type, $count, $last, undef) = unpack("a40CCa*", $buf);

	$res->{FIELD_NAME} = Encode::decode($self->{ENCODE_TO}, $name);
	$res->{FIELD_TYPE} = $type ? "CHAR" : "BIN";
	$res->{FIELD_SIZE} = $count;
    }

    return $res;
}

sub set_print_font_string
{
    my ($self, $pass, $flag, $fontnum, $text, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(47, SET_PRINT_FONT_STRING, "VCCA40", $pass, $flag, $fontnum, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_daily_report
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_DAILY_REPORT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_daily_report
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_DAILY_REPORT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_daily_report_with_dump
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_DAILY_REPORT_DAMP, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_sections_report
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_SECTIONS_REPORT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

    $self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_taxes_report
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_TAXES_REPORT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_cashiers_report
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_CASHIERS_REPORT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_hours_report
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_HOURS_REPORT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_goods_report
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_GOODS_REPORT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_add_update_good
{
    my ($self, $pass, $goodid, $price, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(71, SET_ADD_UPDATE_GOOD, "Vva5CCCCCA54", $pass, $goodid, get_le_bigint5_from_string($price),
		$department, $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub get_read_good
{
    my ($self, $pass, $goodid, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(7, GET_READ_GOOD, "Vv", $pass, $goodid);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $price, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = unpack("Ca5CCCCCA54", $buf);
	$res->{OPERATOR} = $oper;
	$res->{PRICE} = get_string_from_le_bigint5($price);
	$res->{DEPARTMENT} = $department;
	$res->{TAX1} = $tax1;
	$res->{TAX2} = $tax2;
	$res->{TAX3} = $tax3;
	$res->{TAX4} = $tax4;
	$res->{TEXT} = $text;
    }

    return $res;
}

sub set_delete_good
{
    my ($self, $pass, $goodid, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(7, SET_DELETE_GOOD, "Vv", $pass, $goodid);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_print_graphics512_scale
{
    my ($self, $pass, $first, $last, $vscale, $hscale, $flags, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(12, SET_PRINT_GRAPHICS512_SCALE, "VvvCCC", $pass, $first, $last, $vscale, $hscale, $flags);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, undef) = unpack("C", $buf);
        $res->{OPERATOR} = $oper;

        $self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_load_graphics512
{
    my ($self, $pass, $linelength, $startnumberline, $nextcountline, $buffertype, $array_ref, undef) = @_;

    my $res = {};
    my $data = pack("C*", @{$array_ref});
    my $buf = $self->send_cmd(11 + length $data, SET_LOAD_GRAPHICS512, "VCvvCa*", $pass, $linelength, $startnumberline, $nextcountline, $buffertype, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, undef) = unpack("C", $buf);
        $res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_print_graphics_scale
{
    my ($self, $pass, $first, $last, $vscale, $hscale, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(9, SET_PRINT_GRAPHICS_SCALE, "VCCCC", $pass, $first, $last, $vscale, $hscale);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, $through_doc, undef) = unpack("Cv", $buf);
        $res->{OPERATOR} = $oper;
	$res->{THROUGH_DOC_NUMBER} = $through_doc;

        $self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_adding_amount
{
    # amount is big int string
    my ($self, $pass, $amount, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(10, SET_ADDING_AMOUNT, "Va5", $pass, get_le_bigint5_from_string($amount));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $through_doc, undef) = unpack("Cv", $buf);
	$res->{OPERATOR} = $oper;
	$res->{THROUGH_DOC_NUMBER} = $through_doc;
    }

    return $res;
}

sub get_payment_amount
{
    # amount is big int string
    my ($self, $pass, $amount, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(10, GET_PAYMENT_AMOUNT, "Va5", $pass, get_le_bigint5_from_string($amount));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $through_doc, undef) = unpack("Cv", $buf);
	$res->{OPERATOR} = $oper;
	$res->{THROUGH_DOC_NUMBER} = $through_doc;
    }

    return $res;
}

sub set_print_cliche
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_PRINT_CLICHE, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_document_end
{
    my ($self, $pass, $param, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_DOCUMENT_END, "VC", $pass, $param);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_print_ad_text
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_PRINT_AD_TEXT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_serial_number
{
    # serial is 4 byte: "00000000"
    my ($self, $pass, $serial, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(9, SET_SERIAL_NUMBER, "V(H2)4", $pass, unpack("(A2)4", $serial));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_fp_init
{
    my $self = shift;

    my $res = {};
    my $buf = $self->send_cmd(1, SET_FP_INIT, "");

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub get_fp_sum_records
{
    my ($self, $pass, $type, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, GET_FP_SUM_RECORDS, "VC", $pass, $type);

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

    return $res;
}

sub get_fp_last_record_date
{
    my ($self, $pass, $type, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_FP_LAST_RECORD_DATE, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $type, $date, undef) = unpack("CCa3", $buf);

	$res->{OPERATOR} = $oper;
	$res->{LAST_RECORD_TYPE} = $type;
	$res->{LAST_RECORD_DATE} = format_date_decode($date);
    }

    return $res;
}

sub get_query_date_range_tour
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_QUERY_DATE_RANGE_TOUR, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($first_date, $last_date, $first_number, $last_number,  undef) = unpack("a3a3vv", $buf);

	$res->{FIRST_TOUR_DATE} = format_date_decode($first_date);
	$res->{LAST_TOUR_DATE} = format_date_decode($last_date);
	$res->{FIRST_TOUR_NUMBER} = $first_number;
	$res->{LAST_TOUR_NUMBER} = $last_number;
    }

    return $res;
}

sub set_fiscalization
{
    # rnm is 5 byte: "0000000000"
    # inn is 6 byte: "000000000000"
    my ($self, $pass_old, $pass_new, $rnm, $inn, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(20, SET_FISCALIZATION, "VV(H2)5(H2)6", $pass_old, $pass_new, unpack("(A2)5", $rnm), unpack("(A2)6", $inn));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($fiscal_number, $fiscal_last, $last_tour, $last_date, undef) = unpack("CCva3", $buf);

        $res->{FISCAL_NUMBER} = $fiscal_number;
        $res->{FISCAL_LAST} = $fiscal_last;
        $res->{FISCAL_DATE} = format_date_decode($last_date);
        $res->{LAST_TOUR_NUMBER} = $last_tour;
    }

    return $res;
}

sub get_fiscal_report_by_date
{
    my ($self, $pass, $type, $year1, $month1, $day1, $year2, $month2, $day2, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(12, GET_FISCAL_REPORT_BY_DATE, "VCCCCCCC", $pass, $type, $day1, $month1, substr($year1, -2, 2), $day2, $month2, substr($year2, -2, 2));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($first_date, $last_date, $first_number, $last_number,  undef) = unpack("a3a3vv", $buf);

	$res->{FIRST_TOUR_DATE} = format_date_decode($first_date);
	$res->{LAST_TOUR_DATE} = format_date_decode($last_date);
	$res->{FIRST_TOUR_NUMBER} = $first_number;
	$res->{LAST_TOUR_NUMBER} = $last_number;
    }

    return $res;
}

sub get_fiscal_report_by_tour
{
    my ($self, $pass, $type, $firstnum, $lastnum, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(10, GET_FISCAL_REPORT_BY_TOUR, "VCvv", $pass, $type, $firstnum, $lastnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($first_date, $last_date, $first_number, $last_number,  undef) = unpack("a3a3vv", $buf);

	$res->{FIRST_TOUR_DATE} = format_date_decode($first_date);
	$res->{LAST_TOUR_DATE} = format_date_decode($last_date);
	$res->{FIRST_TOUR_NUMBER} = $first_number;
	$res->{LAST_TOUR_NUMBER} = $last_number;
    }

    return $res;
}

sub set_break_full_report
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_BREAK_FULL_REPORT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub get_fiscalization_params
{
    my ($self, $pass, $fiscalnum, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, GET_FISCALIZATION_PARAMS, "VC", $pass, $fiscalnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($rnm, $inn, $tour_number, $fiscal_date, undef) = unpack("a5a6va3", $buf);

	$res->{RNM_NUMBER} = get_hexnum_from_binary_le($rnm);
	$res->{INN_NUMBER} = hex(get_hexnum_from_binary_le($inn));
	$res->{TOUR_NUMBER_AFTER_FICAL} = $tour_number;
	$res->{FIRST_TOUR_DATE} = format_date_decode($fiscal_date);
    }

    return $res;
}

sub get_check_fp_broken_records
{
    my ($self, $pass, $typerec, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, GET_CHECK_FP_BROKEN_RECORDS, "VC", $pass, $typerec);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $broken, undef) = unpack("Cv", $buf);

	$res->{OPERATOR} = $oper;
	$res->{BROKEN_RECORDS} = $broken;
    }

    return $res;
}

sub get_return_error_name
{
    my ($self, $errorcode, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(2, GET_RETURN_ERROR_NAME, "C", $errorcode);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($error_name, undef) = unpack("a*", $buf);

	$res->{ERROR_NAME} = Encode::decode($self->{ENCODE_TO}, $error_name);
    }

    return $res;
}

sub set_open_fiscal_underdoc
{
    my ($self, $pass, $type, $print_doubles, $count_doubles, $offset_orig_first, $offset_first_second, $offset_second_third, $offset_third_fourth, $offset_fourth_fifth,
	$font_number_cliche, $font_number_header, $font_number_eklz, $font_number_kpk, $string_number_cliche, $string_number_header, $string_number_eklz, $string_number_repeat,
	$offset_cliche, $offset_header, $offset_eklz, $offset_kpk, $offset_repeat, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(26, SET_OPEN_FISCAL_UNDERDOC, "VCCCCCCCCCCCCCCCCCCCCC", $pass, $type, $print_doubles, $count_doubles, $offset_orig_first, $offset_first_second, $offset_second_third, $offset_third_fourth, $offset_fourth_fifth,
	$font_number_cliche, $font_number_header, $font_number_eklz, $font_number_kpk, $string_number_cliche, $string_number_header, $string_number_eklz, $string_number_repeat,
	$offset_cliche, $offset_header, $offset_eklz, $offset_kpk, $offset_repeat);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $through_doc, undef) = unpack("Cv", $buf);
	$res->{OPERATOR} = $oper;
	$res->{THROUGH_DOC_NUMBER} = $through_doc;
    }

    return $res;
}

sub set_open_standard_fiscal_underdoc
{
    my ($self, $pass, $type, $print_doubles, $count_doubles, $offset_orig_first, $offset_first_second, $offset_second_third, $offset_third_fourth, $offset_fourth_fifth, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(13, SET_OPEN_STD_FISCAL_UNDERDOC, "VCCCCCCCC", $pass, $type, $print_doubles, $count_doubles, $offset_orig_first, $offset_first_second, $offset_second_third, $offset_third_fourth, $offset_fourth_fifth);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $through_doc, undef) = unpack("Cv", $buf);
	$res->{OPERATOR} = $oper;
	$res->{THROUGH_DOC_NUMBER} = $through_doc;
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

    my $res = {};
    my $buf = $self->send_cmd(82, SET_FORMING_OPERATION_UNDERDOC, "VCCCCCCCCCCCCCCCCCCCCCCa5a5CCCCCA40", $pass,
	$number_format, $string_count, $string_number, $string_number_mul, $string_number_sum, $string_number_dep,
	$font_number_str, $font_number_count, $font_number_mul, $font_number_price, $font_number_sum, $font_number_dep,
	$count_sym_field_str, $count_sym_field_count, $count_sym_field_price, $count_sym_field_sum, $count_sym_field_dep,
	$offset_field_str, $offset_field_mul, $offset_field_sum, $offset_field_dep,
	$number_string_pd, get_le_bigint5_from_string($amount), get_le_bigint5_from_string($price), $department, $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
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

    my $res = {};
    my $buf = $self->send_cmd(61, SET_FORMING_STD_OPERATION_UNDERDOC, "VCa5a5CCCCCA40", $pass,
	$number_string_pd, get_le_bigint5_from_string($amount), get_le_bigint5_from_string($price), $department, $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
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

    my $res = {};
    my $buf = $self->send_cmd(68, SET_FORMING_DISCOUNT_UNDERDOC, "VCCCCCCCCCCCCCCa5CCCCA40", $pass,
	$string_count, $string_number_str, $string_number_name, $string_number_sum, $font_number_str, $font_number_name, $font_number_sum,
	$count_sym_field_str, $count_sym_field_sum, $offset_field_str, $offset_field_name, $offset_field_sum, $operation_type, $number_string_pd,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_forming_std_discount_underdoc
{
    # amount is big int string
    # text is 40 byte
    my ($self, $pass, $operation_type, $string_number_pd,
	$amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(56, SET_FORMING_STD_DISCOUNT_UNDERDOC, "VCCa5CCCCA40", $pass,
	$operation_type, $string_number_pd, get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
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

    my $res = {};
    my $buf = $self->send_cmd(182, SET_FORMING_CLOSE_CHECK_UNDERDOC, "VCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCa5a5a5a5vCCCCA40", $pass,
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
	get_binary_discout_check($discout_on_check), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $change, undef) = unpack("Ca5", $buf);
	$res->{OPERATOR} = $oper;
	$res->{SHORT_CHANGE} = get_string_from_le_bigint5($change);
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

    my $res = {};
    my $buf = $self->send_cmd(72, SET_FORMING_STD_CLOSE_CHECK_UNDERDOC, "VCa5a5a5a5vCCCCA40", $pass, $number_string_pd,
	get_le_bigint5_from_string($amount), get_le_bigint5_from_string($amount_type2), get_le_bigint5_from_string($amount_type3), get_le_bigint5_from_string($amount_type4),
	get_binary_discout_check($discout_on_check), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $change, undef) = unpack("Ca5", $buf);
	$res->{OPERATOR} = $oper;
	$res->{SHORT_CHANGE} = get_string_from_le_bigint5($change);
    }

    return $res;
}

sub set_configuration_underdoc
{
    my ($self, $pass, $width_underdoc, $length_underdoc, $print_direction, $array_ref, undef) = @_;

    my $res = {};
    my $data = pack("C*", @{$array_ref});
    my $buf = $self->send_cmd(209, SET_CONFIGURATION_UNDERDOC, "VvvCa199", $pass, $width_underdoc, $length_underdoc, $print_direction, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_std_configuration_underdoc
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_STD_CONFIGURATION_UNDERDOC, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_fill_buffer_underdoc
{
    my ($self, $pass, $string_number, $data, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6 + length($data), SET_FILL_BUFFER_UNDERDOC, "VCa*", $pass, $string_number, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_clear_string_underdoc
{
    my ($self, $pass, $string_number, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_CLEAR_STRING_UNDERDOC, "VC", $pass, $string_number);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_clear_buffer_underdoc
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_CLEAR_BUFFER_UNDERDOC, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_print_underdoc
{
    my ($self, $pass, $clear, $type, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(7, SET_PRINT_UNDERDOC, "VCC", $pass, $clear, $type);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_general_configuration_underdoc
{
    my ($self, $pass, $width, $length, $direction, $spacing, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(7, GET_GENERAL_CONFIGURATION_UNDERDOC, "VvvCC", $pass, $width, $length, $direction, $spacing);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_sell
{
    # quantity, amount is big int string
    my ($self, $pass, $quantity, $amount, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(60, SET_SELL, "Va5a5CCCCCA40", $pass,
	get_le_bigint5_from_string($quantity), get_le_bigint5_from_string($amount), $department, $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_buy
{
    # quantity, amount is big int string
    my ($self, $pass, $quantity, $amount, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(60, SET_BUY, "Va5a5CCCCCA40", $pass,
	get_le_bigint5_from_string($quantity), get_le_bigint5_from_string($amount), $department, $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_returns_sale
{
    # quantity, amount is big int string
    my ($self, $pass, $quantity, $amount, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(60, SET_RETURNS_SALE, "Va5a5CCCCCA40", $pass,
	get_le_bigint5_from_string($quantity), get_le_bigint5_from_string($amount), $department, $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_returns_purchases
{
    # quantity, amount is big int string
    my ($self, $pass, $quantity, $amount, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(60, SET_RETURNS_PURCHASES, "Va5a5CCCCCA40", $pass,
	get_le_bigint5_from_string($quantity), get_le_bigint5_from_string($amount), $department, $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_reversal
{
    # quantity, amount is big int string
    my ($self, $pass, $quantity, $amount, $department, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(60, SET_REVERSAL, "Va5a5CCCCCA40", $pass,
	get_le_bigint5_from_string($quantity), get_le_bigint5_from_string($amount), $department, $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_check_close
{
    # cash_sum, sum_type2, sum_type3, sum_type4 is big int string
    my ($self, $pass, $cash_sum, $sum_type2, $sum_type3, $sum_type4, $discount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(71, SET_CHECK_CLOSE, "Va5a5a5a5vCCCCA40", $pass,
	get_le_bigint5_from_string($cash_sum), get_le_bigint5_from_string($sum_type2), get_le_bigint5_from_string($sum_type3), get_le_bigint5_from_string($sum_type4),
	get_binary_discout_check($discount), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, $change, undef) = unpack("Ca5", $buf);
        $res->{OPERATOR} = $oper;
        $res->{SHORT_CHANGE} = get_string_from_le_bigint5($change);
    }

    return $res;
}

sub set_discount
{
    # amount is big int string
    my ($self, $pass, $amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(54, SET_DISCOUT, "Va5CCCCA40", $pass,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, undef) = unpack("C", $buf);
        $res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_allowance
{
    # amount is big int string
    my ($self, $pass, $amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(54, SET_ALLOWANCE, "Va5CCCCA40", $pass,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, undef) = unpack("C", $buf);
        $res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_check_cancellation
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_CHECK_CANCELLATION, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, undef) = unpack("C", $buf);
        $res->{OPERATOR} = $oper;
	$self->printing_wait($pass);
    }

    return $res;
}

sub get_check_subtotal
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_CHECK_SUBTOTAL, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, $subtotal, undef) = unpack("Ca5", $buf);
        $res->{OPERATOR} = $oper;
        $res->{CHECK_SUBTOTAL} = get_string_from_le_bigint5($subtotal);
    }

    return $res;
}

sub set_reversal_discount
{
    # amount is big int string
    my ($self, $pass, $amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(54, SET_REVERSAL_DISCOUNT, "Va5CCCCA40", $pass,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, undef) = unpack("C", $buf);
        $res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_reversal_allowance
{
    # amount is big int string
    my ($self, $pass, $amount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(54, SET_REVERSAL_ALLOWANCE, "Va5CCCCA40", $pass,
	get_le_bigint5_from_string($amount), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, undef) = unpack("C", $buf);
        $res->{OPERATOR} = $oper;
    }

    return $res;
}

sub get_document_repeat
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_DOCUMENT_REPEAT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, undef) = unpack("C", $buf);
        $res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_check_open
{
    my ($self, $pass, $type, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_CHECK_OPEN, "VC", $pass, $type);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, undef) = unpack("C", $buf);
        $res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_check_close_ext
{
    # cash_sum, sum_type2 - sum_type16 is big int string
    my ($self, $pass, $cash_sum, $sum_type2, $sum_type3, $sum_type4, $sum_type5, $sum_type6, $sum_type7, $sum_type8, $sum_type9,
	$sum_type10, $sum_type11, $sum_type12, $sum_type13, $sum_type14, $sum_type15, $sum_type16,
	$discount, $tax1, $tax2, $tax3, $tax4, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(131, SET_CHECK_CLOSE_EXT, "Va5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5vCCCCA40", $pass,
	get_le_bigint5_from_string($cash_sum),
	get_le_bigint5_from_string($sum_type2), get_le_bigint5_from_string($sum_type3), get_le_bigint5_from_string($sum_type4),
	get_le_bigint5_from_string($sum_type5), get_le_bigint5_from_string($sum_type6), get_le_bigint5_from_string($sum_type7),
	get_le_bigint5_from_string($sum_type8), get_le_bigint5_from_string($sum_type9), get_le_bigint5_from_string($sum_type10),
	get_le_bigint5_from_string($sum_type11), get_le_bigint5_from_string($sum_type12), get_le_bigint5_from_string($sum_type13),
	get_le_bigint5_from_string($sum_type14), get_le_bigint5_from_string($sum_type15), get_le_bigint5_from_string($sum_type16),
	get_binary_discout_check($discount), $tax1, $tax2, $tax3, $tax4, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, $change, undef) = unpack("Ca5", $buf);
        $res->{OPERATOR} = $oper;
        $res->{SHORT_CHANGE} = get_string_from_le_bigint5($change);
    }

    return $res;
}

sub set_check_close_ext_v2
{
    # cash_sum, sum_type2 - sum_type16 is big int string
    my ($self, $pass, $cash_sum, $sum_type2, $sum_type3, $sum_type4, $sum_type5, $sum_type6, $sum_type7, $sum_type8, $sum_type9,
        $sum_type10, $sum_type11, $sum_type12, $sum_type13, $sum_type14, $sum_type15, $sum_type16,
        $discount, $tax1, $tax2, $tax3, $tax4, $tax5, $tax6, $tax_type, $text, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(134, SET_CHECK_CLOSE_EXT_V2, "Va5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5vCCCCCCCA40", $pass,
        get_le_bigint5_from_string($cash_sum),
        get_le_bigint5_from_string($sum_type2), get_le_bigint5_from_string($sum_type3), get_le_bigint5_from_string($sum_type4),
        get_le_bigint5_from_string($sum_type5), get_le_bigint5_from_string($sum_type6), get_le_bigint5_from_string($sum_type7),
        get_le_bigint5_from_string($sum_type8), get_le_bigint5_from_string($sum_type9), get_le_bigint5_from_string($sum_type10),
        get_le_bigint5_from_string($sum_type11), get_le_bigint5_from_string($sum_type12), get_le_bigint5_from_string($sum_type13),
        get_le_bigint5_from_string($sum_type14), get_le_bigint5_from_string($sum_type15), get_le_bigint5_from_string($sum_type16),
        get_binary_discout_check($discount), $tax1, $tax2, $tax3, $tax4, $tax5, $tax6, $tax_type, $self->encode_string($text));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
        my ($oper, $change, $doc_num, $fiscal_sign, $fiscal_sign_as_string, undef) = unpack("Ca5CC", $buf);
        $res->{OPERATOR} = $oper;
        $res->{SHORT_CHANGE} = get_string_from_le_bigint5($change);
    }

    return $res;
}























sub set_print_continue
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_PRINT_CONTINUE, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	# $self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_load_graphics
{
    my ($self, $pass, $linenum, $array_ref, undef) = @_;

    my $res = {};
    my $data = pack("C*", @{$array_ref});
    my $buf = $self->send_cmd(46, SET_LOAD_GRAPHICS, "VCa40", $pass, $linenum, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_print_graphics
{
    my ($self, $pass, $first, $last, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(7, SET_PRINT_GRAPHICS, "VCC", $pass, $first, $last);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_print_barcode
{
    # barcode is big int string
    my ($self, $pass, $barcode, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(10, SET_PRINT_BARCODE, "Va5", $pass, get_le_bigint5_from_string($barcode));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

        $self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_load_ext_graphics
{
    my ($self, $pass, $linenum, $array_ref, undef) = @_;

    my $res = {};
    my $data = pack("C*", @{$array_ref});
    my $buf = $self->send_cmd(47, SET_LOAD_EXT_GRAPHICS, "Vva40", $pass, $linenum, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_print_ext_graphics
{
    my ($self, $pass, $first, $last, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(9, SET_PRINT_EXT_GRAPHICS, "Vvv", $pass, $first, $last);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_print_line
{
    my ($self, $pass, $repeats, $array_ref, $wait, undef) = @_;

    my $res = {};
    my $data = pack("C*", @{$array_ref});
    my $buf = $self->send_cmd(7 + length $data, SET_PRINT_LINE, "Vva*", $pass, $repeats, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub set_daily_report_damp_buffer
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_DAILY_REPORT_DAMP_BUFFER, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_print_daily_report_buffer
{
    my ($self, $pass, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_PRINT_DAILY_REPORT_BUFFER, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_rowcount_printbuf
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_ROWCOUNT_PRINTBUF, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($count1, $count2, undef) = unpack("vv", $buf);
	$res->{ROW_COUNT_PRINTBUF} = $count1;
	$res->{ROW_COUNT_PRINTED} = $count2;
    }

    return $res;
}

sub get_string_printbuf
{
    my ($self, $pass, $numstr, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(7, GET_STRING_PRINTBUF, "Vv", $pass, $numstr);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($data, undef) = unpack("a*", $buf);
	$res->{DATA_STRING} = get_hexdump($data);
    }

    return $res;
}

sub set_clear_printbuf
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_CLEAR_PRINTBUF, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_print_barcode_printer
{
    my ($self, $pass, $height, $width, $hr1_pos, $hr1_font, $type, $array_ref, undef) = @_;

    my $res = {};
    my $data = pack("C48", @{$array_ref});
    my $buf = $self->send_cmd(10 + length($data), SET_PRINT_BARCODE_PRINTER, "VCCCCCa*", $pass, $height, $width, $hr1_pos, $hr1_font, $type, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

#    SET_CHECK_CLOSE_RETURN_KPK
#    GET_EKLZ_ACTIVATION_PARAMS

sub get_random_sequence
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_RANDOM_SEQUENCE, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $sequence, undef) = unpack("Ca16", $buf);
	$res->{OPERATOR} = $oper;
	$res->{RANDOM_SEQUENCE} = get_hexdump($sequence);
    }

    return $res;
}

sub set_authentication
{
    my ($self, $pass, $code, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_RANDOM_SEQUENCE, "Va16", $pass, $code);

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub get_fr_ibm_status_long
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_FR_IBM_STATUS_LONG, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $cur_date, $cur_time,
	    $last_tour, $last_docnum, $checks_sale, $checks_buy, $checks_sale_returns, $checks_buy_returns,
	    $open_date, $open_time, $cash, $status, $flags, undef) = unpack("Ca3a3vVvvvva3a3a6a8C", $buf);

	$res->{OPERATOR} = $oper;
	$res->{CURRENT_DATE} = format_date_decode($cur_date);
	$res->{CURRENT_TIME} = format_time_decode($cur_time);
	$res->{LAST_TOUR_NUMBER} = $last_tour;
	$res->{LAST_DOCNUM} = $last_docnum;
	$res->{COUNT_CHECKS_SALE} = $checks_sale;
	$res->{COUNT_CHECKS_BUY} = $checks_buy;
	$res->{COUNT_CHECKS_SALE_RETURNS} = $checks_sale_returns;
	$res->{COUNT_CHECKS_BUY_RETURNS} = $checks_buy_returns;
	$res->{OPEN_TOUR_DATE} = format_date_decode($open_date);
	$res->{OPEN_TOUR_TIME} = format_time_decode($open_time);
	$res->{CASH} = get_hexdump($cash);
	$res->{STATUS} = get_hexdump($status);
	$res->{FLAGS} = $flags;
    }

    return $res;
}

sub get_fr_ibm_status
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_FR_IBM_STATUS, "V", $pass);

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

    return $res;
}

sub set_open_turn
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_OPEN_TURN, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_open_nonfiscal_document
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_OPEN_NONFISCAL_DOCUMENT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_close_nonfiscal_document
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, SET_CLOSE_NONFISCAL_DOCUMENT, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_print_props
{
    my ($self, $pass, $propnum, $value, $wait, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6 + length($value), SET_PRINT_PROPS, "VCA*", $pass, $propnum, $self->encode_string($value));

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;

	$self->printing_wait($pass) if($wait);
    }

    return $res;
}

sub get_state_bill_acceptor
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_STATE_BILL_ACCEPTOR, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $mode, $pool1, $pool2, undef) = unpack("CCCC", $buf);

	$res->{OPERATOR} = $oper;
	$res->{MODE} = $oper;
	$res->{POOL1} = $pool1;
	$res->{POOL2} = $pool2;
    }

    return $res;
}

sub get_registers_bill_acceptor
{
    my ($self, $pass, $regnum, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, GET_REGISTERS_BILL_ACCEPTOR, "VC", $pass, $regnum);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $numreg, $pool, @bills) = unpack("CCCCV*", $buf);

	$res->{OPERATOR} = $oper;
	$res->{REGISTERS_SETS_NUMBER} = $numreg;
	$res->{NUMBER_OF_BILLS} = join(',', map(ord($_), @bills));
    }

    return $res;
}

sub get_report_bill_acceptor
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_REPORT_BILL_ACCEPTOR, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub get_operational_report_ni
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(5, GET_OPERATIONAL_REPORT_NI, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_flap_control
{
    my ($self, $pass, $status, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_FLAP_CONTROL, "VC", $pass, $status);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_check_getout
{
    my ($self, $pass, $type, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(6, SET_CHECK_GETOUT, "VC", $pass, $type);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub set_password_cto
{
    my ($self, $old_pass, $new_pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd(9, SET_PASSWORD_CTO, "VL", $old_pass, $new_pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub get_ext_request
{
    my ($self, $type, $array_ref, undef) = @_;

    my $res = {};
    my $data = pack("C*", @{$array_ref});
    my $buf = $self->send_cmd(2 + length $data, GET_EXT_REQUEST, "Ca*", $type, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	$res->{EXT_REQUEST_RESULT} = get_hexdump($buf);
    }

    return $res;
}

sub get_device_type
{
    my $self = shift;

    my $res = {};
    my $buf = $self->send_cmd(1, GET_DEVICE_TYPE);

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
	$res->{NAME} = Encode::decode($self->{ENCODE_TO}, $name);
    }

    return $res;
}

sub set_extdev_command
{
    my ($self, $pass, $portnum, $array_ref, undef) = @_;

    my $res = {};
    my $data = pack("C*", @{$array_ref});
    my $buf = $self->send_cmd(6 + length($data), SET_EXT_DEVICE_COMMAND, "VCa*", $pass, $portnum, $data);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, undef) = unpack("C", $buf);
	$res->{OPERATOR} = $oper;
    }

    return $res;
}

sub get_fn_status
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd_ff(6, FF_GET_FN_STATUS, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($mode, $curdoc, $datadoc, $status, $flags,
	    $date, $hour, $minute, $fn_number, $fd_last, undef) = unpack("CCCCCa3CCa16V", $buf);
	$res->{FN_NUMER} = $fn_number;
	$res->{FD_LAST} = $fd_last;
	$res->{FLAG_LIFE_STATUS} = get_hexstr2($mode);
	$res->{FLAG_CURRENT_DOCUMENT} = get_hexstr2($curdoc);
	$res->{FLAG_DOCUMENT_DATA} = get_hexstr2($datadoc);
	$res->{FLAG_TURN_STATUS} = get_hexstr2($status);
	$res->{FLAG_WARNINGS} = get_hexstr2($flags);
	$res->{DATE} = format_date_decode($date);
	$res->{TIME} = format_time($hour, $minute, 0);
    }

    return $res;
}

sub get_fn_number
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd_ff(6, FF_GET_FN_NUMBER, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $fn_number, undef) = unpack("Ca16", $buf);
	$res->{OPERATOR} = $oper;
	$res->{FN_NUMER} = $fn_number;
    }

    return $res;
}

sub get_fn_duration
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd_ff(6, FF_GET_FN_DURATION, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($oper, $date, undef) = unpack("Ca3", $buf);
	$res->{OPERATOR} = $oper;
	$res->{FN_DURATION} = format_date_decode($date);
    }

    return $res;
}

sub get_fn_version
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd_ff(6, FF_GET_FN_VERSION, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    if($buf)
    {
	my ($version, $type, undef) = unpack("a16C", $buf);
	$res->{FN_VERSION} = Encode::decode($self->{ENCODE_TO}, $version);
	$res->{FN_TYPE} = get_hexstr2($type);
    }

    return $res;
}

sub get_fn_turn_status
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd_ff(6, FF_GET_FN_TURN_STATUS, "V", $pass);


    if($buf) {
        my ($tour_state, $tour_number, $receipt_number, undef) = unpack("Cvv", $buf);

        $res->{TOUR_STATE} = $tour_state;
        $res->{TOUR_NUMBER} = $tour_number;
        $res->{RECEIPT_NUMBER} = $receipt_number;
    }

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_start_open_turn
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd_ff(6, FF_SET_START_OPEN_TURN, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

sub set_start_close_turn
{
    my ($self, $pass, undef) = @_;

    my $res = {};
    my $buf = $self->send_cmd_ff(6, FF_SET_START_CLOSE_TURN, "V", $pass);

    $res->{DRIVER_VERSION} = MY_DRIVER_VERSION;
    $res->{ERROR_CODE} = $self->{ERROR_CODE};
    $res->{ERROR_MESSAGE} = $self->{ERROR_MESSAGE};

    return $res;
}

#
# private
#

sub send_ack
{
    my $self = shift;
    return $self->write_byte(ack());
}

sub send_nak
{
    my $self = shift;
    return $self->write_byte(nak());
}

sub send_enq
{
    my $self = shift;
    return $self->write_byte(enq());
}

sub write_byte
{
    my $self = shift;
    my $byte = shift;
    my $count = $self->{OBJ}->write($byte);
    if($count != 1)
    {
	$self->{ERROR_CODE} = 255;
        $self->{ERROR_MESSAGE} = $! . ": " . $self->{PORT};
	warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
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
	$self->{ERROR_CODE} = 255;
        $self->{ERROR_MESSAGE} = $! . ": " . $self->{PORT};
	warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	return 0;
    }
    return $count;
}

sub read_byte
{
    my ($self, $timeout, undef) = @_;
    $timeout = $self->{TIMEOUT} unless($timeout);

    my $elapsed = 0;
    my ($sec0, $time0) = gettimeofday();

    do
    {
	my ($count, $byte) = $self->{OBJ}->read(1);
	return $byte if(0 < $count);

	my ($sec1, $time1) = gettimeofday();
	$elapsed = ($sec1 - $sec0) * 1000000 + ($time1 - $time0);
	# wait 1 ms
	usleep(1000);
    }
    while($elapsed < $timeout);

    $self->{ERROR_CODE} = 255;
    $self->{ERROR_MESSAGE} = "read byte error";
    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});

    return undef;
}

sub read_buf
{
    my $self = shift;
    my $len = shift;
    my $res = "";

    $res .= $self->read_byte() for(1 .. $len);

    return $res;
}

sub wait_default
{
    my $self = shift;
    usleep($self->{TIMEOUT});
}

sub fix_command_delay
{
    my ($self, $cmd, undef) = @_;

    return $self->{TIMEOUT} * 6 if($cmd == SET_PRINT_CLICHE);
    return $self->{TIMEOUT} * 4 if($cmd == SET_CHECK_CLOSE);
    return $self->{TIMEOUT} * 4 if($cmd == SET_SELL);
    return $self->{TIMEOUT} * 4 if($cmd == SET_RETURNS_SALE);

    return $self->{TIMEOUT} * 2;
}

sub send_cmd
{
    my ($self, $len, $cmd, $str, @param) = @_;

send_enq:
    usleep(1000); # 1 ms

    # send ENQ
    return 0 unless($self->send_enq());

    # wait reply
    my $byte = $self->read_byte($self->{TIMEOUT} * 2);
    unless(defined $byte)
    {
	$self->{ERROR_CODE} = 255;
	$self->{ERROR_MESSAGE} = "device not reply";
	warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	return 0;
    }

    # is ACK
    if(ack() eq $byte)
    {
	my $mJ = 0;
read_stx:

	$byte = $self->read_byte($self->fix_command_delay($cmd));
	unless(defined $byte)
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "wait stx timeout";
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    goto read_stx;
	}

	# bug: fix double ack for long command (device_set_print_cliche)
	goto read_stx if(ack() eq $byte);

	# assert: stx only
	unless(stx() eq $byte)
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "unknown stx: " . get_hexstr2($byte);
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    return 0;
	}

	$byte = $self->read_byte();
	goto repeat_cmd unless(defined $byte);
	my $len = $byte;

	$byte = $self->read_byte();
	goto repeat_cmd unless(defined $byte);
	my $cmd = $byte;

	$byte = $self->read_byte();
	goto repeat_cmd unless(defined $byte);
	my $err = $byte;

	my $res = 2 < ord($len) ? $self->read_buf(ord($len) - 2) : "";
	my $crc1 = $self->read_byte();
	# calc crc
	my $crc2 = $len ^ $cmd ^ $err;
	   $crc2 ^= $_ foreach(split('', $res));

	# check crc
	if($crc1 == $crc2)
	{
	    $self->send_ack();
	    $self->{ERROR_CODE} = ord($err);
	    $self->{ERROR_MESSAGE} = 0 < ord($err) ? $self->get_message_error(ord($err)) : "";

	    return $res;
	}
	else
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "stx crc error";
    	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    $self->send_naq();
	}

repeat_cmd:
	if($mJ < 10)
	{
	    $mJ ++;
	    goto send_enq;
	}
	else
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "read stx: device not reply, 10 times";
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    return 0;
	}
    }

    # is NAK
    if(nak() eq $byte)
    {
	my $mI = 0;
send_stx:
	my $res = pack("CC" . $str, $len, $cmd, @param);
	# and crc to tail
	my $crc = 0;
	   $crc ^= $_ foreach(unpack("C*", $res));
	my $msg = stx() . $res . chr($crc);
	my $count = $self->write_buf($msg);

	if($count != length($msg))
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "send stx error, $count != " . length($msg);
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    return 0;
	}

	$byte = $self->read_byte($self->{TIMEOUT} * 2);
	# check timeout
	goto send_enq unless(defined $byte);

	if(ack() eq $byte)
	{
	    goto read_stx;
	}

	if($mI < 10)
	{
	    $mI++;
	    goto send_stx;
	}
	else
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "send stx: device not reply, 10 times";
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    return 0;
	}
    }

    $self->{ERROR_CODE} = 255;
    $self->{ERROR_MESSAGE} = "reply unknown: " . get_hexstr2($byte);
    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});

    goto send_enq;
}

sub send_cmd_ff
{
    my ($self, $len, $cmd, $str, @param) = @_;

send_enq:
    usleep(1000); # 1 ms

    # send ENQ
    return 0 unless($self->send_enq());

    # wait reply
    my $byte = $self->read_byte($self->{TIMEOUT} * 2);
    unless(defined $byte)
    {
	$self->{ERROR_CODE} = 255;
	$self->{ERROR_MESSAGE} = "device not reply";
	warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	return 0;
    }

    # is ACK
    if(ack() eq $byte)
    {
	my $mJ = 0;
read_stx:

	$byte = $self->read_byte($self->fix_command_delay($cmd));
	unless(defined $byte)
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "wait stx timeout";
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    goto read_stx;
	}

	# bug: fix double ack for long command (device_set_print_cliche)
	goto read_stx if(ack() eq $byte);

	# assert: stx only
	unless(stx() eq $byte)
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "unknown stx: " . get_hexstr2($byte);
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    return 0;
	}

	$byte = $self->read_byte();
	goto repeat_cmd unless(defined $byte);
	my $len = $byte;

	# hight command byte
	$byte = $self->read_byte();
	goto repeat_cmd unless(defined $byte);
	my $cmd1 = $byte;

	# low command byte
	$byte = $self->read_byte();
	goto repeat_cmd unless(defined $byte);
	my $cmd2 = $byte;

	$byte = $self->read_byte();
	unless(defined $byte)
	{
	    goto repeat_cmd;
	}
	my $err = $byte;

	my $res = 3 < ord($len) ? $self->read_buf(ord($len) - 3) : "";
	my $crc1 = $self->read_byte();
	# calc crc
	my $crc2 = $len ^ $cmd1 ^ $err;
	   $crc2 ^= $_ foreach(split('', $res));

	# check crc
	if($crc1 == $crc2)
	{
	    $self->send_ack();
	    $self->{ERROR_CODE} = ord($err);
	    $self->{ERROR_MESSAGE} = 0 < ord($err) ? $self->get_message_error(ord($err)) : "";

	    return $res;
	}
	else
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "stx crc error";
    	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    $self->send_naq();
	}

repeat_cmd:
	if($mJ < 10)
	{
	    $mJ ++;
	    goto send_enq;
	}
	else
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "read stx: device not reply, 10 times";
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    return 0;
	}
    }

    # is NAK
    if(nak() eq $byte)
    {
	my $mI = 0;
send_stx:
	my $res = pack("CCC" . $str, $len, 0xFF, $cmd, @param);
	# and crc to tail
	my $crc = 0;
	   $crc ^= $_ foreach(unpack("C*", $res));
	my $msg = stx() . $res . chr($crc);
	my $count = $self->write_buf($msg);

	if($count != length($msg))
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "send stx error, $count != " . length($msg);
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    return 0;
	}

	$byte = $self->read_byte($self->{TIMEOUT} * 2);
	# check timeout
	goto send_enq unless(defined $byte);

	if(ack() eq $byte)
	{
	    goto read_stx;
	}

	if($mI < 10)
	{
	    $mI++;
	    goto send_stx;
	}
	else
	{
	    $self->{ERROR_CODE} = 255;
	    $self->{ERROR_MESSAGE} = "send stx: device not reply, 10 times";
	    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});
	    return 0;
	}
    }

    $self->{ERROR_CODE} = 255;
    $self->{ERROR_MESSAGE} = "reply unknown: " . get_hexstr2($byte);
    warn(__PACKAGE__, ": ", $self->{ERROR_MESSAGE}) if($self->{DEBUG});

    goto send_enq;
}

sub format_date
{
    return join('-', map(sprintf("%.2u", $_), @_));
}

sub format_date_decode
{
    my ($day, $month, $year, undef) = unpack("CCC", shift);
    return format_date(2000 + $year, $month, $day);
}

sub format_time
{
    return join(':', map(sprintf("%.2u", $_), @_));
}

sub format_time_decode
{
    my ($hour, $min, $sec, undef) = unpack("CCC", shift);
    return format_time($hour, $min, $sec);
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
    my $str = shift;

    return pack("a5", 0)
	unless(length $str);

    my $number = Math::BigInt->new($str);
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
