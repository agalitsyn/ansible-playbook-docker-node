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
touch inventory/inventory
```

For the first run you propbably will have something like this:

```
[all]
docker-0 ansible_host=12.34.56.78 ansible_port=22 ansible_user=ubuntu
```

## Run playbook

```bash
ansible-playbook -vv -i inventory/inventory playbooks/docker.yml
```

## Test

With default variables you can connect like:

```bash
ssh 12.34.56.78 -l ansible -p 2345
```

## Edit inventory file

Ansible created ssh user, changed sshd ports and etc, so we need to update inventory file for next runs:

```
[all]
docker-0 ansible_host=12.34.56.78 ansible_port=2345 ansible_user=ansible
```
