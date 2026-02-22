#!/bin/bash



USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST=mongodb.daws88s.sbs
SCRIPT_DIR=$(pwd)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MYSQL_HOST=mysql.daws88s.sbs
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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
id roboshop
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "system user "
else
    echo -e "user already exist... $Y skippinggg $N"
fi

mkdir -p /app 
VALIDATE $? "app directory "

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "dowloading payment applications "

cd /app 
VALIDATE $? "changing to app dir" 

rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip payment "


pip3 install -r requirements.txt

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "copy sys services "

systemctl daemon-reload &>>$LOG_FILE

systemctl enable payment  &>>$LOG_FILE
systemctl restart payment  &>>$LOG_FILE