#!/bin/bash

user_id=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
logs_folder="/var/log/roboshop"
log_file="${log_folder}/$0"

#checking user is having sudo access
if [ $user_id -ne 0 ]; then
   echo "user $USER is not having sudo access"
   exit 1
fi

mkdir -p $logs_folder

echo "script started execution at $(date +"%F %T") | tee -a $log_file

validate(){
    if [ $1 -ne 0 ]; then
       echo -e "$2..${R}FAILED${N}" | tee -a $log_file
       exit 1
    else
       echo -e "$2..${G}SUCCESS${N}" | tee -a $log_file
    fi
}

#starting mongodb installation

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "adding mongo to repo"

dnf install mongodb-org -y &>> $log_file
validate $? "installing mongodb"

systemctl enable mongod &>> $log_file
validate $? "enabiling mongodb"

systemctl start mongod &>> $log_file
validate $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "updating remote connections to mongodb"

systemctl restart mongod &>> $log_file
validate $? "restarting mongodb"

echo "script ended at $(date +"%F %T") | tee -a $log_file