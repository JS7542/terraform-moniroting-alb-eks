#!/usr/bin/env bash
set -euo pipefail

action="$1"
case "$action" in
  namespace|apply|delete) ;;
  *) echo "Unknown action: $action" >&2; exit 1 ;;
esac
command -v aws >/dev/null || { echo "AWS CLI is missing from PATH" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is missing from PATH" >&2; exit 1; }

temporary_directory=$(mktemp -d)
trap 'rm -f "$temporary_directory/kubeconfig.json" "$temporary_directory/nginx.yaml"; rmdir "$temporary_directory"' EXIT
printf '%s\n' "$KUBECONFIG_JSON" > "$temporary_directory/kubeconfig.json"
printf '%s\n' "$NGINX_MANIFEST" > "$temporary_directory/nginx.yaml"
kubectl_args=(--kubeconfig "$temporary_directory/kubeconfig.json")

apply_manifest() {
  local attempt
  for attempt in {1..18}; do
    if kubectl "${kubectl_args[@]}" --request-timeout=30s apply -f "$temporary_directory/nginx.yaml"; then
      return 0
    fi
    if [ "$attempt" -lt 18 ]; then
      echo "Waiting for EKS API/access permissions..."
      sleep 10
    fi
  done
  return 1
}

if [ "$action" = delete ]; then
  kubectl "${kubectl_args[@]}" --request-timeout=0 delete -f "$temporary_directory/nginx.yaml" --ignore-not-found=true --wait=true --timeout=5m
else
  apply_manifest
  if [ "$action" = apply ]; then
    kubectl "${kubectl_args[@]}" --request-timeout=0 wait nodes --all --for=condition=Ready --timeout=10m
    kubectl "${kubectl_args[@]}" --request-timeout=0 -n nginx rollout status deployment/nginx --timeout=10m
  fi
fi
