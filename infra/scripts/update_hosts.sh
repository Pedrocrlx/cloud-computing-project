#!/bin/bash

source $(dirname "$0")/env_config.sh

log "A iniciar configuração de DNS local (/etc/hosts)..."

sudo sed -i '/# K8S-AUTO-PROJECT/d' /etc/hosts

for CLIENT in "${!CLIENTS_MAP[@]}"; do
    ENVIRONMENTS=${CLIENTS_MAP[$CLIENT]}
    
    # Verifica se o cluster do cliente está a correr
    if minikube -p $CLIENT status >/dev/null 2>&1; then
        IP=$(minikube -p $CLIENT ip)
        DOMAINS=""
        
        # Gera os domínios: odoo.dev.airbnb.local, etc.
        for ENV in $ENVIRONMENTS; do
            DOMAINS="$DOMAINS odoo.$ENV.$CLIENT.local"
        done

        log "Mapeando $CLIENT ($IP) -> $DOMAINS"
        
        # Insere no /etc/hosts com uma tag para fácil remoção
        echo "$IP $DOMAINS # K8S-AUTO-PROJECT" | sudo tee -a /etc/hosts > /dev/null
    else
        warn "Cluster '$CLIENT' não detetado ou desligado. A ignorar DNS."
    fi
done

success "/etc/hosts atualizado!"