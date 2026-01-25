#!/bin/bash
source $(dirname "$0")/env_config.sh

log "Initializing Odoo databases across all clients and environments..."

for CLIENT in "${!CLIENTS_MAP[@]}"; do
    ENVIRONMENTS=${CLIENTS_MAP[$CLIENT]}
    
    if ! minikube -p $CLIENT status >/dev/null 2>&1; then
        warn "Cluster $CLIENT is not running. Skipping."
        continue
    fi

    log "🔍 Checking Client: $CLIENT"
    for ENV in $ENVIRONMENTS; do
        NAMESPACE="$CLIENT-$ENV" # Ex: airbnb-dev
        POD_LABEL="app=odoo-app"
        
        echo "   Target: $NAMESPACE"

        # 1. Wait for Pod to be Ready
        minikube -p $CLIENT kubectl -- wait --for=condition=ready pod -l $POD_LABEL -n $NAMESPACE --timeout=60s >/dev/null 2>&1
        
        # 2. Get Pod Name and DB Password
        POD_NAME=$(minikube -p $CLIENT kubectl -- get pod -l $POD_LABEL -n $NAMESPACE -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
        
        if [ -z "$POD_NAME" ]; then
            warn "   No pod found in $NAMESPACE."
            continue
        fi

        DB_PASS=$(minikube -p $CLIENT kubectl -- get secret odoo-db-secret -n $NAMESPACE -o jsonpath="{.data.PASSWORD}" | base64 --decode)

        # 3. Check Odoo Health
        HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://odoo.$ENV.$CLIENT.local)

        if [ "$HTTP_CODE" == "500" ] || [ "$HTTP_CODE" == "000" ]; then
            log "   Detected error/init pending. Forcing DB installation..."
            
            minikube -p $CLIENT kubectl -- exec -n $NAMESPACE $POD_NAME -- \
                odoo -i base \
                -d odoo_db \
                --db_host=postgres-svc.$NAMESPACE.svc.cluster.local \
                --db_user=odoo \
                --db_password=$DB_PASS \
                --stop-after-init > /dev/null 2>&1

            log "   Restarting Pod to apply changes..."
            minikube -p $CLIENT kubectl -- delete pod $POD_NAME -n $NAMESPACE > /dev/null
        else
            success "   Environment $NAMESPACE is now operational (HTTP $HTTP_CODE)."
        fi
    done
done