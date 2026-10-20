#/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop/"
logs_file="${logs_folder}/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#checking user is having sudo access
if [ $user_id -ne 0 ]; then
   echo "user $USER is not having sudo sccess"
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

#starting redis installation

dnf module disable redis -y &>> $logs_file
validate $? "disabling redis"

dnf module enable redis:7 -y &>> $logs_file
validate $? "enable redis"

dnf install redis -y &>> $logs_file
validate $? "installing redis"

sed -i -e 's/^bind 127.0.0.1/bind 0.0.0.0/' -e 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
validate $? "Allowing remote connections to redis"

systemctl enable redis &>> $logs_file
validate $? "enable redis"

systemctl start redis &>> $logs_file
validate $? "start redis"

echo "script execution ended at $(date +"%F %T")"