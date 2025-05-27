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
read -s RABBITMQ_PASSWD

validate(){

    if [ $1 -eq 0 ]
    then
            echo -e "$2 is installed ... $G Successful $N" | tee -a $log_file
            else
            echo -e "$2 not installed ... $R Failure $N" | tee -a $log_file
            exit 1
    fi        
}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "Adding rabbitmq repo"

dnf install rabbitmq-server -y &>>$log_file
validate $? "Installing rabbitmq server"

systemctl enable rabbitmq-server &>>$log_file
validate $? "Enabling rabbitmq server"

systemctl start rabbitmq-server &>>$log_file
validate $? "Starting rabbitmq server"

rabbitmqctl add_user roboshop $RABBITMQ_PASSWD &>>$log_file
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$log_file

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $log_file