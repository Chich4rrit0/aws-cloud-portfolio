[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',
    [string]$BudgetName = 'portfolio-zero-spend',
    [string]$ProjectPrefix = 'portfolio-p03-e2e',
    [string]$E2eVpcCidr = '10.30.0.0/16',
    [string]$CloudFrontOriginPrefixListId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-AwsJson {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $json = & aws @Arguments --profile $ProfileName --region $Region --no-cli-pager --output json
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments[0..([Math]::Min(1, $Arguments.Count - 1))] -join ' ')"
    }
    return ($json | ConvertFrom-Json)
}

function Get-AwsText {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $value = (& aws @Arguments --profile $ProfileName --region $Region --no-cli-pager --output text | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments[0..([Math]::Min(1, $Arguments.Count - 1))] -join ' ')"
    }
    return $value
}

$identity = Get-AwsJson @('sts', 'get-caller-identity')
$plan = Get-AwsJson @('freetier', 'get-account-plan-state')
$budget = Get-AwsJson @(
    'budgets', 'describe-budgets',
    '--account-id', $identity.Account,
    '--query', "Budgets[?BudgetName==``$BudgetName``] | [0].{Name:BudgetName,Limit:BudgetLimit.Amount,Actual:CalculatedSpend.ActualSpend.Amount,Forecast:CalculatedSpend.ForecastedSpend.Amount}"
)
$vpcCidrs = @(Get-AwsJson @('ec2', 'describe-vpcs', '--query', 'Vpcs[].CidrBlock'))
$prefixLists = @(Get-AwsJson @(
    'ec2', 'describe-managed-prefix-lists',
    '--filters', 'Name=owner-id,Values=AWS',
    '--query', 'Entries[].{Name:PrefixListName,Id:PrefixListId,State:State}'
))
$cloudFrontPrefixList = @($prefixLists | Where-Object {
    $null -ne $_ -and $_.PSObject.Properties['Name'] -and $_.Name -eq 'com.amazonaws.global.cloudfront.origin-facing'
})
$prefixListDiscovered = ($cloudFrontPrefixList.Count -eq 1 -and $cloudFrontPrefixList[0].State -eq 'create-complete')
$prefixListSuppliedFromConsole = (-not [string]::IsNullOrWhiteSpace($CloudFrontOriginPrefixListId) -and $CloudFrontOriginPrefixListId -match '^pl-[0-9a-f]+$')
$postgres183Count = [int](Get-AwsText @(
    'rds', 'describe-db-engine-versions',
    '--engine', 'postgres',
    '--engine-version', '18.3',
    '--query', 'length(DBEngineVersions)'
))
$existingE2eResourceCount = [int](Get-AwsText @(
    'resourcegroupstaggingapi', 'get-resources',
    '--tag-filters', 'Key=ProjectNumber,Values=03', 'Key=Environment,Values=e2e',
    '--query', 'length(ResourceTagMappingList)'
))

$checks = @(
    [PSCustomObject]@{ Name = 'AWS identity'; Passed = [bool]$identity.Arn; Detail = 'Authenticated profile; ARN intentionally not displayed.' }
    [PSCustomObject]@{ Name = 'Free plan'; Passed = ($plan.accountPlanType -eq 'FREE' -and $plan.accountPlanStatus -eq 'ACTIVE'); Detail = "$($plan.accountPlanType)/$($plan.accountPlanStatus)" }
    [PSCustomObject]@{ Name = 'Budget alert'; Passed = ($null -ne $budget.Name); Detail = if ($budget.Name) { "$($budget.Name): limit USD $($budget.Limit), actual USD $($budget.Actual)" } else { 'Required budget not found.' } }
    [PSCustomObject]@{ Name = 'E2E CIDR available'; Passed = -not ($vpcCidrs -contains $E2eVpcCidr); Detail = $E2eVpcCidr }
    [PSCustomObject]@{ Name = 'CloudFront prefix list'; Passed = ($prefixListDiscovered -or $prefixListSuppliedFromConsole); Detail = if ($prefixListDiscovered) { "$($cloudFrontPrefixList[0].Name): $($cloudFrontPrefixList[0].State)" } elseif ($prefixListSuppliedFromConsole) { 'Verified manually in the VPC console; the supplied ID is intentionally not displayed or persisted.' } else { 'AWS-managed prefix list was not discoverable by this CLI query and no console-verified ID was supplied.' } }
    [PSCustomObject]@{ Name = 'PostgreSQL 18.3'; Passed = ($postgres183Count -gt 0); Detail = "Available versions returned: $postgres183Count" }
    [PSCustomObject]@{ Name = 'No E2E-tagged resources'; Passed = ($existingE2eResourceCount -eq 0); Detail = "Tagged resource count: $existingE2eResourceCount" }
)

$checks | Format-Table -AutoSize

[PSCustomObject]@{
    Mode = 'Read-only AWS preflight'
    Region = $Region
    ProjectPrefix = $ProjectPrefix
    RemainingCreditsUsd = $plan.accountPlanRemainingCredits.amount
    CreditExpirationUtc = $plan.accountPlanExpirationDate
    OverallReady = -not ($checks.Passed -contains $false)
    BlockingChecks = @($checks | Where-Object { -not $_.Passed } | Select-Object -ExpandProperty Name)
}
