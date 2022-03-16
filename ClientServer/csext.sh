#!/bin/bash
# 
# This script compiles C source code and run it.
#
#    a) if sole C file compile it and run it (file must have main function)
#
#    b) if zipped C files uncompresses it and compile all C files
#       run the generated a.out executable (only one file can have a main file)
#  #All source files must be in same dir
#  #The ma/usrin file must be the only function in its file.
#  #Nothing usefull for the program besides main should be in this file: not any other function, or data declarations!
#  #This is required for C
#
#    c) if specified in context Environment a client program, copies it to submission directory 
#      i) if a main function exists in this file it is ran (the submitted file with main is deleted)
#     ii) also aditional classes to form a small API can be implemented in this file
#
#   call:
#			myc.sh <compiler> <mooshak dir> <submission_file> <extension> <problem_environment>  <extra_flags>  
#
#	example:
#			myc.sh "/usr/bin/gcc -Wall -lm" /home/mooshak/ src.zip .zip data/contests/POO1920/problems/P3/Environment "-lpthread"
#
# Helder Daniel						
# hdaniel@ualg.pt


xtraZipDir=__MACOSX
extraCodeName="MooshakTester"
#to compile *.c and *.cpp
srcExt="c*"
exec="a.out"
runnerScript="run.sh"
dfltWorkdir="src"

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
function findMainFunctionFile {
local workdir=$1

	#get 1st match only
	result=$(grep -r "main[ ]*(" $workdir | head -n1)
	echo $result | cut -d: -f1
}


#get submitted code and unpack it if needed
function getSubmission {
local extension=$1
local file=$2

case "$extension" in
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
	/usr/bin/unzip $file > /dev/null
	;;

	*)
	#/bin/echo "C/C++ .c or .cpp"
	#Avoid error in creating dir in reevaluation
	if [ ! -d $dfltWorkdir ]; then
		/bin/mkdir $dfltWorkdir
	fi
	/bin/cp $file $dfltWorkdir
	;;
esac

#Give write permissions so that can be deleted 
#on reevaluation
#chmod -R u+w *
}


#Add extra source code if it is defined in problem environment (from Mooshak GUI)
function addExtraCode {
local environment=$1
local workdir=$2
local extraCodeName=$3
local srcExt=$4

#Note: file $environment must not exist or have 0 size
#If exists and have blank chars must be cleanned with mooshak GUI or from cmd line
if [ -f "$environment" ]; then    #exist
	if [ -s "$environment" ]; then #not empty
		#Search for a file with mainextract extension (c or cpp) and remove it
		result=$(findMainFunctionFile $workdir)
		mainExt=$(echo $result | rev | cut -d. -f1 | rev)
		rm "$result"

		#Store extra source code in working dir with file name <submission dir>.$srcExt
		extraCode="$workdir/$extraCodeName.$mainExt"
		cp "$environment" "$extraCode"
	fi
fi
}



######################
#
# Main prg
#
######################

#Get script parameters
compiler="$1"
home="$2"
file="$3"
extension="$4"
environment="$home/$5"
extraflags="$6"

#get submission directory
curdir=$(curDir)

#if revaluating DO NOT recreate files
#search for a report
#if [ -f "1.html" ]; then
#        exit 0
#fi

#if revaluating DO NOT recreate only SOURCE files
#but recreate run.sh.
#This allows to test changing the $ENVIRONMET Extra source code
if [ ! -f "1.html" ]; then
	#Unpack files if needed
	getSubmission $extension $file
fi

#Find unpacking/work directory
workdir=$(newestDir)

#Add extra source code if it is defined in problem environment (from Mooshak GUI)
#If it has a main() function set to run it instead of submitted main() function
addExtraCode $environment $workdir $extraCodeName $srcExt

#compile
serverExec="server"
clientExec="client"
serverSrc=$serverExec.$srcExt
clientSrc=$clientExec.$srcExt
compileMode=0  # 2 client/server; else single *.c

#Search for server and client source code
if [ -f $workdir/$serverSrc -a -f $workdir/$clientSrc ]; then
	compileMode=2
	$compiler $workdir/$serverSrc -o $workdir/$serverExec $extraflags
	$compiler $workdir/$clientSrc -o $workdir/$clientExec $extraflags
else
	$compiler $workdir/*.$srcExt -o $workdir/$exec $extraflags
fi

#Create runner script $runnerScript
#determine if in default package or not
echo "#!/bin/bash" > "$runnerScript"
if [ "$compileMode" -eq 2 ]; then
	echo "pkill -9 -u $UID server" >> "$runnerScript"   #kill client and server if they exist       
	echo "pkill -9 -u $UID client" >> "$runnerScript"   #and are from user
	echo "cat <&0 > tmp" >> "$runnerScript"
	echo "$workdir/$serverExec < tmp 2>&1 &" >> "$runnerScript"
	echo "sleep 0.1" >> "$runnerScript"
	echo "$workdir/$clientExec < tmp 2>&1" >> "$runnerScript"
	echo "rm tmp" >> "$runnerScript"
#	echo "sleep 0.1" >> "$runnerScript"     
	echo "pkill -9 -u $UID server" >> "$runnerScript"               
	echo "exit 0" >> "$runnerScript"   #avoid return error if pkill does not find process
else
	echo "$workdir/$exec 2>&1" >> "$runnerScript"
fi

chmod 750 "$runnerScript"

