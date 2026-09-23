# Ansible Docker node

Cloud provider agnostic automation for provisioning a node with Docker.

Ubuntu 26.04 (resolute) and 24.04 (noble), ansible-core 2.15+.

## Prerequisites

* [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* `make install-deps` — installs the `ansible.posix` and `community.general`
  collections and pulls the two roles from GitHub.

When working on the roles themselves, `make link-roles` symlinks the sibling
checkouts of `../ansible-node` and `../ansible-docker` into `roles/` instead.

## Provision a VM

Create an instance with Ubuntu 26.04, add your SSH key, and note the public
IP. Anything above 512MB RAM is comfortable; at 512MB the node role's swap
file is what keeps the Docker install from being OOM-killed.

### With doctl

Creates the droplet and turns on weekly backups, every parameter spelled
out. Change the name; the rest reproduces the `thaidesk` node exactly:

```bash
doctl compute droplet create thaidesk --size s-1vcpu-512mb-10gb --region sgp1 --image ubuntu-26-04-x64 --vpc-uuid b2d1ac16-6b40-4abd-af7b-c712565917bc --ssh-keys 54371410 --wait --no-header --format ID | xargs -I{} doctl compute droplet-action enable-backups {} --backup-policy-plan weekly --backup-policy-weekday SUN --backup-policy-hour 20 --wait --format ID,Status,Type
```

Backups are a separate action rather than `--enable-backups` on `create`,
because that flag was silently ignored here: the droplet came up with
`features: [droplet_agent, private_networking]` and no backups at all.

The two account-specific IDs come from:

```bash
doctl compute ssh-key list          # --ssh-keys
doctl vpcs list                     # --vpc-uuid, the default for the region
```

Weekly backups cost 20% of the droplet ($0.80/month on this size), daily
30%. `--backup-policy-hour` is UTC. Leaving the policy flags off gets you
daily backups.

Then the public IP, for the inventory:

```bash
doctl compute droplet list --format Name,PublicIPv4
```

Expect `doctl` to report stale values right after a write — backup
settings and reserved IP assignments took minutes to show up in
`droplet get` and `reserved-ip list` while already being in effect. Verify
against `next_backup_window`, or just connect.

## Create an inventory file

Only the address is needed. The playbook works out the user and port
itself:

```
[all]
do-docker-sgp1-01 ansible_host=12.34.56.78
```

## Run

```bash
make deploy
# or: ansible-playbook -i inventory/inventory playbooks/docker.yml
```

`make check` does a `--check --diff` dry run, `make syntax` a syntax check,
`make lint` runs ansible-lint.

## What happens to your SSH access

The run hardens the connection it is using. On a fresh VM it connects as
`root` on port 22, and by the end the node only accepts `ansible` on port
2345 with key auth. Both values come from `inventory/group_vars/all.yml`.

You do not need to edit the inventory between runs. The first play probes
the hardened port and picks the endpoint accordingly, so the playbook is
re-runnable from any state:

```
TASK [Report the endpoint in use]
ok: [do-docker-sgp1-01] => "Connecting as ansible@12.34.56.78:2345"
```

After the first run:

```bash
ssh 12.34.56.78 -l ansible -p 2345
```

Root login and password auth are off, and ufw allows only 2345, 80 and 443.

## Layout

| Path | Purpose |
| --- | --- |
| `playbooks/docker.yml` | Endpoint discovery, bootstrap, then the two roles |
| `inventory/group_vars/all.yml` | SSH user/port, both bootstrap and hardened |
| `requirements.yml` | Collections and roles |

The roles live in their own repositories:

* [agalitsyn.node](https://github.com/agalitsyn/ansible-node) — base setup,
  users, swap, ufw, fail2ban, SSH hardening
* [agalitsyn.docker](https://github.com/agalitsyn/ansible-docker) — Docker
  Engine, Buildx, Compose, and the ufw integration

## Exposing container ports

The Docker role makes published ports obey ufw, which means `-p 8080:80`
alone is no longer reachable from outside. See the
[agalitsyn.docker README](https://github.com/agalitsyn/ansible-docker#docker-and-ufw)
— the rule has to match the *container's* port, not the published one,
because DNAT has already rewritten it by the time ufw sees the packet.

The simplest pattern is to publish on loopback (`-p 127.0.0.1:8080:80`) and
put a reverse proxy on 80/443, which are already open.

## Selective runs

```bash
ansible-playbook -i inventory/inventory playbooks/docker.yml --tags fail2ban
ansible-playbook -i inventory/inventory playbooks/docker.yml --tags docker
```

Endpoint discovery is tagged `always`, so tag-limited runs still connect
correctly.
