#!/bin/bash

echo "#!/usr/bin/env bats"

cat << EOF
verify_ami () {
  aws --region \$1 ec2 describe-images --filters "Name=image-id,Values=\$2" | jq '.Images[] | length'
}
EOF

for i in $(cat /tmp/amilist.txt);
do
  REGION=$(echo $i | cut -d "=" -f 1)
  AMI_ID=$(echo $i | cut -d "=" -f 2)

  cat << EOF
  @test "$REGION" {
    run verify_ami $REGION $AMI_ID
    [ "\$output" > 0 ]
  }
EOF

done
