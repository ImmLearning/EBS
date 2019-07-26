#!/bin/bash

# Memory metrics calculation

TM=`grep MemTotal /proc/meminfo | awk '{ print $2 }'`

AM=`grep MemFree /proc/meminfo | awk '{ print $2 }'`

MAP=`expr $AM \* 100 \/ $TM `

MemUtil=`expr 100 - $MAP `

ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`

REGION=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`

IN=`aws ec2 describe-instances --region $REGION --instance-id $ID --query "Reservations[].Instances[].Tags[*]" --output text | grep Name | awk '{ print $NF }'`

# Change the namespace parameter

aws cloudwatch put-metric-data --metric-name MemoryUtilization --namespace "CustomMetrics" --dimensions "InstanceId=$ID" --value $MemUtil --unit Percent --region $REGION

for line in `df -h | grep "%" | egrep -v "tmpfs|Mounted" | awk '{ print $(NF -1) "," $NF  }' | sed 's/%//g'`

        do

                #echo $line

                mountpoint=`echo $line | awk -F "," '{ print $NF }'`

                utilization=`echo $line | awk -F "," '{ print $1 }'`

                #echo "Montpint is " $mountpoint

                #echo "Utilization is " $utilization

aws cloudwatch put-metric-data --metric-name DiskUtilization --namespace "CustomMetrics" --dimensions "InstanceId=$ID,MountPoint=$mountpoint" --value $utilization --unit Percent --region $REGION

done
