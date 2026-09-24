# Plantilla: deploy.sh sustituye ${EXPRESS_DOMAIN} y la aplica en el clúster
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: express
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/marinavp8/gcloud-spot-k3d-argocd-wp-express.git
    targetRevision: main
    path: k8s
    kustomize:
      # El dominio depende de la IP de la VM: se inyecta aquí, no en git
      patches:
        - target:
            kind: Ingress
            name: express
          patch: |-
            - op: replace
              path: /spec/rules/0/host
              value: ${EXPRESS_DOMAIN}
            - op: replace
              path: /spec/tls/0/hosts/0
              value: ${EXPRESS_DOMAIN}
  destination:
    server: https://kubernetes.default.svc
    namespace: express
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
