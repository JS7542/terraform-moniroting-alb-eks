param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('namespace', 'apply', 'delete')]
    [string]$Action
)
$ErrorActionPreference = 'Stop'
Get-Command aws -ErrorAction Stop | Out-Null
Get-Command kubectl -ErrorAction Stop | Out-Null

$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('terraform-nginx-' + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
$configPath = Join-Path $temporaryDirectory 'kubeconfig.json'
$manifestPath = Join-Path $temporaryDirectory 'nginx.yaml'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Invoke-Kubectl {
    param([string[]]$Arguments)
    & kubectl --kubeconfig $configPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl failed with exit code $LASTEXITCODE"
    }
}

try {
    [System.IO.File]::WriteAllText($configPath, $env:KUBECONFIG_JSON, $utf8)
    [System.IO.File]::WriteAllText($manifestPath, $env:NGINX_MANIFEST, $utf8)
    if ($Action -eq 'delete') {
        Invoke-Kubectl -Arguments @('--request-timeout=0', 'delete', '-f', $manifestPath, '--ignore-not-found=true', '--wait=true', '--timeout=5m')
    } else {
        $applied = $false
        for ($attempt = 1; $attempt -le 18; $attempt++) {
            & kubectl --kubeconfig $configPath --request-timeout=30s apply -f $manifestPath
            if ($LASTEXITCODE -eq 0) {
                $applied = $true
                break
            }
            if ($attempt -lt 18) {
                Write-Host 'Waiting for EKS API/access permissions...'
                Start-Sleep -Seconds 10
            }
        }
        if (-not $applied) { throw 'kubectl apply failed' }
        if ($Action -eq 'apply') {
            Invoke-Kubectl -Arguments @('--request-timeout=0', 'wait', 'nodes', '--all', '--for=condition=Ready', '--timeout=10m')
            Invoke-Kubectl -Arguments @('--request-timeout=0', '-n', 'nginx', 'rollout', 'status', 'deployment/nginx', '--timeout=10m')
        }
    }
} finally {
    # Only these two files were created; no recursive delete is needed.
    Remove-Item -LiteralPath $configPath, $manifestPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $temporaryDirectory -ErrorAction SilentlyContinue
}
