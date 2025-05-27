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

dnf module disable nodejs -y &>>$log_file
validate $? "Disabling the default nodejs"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "Enabling the nodejs:20"

dnf install nodejs -y &>>$log_file
validate $? "Installing nodejs:20"

id roboshop &>>$log_file
if [ $? -ne 0 ]

then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Creating Roboshop system user"
else
    echo -e "system user roboshop already created :$Y SKIPPING $N"
fi

mkdir -p /app
validate $? "Creating App directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$log_file
validate $? "downloading the user"

cd /app 
rm -rf /app/*
unzip /tmp/user.zip &>>$log_file
validate $? "unzipping user"

npm install &>>$log_file
validate $? "Installing Dependencies"

cp $script_dir/user.service /etc/systemd/system/user.service
validate $? "copying user.service"

systemctl daemon-reload
systemctl enable user &>>$log_file
systemctl start user
validate $? "Starting user"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $log_file