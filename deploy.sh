#!/usr/bin/env bash
# Registra la Application "express" en el ArgoCD de la VM creada por
# ../gcloud-spot-k3d-argocd-wp (usa su terraform output y su clave SSH).
set -euo pipefail

INFRA_DIR="${INFRA_DIR:-$(cd "$(dirname "$0")/../gcloud-spot-k3d-argocd-wp" && pwd)}"
IP="$(terraform -chdir="$INFRA_DIR/terraform" output -raw ip)"
export EXPRESS_DOMAIN="express-${IP//./-}.sslip.io"

echo "Registrando Application express → https://$EXPRESS_DOMAIN"
envsubst '${EXPRESS_DOMAIN}' < "$(dirname "$0")/argocd/application.yaml.tpl" |
  ssh -i "$INFRA_DIR/keys/k3d-wp" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
    "jose@$IP" 'kubectl apply -f -'
