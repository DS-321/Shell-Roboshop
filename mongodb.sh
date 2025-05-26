#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_folder="/var/log/shellscript.logs"
script_name=$(echo $0 | cut -d "." -f1-2)
log_file="$logs_folder/$script_name.log"
package=("mysql" "python3" "nginx")

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

cp mongo.repo /etc/yum.repos.d/mongodb.repo
VALIDATE $? "Copying MongoDB repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB"