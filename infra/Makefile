# Makefile for managing Terraform infrastructure and Minikube clusters for multiple clients
CLIENTS := $(shell grep 'CLIENTS_MAP\[' scripts/env_config.sh | cut -d'"' -f2)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

all: clean up hosts init validate ## Run all steps: clean, up, hosts, init, validate

clean: ## Clean previous Terraform state and Minikube clusters
	@echo "Cleaning up previous Terraform state and Minikube clusters..."
	rm -rf .terraform terraform.tfstate.d .terraform.lock.hcl
	minikube delete --all
	@echo "Cleaning done."

up: ## Initialize and apply Terraform configurations for all clients
	@echo "Initializing and applying Terraform configurations for all clients..."
	terraform init
	@for client in $(CLIENTS); do \
		echo "------------------------------------"; \
		echo "🏗️  CLIENT: $$client"; \
		terraform workspace select $$client || terraform workspace new $$client; \
		terraform apply -auto-approve; \
	done
	@echo "All clients have been set up."

hosts: ## Update /etc/hosts with client-specific domain mappings
	@echo "Updating /etc/hosts with client-specific domain mappings..."
	@chmod +x scripts/update_hosts.sh
	@./scripts/update_hosts.sh

init: ## Initialize Minikube clusters and deploy Odoo instances for all clients
	@echo "Initializing Minikube clusters and deploying Odoo instances for all clients..."
	@chmod +x scripts/init_odoo.sh
	@./scripts/init_odoo.sh

validate: ## Validate the deployment by testing final endpoints
	@echo "Testing final endpoints..."
	@# Load the CLIENTS_MAP from the env_config.sh script
	@bash -c 'source scripts/env_config.sh; \
	for client in "$${!CLIENTS_MAP[@]}"; do \
		for env in $${CLIENTS_MAP[$$client]}; do \
			url="https://odoo.$$env.$$client.local"; \
			code=$$(curl -k -s -o /dev/null -w "%{http_code}" $$url); \
			echo "Checking $$url ... HTTP $$code"; \
		done; \
	done'

test: validate