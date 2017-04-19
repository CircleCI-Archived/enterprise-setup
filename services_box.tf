resource "aws_instance" "services" {
    # Instance type - any of the c4 should do for now
    instance_type = "${var.services_instance_type}"

    ami = "${lookup(var.base_services_image, var.aws_region)}"

    key_name = "${var.aws_ssh_key_name}"

    subnet_id = "${var.aws_subnet_id}"
    associate_public_ip_address = true
    vpc_security_group_ids = [
        "${aws_security_group.circleci_services_sg.id}",
        "${aws_security_group.circleci_users_sg.id}"
    ]

    iam_instance_profile = "${aws_iam_instance_profile.circleci_profile.name}"
    tags {
        Name = "${var.prefix}_services"
    }


    root_block_device {
        volume_type = "gp2"
	volume_size = "150"
	delete_on_termination = false
    }

    user_data = <<EOF
#!/bin/bash

replicated -version || curl https://s3.amazonaws.com/circleci-enterprise/init-services.sh | bash

config_dir=/var/lib/replicated/circle-config
mkdir -p $config_dir
echo '${var.circle_secret_passphrase}' > $config_dir/circle_secret_passphrase
echo '${aws_sqs_queue.shutdown_queue.id}' > $config_dir/sqs_queue_url
echo '${aws_s3_bucket.circleci_bucket.id}' > $config_dir/s3_bucket

EOF

    lifecycle {
        prevent_destroy = true
    }

}