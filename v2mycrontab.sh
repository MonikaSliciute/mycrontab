#!/bin/bash

# set variables
yes="y"
no="n"

#display menu:
menu () {
echo "1. Display crontab jobs"
echo "2. Insert a job"
echo "3. Edit a job"
echo "4. Remove a job"
echo "5. Remove all jobs"
echo "9. Exit"
}

#insert job
insert () {
id=$1
echo "Choose a preset or enter a specific frequency: "
echo
echo "1. Preset"
echo "2. Custom"
echo
option=0 # default
until [ $option -eq 1 -o $option -eq 2 2>/dev/null ] # wait for a valid user input
do
read -p "Choose one of the above options: " option
if [ $option -eq 1 ]
then
preset_insert 
elif [ $option -eq 2 ]
then
custom_insert  
else
echo "Invalid input"
fi
done

freq=$retval # returns a frequency e.g. * * 1 2 3 from preset_insert or custom_insert
read -p "Enter a command:" command  # command e.g. echo "Hello"

freq_o=$(echo "$freq" | tr '*' o) # swap all asterisks to 'o' to avoid issues with the special character
translate $freq_o
string=$retval
echo "$string $command" # e.g. At every reboot run echo "Hello"
echo
command="$freq $command" # e.g. * * 1 2 3 echo "Hello"

answer="" # reset answer
until [ "$answer" = "$yes" -o "$answer" = "$no" 2>/dev/null ] # wait for a valid user input
do
read -p "Create the above job? (y/n):" answer
if [ "$answer" = "$yes" ]
then
crontab -l 2>/dev/null | { cat; echo "$command"; } | crontab -
elif [ "$answer" = "$no" ]
then
echo "Job not inserted."
else
echo "Invalid input"
fi
done
}

#insert job with a preset settings:
preset_insert () {
echo "1. Hourly"
echo "2. Daily"
echo "3. Weekly"
echo "4. Monthly"
echo "5. Yearly"
echo "6. At Reboot"

input=0
until [ $input -gt 0 -a $input -le 6 2>/dev/null ]
do
read -p "Choose one of the above options:" input
insertTime=""
case $input in
1)
insertTime="0 * * * *"
;;
2)
insertTime="0 0 * * *"
;;
3)
insertTime="0 0 * * 0"
;;
4)
insertTime="0 0 1 * *"
;;
5)
insertTime="0 0 1 1 *"
;;
6)
insertTime="@reboot"
;;
*)
echo "Invalid input. Choose an option between 1-6."
;;
esac
done
retval=$insertTime # return frequency e.g. 0 * * * * *
}

# if a user enters a range instead of a single number, unifyDelimiters will change '/' and '-' to ',' 
# so it is easier to separate the string to validate user input, e.g. '1-23/2' becomes '1,23,2'
unifyDelimiters () {
str="$1"
strModified=$(echo "$str" | tr '-' ',' | tr '/' ',')
retval="$strModified"
}

#insert a job with custom settings:
custom_insert () {
frequency=""

echo "When would you like the job to occur? Type * for every."
echo

# INPUT MINUTES:
validInput=0
until [ $validInput -eq 1 ]
do

read -p "Enter minutes (0-59): " min
unifyDelimiters "$min" 
minModified="$retval"
IFS=',' read -ra arr <<< "$minModified"  # separate user input using commas
for x in "${arr[@]}"; do  # loop through the user input to validate it
if [ $x -ge 0 -a $x -le 59 2>/dev/null ]  #check if x is a number and valid
then
validInput=1
elif [ "$x" = "*" ]
then
validInput=1
else
validInput=0
echo "Invalid input, try again."
break
fi
done

if [ $validInput -eq 1 ]
then
frequency="$min" # save the frequency
fi
done

# INPUT HOURS:
validInput=0
until [ $validInput -eq 1 ]
do
read -p "Enter hour (0-23): " hour
unifyDelimiters "$hour" 
hourModified="$retval"
IFS=',' read -ra arr <<< "$hourModified"  # separate user input using commas
for x in "${arr[@]}"; do  # loop through the user input to validate it
if [ $x -ge 0 -a $x -le 23 2>/dev/null ] # check if hour is a number and valid
then
validInput=1
elif [ "$x" = "*" ]
then
validInput=1
else
validInput=0
echo "Invalid input, try again."
break
fi
done

if [ $validInput -eq 1 ]
then
frequency="$frequency $hour"
fi
done

# INPUT DAY OF THE MONTH:
validInput=0
until [ $validInput -eq 1 ]
do
read -p "Enter day of the month (1-31): " day
unifyDelimiters "$day" 
dayModified="$retval"
IFS=',' read -ra arr <<< "$dayModified"  # separate user input using commas
for x in "${arr[@]}"; do  # loop through the user input to validate it
if [ $x -ge 1 -a $x -le 31 2>/dev/null ]
then
validInput=1
elif [ "$day" = "*" ]
then
validInput=1
else
validInput=0
echo "Invalid input, try again."
break
fi
done

if [ $validInput -eq 1 ]
then
frequency="$frequency $day"
fi 
done

# INPUT MONTH:
validInput=0
until [ $validInput -eq 1 ]
do
read -p "Enter month (1-12): " month

if [[ "$month" =~ [a-z] ]] && [[ "$month" =~ "-" || "$month" =~ "/" || "$month" =~ "," ]] #input with letters and ranges
then
echo "You cannot use ranges and lists with month names."
validInput=0

elif [[ "$month" =~ [a-z] ]] # input with just letters
then
monthLower=$(echo "$month" | tr '[:upper:]' '[:lower:]')
monthList=("jan" "feb" "mar" "apr" "may" "jun" "jul" "aug" "sep" "oct" "nov" "dec")
for j in ${!monthList[@]};
do
item=${monthList[$j]}
if [ "$monthLower" = "$item" ] 
then
validInput=1 
break #found the right value
fi 
done

else # input with numbers and/or ranges:
unifyDelimiters "$month" 
monthModified="$retval"
IFS=',' read -ra arr <<< "$monthModified"  # separate user input using commas
for x in "${arr[@]}"; do  # loop through the user input to validate it
if [ $x -ge 1 -a $x -le 12 2>/dev/null ] 
then
validInput=1
elif [ "$month" = "*" ]
then
validInput=1
else
validInput=0
break
fi 
done
fi 

if [ $validInput -eq 1 ] 
then
frequency="$frequency $month"
else
echo "Invalid input, try again."
fi 
done

# INPUT WEEKDAYS:
validInput=0
until [ $validInput -eq 1 ]
do
read -p "Enter weekday (0-7 note: 0 and 7 is Sunday): " weekday

if [[ "$weekday" =~ [a-z,A-Z] ]] && [[ "$weekday" =~ "-" || "$weekday" =~ "/" || "$weekday" =~ "," ]] #input with letters and ranges
then
echo "You cannot use ranges and lists with weekday names."
validInput=0

elif [[ "$weekday" =~ [a-z,A-Z] ]] # input with just letters
then
weekdayLower=$(echo "$weekday" | tr '[:upper:]' '[:lower:]')
dayList=("sun" "mon" "tue" "wed" "thu" "fri" "sat")
for j in ${!dayList[@]};
do
item=${dayList[$j]}
if [ "$weekdayLower" = "$item" ] 
then
validInput=1 
break #found the right value
fi #2
done

else # input with numbers and/or ranges:
unifyDelimiters "$weekday" 
dayModified="$retval"
IFS=',' read -ra arr <<< "$dayModified"  # separate user input using commas
for x in "${arr[@]}"; do  # loop through the user input to validate it
if [ $x -ge 0 -a $x -le 7 2>/dev/null  ] 
then
validInput=1
elif [ "$weekday" = "*" ]
then
validInput=1
else
validInput=0
break
fi 
done
fi 

if [ $validInput -eq 1 ] 
then
frequency="$frequency $weekday"
else
echo "Invalid input, try again."
fi 
done

retval=$frequency # return frequency e.g. 1 2 3 * *
}

#edit a job:
edit () {
echo "Choose a job to edit:"
maxEditID=$1 #last id number to edit
displayJobs
noJobs=$?
if [ $noJobs -eq 1 ] # check if the job list is empty
then 
echo 
else
number=0 #default
until [ $number -ge 1 -a $number -lt $maxEditID 2>/dev/null ]
do
read -p "Enter job's number: " number #ask user for a job number to edit
done
crontab -l | sed ""$number"d" | crontab - # delete the 'number' line with the job to be deleted
echo
insert $number # insert an edited job
echo
echo "Job successfully edited."
echo

fi
}

#remove a job:
remove () {
echo "Choose a job to remove:"
maxRemoveID=$1
displayJobs
noJobs=$? 
if [ $noJobs -eq 1 ] # check if displayJobs returns a 'no jobs' flag
then
echo # message already generated in displayJobs method

else # jobs exist:
number=0 # to check if such job exists
until [ $number -ge 1 -a $number -lt $maxRemoveID 2>/dev/null ]
do
read -p "Enter job's number: " number
done

crontab -l | sed ""$number"d" | crontab -  #delete the line with the job that needs removing
echo 
echo "Job successfully removed"
echo
fi
return $number # return a new job id, already incremented
}

translate () {
string=""
# cases for presets
freq_o="$1 $2 $3 $4 $5"

case "$freq_o" in
"0 o o o o")
string="At the beginning of every hour, run the following command:"
;;
"0 0 o o o")
string="At the beginning of every day, run the following command:"
;;
"0 0 o o 0")
string="At the beginning of every week(Sunday), run the following command:"
;;
"0 0 1 o o")
string="At the beginning of every month, run the following command:"
;;
"0 0 1 1 o")
string="At the beginning of every year, run the following command:"
;;
*)
;;
esac

# translation for special presets
if [ "$1" = "@reboot" ]
then
string="At every reboot, run the following command:"
fi

# custom
if [ "$string" = "" ]
then
# custom translate

count=1 # to count words in frequency string

### e.g. freq_o="1-20 */2 1-3,28 dec fri"
for word in $freq_o # loop through each word in freqency string
do

case $count in
1)
if [ $word = "o" ] # if it used to be an asterisk
then
string="At every minute"

elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
minAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
minBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$minBeforeSlash" =~ "-" ]]
then
string="Between $minBeforeSlash every $minAfterSlash minutes"
else
string="Every $minAfterSlash minutes"
fi

else
string="At minute $word"
fi
;;
2)
if [ $word = "o" ]
then
string="$string every hour"

elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
hourAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
hourBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$hourBeforeSlash" =~ "-" ]]
then
string="$string between $hourBeforeSlash every $hourAfterSlash hours"
else
string="$string every $hourAfterSlash hours"
fi

else
string="$string past hour $word"
fi
;;
3)
if [ $word = "o" ]
then
string="$string on every day"
elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
dayAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
dayBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$dayBeforeSlash" =~ "-" ]]
then
string="$string between $dayBeforeSlash every $dayAfterSlash days"
else
string="$string every $dayAfterSlash days"
fi

else
string="$string on day $word"
fi
;;
4)
if [ $word = "o" ]
then
string="$string every month"
# if there's a range or a list
# elif [[ "$word" =~ "-" || "$word" =~ "/" || "$word" =~ "," ]]
else
getMonth $month # call get month and pass month(int)
mthname=$retval # get the return value
string="$string in month $mthname"

# elif [ "$word" =~ [a-z,A-Z] ]
# then
#string="$string in month $mthname"
fi
;;
5)
if [ $word = "o" ]
then
string="$string every weekday"
# if there's a range or a list
# elif [[ "$word" =~ "-" || "$word" =~ "/" || "$word" =~ "," ]]
else
getWeekday $weekday # call getWeekday with weekday(int)
weekname=$retval # get the return value: weekday(string)
string="$string on $weekname"

#elif [ "$word" =~ [a-z,A-Z] ]
#then
#string="$string on $weekname"
fi
;;
*)
;;
esac

count=$(($count+1)) # increment count
done # foreach loop end
string="$string, run the following command:"

fi # end of if custom

retval=$string # return translated job
}
getMonth () { #translate month(int) to month(string)
month=$1
monthstring=""
case $month in
1)
monthstring="January"
;;
2)
monthstring="February"
;;
3)
monthstring="March"
;;
4)
monthstring="April"
;;
5)
monthstring="May"
;;
6)
monthstring="June"
;;
7)
monthstring="July"
;;
8)
monthstring="August"
;;
9)
monthstring="September"
;;
10)
monthstring="October"
;;
11)
monthstring="November"
;;
12)
monthstring="December"
;;
*)
monthstring=""
;;
esac
retval=$monthstring
}

getWeekday () { #translate weekday(int) to weekday(string)
day=$1
daystring=""
case $day in
1)
daystring="Mondays"
;;
2)
daystring="Tuesdays"
;;
3)
daystring="Wednesdays"
;;
4)
daystring="Thursdays"
;;
5)
daystring="Fridays"
;;
6)
daystring="Saturdays"
;;
7)
daystring="Sundays"
;;
0)
daystring="Sundays"
;;
*)
daystring=""
;;
esac
retval=$daystring
}

displayJobs () {

firstLine=$( cat newJobList.txt) #get the content of the crontab job file to check if it's empty

if [ -z "$firstLine" ] # check if empty
then
echo "There are no crontab jobs."
return 1 # return 1(true) if there are no jobs

else
echo "Current crontab jobs:"
while IFS= read -r line # loop through the temp file
do
job="$line" # get a single line from a file (crontab job)
check=$( echo "$job" | cut -d" " -f 1 )
if [ "$check" = "@reboot" ]
then
freq=$check
command=$( echo "$job" | cut -d" " -f 2- ) # get the command part
else
freq=$( echo "$job" | cut -d" " -f 1-5 ) # get just the frequency setting
command=$( echo "$job" | cut -d" " -f 6- ) # get the command part
fi

id=$( echo "$job" | cut -d"#" -f 2 ) # get the job id number
command=$( echo "$command" | cut -d"#" -f 1 ) # get rid of the id comment
freq=$(echo "$job" | tr '*' o) # swap all asterisks to 'o' to avoid issues with the special character

translate $freq # translate the frequency string
string=$retval # get the return value from the translate method
string="$id. $string"
echo "$string $command"
echo
done < newJobList.txt # while loop end
return 0 # return 0(false) if there are jobs
fi
}

# MAIN:
i=1 # to create job ids
key=0 #default key for user input

# pull crontab jobs and display menu, loop until user presses 9 to exit:
until [ $key -eq 9 2>/dev/null ]
do

# create/update job list file:
rm newJobList.txt 2>/dev/null # remove the file if already exists
i=1 # to count jobs/give them IDs
echo "$(crontab -l 2>/dev/null )" > jobList.txt # create a temporary file with all crontab jobs
firstLine=$( cat jobList.txt) #get the content of the crontab job file to check if it's empty
if [ -z "$firstLine" ] # check if empty
then
i=1 # set job count/ID to 1
echo "" >> newJobList.txt #create an empty file (no jobs)
else
line=""
# a loop to add ids to jobs:
while IFS= read -r line # loop through the crontab list
do
newline="$line #$i" # add an id
echo "$newline" >> newJobList.txt # save the job to a file
i=$(($i+1)) # increment id
done < jobList.txt 
fi
# remove temporary files:
rm jobList.txt 2>/dev/null

echo 
menu #display menu
echo
read -p "Choose an option: " key
echo "Option chosen: $key"
echo
#cases:
case $key in
1) # display all jobs:
displayJobs
;;
2) # insert a new job:
insert $i # pass a new job id
;;
3) # edit a job:
edit $i
;;
4) # remove a job:
remove $i
;;
5) # remove all jobs:
crontab -r 2>/dev/null 
echo "All jobs were removed."
i=1 # reset the id to 1 again
;;
9)
rm newJobList.txt 2>/dev/null # delete the temporary file
echo "Exit"
;;
*)
echo "Sorry, invalid input"
;;
esac
done
