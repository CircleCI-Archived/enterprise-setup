.PHONY: init ansible-roles

init:
	@rsync -aq terraform.tfvars.template terraform.tfvars

ansible-dependencies:
	ansible-galaxy install -fr requirements.yml
