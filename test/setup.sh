#!/bin/bash

echo "#!/usr/bin/env bats"

for i in $(cat /tmp/amilist.txt);
do
  REGION=$(echo $i | cut -d "=" -f 1)
  AMI_ID=$(echo $i | cut -d "=" -f 2)

  cat << EOF
  @test "\$REGION" {
    printf "Validating \$AMI_ID located in \$REGION..."

    aws --region $REGION ec2 describe-images --filters "Name=image-id,Values=\$AMI_ID" | jq '.Images[] | length'
  }
EOF

done
