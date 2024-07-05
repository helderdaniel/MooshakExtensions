#!/bin/bash
# 
# This script prepares a report to be sent to the user 
# along with the source code (IF it is a zip file)
#
# call:
#
# 	report.sh <submissionFolder> <submissionFolder/submittedZipFile> <submissionFolder/reportHTMLfile> <contestFolder/problems/problemFolder>
#
# example:
#
#	myreport.sh /home/jvo/data/contests/POO2324/submissions/03214519_Z_had 
#		    /home/jvo/data/contests/POO2324/submissions/03214519_Z_had/src.zip
#		    /home/jvo/data/contests/POO2324/submissions/03214519_Z_had/1.html
#		    /home/jvo/data/contests/POO2324/problems/Z
#
# Helder Daniel						
# hdaniel@ualg.pt
# v1 March 2020
# v2 April 2022
# v3 July  2024

Submission="$1"
Program="$2"
Report="$3"
Problem="$4"
testInfoFileName=".data.tcl"
inputSuf="input"
filter="[^H]*"   #Exclude folder started by H*


ftype=$(file $Program | cut -d' ' -f2)

#If it is NOT a zip, DOES not return report
if [ "$ftype" == "Zip" ]; then
	chmod 600 $Program

	#Add report to zip
	/usr/bin/zip -uj  $Program  $Report

	#Add output error 
	/usr/bin/zip -uj  $Program  $Submission/*.err

	#Get test file info names
        testInfoFiles=$(find $Problem/tests/$filter -name $testInfoFileName | sort) 	

        #Add tests inputs to zip
        for i in $testInfoFiles; do
        	#Get test input filename, path and folder name
        	path=$(echo $i | rev | cut -d'/' -f2- | rev)
        	testFolder=$(echo $path | rev | cut -d'/' -f1 | rev)
		inputFile=$(grep $inputSuf $i | rev | cut -d' ' -f1 | rev)
		#echo $path/$inputFile
		
		#Add to zip
		zip -uj  $Program  "$path/$inputFile"
		
		#rename to format: T?input
		#https://stackoverflow.com/a/16710654/9567003
		newInputFileName=$testFolder$inputSuf
		#echo $newInputFileName
		printf "@ "$inputFile"\n@="$newInputFileName"\n" | zipnote -w $Program
        done
        
        chmod 400 $Program
else
	echo "Cannot add report to submission, submitted code is NOT a ZIP archive"
fi
