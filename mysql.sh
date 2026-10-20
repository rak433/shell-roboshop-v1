#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshoop"
logs_file="${logs_folder}/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#checking user sudo access
if [ $user_id -ne 0 ]; then
   echo "user $USER is not having sudo access"
   exit 1
fi

mkdir -p "$logs_folder"

validate(){
    if [ $1 -ne 0 ]; then
       echo -e "$2..${R}FAILED${N}" | tee -a $logs_file
    else
       echo -e "$2..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

echo "script execution started at $(date +"%F %T")"

#installing mysql

dnf module enable mysql:8.4 -y &>> $logs_file
validate $? "enabiling mysql"

dnf install mysql-server -y &>> $logs_file
validate $? "installing mysql-server"

systemctl enable mysqld &>> $logs_file
validate $? "enable mysqld"

systemctl start mysqld &>> $logs_file
validate $? "starting mysqld"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $logs_file
validate $? "setup mysql root password"

echo "script execution endded at $(date +"%F %T")"