#!/bin/bash

START_TIME=$(date +%s)	# Time in seconds... to capture total executed by this activitiy/shell
USERID=$(id -u)	# This is to check if the user logged in running this shell as root user or not
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"	# to set log folder for the application log to capture the logs from the execution
SCRIPT_NAME=$(echo $0 |cut -d "." -f1)	#
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at:$(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
	echo -e "$R ERROR:: Please run this script with root access $N" |tee -a $LOG_FILE
	exit 1 # error..give any number from 1 to 127.... 0 is reserved for the success
else
	echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command been used to install
VALIDATE(){
	if [ $1 -eq 0 ]
	then
		echo -e "$2 is ... $G SUCCESS $N" |tee -a $LOG_FILE
	else
		echo -e "$2 is ... $G FAILURE $N" |tee -a $LOG_FILE
		exit 1
	fi
}

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling default Redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling Redis:7 as default"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Edited redis.conf to accept remote connections"

systemctl enable redis
VALIDATE $? "Enabling Redis service"

systemctl start redis
VALIDATE $? "Starting Redis service"

END_TIME=$(dat +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME)) # Time taken to execute in seconds

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE