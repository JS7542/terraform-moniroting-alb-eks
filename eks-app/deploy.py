"""Apply-time nginx bootstrap; uses isolated temporary files and no shell."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time


def run(args, *, retry=False):
    attempts = 18 if retry else 1
    for attempt in range(attempts):
        result = subprocess.run(args, check=False)
        if result.returncode == 0:
            return
        if attempt + 1 < attempts:
            print("Waiting for EKS API/access propagation...", flush=True)
            time.sleep(10)
    raise RuntimeError(f"Command failed (exit {result.returncode}): {args[0]}")


def main():
    mode = sys.argv[1]
    if mode not in {"check", "namespace", "apply", "delete"}:
        raise ValueError("Unknown operation")
    for executable in ("aws", "kubectl"):
        if shutil.which(executable) is None:
            raise RuntimeError(f"Required executable is missing from PATH: {executable}")
    if mode == "check":
        run(["aws", "--version"])
        run(["kubectl", "version", "--client=true"])
        return

    connection = json.loads(os.environ["EKS_CONNECTION"])
    kubeconfig = {
        "apiVersion": "v1",
        "kind": "Config",
        "clusters": [{"name": "target", "cluster": {
            "server": connection["endpoint"],
            "certificate-authority-data": connection["ca"],
        }}],
        "users": [{"name": "terraform", "user": {"exec": {
            "apiVersion": "client.authentication.k8s.io/v1beta1",
            "command": "aws",
            "args": ["eks", "get-token", "--region", connection["region"],
                     "--cluster-name", connection["name"]],
            "interactiveMode": "Never",
        }}}],
        "contexts": [{"name": "target", "context": {
            "cluster": "target", "user": "terraform",
        }}],
        "current-context": "target",
    }
    with tempfile.TemporaryDirectory(prefix="terraform-nginx-") as directory:
        config_path = Path(directory) / "kubeconfig.json"
        manifest_path = Path(directory) / "nginx.yaml"
        config_path.write_text(json.dumps(kubeconfig), encoding="utf-8")
        manifest_path.write_text(os.environ["NGINX_MANIFEST"], encoding="utf-8")
        kubectl = ["kubectl", "--kubeconfig", str(config_path), "--request-timeout=30s"]
        if mode == "delete":
            run(kubectl + ["delete", "-f", str(manifest_path),
                           "--ignore-not-found=true", "--wait=true", "--timeout=5m"], retry=True)
        else:
            run(kubectl + ["apply", "--server-side", "--field-manager=terraform-nginx",
                           "-f", str(manifest_path)], retry=True)
            if mode == "apply":
                wait_client = kubectl[:-1] + ["--request-timeout=0"]
                run(wait_client + ["wait", "nodes", "--all", "--for=condition=Ready", "--timeout=10m"])
                run(wait_client + ["-n", "nginx", "rollout", "status", "deployment/nginx", "--timeout=10m"])


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError, KeyError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
