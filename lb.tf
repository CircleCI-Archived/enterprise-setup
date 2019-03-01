#
# Configure an ELB in the public subnet
#
resource "aws_lb" "lb" {
  name            = "${var.prefix}-circle-lb"
  internal        = false
  security_groups = ["${aws_security_group.lb_ingress.id}"]
  subnets         = ["${var.aws_elb_subnets}"]

  #access_logs {
  #  bucket  = "${module.aws_logs.aws_logs_bucket}"
  #  prefix  = "${var.prefix}-circle"
  #  enabled = true
  #}
}

#
# Setup HTTPS :443 listener with acm created certificate
#
resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-west-2:027086599304:certificate/2c9be172-3edc-4919-adf1-39cce85deca9"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.https.arn}"
  }
}

#
# Setup HTTPS :8800 listener with acm created certificate for admin page
#
resource "aws_lb_listener" "https8800" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "8800"
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-west-2:027086599304:certificate/2c9be172-3edc-4919-adf1-39cce85deca9"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.https8800.arn}"
  }
}

#
# Configure HTTP :80 listener
#
resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.http.arn}"
  }
}

resource "aws_lb_target_group" "https" {
  name     = "${var.prefix}-lb-443"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${var.aws_vpc_id}"
}

resource "aws_lb_target_group" "https8800" {
  name     = "${var.prefix}-lb-8800"
  port     = 8800
  protocol = "HTTPS"
  vpc_id   = "${var.aws_vpc_id}"
}

resource "aws_lb_target_group" "http" {
  name     = "${var.prefix}-lb-80"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.aws_vpc_id}"
}

resource "aws_lb_target_group_attachment" "https" {
  target_group_arn = "${aws_lb_target_group.https.arn}"
  target_id        = "${aws_instance.services.id}"
  port             = 443
}

resource "aws_lb_target_group_attachment" "https8800" {
  target_group_arn = "${aws_lb_target_group.https8800.arn}"
  target_id        = "${aws_instance.services.id}"
  port             = 8800
}

resource "aws_lb_target_group_attachment" "http" {
  target_group_arn = "${aws_lb_target_group.http.arn}"
  target_id        = "${aws_instance.services.id}"
  port             = 80
}

#
# All all inbound to 80 and 443
#
resource "aws_security_group" "lb_ingress" {
  name   = "${var.prefix}-lb-ingress"
  vpc_id = "${var.aws_vpc_id}"

  # For Web traffic to services
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 8800
    to_port     = 8800
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = ["${aws_security_group.circleci_users_sg.id}"]
  }
}

#
# Use existing truss module for Log bucket setup
#
#module "aws_logs" {
#  source         = "trussworks/logs/aws"
#  s3_bucket_name = "aws-cms-oit-iusg-draas-circleci-sbx-elb"
#  region         = "us-west-2"
#  default_allow  = false
#  allow_elb      = true
#}

