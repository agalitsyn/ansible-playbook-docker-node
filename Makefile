VERBOSITY_FLAG ?= -vv

.PHONY: all
all:
	echo "no default action"

.PHONY: lint
lint:
	ansible-playbook $(VERBOSITY_FLAG) -i inventory.local --syntax-check playbooks/docker.yml --list-tasks

.PHONY: install-roles
install-roles:
	ansible-galaxy -v install --role-file ansible-galaxy.yml --roles-path roles --force --ignore-errors
