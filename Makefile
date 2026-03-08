ANSIBLE_DIR ?= ansible
PLAYBOOK ?= playbooks/bootstrap.yml
GROUP ?= workstations
HOST ?=
LIMIT_FLAG = $(if $(HOST),--limit $(HOST),)
ANSIBLE_CMD = cd $(ANSIBLE_DIR) &&

.PHONY: help ping ping-host check check-host apply apply-host syntax inventory inventory-list list-hosts facts

help:
	@printf '%s\n' \
	  'Available targets:' \
	  '  make help                - Show available commands' \
	  '  make ping                - Ping all hosts in $(GROUP)' \
	  '  make ping-host HOST=name - Ping one host' \
	  '  make check               - Dry-run $(PLAYBOOK) with diff' \
	  '  make check-host HOST=name- Dry-run for one host' \
	  '  make apply               - Apply $(PLAYBOOK)' \
	  '  make apply-host HOST=name- Apply to one host' \
	  '  make syntax              - Syntax check $(PLAYBOOK)' \
	  '  make inventory           - Show inventory graph' \
	  '  make inventory-list      - Show full resolved inventory' \
	  '  make list-hosts          - List hosts in $(GROUP)' \
	  '  make facts HOST=name     - Gather facts for one host'

ping:
	$(ANSIBLE_CMD) ansible $(GROUP) -m ping

ping-host:
	$(ANSIBLE_CMD) ansible $(GROUP) -m ping --limit $(HOST)

check:
	$(ANSIBLE_CMD) ansible-playbook $(PLAYBOOK) --check --diff $(LIMIT_FLAG)

check-host:
	$(ANSIBLE_CMD) ansible-playbook $(PLAYBOOK) --check --diff --limit $(HOST)

apply:
	$(ANSIBLE_CMD) ansible-playbook $(PLAYBOOK) $(LIMIT_FLAG)

apply-host:
	$(ANSIBLE_CMD) ansible-playbook $(PLAYBOOK) --limit $(HOST)

syntax:
	$(ANSIBLE_CMD) ansible-playbook $(PLAYBOOK) --syntax-check

inventory:
	$(ANSIBLE_CMD) ansible-inventory --graph

inventory-list:
	$(ANSIBLE_CMD) ansible-inventory --list

list-hosts:
	$(ANSIBLE_CMD) ansible $(GROUP) --list-hosts

facts:
	$(ANSIBLE_CMD) ansible $(GROUP) -m setup --limit $(HOST)
