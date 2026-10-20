#!/bin/bash

user_id=(id -u)
logs_folder="var/log/roboshop"
logs_file="${logs_folder}/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#checking users sudo access
if [ $user_id -ne 0 ]; then
   echo "user $USER is not having sudo access"
   exit 1
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

#starting rabbitmq installation

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "adding rabbitmq to repo"

dnf install erlang rabbitmq-server -y &>> logs_file
validate $? "installing rabbitmq"

systemctl enable rabbitmq-server &>> logs_file
validate $? "enabiling rabbitmq"

systemctl start rabbitmq-server &>> logs_file
validate $? "start rabbitmq"

rabbitmqctl add_user roboshop roboshop123 &>> logs_file
validate $? "adding roboshop user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> logs_file
validate $? "setting permission for roboshop user"

echo "script execution endeed at $(date +"%F %T")"
