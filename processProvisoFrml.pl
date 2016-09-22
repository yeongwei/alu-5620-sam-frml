#!/bin/perl

use strict;
use warnings;
use Data::Dumper qw(Dumper);
use File::Basename; 
use Cwd;

sub log {
	print $_[0] . "\n";
}

sub ifElse {
	if (defined $_[0]) {
		return $_[0];
	} else {
		return "";
	} 
}

# print Dumper \@ARGV;
my ($frmlInputFile) = @ARGV;

if (! -e $frmlInputFile) {
	&log("File " . $frmlInputFile . " is not valid!");
	exit -1;
}

my @STORE = ();
my $DELIM = qq(|_|);

open (my $FILE_HANDLE, '<', $frmlInputFile);
my $VALID_LINE = "";
while (my $LINE = <$FILE_HANDLE>) {
	chomp($LINE);
	$LINE =~ s/\<E\>//g;
	# print $LINE . "\n";
	if ($LINE =~ m/^\d+.*/ && $LINE =~ m/CME/) {
		$VALID_LINE = $LINE;
		next;
	} elsif ($LINE =~ m/^\d+.*/ && $LINE =~ m/(Generic|Bulk)/) {
		$VALID_LINE = $LINE;	
	} else {
		$VALID_LINE .= $LINE;
	}
	# print Dumper $VALID_LINE;
	# sleep 2;
	my (
		$dbIndex, $npath, $name, $data,
		$exprType, $type, $comment, $dataType,
		$date, $state, $curve, $nbHost, $defValue,
		$domaine
	) = ("", "", "", "", "", "", "", "", "", "", "", "", "", "");
	my @DATA = split(/\|\_\|/, $VALID_LINE);
	# print Dumper $#DATA;
	# if ($#DATA < 10) {
	#	print Dumper $LINE;
	# }

	(
                 $dbIndex, $npath, $name, $data,
                 $exprType, $type, $comment, $dataType,
                 $date, $state, $curve, $nbHost, $defValue,
                  $domaine
        ) = @DATA; 
	
	# if (!$npath =~ m/CME/) {
	#	next;
	# }
	
	my $styleSheet = getcwd; # print $styleSheet;
	$styleSheet = $styleSheet . "/smallTalkFormula.xslt.xml";
	
	my $tmpFile = basename($0);
	$tmpFile =~ s/\.pl/.xml/;
	$tmpFile = "/tmp/" . $tmpFile;
	
	open (my $FILE_HANDLE2, '>', $tmpFile);
	# $data = `echo $data | xmllint --format -`;
	print $FILE_HANDLE2 $data;
	close $FILE_HANDLE2;
	# print $data;
	
	my $cmd = "xsltproc" . " " . $styleSheet . " " . $tmpFile . " " . "2>/dev/null";
	# print Dumper $cmd;
	my $parsed = `$cmd`;
	chomp($parsed);
	# print Dumper $parsed;
	
	my @parsedData = split(/\-\-\+\-\-\+\-\-/, $parsed);
	# print Dumper \@parsedData;
	# print Dumper $#parsedData;
	my @inputBindings = ();
	my @inputBindingTypes = ();
	my $inputBindingCount = 0;
	my $source = "";
	my $sourceLength = 0;
	if ($#parsedData > 0) {
		$source = $parsedData[1];
		chomp($source);
		$source =~ s/\R//g;
		# print Dumper $source;
		$sourceLength = length($source);
		
		my @tmpInputBindings = split(",", $parsedData[0]);
		# print Dumper \@tmpInputBindings;	
		foreach my $tmpInputBinding (@tmpInputBindings) {
			my @tmp = split(/\|/,  $tmpInputBinding);
			# print Dumper \@tmp;
			push(@inputBindings, $tmp[0]);
			push(@inputBindingTypes, $tmp[1]);
		}

		# print Dumper \@inputBindings;
		# print Dumper \@inputBindingTypes;	
		
		$inputBindingCount = ($#inputBindings + $#inputBindingTypes)/2 + 1;
	}
	
	# next;
	
	my $NEW_LINE = "";
	$NEW_LINE .= $dbIndex . $DELIM;
	$NEW_LINE .= $npath . $DELIM;
	$NEW_LINE .= $name . $DELIM;
	# $NEW_LINE .= $data . $DELIM;
	$NEW_LINE .= $inputBindingCount . $DELIM;
	$NEW_LINE .= $sourceLength . $DELIM;
	$NEW_LINE .= join(",", @inputBindings) . $DELIM;
	$NEW_LINE .= join(",", @inputBindingTypes) . $DELIM;
	$NEW_LINE .= $source . $DELIM;
	$NEW_LINE .= &ifElse($exprType) . $DELIM;
	$NEW_LINE .= &ifElse($type) . $DELIM;
	$NEW_LINE .= &ifElse($comment) . $DELIM;
	$NEW_LINE .= &ifElse($dataType) . $DELIM;
	$NEW_LINE .= &ifElse($date) . $DELIM;
	$NEW_LINE .= &ifElse($curve) . $DELIM;
	$NEW_LINE .= &ifElse($nbHost) . $DELIM;
	$NEW_LINE .= &ifElse($defValue) . $DELIM;
	$NEW_LINE .= &ifElse($domaine);

	# print Dumper $NEW_LINE;
	push(@STORE, $NEW_LINE);
}
close $FILE_HANDLE;

my $dateTime = `date +%Y.%m.%d-%H.%M.%S`;
chomp($dateTime);
my $outputFileName = "out.$dateTime.txt";

my $HEADER_LINE = "";
$HEADER_LINE .= "dbIndex" . $DELIM;
$HEADER_LINE .= "npath" . $DELIM;
$HEADER_LINE .= "name" . $DELIM;
# $HEADER_LINE .= "data" . $DELIM;
$HEADER_LINE .= "inputBindingCount" . $DELIM;
$HEADER_LINE .= "sourceLength" . $DELIM;
$HEADER_LINE .= "inputBindings" . $DELIM;
$HEADER_LINE .= "inputBindingTypes" . $DELIM;
$HEADER_LINE .= "source" . $DELIM;
$HEADER_LINE .= "exprType" . $DELIM;
$HEADER_LINE .= "type" . $DELIM;
$HEADER_LINE .= "comment" . $DELIM;
$HEADER_LINE .= "dataType" . $DELIM;
$HEADER_LINE .= "date" . $DELIM;
$HEADER_LINE .= "curve" . $DELIM;
$HEADER_LINE .= "nbHost" . $DELIM;
$HEADER_LINE .= "defValue" . $DELIM;
$HEADER_LINE .= "domaine";

open (my $FILE_HANDLE3, '>>', $outputFileName);
print $FILE_HANDLE3 $HEADER_LINE . "\n";
for my $EACH_LINE (@STORE) {
	# print Dumper $EACH_LINE;
	print $FILE_HANDLE3 $EACH_LINE . "\n";
}
close $FILE_HANDLE3;
