# GitOps

## MySQL

Deploy the secret manually, due to passwords...

Example:

```bash
kubectl create namespace mysql
kubectl create secret generic passwords -n mysql --from-literal=mysql-root-password=root --from-literal=mysql-password=password
```

MySQL will fail to start if the secret is not present.

## ArgoCD

Must be installed and configured manually, for example:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl edit configmap -n argocd argocd-cm
```

### ConfigMap changes

#### Helm + Kustomize

This allows Helm chart installation with Kustomize overlays. Add to `argocd-cm` ConfigMap:

```yaml
  configManagementPlugins: |
    - name: kustomized-helm
      init:
        command: ["/bin/sh", "-c"]
        args: ["helm dependency build || true"]
      generate:
        command: [sh, -c]
        args: ["helm template . --name-template $ARGOCD_APP_NAME --namespace $ARGOCD_APP_NAMESPACE --include-crds > all.yaml && kustomize build"]
```

#### GitHub OIDC Integration

Add to `argocd-cm` ConfigMap:

```yaml
  dex.config: |
    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: $dex.github.clientID
          clientSecret: $dex.github.clientSecret
          orgs:
          - name: kzdv
  url: https://argo.cd.denartcc.org
```

Then edit `argocd-secret` Secret:

```yaml
  stringData:
    dex.github.clientID: $GITHUB_CLIENT_ID
    dex.github.clientSecret: $GITHUB_CLIENT_SECRET
```

Replace `$GITHUB_CLIENT_ID` and `$GITHUB_CLIENT_SECRET` with your GitHub OAuth App credentials.

## Cert-Manager configs

You need to apply the Cloudflare API Token secret to the `cert-manager` namespace:

```bash
kubectl create secret generic cloudflare-api-token --from-literal=api-token=$CLOUDFLARE_API_TOKEN -n cert-manager
```

Replace `$CLOUDFLARE_API_TOKEN` with your Cloudflare API Token.
