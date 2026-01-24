#!/bin/bash

# Define um Array Associativo (Map) igual ao teu variables.tf
declare -A CLIENTS_MAP

# --- CONFIGURAÇÃO ESPELHADA DO TERRAFORM ---
CLIENTS_MAP["airbnb"]="dev prod"
# CLIENTS_MAP["nike"]="dev qa prod"     
# CLIENTS_MAP["mcdonalds"]="dev qa beta prod"


log() {
    echo -e "\033[1;34m[K8S-OPS]\033[0m $1"
}

warn() {
    echo -e "\033[1;33m[AVISO]\033[0m $1"
}

success() {
    echo -e "\033[1;32m[SUCESSO]\033[0m $1"
}