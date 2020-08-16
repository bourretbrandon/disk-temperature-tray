#!/usr/bin/perl

use File::Spec;
use GD;
use Glib qw|TRUE FALSE|;
use Gtk2;
use Gtk2::AppIndicator;
use Path::Tiny;

my $strBlockDevice = shift(@ARGV);
open STDERR, '>>', File::Spec->devnull();
&PreCheck;
my $strAppPath = $0;
$strAppPath =~ s/\/[^\/]{1,}$//g;
my $pathTrayAssets = Path::Tiny->tempdir;
system( 'cp "'
      . $strAppPath . '/Lucida.ttf' . '" "'
      . $pathTrayAssets
      . '/Lucida.ttf"' );
my @listBlockDevices = &ListBlockDevices;
my $boolFoundTarget  = 0;
foreach $strFoundDev (@listBlockDevices) {

    if ( $strFoundDev eq $strBlockDevice ) {
        $boolFoundTarget = 1;
    }
}
if ( !$boolFoundTarget ) {
    print 'Could not find supported devices to monitor. Exiting now.' . "\n";
    &GracefulExit;
}
my $intDeviceTemp = &GetTemperature($strBlockDevice);
&DrawIcon($intDeviceTemp);
Gtk2->init;
my $appIndicator = Gtk2::AppIndicator->new( $strBlockDevice, $intDeviceTemp,
    'application-status' );
$appIndicator->set_icon_theme_path($pathTrayAssets);
$appIndicator->set_icon_name_active($intDeviceTemp);
my $indicatorMenu  = Gtk2::Menu->new();
my $indicatorLabel = Gtk2::MenuItem->new($strBlockDevice);
$indicatorMenu->append($indicatorLabel);
my $indicatorQuitCommand = Gtk2::MenuItem->new('Exit');
$indicatorQuitCommand->signal_connect( 'activate' => \&GracefulExit );
$indicatorMenu->append($indicatorQuitCommand);
$appIndicator->set_menu($indicatorMenu);
$indicatorMenu->show_all();
$appIndicator->set_active();
my $glibTimer = Glib::Timeout->add(
    10000,
    sub {
        my $intDeviceTemp = &GetTemperature($strBlockDevice);
        if ( !( -e ( $pathTrayAssets . '/' . $intDeviceTemp . '.png' ) ) ) {
            &DrawIcon($intDeviceTemp);
        }
        $appIndicator->set_icon_name_active($intDeviceTemp);
        $appIndicator->set_active();
        return (TRUE);
    }
);
Gtk2->main;

sub GracefulExit {
    $pathTrayAssets->remove_tree;
    Gtk2->main_quit;
    exit(0);
}

sub PreCheck {
    if ($>) {
        print 'Must be run with super-user privileges. Exiting now.' . "\n";
        exit;
    }
    my $intProcID = open( my $fhTemp, 'smartctl -V |' );
    close($fhTemp);
    if ( !$intProcID ) {
        print 'Could not find "smartctl" on this system. Exiting now.' . "\n";
        exit;
    }
    return;
}

sub DrawIcon {
    my $strText           = shift(@_);
    my $gdImage           = new GD::Image( 64, 64 );
    my $gdColorForeground = $gdImage->colorAllocate( 255, 255, 255 );
    my $strBackground     = '66, 66, 192';
    if ( $strText > 30 ) {
        $strBackground = '66, 192, 66';
    }
    elsif ( $strText > 50 ) {
        $strBackground = '192, 64, 0';
    }
    elsif ( $strText > 60 ) {
        $strBackground = '192, 66, 66';
    }
    my $gdColorBackground =
      $gdImage->colorAllocate( split( /\s?,\s?/, $strBackground ) );
    $gdImage->rectangle( 0, 0, 63, 63, $gdColorBackground );
    $gdImage->fill( 32, 32, $gdColorBackground );
    my @listBounds =
      GD::Image->stringFT( $gdColorForeground,
        ( $pathTrayAssets . '/Lucida.ttf' ),
        26, 0, 0, 0, ( $strText . '°' ) );
    $gdImage->stringFT(
        $gdColorForeground,
        ( $pathTrayAssets . '/Lucida.ttf' ),
        26,
        0,
        int( ( 64 - ( $listBounds[2] - $listBounds[0] ) ) / 2 ),
        ( 32 + int( ( abs( $listBounds[5] ) + $listBounds[1] ) / 2 ) ),
        ( $strText . '°' )
    );
    open( BOUT, '>:raw', ( $pathTrayAssets . '/' . $strText . '.png' ) );
    print BOUT $gdImage->png;
    close(BOUT);
    return;
}

sub ListBlockDevices {
    my @listReturn;
    my @listDevs = `lsblk -d -p`;
    foreach my $strDev (@listDevs) {
        if ( $strDev =~ m/^(\/[^\s]+)/g ) {
            push( @listReturn, $1 );
        }
    }
    return (@listReturn);
}

sub GetTemperature {
    my $strBlockDevice = shift(@_);
    my $intDeviceTemp  = '--';
    my @listSmartReport =
      `sudo smartctl -A $strBlockDevice | grep -i "temperature"`;
    foreach my $strSmartReport (@listSmartReport) {
        if ( $strSmartReport =~ m/temperature:\s+([0-9]+)/ig ) {
            $intDeviceTemp = $1;
        }
        elsif (( $strSmartReport =~ m/_temperature_/i )
            && ( $strSmartReport =~ m/([0-9]+)$/ ) )
        {
            $intDeviceTemp = $1;
        }
    }
    return ($intDeviceTemp);
}
