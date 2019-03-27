#
# Configure an ELB in the public subnet
#
resource "aws_lb" "lb" {
  name            = "${local.prefix}-circle-lb"
  internal        = false
  security_groups = ["${aws_security_group.lb_ingress.id}"]
  subnets         = ["${module.network.public_subnet_ids}"]
  tags            = "${module.tags.application_tags}"

  #access_logs {
  #  bucket  = "${module.aws_logs.aws_logs_bucket}"
  #  prefix  = "${local.prefix}-circle"
  #  enabled = true
  #}
}

#
# Setup an ACM certificate for this environment
#
resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.fqdn}"
  validation_method = "DNS"
  tags              = "${module.tags.application_tags}"

  lifecycle {
    create_before_destroy = true
  }
}

#
# Setup HTTPS :443 listener with acm created certificate
#
resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${aws_acm_certificate.cert.arn}"

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
  certificate_arn   = "${aws_acm_certificate.cert.arn}"

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
  name     = "${local.prefix}-lb-443"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${module.network.vpc_id}"
  tags     = "${module.tags.application_tags}"
}

resource "aws_lb_target_group" "https8800" {
  name     = "${local.prefix}-lb-8800"
  port     = 8800
  protocol = "HTTPS"
  vpc_id   = "${module.network.vpc_id}"
  tags     = "${module.tags.application_tags}"
}

resource "aws_lb_target_group" "http" {
  name     = "${local.prefix}-lb-80"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${module.network.vpc_id}"
  tags     = "${module.tags.application_tags}"
}

resource "aws_lb_target_group_attachment" "https" {
  target_group_arn = "${aws_lb_target_group.https.arn}"
  target_id        = "${module.circleci.aws_instance_id}"
  port             = 443
}

resource "aws_lb_target_group_attachment" "https8800" {
  target_group_arn = "${aws_lb_target_group.https8800.arn}"
  target_id        = "${module.circleci.aws_instance_id}"
  port             = 8800
}

resource "aws_lb_target_group_attachment" "http" {
  target_group_arn = "${aws_lb_target_group.http.arn}"
  target_id        = "${module.circleci.aws_instance_id}"
  port             = 80
}

#
# All all inbound to 80 and 443
#
resource "aws_security_group" "lb_ingress" {
  name   = "${local.prefix}-lb-ingress"
  vpc_id = "${module.network.vpc_id}"
  tags   = "${module.tags.application_tags}"

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
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${module.circleci.circleci_users_sg_id}"]
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

