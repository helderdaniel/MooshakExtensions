#!/bin/bash
# 
# This script unzips and compiles RISC-V assembly source code and run it.
#
#    a) Only one file must have *.asm extension
#
#    b) Other supporting files must have a different extension
#       it is suggested *.inc
#
#	 c) If Environment file exists for this problem:
#			- deletes all *.asm files in the unzipped source folder
#			- cp Environment to <unzipped>/client.asm
#
#    Call:
#		myrars.sh <mooshak dir> <submission_file> <extension> <environment>
#
#    mooshak compile:
#		/bin/bash myrars.sh   $home   $file  $extension   $environment 2>compile.err
#
#    mooshak execute:
#		/bin/bash run.sh 2> run.err 2>run.err
#
# 		Note1:  Needed to separate in compile and execute, because in execute there
#				is no access permitions to Environment file in problem folder
#
#		Note2:  If willing to detect errors when running scripts, redirect stderr
#				to files in the submission directory
#
#    cmd line:
#		myrars.sh  /home/mooshak/  src.zip  .zip  data/contests/AC2122/problems/A/Environment
#
#
# Helder Daniel						
# hdaniel@ualg.pt
# January 2022


#MacOsX
xtraZipDir=__MACOSX

#Get script parameters
home="$1"
file="$2"
extension="$3"
environment="$home/$4"

runnerScript="run.sh"
compiler="$home/contrib/rars_533d3c0.jar"

#unpacking/work directory
workdir="${file%.*}"
#echo wkdir: $workdir 

#client file to add if NOT null
clientFile="$workdir/client.asm"

#Unpack files only if needed
#if revaluating DO NOT unzip SOURCE files again
if [ ! -d "$workdir" ]; then
	#/bin/tar xmzf $file > /dev/null
	/usr/bin/unzip -o $file > /dev/null
fi

# IF $environment exists for this problem (<problem>/Environment)
#   delete all *.asm and 
#   cp $environment $clientFile
#
#Note could NOT do with cp, due to permissions
#but on POO2021 it works
if [ -f "$environment" ]; then
    rm $workdir/*.asm
   	cp "$environment" "$clientFile"
fi

#Find main
main=$(find $workdir -name *.asm)
#echo main: $main

#compile and run
#echo "/usr/bin/java -jar $compiler me $main 2> /dev/null" > $runnerScript
echo "/usr/bin/java -jar $compiler me $main" > $runnerScript
chmod 750 "$runnerScript"

