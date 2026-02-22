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

dnf install maven -y &>>$LOG_FILE

if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "system user "
else
    echo -e "user already exist... $Y skippinggg $N"
fi

mkdir -p /app 
VALIDATE $? "app directory "

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "dowloading shipping applications "

cd /app 
VALIDATE $? "changing to app dir"


mvn clean package &>>$LOG_FILE
mv $SCRIPT_DIR/target/shipping-1.0.jar shipping.jar 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE

systemctl enable shipping  &>>$LOG_FILE


dnf install mysql -y 
VALIDATE $? "installed mysql"
mysql -h mysql.daws88s.sbs -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "shipping data already loaded $Y skipping $N"

systemctl restart shipping