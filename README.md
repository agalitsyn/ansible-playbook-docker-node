# Ansible Docker node

Cloud provider agnostic automation for provisioning node with Docker daemon.

## Prerequisites

* [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-apt-ubuntu)
* Run `make install-roles`

## Provision VM

Use your favourite cloud and create instance with Ubuntu 20.04
Don't forget to:
* configure ssh keys
* obtain public IP address

## Create inventory file

```bash
$ touch inventory/inventory
```

For the first run you propbably will have something like this:

```
[all]
docker-0 ansible_host=12.34.56.78 ansible_port=22 ansible_user=root
```

## Run playbook

```bash
$ ansible-playbook -vv -i inventory/inventory playbooks/docker.yml
```

## Edit inventory file

Ansible will create ssh user, change sshd ports and etc, so we will need to update inventory file for new runs:

```
[all]
docker-0 ansible_host=12.34.56.78 ansible_port=2345 ansible_user=ansible
```
