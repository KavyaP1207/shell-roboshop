#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-063ff765de26714d5"   
ZONE_ID="Z012055134XPX8JBK0O0E"
DOMAIN_NAME="daws88s.sbs"
for instance in $@
do 
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

#get private ip
if [ $instance != "frontend" ]; then
   IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
   RECORD_NAME="$instance.$DOMAIN_NAME"  #mongodb.daws88s.sbs
else
   IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
   RECORD_NAME="$DOMAIN_NAME"  #daws88s.sbs
fi
   
echo "$instance : $IP"

  aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
{
  "Comment": "Update DNS record"
  ,"Changes": [{
    "Action": "UPSERT"
    ,"ResourceRecordSet":  {
      "Name": "'$RECORD_NAME'",
      "Type": "A",
      "TTL": 1,
      "ResourceRecords": [
        {
          "Value": "'$IP'"
        }
      ]
    }
  }]
}'


done 
