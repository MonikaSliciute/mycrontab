#!/bin/bash

# set global variables:
yes="y"
no="n"

# a function that displays the program's menu:
displayMenu () {
echo "1. Display crontab jobs"
echo "2. Insert a job"
echo "3. Edit a job"
echo "4. Remove a job"
echo "5. Remove all jobs"
echo "9. Exit"
}

# a function to insert a new job to crontab file:
insertJob () {
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
presetInsert 
elif [ $option -eq 2 ]
then
customInsert  
else
echo "Invalid input"
fi
done

freq=$retval # returns a frequency e.g. * * 1 2 3 from preset_insert or custom_insert
read -p "Enter a command:" command  # command e.g. echo "Hello"

freqO=$(echo "$freq" | tr '*' o) # swap all asterisks to 'o' to avoid issues with the special character
translate $freqO
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

# a function that prompts a user to choose a preset frequency and returns it as a crontab frequency:
presetInsert () {
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

# a function to print custom insert options for the user:
insertOptions () {
field=$1
echo
echo "Input options:"
echo "- single specific $field X, enter: X"
echo "- every $field, enter: *"
echo "- every X "$field"s, enter: */X"
echo "- between X and Y "$field"s, enter: X-Y"
echo "- between X and Z, A and B ... enter: X-Z,A-B,..."
echo "- multiple specific "$field"s X,Y,Z, enter: X,Y,Z"
echo "- between X and Y "$field"s every Z "$field"s, enter: X-Y/Z"
echo
}

# a function that asks the user for a custom frequency and returns it as a crontab frequency:
customInsert () {
frequency=""

echo "When would you like the job to occur? Type * for every."
echo

# INPUT MINUTES:
validInput=0
until [ $validInput -eq 1 ]
do
insertOptions "minute"
read -p "Enter minutes: " min
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
insertOptions "hour"
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
insertOptions "day"
read -p "Enter day of the month (1-31): " day
unifyDelimiters "$day" 
dayModified="$retval"
IFS=',' read -ra arr <<< "$dayModified"  # separate user input using commas
for x in "${arr[@]}"; do  # loop through the user input to validate it
if [ $x -ge 1 -a $x -le 31 2>/dev/null ]
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
frequency="$frequency $day"
fi 
done

# INPUT MONTH:
validInput=0
until [ $validInput -eq 1 ]
do
insertOptions "month"
read -p "Enter month (1-12): " month
month=$(echo "$month" | tr '[:upper:]' '[:lower:]' 2>/dev/null )
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
elif [ "$x" = "*" ]
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
insertOptions "weekday"
read -p "Enter weekday (0-7 note: 0 and 7 is Sunday): " weekday
weekday=$(echo "$weekday" | tr '[:upper:]' '[:lower:]' 2>/dev/null )
if [[ "$weekday" =~ [a-z] ]] && [[ "$weekday" =~ "-" || "$weekday" =~ "/" || "$weekday" =~ "," ]] #input with letters and ranges
then
echo "You cannot use ranges and lists with weekday names."
validInput=0

elif [[ "$weekday" =~ [a-z] ]] # input with just letters
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
elif [ "$x" = "*" ]
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
editJob () {
echo "Choose a job to edit:"
maxEditID=$1 #last id number to edit
echo "$maxEditID"
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
removeJob () {
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
freqO="$1 $2 $3 $4 $5"

case "$freqO" in
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

### e.g. freqO="1-20 */2 1-3,28 dec fri"
for word in $freqO # loop through each word in freqency string
do

case $count in
1) # MINUTES:
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
string="Between $minBeforeSlash minutes every $minAfterSlash minutes"
else
string="Every $minAfterSlash minutes"
fi

else
string="At minute(s) $word"
fi
;;

2) # HOURS:
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
string="$string between $hourBeforeSlash hours every $hourAfterSlash hours"
else
string="$string every $hourAfterSlash hours"
fi

else
string="$string past hour(s) $word"
fi
;;

3) # DAY:
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
string="$string between days $dayBeforeSlash every $dayAfterSlash days"
else
string="$string every $dayAfterSlash days"
fi

else
string="$string on day(s) $word"
fi
;;

4) # MONTH:
word=$(echo "$word" | tr '[:upper:]' '[:lower:]' 2>/dev/null )
if [ $word = "o" ]
then
string="$string every month"
elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
monthAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
monthBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$monthBeforeSlash" =~ "-" ]]
then
### split before and after '-'
m1=$(echo "$monthBeforeSlash" | cut -d'-' -f 1)
m2=$(echo "$monthBeforeSlash" | cut -d'-' -f 2)
getMonth $m1
m1=$retval
getMonth $m2
m2=$retval
string="$string between months $m1 and $m2 every $monthAfterSlash months"
else
string="$string every $monthAfterSlash months"
fi
# if there's a range or a list
elif [[ "$word" =~ "-" || "$word" =~ "/" || "$word" =~ "," ]]
then
getMonth $word
monthTrans=$retval
string="$string in $monthTrans"

elif [[ "$word" =~ [a-z] ]]
then
string="$string on $word"

else
getMonth $word # call get month and pass month(int)
monthTrans=$retval # get the return value
string="$string in month $monthTrans"
fi
;;

5) # WEEKDAY:
word=$(echo "$word" | tr '[:upper:]' '[:lower:]' 2>/dev/null )
if [ $word = "o" ]
then
string="$string every weekday"

elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
weekdayAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
weekdayBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$weekdayBeforeSlash" =~ "-" ]]
then
### split before and after '-'
w1=$(echo "$weekdayBeforeSlash" | cut -d'-' -f 1)
w2=$(echo "$weekdayBeforeSlash" | cut -d'-' -f 2)
getWeekday $w1
w1=$retval
getWeekday $w2
w2=$retval
string="$string between weekdays $w1 and $w2 every $monthAfterSlash days"
else
string="$string every $weekdayAfterSlash days"
fi

# if there's a range or a list
elif [[ "$word" =~ "-" || "$word" =~ "/" || "$word" =~ "," ]]
then
getWeekday $word
weekdayTrans=$retval
string="$string on $weekdayTrans"

elif [[ "$word" =~ [a-z] ]]
then
string="$string on $word"

else
getWeekday $word # call getWeekday with weekday(int)
weekdayTrans=$retval # get the return value: weekday(string)
string="$string on $weekdayTrans"
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
monthTrans=$1

monthTrans=$(echo ${monthTrans/10/October})
monthTrans=$(echo ${monthTrans/11/November})
monthTrans=$(echo ${monthTrans/12/December})
monthTrans=$(echo ${monthTrans/1/January})
monthTrans=$(echo ${monthTrans/2/February})
monthTrans=$(echo ${monthTrans/3/March})
monthTrans=$(echo ${monthTrans/4/April})
monthTrans=$(echo ${monthTrans/5/May})
monthTrans=$(echo ${monthTrans/6/June})
monthTrans=$(echo ${monthTrans/7/July})
monthTrans=$(echo ${monthTrans/8/August})
monthTrans=$(echo ${monthTrans/9/September})

retval=$monthTrans
}

getWeekday () { #translate weekday(int) to weekday(string)
weekdayTrans=$1

weekdayTrans=$(echo ${weekdayTrans/1/Monday})
weekdayTrans=$(echo ${weekdayTrans/2/Tuesday})
weekdayTrans=$(echo ${weekdayTrans/3/Wednesday})
weekdayTrans=$(echo ${weekdayTrans/4/Thursday})
weekdayTrans=$(echo ${weekdayTrans/5/Friday})
weekdayTrans=$(echo ${weekdayTrans/6/Saturday})
weekdayTrans=$(echo ${weekdayTrans/7/Sunday})
weekdayTrans=$(echo ${weekdayTrans/0/Sunday})

retval=$weekdayTrans
}


displayJobs () {

crontabFile=$( crontab -l 2>/dev/null ) #get the content of the crontab job file to check if it's empty
num=1
if [ -z "$crontabFile" ] # check if empty
then
echo "There are no crontab jobs."
return 1 # return 1(true) if there are no jobs

else
echo "Current crontab jobs:"
crontab -l | while IFS= read -r line # loop through the crontab file
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

freq=$(echo "$job" | tr '*' o) # swap all asterisks to 'o' to avoid issues with the special character

translate $freq # translate the frequency string
string=$retval # get the return value from the translate method
string="$num. $string"
echo "$string $command"
echo
num=$(($num+1))
done # while loop end
return 0 # return 0(false) if there are jobs
fi
}

# MAIN FUNCTION:
key=0 #default key for user input

# pull crontab jobs and display menu, loop until user presses 9 to exit:
until [ $key -eq 9 2>/dev/null ]
do

i=0 # to create keep track of crontab jobs
crontabList=$( crontab -l 2>/dev/null ) #get the content of the crontab file to check if it's empty
if [ -z "$crontabList" ] # check if empty
then
i=1 # set job count/ID to 1
else
# a loop to count jobs:
while IFS= read -r line # loop through the crontab list
do
i=$(($i+1)) # count jobs
done <<< "$(crontab -l)" # here string to loop through the crontab list   
fi
echo 
displayMenu #display menu
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
insertJob $i # pass a new job id
;;
3) # edit a job:
editJob $i
;;
4) # remove a job:
removeJob $i
;;
5) # remove all jobs:
crontab -r 2>/dev/null 
echo "All jobs were removed."
;;
9)
echo "Exit"
;;
*)
echo "Sorry, invalid input"
;;
esac
done
