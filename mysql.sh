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
SCRIPT_DIR=$PWD

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

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

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

dnf install mysql-server -y &>>LOG_FILE
VALIDATE $? "Installing MySQL server"

systemctl enable mysqld &>>LOG_FILE
systemctl start mysqld &>>LOG_FILE
VALIDATE $? "Starting MySQL"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD &>>$LOG_FILE
VALIDATE $? "Setting MySQL root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE