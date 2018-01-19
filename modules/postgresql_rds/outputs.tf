output "instance_ip" {
  value = "${aws_db_instance.mod.address}"
}

output "endpoint" {
  value = "${aws_db_instance.mod.endpoint}"
}

output "instance_id" {
  value = "${aws_db_instance.mod.id}"
}

output "postgres_setup_script" {
  value = "${data.template_file.setup_script.rendered}"
}
