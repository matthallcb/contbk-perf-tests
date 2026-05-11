# Contbk perf tests

Infrastructure as Code (IaC) files for doing continuous backup performance
testing. We use terraform to create EC2 instances and ansible to configure
them.

## Usage

To spin up EC2 nodes:

```
$ cd terraform
$ # Make sure you can authenticate with AWS, e.g. 'aws sso login' or 'export AWS_SECRET_KEY_ID=blargh'
$ terraform apply -var 'key_name=<aws key name>'
```

where `<aws key name>` is an SSH keypair in your AWS account.

To setup the nodes:

```
$ cd ansible
$ cp vars.example.yml vars.yaml
$ ansible-playbook -i ../bridge/inventory.ini setup.yml
```

Backups and restores can then be run through the playbooks in `bk/` and `restore/`.

## Configuration

Number of CB server nodes, instance types, disk throughput etc can all be
configured through terraform variables. See variables.tf for definitions and
use a terraform.tfvars file to override.

`ansible/ansible.cfg` will need to be edited to point to your SSH key.

Variables for the performance tests themselves are in `ansible/vars.yml`.
