#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_folder="/var/log/shellscript.logs"
script_name=$(echo $0 | cut -d "." -f1-2)
log_file="$logs_folder/$script_name.log"
package=("mysql" "python3" "nginx")
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

dnf module disable nginx -y &>>$log_file
validate $? "Disabling default nginx"

dnf module enable nginx:1.24 -y &>>$log_file
validate $? "Enabling nginx:1.24"

dnf install nginx -y &>>$log_file
validate $? "Installing nginx:1.24"

systemctl enable nginx 
systemctl start nginx 
validate $? "Starting nginx"

rm -rf /usr/share/nginx/html/* 
validate $? "Remove the default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$log_file
validate $? "installing the frontend"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$log_file
validate $? "Unzipping the frontend"

rm -rf /etc/nginx/nginx.conf &>>$log_file
validate $? "remove deafult nginx.conf"

cp $script_dir/nginx.conf /etc/nginx/nginx.conf 
validate $? "copying nginx.conf"

systemctl restart nginx 
validate $? "restarting nginx"
