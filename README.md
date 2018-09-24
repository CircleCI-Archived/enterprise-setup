# CircleCI Server Setup

This package allows you to easily orchestrate your CircleCI Server cluster in AWS using Terraform. For a full step by step guide to installing CircleCI Server with Terraform, see our [installation guide](https://circleci.com/docs/2.0/circleci-install-doc-v2-17.pdf#section=administration).

**Note: This is only meant to be used for the initial setup of CircleCI Server and is not meant to be used for the ongoing maintenance of the CircleCI Server.**

**Note: Master is the only supported branch. All other branches of this repo should not be considered stable, and is to be used at your own risk.**

## Documentation

We use Terraform to automate parts of the infrastructure for your CircleCI Server install, so you will need to install this first:

* [Terraform](https://www.terraform.io/downloads.html)

**Note: This script only supports terraform version 0.12 and higher. Please update to the most recent version before fetching from upstream.**

## Installation

You can find instructions here: https://circleci.com/docs/2.0/aws/

### Variables

There are some optional variables that aren't described in the instructions.
You can view their names and descriptions in [variables.tf](variables.tf).

### Teardown

You can find teardown instructions at https://circleci.com/docs/2.0/aws-teardown/
