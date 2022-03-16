#!/bin/bash

#path to Digital.jar
#Digital.jar must have ** lib ** folder to access components such as chips
digpath="/home/mooshak/contrib/Digital-v0.25/Digital.jar"

#output if all tests passed: "passed"
#if one does NOT pass it outputs NOTHING
okstring="passed"

#get stdin from input test case file and pass it as -tests arg
#clear stderr (2>/dev/null) to avoid error on set utils.prefs with usr "nobody"
#with uid defined by mooshak [MinUID, MaxUID], different than mooshak uid
#which will give RUNTIME ERROR
java -cp $digpath CLI test -circ $1 -tests /dev/stdin 2> /dev/null | grep -o -w $okstring




