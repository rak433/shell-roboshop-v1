#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#checking user is having sudo access
if [ $user_id -ne 0 ]; then
   echo "user $USER is not having sudo access"
fi

mkdir -p $logs_folder

validate(){
    if [ $1 -ne 0 ]; then
       echo -e "$2..${R}FAILED${N}" | tee -a $logs_file
    else
       echo -e "$2..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

echo "script execution started at $(date +"%F %T")"

#installing mongodb

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "creating repo for mongodb"

dnf install mongodb-org -y &>> $logs_file
validate $? "installing mongodb"

systemctl enable mongod &>> $logs_file
validate $? "enable mongodb"

systemctl start mongod &>> $logs_file
validate $? "start mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "updating remote connections to mongodb"

systemctl restart mongod &>> $logs_file
validate $? "restarting mongodb"

echo "script execution ended at $(date +"%F %T")"