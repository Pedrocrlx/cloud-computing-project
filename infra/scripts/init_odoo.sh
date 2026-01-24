#!/bin/bash
# scripts/init_odoo.sh
source $(dirname "$0")/env_config.sh

log "A iniciar validação e configuração das Bases de Dados Odoo..."

for CLIENT in "${!CLIENTS_MAP[@]}"; do
    ENVIRONMENTS=${CLIENTS_MAP[$CLIENT]}
    
    if ! minikube -p $CLIENT status >/dev/null 2>&1; then
        warn "Cluster $CLIENT está desligado. A saltar."
        continue
    fi

    log "🔍 A verificar Cliente: $CLIENT"

    for ENV in $ENVIRONMENTS; do
        NAMESPACE="$CLIENT-$ENV" # Ex: airbnb-dev
        POD_LABEL="app=odoo-app"
        
        echo "   Target: $NAMESPACE"

        # 1. Esperar que o Pod esteja Running
        minikube -p $CLIENT kubectl -- wait --for=condition=ready pod -l $POD_LABEL -n $NAMESPACE --timeout=60s >/dev/null 2>&1
        
        # 2. Obter nome do Pod e Password
        POD_NAME=$(minikube -p $CLIENT kubectl -- get pod -l $POD_LABEL -n $NAMESPACE -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
        
        if [ -z "$POD_NAME" ]; then
            warn "   Nenhum pod encontrado em $NAMESPACE."
            continue
        fi

        DB_PASS=$(minikube -p $CLIENT kubectl -- get secret odoo-db-secret -n $NAMESPACE -o jsonpath="{.data.PASSWORD}" | base64 --decode)

        # 3. Testar se precisa de inicialização (Curl Check)
        HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://odoo.$ENV.$CLIENT.local)

        if [ "$HTTP_CODE" == "500" ] || [ "$HTTP_CODE" == "000" ]; then
            log "   🛠️  Detectado Erro/Init pendente. A forçar instalação da BD..."
            
            minikube -p $CLIENT kubectl -- exec -n $NAMESPACE $POD_NAME -- \
                odoo -i base \
                -d odoo_db \
                --db_host=postgres-svc.$NAMESPACE.svc.cluster.local \
                --db_user=odoo \
                --db_password=$DB_PASS \
                --stop-after-init > /dev/null 2>&1

            log "   ♻️  A reiniciar Pod para aplicar alterações..."
            minikube -p $CLIENT kubectl -- delete pod $POD_NAME -n $NAMESPACE > /dev/null
        else
            success "   Ambiente $NAMESPACE já está operacional (HTTP $HTTP_CODE)."
        fi
    done
done