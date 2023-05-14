#!/bin/bash

set -ex

service_account_cred_file=${1:-"../google-credentials.json"}
if [[ ! -f "$service_account_cred_file" ]]; then
  echo "Service account credentials file not found at $service_account_cred_file"
  exit 1
fi

helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --set installCRDs=true

# Create secret where data key is "secret-access-credentials" and value is the contents of the service account credentials file
kubectl create secret generic gcpsm-secret --from-file=secret-access-credentials="${service_account_cred_file}" -n external-secrets

# Wait for webhook rollout
kubectl rollout status deployment/external-secrets-webhook -n external-secrets

# Create Secret Store
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcp-store
spec:
  provider:
      gcpsm:
        auth:
          secretRef:
            secretAccessKeySecretRef:
              name: gcpsm-secret
              key: secret-access-credentials
        projectID: adhp-386716
EOF