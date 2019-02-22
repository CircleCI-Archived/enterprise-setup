#!/bin/sh

set -e

sed -i.bak '/Name = "${var.prefix}_services"/a\
\ \ \ \ ce_email = "${var.ce_email}"
\ \ \ \ ce_purpose = "${var.ce_purpose}"
\ \ \ \ customer = "${var.customer}"
\ \ \ \ ce_schedule = "${var.ce_schedule}"
\ \ \ \ ce_duration = "${var.ce_duration}"
' circleci.tf
