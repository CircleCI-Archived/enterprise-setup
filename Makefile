.PHONY: init ansible-setup

init:
	@rsync -aq terraform.tfvars.template terraform.tfvars

ansible-setup:
	@mkdir -p .ansible
	@ansible-galaxy install -fr requirements.yml
