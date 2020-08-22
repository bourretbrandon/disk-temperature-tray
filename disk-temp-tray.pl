#!/opt/ActivePerl-5.22/bin/perl

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
system('cp "./Lucida.ttf" "' . $pathTrayAssets . '/Lucida.ttf"');
my @listBlockDevices = &ListBlockDevices;
my $boolFoundTarget = 0;
foreach $strFoundDev (@listBlockDevices)
{
	if($strFoundDev eq $strBlockDevice)
	{
		$boolFoundTarget = 1;
	}
}
if(! $boolFoundTarget)
{
	print 'Could not find supported devices to monitor. Exiting now.' . "\n";
	&GracefulExit;
}
my $intDeviceTemp = &GetTemperature($strBlockDevice);
&DrawIcon($intDeviceTemp, $strBlockDevice);
Gtk2->init;
my $appIndicator = Gtk2::AppIndicator->new($strBlockDevice, $intDeviceTemp, 'application-status');
$appIndicator->set_icon_theme_path($pathTrayAssets);
$appIndicator->set_icon_name_active($intDeviceTemp);
	my $indicatorMenu = Gtk2::Menu->new();
		my $indicatorLabel = Gtk2::MenuItem->new($strBlockDevice);
	$indicatorMenu->append($indicatorLabel);
		my $indicatorQuitCommand = Gtk2::MenuItem->new('Exit');
			$indicatorQuitCommand->signal_connect('activate' => \&GracefulExit);
	$indicatorMenu->append($indicatorQuitCommand);
$appIndicator->set_menu($indicatorMenu);
$indicatorMenu->show_all();
$appIndicator->set_active();
my $glibTimer = Glib::Timeout->add(10000,	sub
											{
												my $intDeviceTemp = &GetTemperature($strBlockDevice);
												if(!(-e ($pathTrayAssets . '/' . $intDeviceTemp . '.png')))
												{
													&DrawIcon($intDeviceTemp, $strBlockDevice);
												}
												$appIndicator->set_icon_name_active($intDeviceTemp);
												$appIndicator->set_active();
												return(TRUE);
											});
Gtk2->main;

sub GracefulExit
{
	$pathTrayAssets->remove_tree;
	Gtk2->main_quit;
	exit(0);
}

sub PreCheck
{
	if($>)
	{
		print 'Must be run with super-user privileges. Exiting now.' . "\n";
		exit;
	}	
	my $intProcID = open(my $fhTemp, 'smartctl -V |');
	close($fhTemp);
	if(!$intProcID)
	{
		print 'Could not find "smartctl" on this system. Exiting now.' . "\n";
		exit;
	}
	return;
}

sub DrawIcon
{
	my $intTempDisplay = shift(@_);
	my $strDeviceDisplay = shift(@_);
	$strDeviceDisplay =~ m/\/([^\/]+)$/;
	$strDeviceDisplay = uc($1);
	$strDeviceDisplay =~ s/n[0-9]$//i;
	my $gdImage = new GD::Image(64, 64);
	my $gdColorForeground = $gdImage->colorAllocate(255, 255, 255);
	my $strBackground = '0, 64, 255';
	if($intTempDisplay > 30)
	{
		$strBackground = '0, 192, 0';
	}
	if($intTempDisplay > 50)
	{
		$strBackground = '255, 128, 33';
	}
	if($intTempDisplay > 60)
	{
		$strBackground = '255, 33, 33';
	}
	my $gdColorBackground = $gdImage->colorAllocate(split(/\s?,\s?/, $strBackground));
	$gdImage->rectangle(0, 0, 63, 63, $gdColorBackground);
	$gdImage->fill(32, 32, $gdColorBackground);
	my @listBounds1 = GD::Image->stringFT($gdColorForeground, ($pathTrayAssets . '/Lucida.ttf'), 12, 0, 0, 0, $strDeviceDisplay);
	$gdImage->stringFT($gdColorForeground, ($pathTrayAssets . '/Lucida.ttf'), 12, 0, int((64 - ($listBounds1[2] - $listBounds1[0])) / 2), (12 + int((abs($listBounds1[5]) + $listBounds1[1]) / 2)), $strDeviceDisplay);
	my @listBounds2 = GD::Image->stringFT($gdColorForeground, ($pathTrayAssets . '/Lucida.ttf'), 26, 0, 0, 0, ($intTempDisplay . '°'));
	$gdImage->stringFT($gdColorForeground, ($pathTrayAssets . '/Lucida.ttf'), 26, 0, int((64 - ($listBounds2[2] - $listBounds2[0])) / 2), (40 + int((abs($listBounds2[5]) + $listBounds2[1]) / 2)), ($intTempDisplay . '°'));
	open(BOUT, '>:raw', ($pathTrayAssets . '/' . $intTempDisplay . '.png'));
	print BOUT $gdImage->png;
	close(BOUT);
	return;
}

sub ListBlockDevices
{
	my @listReturn;
	my @listDevs = `lsblk -d -p`;
	foreach my $strDev (@listDevs)
	{
		if($strDev =~ m/^(\/[^\s]+)/g)
		{
			push(@listReturn, $1);
		}
	}
	return(@listReturn);
}

sub GetTemperature
{
	my $strBlockDevice = shift(@_);
	my $intDeviceTemp = '--';
	my @listSmartReport = `sudo smartctl -A $strBlockDevice | grep -i "temperature"`;
	foreach my $strSmartReport (@listSmartReport)
	{
		if($strSmartReport =~ m/temperature:\s+([0-9]+)/ig)
		{
			$intDeviceTemp = $1;
		}
		elsif(($strSmartReport =~ m/_temperature_/i) && ($strSmartReport =~ m/([0-9]+)$/))
		{
			$intDeviceTemp = $1;
		}
	}
	return($intDeviceTemp);
}