[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$projectRoot = Join-Path $repositoryRoot 'projects\01-web-task-manager'
$appSource = Join-Path $projectRoot 'app'
$frontendSource = Join-Path $projectRoot 'frontend'

if (-not $Execute) {
    [PSCustomObject]@{
        Mode              = 'Dry run - no ZIP will be uploaded'
        AppSource         = $appSource
        FrontendSource    = $frontendSource
        DestinationPrefix = 's3://portfolio-p01-artifacts-<account-id>-<region>/releases/'
        Excluded          = 'node_modules and local .env files'
    }
    return
}

if (-not (Test-Path -LiteralPath $appSource) -or -not (Test-Path -LiteralPath $frontendSource)) {
    throw 'Expected Project 01 app and frontend directories were not found.'
}

$accountId = (& aws sts get-caller-identity '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--query' 'Account' '--output' 'text')
if ($LASTEXITCODE -ne 0) {
    throw 'Could not determine the AWS account for the artifact bucket.'
}
$bucketName = "portfolio-p01-artifacts-$accountId-$Region"
$commit = (git -C $repositoryRoot rev-parse --short HEAD).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Could not determine the current Git commit for the artifact name.'
}

$artifactDirectory = Join-Path $repositoryRoot 'shared\artifacts'
$stagingDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "project-01-artifact-$commit"
$archivePath = Join-Path $artifactDirectory "task-manager-$commit.zip"

try {
New-Item -ItemType Directory -Path $artifactDirectory, $stagingDirectory, (Join-Path $stagingDirectory 'app') -Force | Out-Null
    Get-ChildItem -LiteralPath $appSource -Force | Where-Object { $_.Name -notin @('node_modules', '.env', '.env.local') } | Copy-Item -Destination (Join-Path $stagingDirectory 'app') -Recurse -Force
    Copy-Item -LiteralPath $frontendSource -Destination (Join-Path $stagingDirectory 'frontend') -Recurse -Force
    Compress-Archive -Path (Join-Path $stagingDirectory 'app'), (Join-Path $stagingDirectory 'frontend') -DestinationPath $archivePath -Force

    $objectKey = "releases/task-manager-$commit.zip"
    $upload = & aws s3api put-object '--bucket' $bucketName '--key' $objectKey '--body' $archivePath '--server-side-encryption' 'AES256' '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw 'Artifact upload failed.'
    }

    [PSCustomObject]@{
        Artifact          = $archivePath
        Sha256            = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
        S3Object          = "s3://$bucketName/$objectKey"
        UploadResult      = $upload | ConvertFrom-Json
    }
}
finally {
    if (Test-Path -LiteralPath $stagingDirectory) {
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
    }
}
