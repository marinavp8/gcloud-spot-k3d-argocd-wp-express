#!/usr/bin/env bash
# Alternativa a GitHub Actions: construye la imagen en la VM y la importa en k3d
# (sin registry ni credenciales), y fija el tag en git para que ArgoCD lo despliegue.
set -euo pipefail
cd "$(dirname "$0")"

INFRA_DIR="${INFRA_DIR:-$(cd ../gcloud-spot-k3d-argocd-wp && pwd)}"
IP="$(terraform -chdir="$INFRA_DIR/terraform" output -raw ip)"
SSH=(ssh -i "$INFRA_DIR/keys/k3d-wp" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "jose@$IP")
IMAGE=ghcr.io/marinavp8/gcloud-spot-k3d-argocd-wp-express
TAG="$(git rev-parse --short=7 HEAD)"

git diff --quiet HEAD -- app || { echo "Hay cambios sin commit en app/" >&2; exit 1; }

echo "Construyendo $IMAGE:$TAG en $IP"
git archive HEAD app | "${SSH[@]}" "rm -rf /tmp/express-build && mkdir -p /tmp/express-build && tar -x -C /tmp/express-build &&
  docker build -q --build-arg APP_VERSION=$TAG -t $IMAGE:$TAG /tmp/express-build/app &&
  k3d image import -c wp $IMAGE:$TAG"

sed -i.bak "s|newTag: .*|newTag: $TAG   # lo actualiza el workflow de GitHub Actions (o build-on-vm.sh) con el SHA del commit|" k8s/kustomization.yaml
rm k8s/kustomization.yaml.bak
git add k8s/kustomization.yaml
git commit -q -m "Imagen $TAG" && git push -q
echo "Tag $TAG en git; ArgoCD lo sincroniza en ≤3 min"
