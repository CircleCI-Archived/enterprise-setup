# elastic IP for services box
resource "aws_eip" "services" {
  instance = "${aws_instance.services.id}"
  vpc      = true
}