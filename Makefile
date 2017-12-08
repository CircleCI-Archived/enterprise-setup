.PHONY: dev init

init:
	@terraform get
	@if [ -f terraform.tfvars ]; then mv terraform.tfvars terraform.tfvars-`date "+%Y-%m-%d-%H:%M:%S"`; fi
	@rsync -aq terraform.tfvars.template terraform.tfvars

dev:
	@if [ -f terraform.tfvars ]; then mv terraform.tfvars terraform.tfvars-`date "+%Y-%m-%d-%H:%M:%S"`; fi
	@rsync -aq terraform.tfvars-dev.template terraform.tfvars

