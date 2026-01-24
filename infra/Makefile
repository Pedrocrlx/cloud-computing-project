# Makefile
# Extrai a lista de clientes do script de config para iterar no make
CLIENTS := $(shell grep 'CLIENTS_MAP\[' scripts/env_config.sh | cut -d'"' -f2)

.PHONY: all clean up hosts init validate test

all: clean up hosts init validate

clean:
	@echo "🧹 A limpar infraestrutura..."
	rm -rf .terraform terraform.tfstate.d .terraform.lock.hcl
	minikube delete --all
	@echo "✨ Limpeza concluída."

up:
	@echo "🚀 A Provisionar Clusters..."
	terraform init
	@for client in $(CLIENTS); do \
		echo "------------------------------------"; \
		echo "🏗️  CLIENTE: $$client"; \
		terraform workspace select $$client || terraform workspace new $$client; \
		terraform apply -auto-approve; \
	done
	@echo "✅ Terraform finalizado."

hosts:
	@chmod +x scripts/update_hosts.sh
	@./scripts/update_hosts.sh

init:
	@chmod +x scripts/init_odoo.sh
	@./scripts/init_odoo.sh

validate:
	@echo "🧪 A testar endpoints finais..."
	@# Script simples embutido para validar
	@bash -c 'source scripts/env_config.sh; \
	for client in "$${!CLIENTS_MAP[@]}"; do \
		for env in $${CLIENTS_MAP[$$client]}; do \
			url="https://odoo.$$env.$$client.local"; \
			code=$$(curl -k -s -o /dev/null -w "%{http_code}" $$url); \
			echo "Checking $$url ... HTTP $$code"; \
		done; \
	done'

test: validate