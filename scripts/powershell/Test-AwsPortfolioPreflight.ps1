[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-AwsJson {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $rawOutput = & aws @Arguments '--no-cli-pager' '--output' 'json'

    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }

    return $rawOutput | ConvertFrom-Json
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI was not found in PATH.'
}

$configuredRegion = (& aws configure get region --profile $ProfileName).Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Could not read the region for profile '$ProfileName'."
}

if ($configuredRegion -ne $Region) {
    throw "Profile '$ProfileName' is configured for '$configuredRegion', but this project expects '$Region'."
}

$identity = Invoke-AwsJson -Arguments @(
    'sts', 'get-caller-identity',
    '--profile', $ProfileName
)

$plan = Invoke-AwsJson -Arguments @(
    'freetier', 'get-account-plan-state',
    '--profile', $ProfileName
)

$usesRootSession = $identity.Arn -match ':root$'

if ($usesRootSession) {
    Write-Warning 'This profile uses a temporary root session. Do not store credentials in the repository or use this profile beyond the agreed lab bootstrap scope.'
}

[PSCustomObject]@{
    CheckedAtUtc      = (Get-Date).ToUniversalTime().ToString('o')
    TargetRegion      = $Region
    Authentication    = 'Success'
    UsesRootSession   = $usesRootSession
    AccountPlan       = $plan.accountPlanType
    PlanStatus        = $plan.accountPlanStatus
    CreditsAvailable  = "$($plan.accountPlanRemainingCredits.amount) $($plan.accountPlanRemainingCredits.unit)"
    PlanExpirationUtc = $plan.accountPlanExpirationDate
}
