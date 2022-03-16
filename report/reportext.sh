#!/bin/bash
# 
# This script prepares a report to be sent to the user 
# along with the source code (IF it is a zip file)
#
# Note:Excludes test folders started by H* from report
#
# Helder Daniel						
# hdaniel@ualg.pt


Submission="$1"
Program="$2"
Report="$3"
Problem="$4"

filter="[^H]*"   #Exclude test folder started by H* from report

hide=0	#Number of hidden test inputs
hidef=$(($hide+1))

ftype=$(file $Program | cut -d' ' -f2)

#If it is NOT a zip, DOES not return report
if [ "$ftype" == "Zip" ]; then
  chmod 600 $Program

  #Add report to zip
  /usr/bin/zip -uj  $Program  $Report

  #Add output error 
  /usr/bin/zip -uj  $Program  $Submission/*.err

  #Add tests inputs to zip
  cp -r $Problem/tests $Submission
  testFolders=$(find $Submission/tests/$filter -name input | sort)
  testFolders=$(echo $testFolders | rev | cut -d' ' -f$hidef- | rev)

  for i in $testFolders; do
    new=${Submission}/tests/$(echo $i | rev | cut -d / -f 2 | rev)input
    mv $i $new
  done

  zip -uj  $Program  $Submission/tests/*input
  rm -rf $Submission/tests

  chmod 400 $Program
else
	echo "Cannot add report to submission, submitted code is NOT a ZIP archive"
fi
