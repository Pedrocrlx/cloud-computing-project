#!/bin/bash

source $(dirname "$0")/env_config.sh

log "Initializing local DNS configuration (/etc/hosts)..."

sudo sed -i '/# K8S-AUTO-PROJECT/d' /etc/hosts

for CLIENT in "${!CLIENTS_MAP[@]}"; do
    ENVIRONMENTS=${CLIENTS_MAP[$CLIENT]}
    
    # Verify if Minikube cluster is running
    if minikube -p $CLIENT status >/dev/null 2>&1; then
        IP=$(minikube -p $CLIENT ip)
        DOMAINS=""
        
        # Generate domains: odoo.dev.airbnb.local, etc.
        for ENV in $ENVIRONMENTS; do
            DOMAINS="$DOMAINS odoo.$ENV.$CLIENT.local"
        done

        log "Mapping $CLIENT ($IP) -> $DOMAINS"
        
        # Append to /etc/hosts file
        echo "$IP $DOMAINS # K8S-AUTO-PROJECT" | sudo tee -a /etc/hosts > /dev/null
    else
        warn "Cluster '$CLIENT' not running. Skipping DNS."
    fi
done

success "/etc/hosts updated!"