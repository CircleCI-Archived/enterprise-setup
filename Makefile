.PHONY: init

init:
	@rsync -aq terraform.tfvars.template terraform.tfvars
