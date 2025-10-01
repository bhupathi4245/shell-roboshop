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

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>LOG_FILE
VALIDATE $? "installing python3 development"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user roboshop"
else
    echo -e "system user roboshot already created... $Y SKIPPING $N" 
fi

mkdir -p /app
VALIDATE $? "creating app folder"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading payment package"

rm -rf /app/*
cd /app
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzipping payment pkg"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "install pip3 dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "copying payment service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reload daemon"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "enable payment service"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "starting payment service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE