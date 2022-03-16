#!/bin/bash
# 
# This script compiles java source code and run it.
#
#    a) if sole java file compile it and run it (file must have class with main function)
#
#    b) if zipped java files uncompresses it and compile all java files
#         run the class where main is specified (only one class can have a main file)
#
#    c) if specified in context Environment a client program, copies it to submission directory 
#      i) if a main function exists in this file it is ran
#     ii) also aditional classes to form a small API can be implemented in this file
#
#    Call:
#
#          myjava.sh   <mooshak dir> <submission_file> <extension> <problem_environment>
#
#    mooshak:
#          
#/bin/bash myjava.sh   $home         $file             $extension  $environment
#
#
#    cmd line
#
#	   myjava.sh   /home/mooshak/   src.zip           .zip     data/contests/POO1920/problems/P3/Environment
#
#
#	To run junit5 Mooshak "contest language" must be configure to:
#				MaxCompFork	10 (or 100)
#				MaxExecFork	10 (or 100)
#
#	And uncomment junit5 compile an run lines below
#
# Helder Daniel						
# hdaniel@ualg.pt


xtraZipDir=__MACOSX
extraCodeName="MooshakTester"
javaExt="java"
runnerScript="run.sh"
dfltWorkdir="src"

#Change for desired mode
username="mooshak"   # instdir: as in /home/$username/contrib (...)
junit="5"	      # junit 4 or 5
jdk="/usr"          #"/usr" or for local "/home/$username/jdk-15.0.2"
#jdk="/home/$username/jdk-15.0.2"
 
#get cur directory name
function curDir {
	result=$(basename $(pwd))
	echo $result
}


#get last created directory name
function newestDir {
	#remove extra Zip dir (MACOSX)
	if [ -d "$xtraZipDir" ]; then
		rm -r $xtraZipDir
	fi
	#get newest dir entry data
	result=$(ls -lF --sort=time | grep / | head -n1)

	#extract dir name
	echo ${result##*' '} | cut -d/ -f1

}


#Find file with main function
function findMainClass {
local workdir=$1

	#get 1st macth only
	result=$(grep -r "void[ ]*main" $workdir | head -n1)
	echo $result | cut -d: -f1 | cut -d. -f1
}


#get submitted code and unpack it if needed
function getSubmission {
local extension=$1
local file=$2

case "$extension" in
	.java)
	#Avoid error in creating dir in reevaluation
	if [ ! -d $dfltWorkdir ]; then
		/bin/mkdir $dfltWorkdir
	fi
	/bin/cp $file $dfltWorkdir
	;;

	.gz)
	#/bin/echo "tar.gz"
	#Send output of unzip to /dev/null to avoid returning it to mooshak.
	#Mooshak requires no output or consider an error
	/bin/tar xmzf $file > /dev/null
	;;

	.zip)
	#/bin/echo "zip"
	#Send output of unzip to /dev/null to avoid returning it to mooshak.
	#Mooshak requires no output or consider an error
	/usr/bin/unzip -o $file > /dev/null
	;;

	*)
	exit 1;
	;;
esac
}


#Add extra source code if it is defined in problem environment (from Mooshak GUI)
function addExtraCode {
local environment=$1
local workdir=$2
local extraCodeName=$3
local javaExt=$4

if [ -f "$environment" ]; then
	extraCode="$workdir/$extraCodeName.$javaExt"

	#Store extra source code in working dir with file name <submission dir>.java
	cp "$environment" "$extraCode"

	#If root package of submission not the default: <src>, set package 
	#in extracode file to workdir (root package name of submission)
	if [ "$workdir" != "src" ]; then
		echo "package $workdir;" | cat - $extraCode > temp && mv temp $extraCode
	fi

	#Search for junit4 or 5 in "$extraCode" 
	#junit4: "org.junit.Test"
	#junit5: "org.junit.jupiter.api.Test"
	#This ways detect junit4 or 5
	junit=$(grep "org.junit" "$extraCode" | wc -l)
	if [ $junit -gt 0 ]; then
		echo "junit"
	else
		#Search for a class $extraCodeName which should have main()
		result=$(grep -w "class[ ]*$extraCodeName" $extraCode)
		echo $result
	fi
fi
}



######################
#
# Main prg
#
######################

#Get script parameters
home="$1"
file="$2"
extension="$3"
environment="$home/$4"

#if revaluating DO NOT recreate files
#search for a report
#if [ -f "1.html" ]; then
#        exit 0
#fi

#get submission directory
curdir=$(curDir)
fullcurdir=$(pwd)

#if revaluating DO NOT recreate only SOURCE files
#but recreate run.sh.
#This allows to test changing the $ENVIRONMET Extra source code
if [ ! -f "1.html" ]; then
	#Unpack files if needed
	getSubmission $extension $file
fi

#Find unpacking/work directory
workdir=$(newestDir)

#Find file with main in submitted code
mainClass=$(findMainClass $workdir)
mainClassSoloName=$(echo ${mainClass##*'/'})
mainClassName=$(echo $mainClass | cut -d/ -f2-)

#Add extra source code if it is defined in problem environment (from Mooshak GUI)
#If it has a main() function set to run it instead of submitted main() function
result=$(addExtraCode $environment $workdir $extraCodeName $javaExt)
if [ "$result" != "" ]; then

	if [ "$result" != "junit" ]; then
		mainClassName=$extraCodeName
	fi
fi


#compile
find $workdir -name *.java > sources.txt

#This way allows that anyone submit junit 4/5 files too
#junit 4
if [ "$junit" = "4" ]; then
	$jdk/bin/javac -J-Dfile.encoding=UTF-8 -cp .:/home/$username/contrib/junit-4.12.jar @sources.txt -Xlint:-unchecked
fi
#junit 5
#(NEED fork>0 to run in safeexec)
if [ "$junit" = "5" ]; then
	$jdk/bin/javac -J-Dfile.encoding=UTF-8 -cp .:/home/$username/contrib/junit-platform-console-standalone-1.6.0.jar @sources.txt -Xlint #:-unchecked
fi

rm sources.txt


#Create runner script $runnerScript

#For alone files in zip
if [ "$workdir" = "" ]; then
	workdir="."
fi

echo "#!/bin/bash" > "$runnerScript"
if [ "$result" != "junit" ]; then
	#echo "$jdk/bin/java -cp $workdir $package$mainClassName 2>&1" >> "$runnerScript"
	echo "$jdk/bin/java -cp $workdir $mainClassName" >> "$runnerScript"
else
	#junit 4
	#Remove test time (which is variable) and last line
	#Not needed in below soultion, cause just prints error lines
	if [ "$junit" = "4" ]; then
		echo "$jdk/bin/java -cp .:/home/$username/contrib/junit-4.12.jar:/home/$username/contrib/hamcrest-core-1.3.jar:$workdir org.junit.runner.JUnitCore MooshakTester | grep 'Mooshak\|expected' | grep '^[^0-9]' | cut -d' ' -f2- 2>&1" >> "$runnerScript"
	fi

	#junit 5
	#(NEED fork>0 to run in safeexec)
	if [ "$junit" = "5" ]; then
		echo "$jdk/bin/java -jar /home/$username/contrib/junit-platform-console-standalone-1.6.0.jar --class-path $fullcurdir/$workdir --scan-class-path 2>&1" >> "$runnerScript"
	fi
fi

chmod 750 "$runnerScript"


