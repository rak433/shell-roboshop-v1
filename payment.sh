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

#Installing payment

dnf install python3.14 python3.14-pip -y &>> $logs_file
validate $? "installing python 3.14"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
   validate $? "creating system user"
else
   echo -e "$(timestamp) [INFO] user is already added...${Y}SKIPPING${N}"
fi

rm -rf /app
validate $? "removing old code"

mkdir -p /app
validate $? "creating app directorey"

curl -L -o /tmp/payment.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/payment-v4.zip &>> $logs_file
validate $? "downloading payment code"

cd /app
unzip /tmp/payment.zip &>> $logs_file
validate $? "unzipping the payment code"

python3.14 -m venv /app/.venv &>> $logs_file
validate $? "creating virtual environment"

/app/.venv/bin/pip install -r requirements.txt &>> $logs_file
validate $? "isnatlling dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/payment.service"
cp "$script_dir/payment.service" /etc/systemd/system/payment.service

systemctl daemon-reload &>> $logs_file
validate $? "reload daemon"

systemctl enable payment &>> $logs_file
validate $? "enable payment"

systemctl start payment &>> $logs_file
validate $? "start payment"

echo "script execution started completed $(timestamp)" | tee -a $logs_file
