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

#Installing Java
dnf module enable maven:3.9 -y &>> $logs_file
validate $? "enable maven 3.9"

dnf install maven java-25-openjdk-devel -y &>> $logs_file
validate $? "install java 25"

alternatives --set java "/usr/lib/jvm/java-25-openjdk/bin/java"
validate $? "Setting Java 25 as default Java version"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "Setting JAVA_HOME for maven"

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

curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>> $logs_file
validate $? "downloading shipping code"

cd /app
unzip /tmp/shipping.zip &>> $logs_file
validate $? "unzipping the shippment code"

mvn clean package &>> $logs_file
validate $? "installing dependencies"

mv target/shipping.jar shipping.jar
validate $? "moving shipping.jar file"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/shipping.service"
cp "$script_dir/shipping.service" /etc/systemd/system/shipping.service

dnf install mysql -y &>> $logs_file
validate $? "installing mysql client"

count=$(mysql -h "mysql.$domain_name" -u root -pRoboShop@1 -N -B -e "SELECT COUNT(*) FROM cities.cities;" 2>> $logs_file )
if [ -z "$count" ] || [ "$count" -ne 0 ]; then
   mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/master-data.sql
   validate $? "Loading shipping data"
else
   echo -e "$(timestamp) [INFO] Master data already loaded...${Y}SKIPPING${N}"
fi

mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/app-user.sql
validate $? "Creating APP user"

systemctl daemon-reload &>> $logs_file
validate $? "reloading daemon"

systemctl enable shipping &>> $logs_file
validate $? "enable shipping"

systemctl restart shipping &>> $logs_file
validate $? "restart shipping"

echo "$(timestamp) [INFO]=====Script execution completed=====" | tee -a $logs_file

