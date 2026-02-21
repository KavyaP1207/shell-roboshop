#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-063ff765de26714d5"   

for instance in "$@"
do 
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type t3.micro --security-group-ids sg-063ff765de26714d5 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

#get private ip
if [ $instance != "frontend" ]; then
   IP=$(aws ec2 describe-instances --instance-ids i-03a4820c9b722b1de --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
else
   IP=$(aws ec2 describe-instances --instance-ids i-03a4820c9b722b1de --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
fi
   
echo "$instance : $IP"
done 
