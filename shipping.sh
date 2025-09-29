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
if[$USERID -ne 0]
then
	echo -e "$R ERROR:: Please run this script with root access $N" |tee -a $LOG_FILE
	exit 1 # error..give any number from 1 to 127.... 0 is reserved for the success
else
	echo "You are running with root access" | tee -a $LOG_FILE
fi

echo "please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

# validate functions takes input as exit status, what command been used to install
VALIDATE(){
if [$1 -eq 0]
then
	echo -e "$2 is ... $G SUCCESS $N" |tee -a $LOG_FILE
else
	echo -e "$2 is ... $G FAILURE $N" |tee -a $LOG_FILE
	exit 1
fi
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing maven and java"

id roboshop
if [ $? -ne 0 ]
then
	useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
	VALIDATE $? "creating system user roboshop "
else
	echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip
VALIDATE $? "unzippping shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "moving and renaming the jar file"

cp $SCRIPT_DIR/shipping.services /etc/systemd/system/shipping.service

systemctl deamon-reload &>>$LOG_FILE
VALIDATE $? "deamon reload"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "enabling shipping services"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "starting shipping services"

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Install MySQL"

mysql -h mysql.daws84s.site -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restart shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE