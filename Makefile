SHELL := /bin/bash

# Default goal to be displayed when no target is specified
.DEFAULT_GOAL := help

# Variables
VIRTUALENV ?= "venv-aro"
CONFIGPATH ?= "ansible.cfg"
TEMPFILE ?= "temp_file"

# Help target
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make virtualenv       -  Create a virtual environment and install dependencies"
	@echo "  make create-cluster   -  Deploy the cluster using Ansible"
	@echo "  make deploy-mas       -  Deploy MAS using Ansible"
	@echo "  make delete-cluster   -  Delete the cluster using Ansible"
	@echo "  make recreate-cluster -  Recreate the cluster using Ansible"
	@echo "  make uninstall-mas    -  Uninstall Maximo on running cluster"
	@echo "  make backup-mas       -  Restore Maximo Instance"
	@echo "  make restore-mas      -  Backup Maximo Instance"
	@echo "  make upgrade-mas      -  Upgrade Maximo Instance"

# Target to create virtual environment and configure Ansible
.PHONY: virtualenv
virtualenv:
	# Install Ansible
	# sudo dnf install ansible -y
	# Remove old ansible.cfg if it exists
	rm -rf $(CONFIGPATH)
	# Remove old virtual environment if it exists
	rm -rf $(VIRTUALENV)
	# Create a new virtual environment
	LC_ALL=en_US.UTF-8 python3 -m venv $(VIRTUALENV) --prompt "ARO Ansible Environment"
	# Activate the virtual environment and install dependencies
	@echo "Activating virtual environment and installing dependencies..."
	source $(VIRTUALENV)/bin/activate && \
	pip3 install --upgrade pip && \
	pip3 install setuptools && \
	pip3 install -r requirements.txt && \
	pip3 install openshift-client && \
	pip3 install ansible-lint && \
	pip3 install junit_xml pymongo xmljson jmespath kubernetes openshift && \
	ansible-galaxy collection install azure.azcollection && \
	ansible-galaxy collection install community.general && \
	ansible-galaxy collection install community.okd && \
	ansible-galaxy collection install ibm.mas_devops && \
	ansible-config init --disabled -t all > $(CONFIGPATH) && \
	awk 'NR==2{print "callbacks_enabled=ansible.posix.profile_tasks"} 1' $(CONFIGPATH) > $(TEMPFILE) && \
	cat $(TEMPFILE) > $(CONFIGPATH) && \
	rm -rf $(TEMPFILE) && \
	deactivate 

# Target to deploy the cluster
.PHONY: deploy-cluster
create-cluster:
	source $(VIRTUALENV)/bin/activate && \
	ansible-playbook ansible/create-cluster.yaml

# Target to deploy MAS
.PHONY: deploy-mas
deploy-mas:
	source $(VIRTUALENV)/bin/activate && \
	source ansible/artefacts/setenv-install.sh && \
	./ansible/artefacts/login-script.sh && \
	ansible-playbook ibm.mas_devops.oneclick_core

# Target to delete the cluster
.PHONY: delete-cluster
delete-cluster:
	source $(VIRTUALENV)/bin/activate && \
	ansible-playbook ansible/delete-cluster.yaml

# Target to recreate the cluster
.PHONY: recreate-cluster
recreate-cluster:
	source $(VIRTUALENV)/bin/activate && \
	ansible-playbook ansible/recreate-cluster.yaml

# Delete Cluster, Create Cluster and Deploy MAS 
.PHONY: redeploy
redeploy:
	source $(VIRTUALENV)/bin/activate && \
	ansible-playbook ansible/delete-cluster.yaml && \
	ansible-playbook ansible/create-cluster.yaml && \
	source ansible/artefacts/setenv-install.sh && \
	./ansible/artefacts/login-script.sh && \
	ansible-playbook ibm.mas_devops.oneclick_core

# Target to uninstall MAS 
.PHONY: uninstall-mas
uninstall-mas:
	source $(VIRTUALENV)/bin/activate && \
	source $(PWD)/ansible/variables/mas-uninstall.sh && \
    ansible-playbook ibm.mas_devops.uninstall_core && \
	deactivate

# Target to Backup MAS and its components
.PHONY: backup-mas
backup-mas:
	source $(VIRTUALENV)/bin/activate && \
	source $(PWD)/ansible/variables/mas-backup.sh && \
	ansible-playbook mas-backup.yaml && \
	deactivate

# Target to Backup MAS and its components
.PHONY: restore-mas
restore-mas:
	source $(VIRTUALENV)/bin/activate && \
	source $(PWD)/ansible/variables/mas-backup.sh && \
	ansible-playbook mas-restore.yaml && \
	deactivate

# Target to Upgrade MAS and its components
.PHONY: upgrade-mas
upgrade-mas:
	source $(VIRTUALENV)/bin/activate && \
	source $(PWD)/ansible/variables/mas-upgrade.sh && \
	ansible-playbook ibm.mas_devops.oneclick_upgrade && \
	deactivate

