#!/bin/bash
START_TIME=$(date +%s)
Userid=$(id -u)
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

if [ $Userid -ne 0 ]
    then
    echo -e "$R ERROR: You are not running with root access $N" | tee -a $log_file
    exit 1
    else
    echo "You are running with root access" | tee -a $log_file
fi

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

validate(){

    if [ $1 -eq 0 ]
    then
            echo -e "$2 is installed ... $G Successful $N" | tee -a $log_file
            else
            echo -e "$2 not installed ... $R Failure $N" | tee -a $log_file
            exit 1
    fi        
}

dnf install maven -y &>>$log_file
validate $? "Installing Maven and Java"

id roboshop &>>$log_file
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app 
validate $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file
validate $? "Downloading shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$log_file
validate $? "unzipping shipping"

mvn clean package  &>>$log_file
validate $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar  &>>$log_file
validate $? "Moving and renaming Jar file"

cp $script_dir/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$log_file
validate $? "Daemon Realod"

systemctl enable shipping  &>>$log_file
validate $? "Enabling Shipping"

systemctl start shipping &>>$log_file
validate $? "Starting Shipping"

dnf install mysql -y  &>>$log_file
validate $? "Install MySQL"

mysql -h mysql.dcloudlab.site -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$log_file
if [ $? -ne 0 ]
then
    mysql -h mysql.dcloudlab.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$log_file
    mysql -h mysql.dcloudlab.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  &>>$log_file
    mysql -h mysql.dcloudlab.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$log_file
    validate $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$log_file
validate $? "Restart shipping"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $log_file