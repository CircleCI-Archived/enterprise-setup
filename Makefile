.PHONY: init ansible-setup

init:
	@if [ -f terraform.tfvars ]; then mv terraform.tfvars terraform.tfvars-`date "+%Y-%m-%d-%H:%M:%S"`; fi
	@rsync -aq terraform.tfvars.template terraform.tfvars

ansible-setup:
	@mkdir -p .ansible
	@ansible-galaxy install -fr requirements.yml
