
Your installation is complete. It may take several minutes until it is ready.

${ ansible ? "Get started by visiting:" : "Continue the installation by visiting:" }

    http://${services_public_ip}/

To ssh into the Services box of your installation using your `${ssh_key}` private key:

    ssh ubuntu@${services_public_ip}

${ ansible ? "To rerun the Ansible provisioner using your `${ssh_key}` private key:

    ansible-playbook playbook.yml -v -i ./.ansible/hosts -e '@./.ansible/extra_vars.json'" : "" }

Thank you and enjoy using CircleCI Enterprise!
