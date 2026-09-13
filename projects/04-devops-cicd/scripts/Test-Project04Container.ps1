[CmdletBinding()]
param(
    [string]$ImageTag = 'portfolio-p04-task-manager:local',
    [string]$ContainerName = 'portfolio-p04-task-manager-check'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$projectOneApp = Join-Path $repositoryRoot 'projects\01-web-task-manager\app'
$dockerfile = Join-Path $repositoryRoot 'projects\04-devops-cicd\docker\Dockerfile'
$dockerExecutable = (Get-Command docker -ErrorAction SilentlyContinue).Source
if ([string]::IsNullOrWhiteSpace($dockerExecutable)) {
    $dockerExecutable = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
}

if (-not (Test-Path -LiteralPath $projectOneApp -PathType Container)) {
    throw "Project 01 application source was not found: $projectOneApp"
}
if (-not (Test-Path -LiteralPath $dockerExecutable -PathType Leaf)) {
    throw "Docker CLI was not found: $dockerExecutable"
}

function Invoke-Docker {
    param([string[]]$Arguments)

    & $dockerExecutable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker command failed: docker $($Arguments -join ' ')"
    }
}

try {
    Invoke-Docker @('build', '--pull', '--tag', $ImageTag, '--file', $dockerfile, $projectOneApp)

    $existing = & $dockerExecutable ps --all --quiet --filter "name=^/$ContainerName$"
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not inspect existing local validation container.'
    }
    if ($existing) {
        Invoke-Docker @('rm', '--force', $ContainerName)
    }

    Invoke-Docker @('run', '--detach', '--name', $ContainerName, '--publish', '127.0.0.1::3000', $ImageTag)

    $port = (& $dockerExecutable port $ContainerName 3000/tcp).Trim() -replace '^127\.0\.0\.1:', ''
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($port)) {
        throw 'Could not determine the local mapped container port.'
    }

    $healthUri = "http://127.0.0.1:$port/health"
    $healthy = $false
    for ($attempt = 1; $attempt -le 15; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $healthUri -TimeoutSec 2
            if ($response.status -eq 'ok') {
                $healthy = $true
                break
            }
        } catch {
            Start-Sleep -Seconds 1
        }
    }
    if (-not $healthy) {
        throw "Container health endpoint did not return status=ok: $healthUri"
    }

    [PSCustomObject]@{
        Image = $ImageTag
        Container = $ContainerName
        HealthEndpoint = $healthUri
        Result = 'Container build and health check passed'
    }
}
finally {
    $running = & $dockerExecutable ps --all --quiet --filter "name=^/$ContainerName$"
    if ($LASTEXITCODE -eq 0 -and $running) {
        & $dockerExecutable rm --force $ContainerName | Out-Null
    }
}
