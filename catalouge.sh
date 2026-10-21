#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
domain_name="testdevops.sbs"
script_dir=$(dirname "$(realpath "$0")")

#checking user is having sudo access
if [ $user_id -ne 0 ]; then
   echo "user $USER is not having sudo access"
   exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date +"%F %T"
}

validate(){
    if [ $1 -ne 0 ]; then
       echo -e "$(timestamp) [ERROR]..$2..${R}FAILED${N}" | tee -a $logs_file
    else
       echo -e "$(timestamp) [INFO]..$2..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

echo "script execution started at $(timestamp)" | tee -a $logs_file

dnf module disable nodejs -y &>> $logs_file
validate $? "disabiling nodejs"

dnf module enable nodejs:24 -y &>> $logs_file
validate $? "enable nodejs"

dnf install nodejs -y &>> $logs_file
validate $? "installing nodejs"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "creating system user"
else
   echo -e "system user is aiready added ${Y}SKIPPING${N}"
fi

rm -rf /app &>> $logs_file
validate $? "removing files under app directory"

mkdir -p /app &>> $logs_file
validate $? "creating app directorey"

curl -L -o /tmp/catalouge.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>>logs_folder
validate $? "downloading catalouge"

cd /app
unzip /tmp/catalouge.zip &>> $logs_file
validate $? "unzipping catalouge"

npm install &>> $logs_file
validate $? "installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/catalouge.service"
cp "$script_dir/catalouge.service" /etc/systemd/system/catalouge.service

systemctl daemon-reload &>> $logs_file
validate $? "reloading demon"

systemctl enable catalouge &>> $logs_file
validate $? "enable catalouge"

systemctl start catalouge &>> $logs_file
validate $? "starting catalouge"

cp "$script_dir/mongo.repo" /etc/yum.repos.d/mongo.repo
validate $? "adding mngodb to repo"

dnf install mongodb-mongosh -y &>> $logs_file
validate $? "downloading mongodb client"

product_count=$(mongosh --host "mongodb.$domain_name" --quiet --eval 'db.getSiblingDB("catalouge").products.countDocuments()' 2>> $logs_file)
validate $? "connecting to mongodb"

if [ ${product_count} -eq 0 ]; then
   mongosh --host "mongodb.$domain_name" </app/db/master-data.js &>> $logs_file
   validate $? "Loading products"
else
   echo -e "Products already lodded ${Y}SKIPPING${N}"
fi

systemctl restart catalouge &>> $logs_file
validate $? "restarting catalouge"

echo "script execution ended at $(timestamp)" | tee -a $logs_file