#!/usr/bin/perl
$do_standardise = 0; # TODO: implement speaker standardisation...
$do_select = 0;
$regression = 0;  # 0: classification model , 1: regression model

#--------------
use File::Basename;
require "arff-functions.pl";

if ($#ARGV < 0) {
  print "\nUsage: perl predict.pl <corpus_path ¦ arff file (must end in .arff)>  [SMILExtract config for corpus mode]\n\n";
  exit -1;
}

$xtract = "../../SMILExtract";

#mkdir ("built_models");
mkdir ("work1");
$corp = $ARGV[0];  # full path to corpus OR direct arff file...
if ($corp =~ /\.arff$/i) {
  $mode="arff";
  unless (-f "$corp") {
    print "ERROR '$corp' is not an ARFF file or does not exist!\n";
    exit;
  }
  $cname=basename($corp);
  $cname =~s/\.arff$//i;
  $arff = $corp;
  #$modelpath = "built_models/$cname";
  $workpath = "work1/$cname";
} else {
  $mode = "corp";
  unless (-d "$corp") {
    print "ERROR '$corp' is not a corpus directory or does not exist!\n";
    exit;
  }
  $corp =~ /\/([^\/]+)_FloEmoStdCls/;
  $cname = $1; 
  $conf = $ARGV[1];
  unless ($conf) { $conf = "is09s.conf"; }
  $cb=$conf; $cb=~s/\.conf$//;
  #$modelpath = "built_models/$cname";
  $workpath = "work1/$cname";
  $arff = "$workpath/$cb.arff";
}

  #mkdir("$modelpath");
  mkdir("$workpath");


#extract features
if ($mode eq "corp") {
  print "-- Corpus mode --\n  Running feature extraction on corpus '$corp' ...\n";
  system("perl stddirectory_smileextract.pl \"$corp\" \"$conf\" \"$arff\"");
} else {
  print "-- Arff mode --\n  Copying '$arff' to work directory ...\n";
  $arffb = basename($arff);
#  print("cp $arff $workpath/$arffb");
  system("cp $arff $workpath/$arffb");
  $arff = "$workpath/$arffb";
}

# ? standardise features
if ($do_standardise) {
 print "NOTE: standardsise not implemented yet, svm-scale will do the job during building of model\n";
}

# ? select features
$lsvm=$arff; $lsvm=~s/\.arff$/.lsvm/i;
if ($do_select) {
 print "Selecting features (CFS)...\n";
 $fself = $arff;
 $fself=~s/\.arff/.fselection/i;
 system("perl fsel.pl $arff");
 $arff = "$arff.fsel.arff";
} else {
  $fself="";
  print "Converting arff to libsvm feature file (lsvm) ...\n";
  # convert to lsvm
  my $hr = &load_arff($arff);
  my $numattr = $#{$hr->{"attributes"}};
  if ($hr->{"attributes"}[0]{"name"} =~ /^name$/) {
    $hr->{"attributes"}[0]{"selected"} = 0;  # remove filename
  }
  if ($hr->{"attributes"}[0]{"name"} =~ /^filename$/) {
    $hr->{"attributes"}[0]{"selected"} = 0;  # remove filename
  }
  if ($hr->{"attributes"}[1]{"name"} =~ /^timestamp$/) {
    $hr->{"attributes"}[1]{"selected"} = 0;  # remove filename
  }
  if ($hr->{"attributes"}[1]{"name"} =~ /^frameIndex$/) {
    $hr->{"attributes"}[1]{"selected"} = 0;  # remove filename
    if ($hr->{"attributes"}[2]{"name"} =~ /^frameTime$/) {
      $hr->{"attributes"}[2]{"selected"} = 0;  # remove filename
    }
  }
  if ($hr->{"attributes"}[1]{"name"} =~ /^frameTime$/) {
    $hr->{"attributes"}[1]{"selected"} = 0;  # remove filename
  }
   #$hr->{"attributes"}[$numattr-1]{"selected"} = 0; # remove continuous label
  &save_arff_AttrSelected($arff,$hr);
  system("perl arffToLsvm.pl $arff $lsvm");
}

# do prediction for data in .lsvm file
print "Predicting (using libsvm)...\n";

$scale = $lsvm; $scale=~s/\.lsvm$/.scale/; 
$scaled_lsvm = $lsvm; $scaled_lsvm =~ s/\.lsvm/.scaled.lsvm/;
$model = "built_models/$ARGV[1]"; $model=~ s/\.conf$/.allft.model/;
 
# scale features

system("libsvm-small/svm-scale -s $scale $lsvm > $scaled_lsvm");

$discfile = $lsvm; $discfile=~s/\.lsvm$/.disc/;
open(FILE,"<$discfile");
$disc=<FILE>; $disc=~s/\r?\n$//;
close(FILE);

$output = "$workpath/output";

if ($disc) { # classification if disc==1

print " Predicting using SVM CLASSFICATION model...\n";
#classification:
system("libsvm-small/svm-predict -b 1 $scaled_lsvm $model $output");

} else { # regression otherwise:

print "  Predicting using SVR REGRESSION model...\n";
#regression
system("svm-predict -b 1 $scaled_lsvm $model $output");



}


$discfile = $lsvm; $discfile=~s/\.lsvm$/.disc/;
open(FILE,"<$discfile");
$disc=<FILE>; $disc=~s/\r?\n$//;
close(FILE);