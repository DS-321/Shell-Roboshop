#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_folder="/var/log/roboshop.logs"
script_name=$(echo $0 | cut -d "." -f1-2)
log_file="$logs_folder/$script_name.log"
script_dir=$PWD

mkdir -p $logs_folder
echo "script started executing at: $(date)" | tee -a $log_file

Userid=$(id -u)
if [ $Userid -ne 0 ]
    then
    echo -e "$R ERROR: You are not running with root access $N" | tee -a $log_file
    exit 1
    else
    echo "You are running with root access" | tee -a $log_file
fi
validate(){

    if [ $1 -eq 0 ]
    then
            echo -e "$2 is installed ... $G Successful $N" | tee -a $log_file
            else
            echo -e "$2 not installed ... $R Failure $N" | tee -a $log_file
            exit 1
    fi        
}

dnf module disable nodejs -y &>>$log_file
validate $? "Disabling the default nodejs"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "Enabling the nodejs:20"

dnf install nodejs -y &>>$log_file
validate $? "Installing nodejs:20"

id roboshop
if [ $? -ne 0 ]

then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating Roboshop system user"
else
    echo -e "system user roboshop already created :$Y SKIPPING $N"
fi

mkdir -p /app
validate $? "Creating App directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
validate $? "dowingloading the Catalogue"

cd /app 
rm -rf /app/*
unzip /tmp/catalogue.zip &>>$log_file
validate $? "unzipping catalogue"

npm install &>>$log_file
validate $? "Installing Dependencies"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
validate $? "copying catalogue.service"

systemctl daemon-reload
systemctl enable catalogue &>>$log_file
systemctl start catalogue
validate $? "Starting Catalogue"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$log_file
validate $? "Installing Mongodb client"

STATUS=$(mongosh --host mongodb.dcloudlab.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.dcloudlab.site </app/db/master-data.js &>>$log_file
    validate $? "Loading data in to Mongodb"
else
    echo -e "Data already loaded in Mongodb: $Y SKIPPING $N"
fi