#!/bin/bash



USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST=mongodb.daws88s.sbs

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privilege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ #functions receive inputs through args just like shell script args
   if [ $1 -ne 0 ]; then
   echo -e " $2 ... $R FAILURE $N" | tee -a $LOG_FILE
   exit 1
   else
    echo -e " $2 ... $G SUCCESS $N" | tee -a $LOG_FILE
   fi 
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling node js"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling node js "

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "INSTALLING NODE JS"
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "system user "
else
    echo -e "user already exist... $Y skippinggg $N"
fi

mkdir -p /app 
VALIDATE $? "app directory "

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "dowloading catalogue applications "

cd /app 
VALIDATE $? "changing to app dir"

rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue "

npm install &>>$LOG_FILE
VALIDATE $? "install dependies"


cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copy sys services "

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enabling catalogue" 


cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy mongo repo"


dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "install mongodb client "

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "load catalogue products "

systemctl restart catalogue
VALIDATE $? "restarted catalogue"