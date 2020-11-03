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
displayJobs # displays all jobs in crontab
totalJobs=$? # number of current jobs
if [ $totalJobs -ne 0 ] # check if the job list has jobs
then 
selectedJob=0 # default, for checking if such job exists
# until a user select a job that is in the crontab
until [ $selectedJob -ge 1 -a $selectedJob -le $totalJobs 2>/dev/null ]
do
read -p "Enter job's number: " selectedJob # ask user for a job number to edit
done
crontab -l | sed ""$selectedJob"d" | crontab - # delete the 'selectedJob' line with the job to be deleted
echo
insertJob # insert an edited job
echo
echo "Job successfully edited."
echo
fi
}

#remove a job:
removeJob () {
echo "Choose a job to remove:"
displayJobs # displays all jobs in crontab
totalJobs=$? # number of current jobs
if [ $totalJobs -ne 0 ] # check if the job list has jobs
then
selectedJob=0 # default, for checking if such job exists
# until a user select a job that is in the crontab
until [ $selectedJob -ge 1 -a $selectedJob -le $totalJobs 2>/dev/null ]
do
read -p "Enter job's number: " selectedJob # ask user for a job number to remove
done
crontab -l | sed ""$selectedJob"d" | crontab -  # delete the line with the job that needs to be removed
echo 
echo "Job successfully removed"
echo
fi

}

translate () {
string="" # create an empty string (for storing the translated frequency)
freqO="$1 $2 $3 $4 $5" # frequency string (value(s) passed to the translate function)

# cases for translating presets
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

# case for translating special preset (@reboot)
if [ "$1" = "@reboot" ] # only the first field is used for frequency in this case
then
string="At every reboot, run the following command:"
fi

# cases for translating custom frequencies
if [ "$string" = "" ] # if the translation string is still empty (preset translations were not applicable)
then
# custom translate
count=1 # to count words in frequency string

### e.g. freqO="1-20 o/2 1-3,28 dec fri"
for word in $freqO # loop through each word in freqency string
do

case $count in # count=1->minutes, count=2->hours...
1) # MINUTES:
# case: every minute
if [ $word = "o" ] # if it used to be an asterisk
then
string="At every minute"

# case: every X minutes
elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
minAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
minBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$minBeforeSlash" =~ "-" ]]
then # single range case:
string="Between $minBeforeSlash minutes every $minAfterSlash minutes"
else # star case:
string="Every $minAfterSlash minutes"
fi
# case: single value, list, range
else
string="At minute(s) $word"
fi
;;

2) # HOURS:
# case: every hour
if [ $word = "o" ]
then
string="$string every hour"

# case: every X hours
elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
hourAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
hourBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$hourBeforeSlash" =~ "-" ]]
then # single range case:
string="$string between $hourBeforeSlash hours every $hourAfterSlash hours"
else # star case:
string="$string every $hourAfterSlash hours"
fi

# case: single value, list, range
else
string="$string past hour(s) $word"
fi
;;

3) # DAY:
# case: every day
if [ $word = "o" ]
then
string="$string on every day"

# case: every X days
elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
dayAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
dayBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$dayBeforeSlash" =~ "-" ]]
then # single range case:
string="$string between days $dayBeforeSlash every $dayAfterSlash days"
else # star case:
string="$string every $dayAfterSlash days"
fi

# case: single value, list, range
else
string="$string on day(s) $word"
fi
;;

4) # MONTH:
# in case user's input was a string, translate to lowercase
word=$(echo "$word" | tr '[:upper:]' '[:lower:]' 2>/dev/null )

# case: every month
if [ $word = "o" ]
then
string="$string every month"

# case: every X months
elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
monthAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
monthBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$monthBeforeSlash" =~ "-" ]]
then # single range case:
### split before and after '-'
m1=$(echo "$monthBeforeSlash" | cut -d'-' -f 1)
m2=$(echo "$monthBeforeSlash" | cut -d'-' -f 2)
getMonth $m1 # translate first month
m1=$retval # get first monthname
getMonth $m2 # translate second month
m2=$retval # get second monthname
string="$string between months $m1 and $m2 every $monthAfterSlash months"
else # star case:
string="$string every $monthAfterSlash months"
fi

# case: if there's a range or a list
elif [[ "$word" =~ "-" || "$word" =~ "/" || "$word" =~ "," ]]
then
getMonth $word # translate all numbers to month names
monthTrans=$retval # get the translated string
string="$string in $monthTrans"

# case: if user input was a 3 letter month name
elif [[ "$word" =~ [a-z] ]]
then
# translate it to upper case for displaying
word=$(echo "$word" | tr '[:lower:]' '[:upper:]' 2>/dev/null )
string="$string in $word"

# case: single value, list, range
else
getMonth $word # translate all numeric values to month names
monthTrans=$retval # get the translated string
string="$string in month $monthTrans"
fi
;;

5) # WEEKDAY:
# in case user's input was a string, translate to lowercase
word=$(echo "$word" | tr '[:upper:]' '[:lower:]' 2>/dev/null )

# case: every weekday
if [ $word = "o" ]
then
string="$string every weekday"

elif [[ "$word" =~ "/" ]]
then
### split before and after '/'
weekdayAfterSlash=$( echo "$word" | cut -d"/" -f 2 )
weekdayBeforeSlash=$( echo "$word" | cut -d"/" -f 1 )
if [[ "$weekdayBeforeSlash" =~ "-" ]]
then # single range case:
### split before and after '-'
w1=$(echo "$weekdayBeforeSlash" | cut -d'-' -f 1)
w2=$(echo "$weekdayBeforeSlash" | cut -d'-' -f 2)
getWeekday $w1 # translate first weekday
w1=$retval # get first weekday name
getWeekday $w2 # translate second weekday
w2=$retval # get second weekday name
string="$string between weekdays $w1 and $w2 every $monthAfterSlash days"
else # star case:
string="$string every $weekdayAfterSlash days"
fi

# if there's a range or a list
elif [[ "$word" =~ "-" || "$word" =~ "/" || "$word" =~ "," ]]
then
getWeekday $word # translate all weekdays to weekday names
weekdayTrans=$retval # get the translated string
string="$string on $weekdayTrans"

# if user input was a 3 letter weekday name
elif [[ "$word" =~ [a-z] ]]
then
# translate it to upper case for displaying
word=$(echo "$word" | tr '[:lower:]' '[:upper:]' 2>/dev/null )
string="$string on $word"

# case: single value, list, range
else
getWeekday $word # translate all numeric values to weekday names
weekdayTrans=$retval # get the translated string
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

# if there are jobs:
#   displays all jobs (translated and numbered),
#   returns the number of current jobs;
# if there are no jobs:
#   displays a message saying "There are no crontab jobs",
#   returns 0 as the number of current jobs;
displayJobs () {

crontabFile=$( crontab -l 2>/dev/null ) #get the content of the crontab job file to check if it's empty
jobCount=0 # initialise jobCount to 0

# if there are no crontab jobs
if [ -z "$crontabFile" ] # check if empty
then
echo "There are no crontab jobs."

# if there are crontab jobs
else
echo "Current crontab jobs:"
crontab -l | while IFS= read -r line # loop through the crontab file
do
job="$line" # get a single line from a file (crontab job)

# if the first field is "@reboot"
check=$( echo "$job" | cut -d" " -f 1 )
if [ "$check" = "@reboot" ]
then
freq=$check
command=$( echo "$job" | cut -d" " -f 2- ) # get the command part
# if there are 5 fields for frequency
else
freq=$( echo "$job" | cut -d" " -f 1-5 ) # get just the frequency setting
command=$( echo "$job" | cut -d" " -f 6- ) # get the command part
fi

freq=$(echo "$job" | tr '*' o) # swap all asterisks to 'o' to avoid issues with the special character

translate $freq # translate the frequency string
string=$retval # get the return value from the translate method
jobCount=$(($jobCount+1)) # increment jobCount (##### TEST IF IT WORKS)
string="$jobCount. $string"
echo "$string $command"
echo
# jobCount=$(($jobCount+1)) # increment jobCount
done # while loop end
fi

return jobCount # return the number of jobs in the crontab
}

# MAIN FUNCTION:
key=0 #default key for user input

# pull crontab jobs and display menu, loop until user presses 9 to exit:
until [ $key -eq 9 2>/dev/null ]
do

#i=-1 # to create keep track of crontab jobs
#crontabList=$( crontab -l 2>/dev/null ) #get the content of the crontab file to check if it's empty
#if [ -z "$crontabList" ] # check if empty
#then
#i=0 # set job count/ID to 0
#else
## a loop to count jobs:
#while IFS= read -r line # loop through the crontab list
#do
#i=$(($i+1)) # count jobs
#done <<< "$(crontab -l)" # here string to loop through the crontab list
#fi
#echo


displayJobs # redirect output to /dev/null? so that it doesn't display the jobs and just counts them
#totalJobs=$? # get the number of current jobs from displayJobs

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
insertJob 
;;
3) # edit a job:
editJob
;;
4) # remove a job:
removeJob
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
