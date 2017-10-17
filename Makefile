.PHONY: init ansible-setup

init:
	@if [ -f terraform.tfvars ]; then mv terraform.tfvars terraform.tfvars-`date "+%Y-%m-%d-%H:%M:%S"`; fi
	@rsync -aq terraform.tfvars.template terraform.tfvars
	@perl -i -pe 's/\n/\n##/g' elastic-ip.tf
	@perl -i -pe 's/\n/\n##/g' scheduler.tf

ansible-setup:
	@mkdir -p .ansible
	@ansible-galaxy install -fr requirements.yml

dev:
	@perl -i -pe 's/##//g' elastic-ip.tf
	@perl -i -pe 's/##//g' scheduler.tf
	@echo '\n# Times must be in cron format, UTC time zone (see https://stackoverflow.com/questions/20865688/is-it-possible-to-set-up-amazon-ec2-auto-scaling-for-particular-days-of-the-week)\nspin_up_schedule = "0 14 * * MON-FRI" # a.k.a. 7 AM PST, M-F\nspin_down_schedule = "0 2 * * TUE-SAT" # a.k.a. 7 PM PST, M-F' >> terraform.tfvars