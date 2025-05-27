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

validate(){

    if [ $1 -eq 0 ]
    then
            echo -e "$2 is installed ... $G Successful $N" | tee -a $log_file
            else
            echo -e "$2 not installed ... $R Failure $N" | tee -a $log_file
            exit 1
    fi        
}

dnf install python3 gcc python3-devel -y &>>$log_file
validate $? "Install Python3 packages"

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

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$log_file
validate $? "Downloading payment"

rm -rf /app/*
cd /app 
unzip /tmp/payment.zip &>>$log_file
validate $? "unzipping payment"

pip3 install -r requirements.txt &>>$log_file
validate $? "Installing dependencies"

cp $script_dir/payment.service /etc/systemd/system/payment.service &>>$log_file
validate $? "Copying payment service"

systemctl daemon-reload &>>$log_file
validate $? "Daemon Reload"

systemctl enable payment &>>$log_file
validate $? "Enable payment"

systemctl start payment &>>$log_file
validate $? "Starting payment"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $log_file