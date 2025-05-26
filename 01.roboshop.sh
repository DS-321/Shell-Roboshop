#!/bin/bash

AMI_ID=ami-09c813fb71547fc4f
SG_ID=sg-063265bfaadd1ddd9
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shippig" "payment" "dspatch" "frontend")
ZONE_ID=Z104650557V08CNWBHYW
DOMAIN_NAME="dcloudlab.site"

for instance in ${INSTANCES[@]}

do

    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-063265bfaadd1ddd9 --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=MyEC2Instance}]" --query "Instances[0].InstanceID" --output text)

    if [ $instance != "frontend" ]

    then
        IP=aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text
    else
        IP=aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    fi
    echo "$instance IP address: $IP"
done