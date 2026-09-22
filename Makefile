VERBOSITY_FLAG ?= -v
INVENTORY ?= inventory/inventory
PLAYBOOK ?= playbooks/docker.yml

.PHONY: all
all:
	@echo "targets: install-deps, link-roles, lint, syntax, check, deploy"

# Pulls the roles from GitHub. Use link-roles instead when developing them.
.PHONY: install-deps
install-deps:
	ansible-galaxy collection install -r requirements.yml
	ansible-galaxy role install -r requirements.yml --roles-path roles --force

# Symlinks the sibling role checkouts into roles/ so edits take effect
# without a galaxy round-trip.
.PHONY: link-roles
link-roles:
	mkdir -p roles
	rm -rf roles/agalitsyn.node roles/agalitsyn.docker
	ln -s ../../ansible-node roles/agalitsyn.node
	ln -s ../../ansible-docker roles/agalitsyn.docker

.PHONY: syntax
syntax:
	ansible-playbook -i $(INVENTORY) --syntax-check $(PLAYBOOK) --list-tasks

.PHONY: lint
lint:
	ansible-lint $(PLAYBOOK) roles/

.PHONY: check
check:
	ansible-playbook $(VERBOSITY_FLAG) -i $(INVENTORY) --check --diff $(PLAYBOOK)

.PHONY: deploy
deploy:
	ansible-playbook $(VERBOSITY_FLAG) -i $(INVENTORY) $(PLAYBOOK)
