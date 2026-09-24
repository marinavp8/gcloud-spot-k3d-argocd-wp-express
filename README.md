# Express en k3d con ArgoCD (GitOps)

App Express 5 desplegada por ArgoCD en el clúster k3d de la VM Spot creada por
[gcloud-spot-k3d-argocd-wp](https://github.com/marinavp8/gcloud-spot-k3d-argocd-wp).

```
push a main (app/**) ──▶ GitHub Actions ──▶ ghcr.io/marinavp8/gcloud-spot-k3d-argocd-wp-express:<sha>
                                   └──▶ commit "Imagen <sha>" en k8s/kustomization.yaml
                                                   │
ArgoCD (Application "express", auto-sync) ◀────────┘ ──▶ namespace express
```

## Estructura

```
.
├── app/                      # Express 5 (Node 24) + Dockerfile
│   ├── server.js             # /  ·  /api/info  ·  /healthz
│   └── Dockerfile
├── k8s/                      # kustomize que sincroniza ArgoCD
│   ├── deployment.yaml       # 2 réplicas, probes, non-root, FS read-only
│   ├── service.yaml
│   ├── ingress.yaml          # Traefik + cert-manager (letsencrypt-prod) + redirección a HTTPS
│   └── kustomization.yaml    # tag de la imagen (lo actualiza el workflow)
├── argocd/application.yaml.tpl
├── deploy.sh                 # registra la Application en el ArgoCD de la VM
├── build-on-vm.sh            # alternativa a Actions: build en la VM + k3d image import
└── .github/workflows/build.yml
```

- **Dominio**: `express-<ip-con-guiones>.sslip.io`. Como la IP depende del `terraform apply`,
  no está en git: la Application lo inyecta con `kustomize.patches` (igual que WordPress).
- **Imagen**: la construye GitHub Actions y la sube a GHCR (paquete público, sin `imagePullSecret`).
- **Credenciales**: ninguna en el repo. `deploy.sh` usa la clave SSH y el `terraform output`
  del repo de infraestructura (`../gcloud-spot-k3d-argocd-wp`); GHCR usa el `GITHUB_TOKEN` del workflow.

## Uso

```bash
# Local
cd app && npm install && npm start          # http://localhost:3000

# Registrar en ArgoCD (una vez; la VM tiene que estar arrancada)
./deploy.sh

# Desplegar una nueva versión: basta con hacer push de cambios en app/
git push                                     # Actions → nueva imagen → commit del tag → ArgoCD sincroniza

# Sin GitHub Actions: build en la VM + k3d image import + commit del tag
./build-on-vm.sh
```

> Hoy Actions está bloqueado en `marinavp8` por facturación, así que el despliegue actual
> se hizo con `build-on-vm.sh`. Por eso el Deployment usa `imagePullPolicy: IfNotPresent`:
> la imagen importada en k3d no existe en GHCR. Ojo: si se recrea el clúster hay que volver a ejecutarlo.

Comprobar en la VM:

```bash
kubectl -n argocd get application express
kubectl -n express get pods,ingress,certificate
```
