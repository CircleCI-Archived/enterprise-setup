#!/bin/bash

for i in $(cat /tmp/amilist.txt);
do
  REGION=$(echo $i | cut -d "=" -f 1)
  AMI_ID=$(echo $i | cut -d "=" -f 2)

  printf "Validating $AMI_ID located in $REGION..."

  AWS_RESULT=$(aws --region $REGION  ec2 describe-images --filters "Name=image-id,Values=$AMI_ID" | jq '.Images[] | length')

  if [ $AWS_RESULT -gt 0 ]; then
    printf " PASSED\n"
  fi

done