#------------------------------------
# Security Groups for Services Box
#------------------------------------

resource "aws_security_group" "circleci_builders_sg" {
    name = "${var.prefix}_builders_sg"
    description = "SG for CircleCI Builder instances"

    vpc_id = "${var.aws_vpc_id}"
    ingress {
        self = true
        from_port = 0
        to_port = 0
        protocol = "-1"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "circleci_services_sg" {
    name = "${var.prefix}_services_sg"
    description = "SG for CircleCI services/database instances"

    vpc_id = "${var.aws_vpc_id}"
    ingress {
        security_groups = ["${aws_security_group.circleci_builders_sg.id}"]
        protocol = "-1"
        from_port = 0
        to_port = 0
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # If using github.com (not GitHub Enterprise) whitelist GitHub cidr block
    # https://help.github.com/articles/what-ip-addresses-does-github-use-that-i-should-whitelist/
    #
    #ingress {
    #    security_groups = ["192.30.252.0/22"]
    #    protocol = "tcp"
    #    from_protocol = 443
    #    to_protocol = 443
    #}
    #ingress {
    #    security_groups = ["192.30.252.0/22"]
    #    protocol = "tcp"
    #    from_protocol = 80
    #    to_protocol = 80
    #}
}

#------------------------------------
# Security Groups for Builders
#------------------------------------

resource "aws_security_group" "circleci_builders_admin_sg" {
    name = "${var.prefix}_builders_admin_sg"
    description = "SG for services to masters communication - avoids circular dependency"

    vpc_id = "${var.aws_vpc_id}"
    ingress {
        security_groups = ["${aws_security_group.circleci_services_sg.id}"]
        protocol = "tcp"
        from_port = 443
        to_port = 443
    }
}


#------------------------------------
# Security Groups for Users
#-------------------------------------
# This should be configured by admins to restrict access to machines
# TODO: Make this more extensible
#------------------------------------
resource "aws_security_group" "circleci_users_sg" {
    name = "${var.prefix}_users_sg"
    description = "SG representing users of CircleCI Enterprise"

    vpc_id = "${var.aws_vpc_id}"
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 22
        to_port = 22
    }
    # For Web traffic to services
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 80
        to_port = 80
    }
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 443
        to_port = 443
    }
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 8800
        to_port = 8800
    }
    # For SSH traffic to builder boxes
    # TODO: Update once services box has ngrok
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 64535
        to_port = 65535
    }
}