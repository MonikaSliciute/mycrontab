#!/bin/sh

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
until [ $option -eq 1 -o $option -eq 2 2>/dev/null ]
do
read -p "Choose one of the above options: " option
if [ $option -eq 1 ]
then
preset_insert # $i don't need the id there
elif [ $option -eq 2 ]
then
custom_insert  # $i don't need the id there
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
until [ "$answer" = "$yes" -o "$answer" = "$no" 2>/dev/null ]
do
read -p "Create the above job? (y/n):" answer
if [ "$answer" = "$yes" ]
then
crontab -l | { cat; echo "$command #$id"; } | crontab -
id=$(($id+1)) # increment id
elif [ "$answer" = "$no" ]
then
echo "Job not inserted."
else
echo "Invalid input"
fi
done
retval=$id
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
string=""
case $input in
1)
insertTime="0 * * * *" 
string="At the beginning of every hour, run the following command:"
;;
2)
insertTime="0 0 * * *"
string="At the beginning of every day, run the following command:"
;;
3)
insertTime="0 0 * * 0"
string="At the beginning of every week(Sunday), run the following command:"
;;
4)
insertTime="0 0 1 * *"
string="At the beginning of every month, run the following command:"
;;
5)
insertTime="0 0 1 1 *"
string="At the beginning of every year, run the following command:"
;;
6)
insertTime="@reboot"
string="At every reboot, run the following command:"
;;
*)
echo "Invalid input. Choose an option between 1-6."
;;
esac
done
retval=$insertTime # return frequency e.g. 0 * * * * *
}

#crontab guide ##### should probs delete
view_guide () {
echo "Guide to job's frequency:"
echo "Order of time values: minute hour day-of-month month day-of-week"
echo "Valid values:"
echo " - minute: 0-59"
echo " - hour: 0-23"
echo " - day of month: 1-31"
echo " - month: 1-12"
echo " - day of week: 0-7 (0 or 7 is Sunday)"
echo " - or an asterisk (*) which stands for first-last "
echo "Example: 0 9 * * * - repeat the job at 9am every day"
}

#insert a job with custom settings:
custom_insert () {
frequency=""

echo "When would you like the job to occur? Type * for every."
echo

bool=0
until [ $bool -eq 1 ]
do
read -p "Enter minutes (0-59): " min
if [ $min -ge 0 -a $min -le 59 2>/dev/null ]  #check if min is a number and valid
then
frequency="$min"
bool=1 # exit loop
elif [ "$min" = "*" ]
then
frequency="o"
bool=1 # exit loop
else
echo "Invalid input, try again."
fi
done

bool=0
until [ $bool -eq 1 ]
do
read -p "Enter hour (0-23): " hour
if [ $hour -ge 0 -a $hour -le 23 2>/dev/null ] # check if hour is a number and valid
then
frequency="$frequency $hour"
bool=1
elif [ "$hour" = "*" ]
then
frequency="$frequency o"
bool=1
else
echo "Invalid input, try again."
fi
done


bool=0
until [ $bool -eq 1 ]
do
read -p "Enter day of the month (1-31): " day
if [ $day -ge 1 -a $day -le 31 2>/dev/null ]
then
frequency="$frequency $day"
bool=1
elif [ "$day" = "*" ]
then
frequency="$frequency o"
bool=1
else
echo "Invalid input, try again."
fi
done

bool=0
until [ $bool -eq 1 ]
do
read -p "Enter month (1-12): " month
if [ $month -ge 1 -a $month -le 12 2>/dev/null ]
then
frequency="$frequency $month"
bool=1
elif [ "$month" = "*" ]
then
frequency="$frequency o"
bool=1
else
echo "Invalid input, try again."
fi
done

bool=0
until [ $bool -eq 1 ]
do
read -p "Enter weekday (0-7 note: 0 and 7 is Sunday): " weekday
if [ $weekday -ge 0 -a $weekday -le 7 2>/dev/null ]
then
frequency="$frequency $weekday"
bool=1
elif [ "$weekday" = "*" ]
then
frequency="$frequency o"
bool=1
else
echo "Invalid input, try again."
fi
done

frequency=$(echo "$frequency" | tr o '*' )
retval=$frequency # return frequency e.g. 1 2 3 * *
}

#edit a job:
edit () {

read -p "Enter job's number: " number #ask user to give you a job number
crontab -l | grep -v "#$number" | crontab - # delete job
insert $number
crontab -l | sort -t '#' -k 2 | crontab -
echo
echo "Job successfully edited."
echo
}

#remove a job:
remove () {

read -p "Enter job's number: " number
crontab -l | grep -v "#$number" | crontab -
echo 
echo "Job successfully removed"
#### leaves a gap in the id numbers e.g. if we remove a job in the middle of the job list e.g. job 3, the job list is now 1 2 4 5..
#### id increments when adding new jobs after deleting the last job e.g. total jobs = 7, remove job 7, total jobs = 6, next job = 8
echo
}

translate () {
string=""
# cases for presets
freq_o="$1 $2 $3 $4 $5"    # add special cases e.g. @reboot

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

# custom
if [ "$string" = "" ]
then
# custom translate

count=1 # to count words in frequency string

for word in $freq_o # loop through each word in freqency string
do

case $count in
1)
if [ $word = "o" ] # if it used to be an asterisk
then
string="At every minute"
else
string="At minute $word"
fi
;;
2)
if [ $word = "o" ]
then
string="$string every hour"
else
string="$string past hour $word"
fi
;;
3)
if [ $word = "o" ]
then
string="$string on every day"
else
string="$string on day $word"
fi
;;
4)
if [ $word = "o" ]
then
string="$string every month"
else
getMonth $month # call get month and pass month(int)
mthname=$retval # get the return value
string="$string in month $mthname"
fi
;;
5)
if [ $word = "o" ]
then
string="$string every weekday"
else
getWeekday $weekday # call getWeekday with weekday(int)
weekname=$retval # get the return value: weekday(string)
string="$string on $weekname"
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

echo "$(crontab -l)" > jobList.txt # create a temporary file to store jobs

while IFS= read -r line # loop through the temp file
do

job="$line" # get a single line from a file (crontab job)
freq=$( echo "$job" | cut -d" " -f 1-5 ) # get just the frequency setting
command=$( echo "$job" | cut -d" " -f 6- ) # get the command part
id=$( echo "$job" | cut -d"#" -f 2 ) # get the job id number
command=$( echo "$command" | cut -d"#" -f 1 ) # get rid of the id comment
freq=$(echo "$job" | tr '*' o) # swap all asterisks to 'o' to avoid issues with the special character

string="" # to save the translation
count=1 # to count words in frequency string

for word in $freq # loop through each word in freqency string
do

case $count in
1)
if [ $word = "o" ] # if it used to be an asterisk
then
string="At every minute"
else
string="At minute $word"
fi
;;
2)
if [ $word = "o" ]
then
string="$string every hour"
else
string="$string past hour $word"
fi
;;
3)
if [ $word = "o" ]
then
string="$string on every day"
else
string="$string on day $word"
fi
;;
4)
if [ $word = "o" ]
then
string="$string in every month"
else
string="$string in $word"
fi
;;
5)
if [ $word = "o" ]
then
string="$string every week day"
else
string="$string on day: $word"
fi
;;
*)
;;
esac

count=$(($count+1)) # increment count 
done # foreach loop end

string="$id. $string, run the following command: "
echo "$string $command"
echo
done < jobList.txt # while loop end

rm jobList.txt # remove the temporary file
}

# MAIN:
i=1 # to identify jobs
# get the last id number and increment it:
i=$(crontab -l | sort -t '#' -k 2 | tail -n 1 | cut -d"#" -f 2 )
i=$(($i+1))

key=0 #default key for user input

# loop until user presses 9 to exit:
until [ $key -eq 9 2>/dev/null ]
do
echo 
menu #display menu
echo
read -p "Choose an option: " key
echo "Option chosen: $key"
echo
#cases:
case $key in
1)
echo "Current crontab jobs:"
displayJobs
;;
2)
echo "Inserting a job:"
insert $i # pass new job id
i=$retval
;;
3)
echo "Editing a job:"
displayJobs
edit
;;
4)
echo "Removing a job:"
displayJobs
remove
;;
5)
echo "All jobs were removed."
crontab -r
i=1 # reset the id to 1 again
;;
9)
echo "Exit"
;;
*)
echo "Sorry, invalid input"
;;
esac
done
