.PHONY: init ansible-setup

init:
	@if [ -f terraform.tfvars ]; then mv terraform.tfvars terraform.tfvars-`date "+%Y-%m-%d-%H:%M:%S"`; fi
	@rsync -aq terraform.tfvars.template terraform.tfvars
	@zip files/start-server.zip start-server.js
	@zip files/stop-server.zip stop-server.js

ansible-setup:
	@mkdir -p .ansible
	@ansible-galaxy install -fr requirements.yml
