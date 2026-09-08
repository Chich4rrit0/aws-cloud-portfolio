[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$distributionComment = 'Project 01 Task Manager frontend and API delivery'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run - no public request or temporary task will be created'
        Checks = 'HTTPS frontend, /health, and create/read/delete through /api/tasks'
        Cleanup = 'The temporary task is deleted at the end of a successful validation'
    }
    return
}

$distributions = Invoke-AwsJson -Arguments @('cloudfront', 'list-distributions')
$distribution = @($distributions.DistributionList.Items | Where-Object { $_.Comment -eq $distributionComment } | Select-Object -First 1)[0]
if ($null -eq $distribution -or $distribution.Status -ne 'Deployed') {
    throw 'The Project 01 CloudFront distribution is not deployed.'
}

$baseUri = "https://$($distribution.DomainName)"
$frontend = Invoke-WebRequest -Uri "$baseUri/" -UseBasicParsing -TimeoutSec 30
$health = Invoke-RestMethod -Uri "$baseUri/health" -Method Get -TimeoutSec 30
$created = Invoke-RestMethod -Uri "$baseUri/api/tasks" -Method Post -ContentType 'application/json' -Body '{"title":"CloudFront validation","description":"temporary end-to-end check","status":"todo"}' -TimeoutSec 30
$taskId = $created.task.id

try {
    $read = Invoke-RestMethod -Uri "$baseUri/api/tasks/$taskId" -Method Get -TimeoutSec 30
    if ($read.task.id -ne $taskId) { throw 'The API did not return the task created through CloudFront.' }
}
finally {
    if ($taskId) {
        Invoke-WebRequest -Uri "$baseUri/api/tasks/$taskId" -Method Delete -UseBasicParsing -TimeoutSec 30 | Out-Null
    }
}

[PSCustomObject]@{
    FrontendHttps = ($frontend.StatusCode -eq 200 -and $frontend.Content -match 'Task Manager')
    HealthThroughCloudFront = ($health.status -eq 'ok')
    PostgresCrudThroughCloudFront = $true
    TemporaryTaskRemoved = $true
}
