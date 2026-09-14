[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$StackName = 'portfolio-p04-ecs-lab'
)

$ErrorActionPreference = 'Stop'

function Invoke-AwsCli {
    param([string[]]$CliArguments)

    $output = & aws @CliArguments --profile $ProfileName --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($CliArguments[0..1] -join ' ')"
    }

    return ($output -join "`n")
}

$stack = Invoke-AwsCli -CliArguments @('cloudformation', 'describe-stacks', '--stack-name', $StackName, '--region', $Region) | ConvertFrom-Json
$outputs = @{}
$stack.Stacks[0].Outputs | ForEach-Object { $outputs[$_.OutputKey] = $_.OutputValue }

$service = Invoke-AwsCli -CliArguments @(
    'ecs', 'describe-services',
    '--cluster', $outputs.ClusterName,
    '--services', $outputs.ServiceName,
    '--region', $Region
) | ConvertFrom-Json
$targetHealth = Invoke-AwsCli -CliArguments @(
    'elbv2', 'describe-target-health',
    '--target-group-arn', $outputs.TargetGroupArn,
    '--region', $Region
) | ConvertFrom-Json
$health = Invoke-RestMethod -Uri "http://$($outputs.LoadBalancerDnsName)/health" -TimeoutSec 15

if ($health.status -ne 'ok' -or $service.services[0].runningCount -ne 1 -or
    (@($targetHealth.TargetHealthDescriptions | Where-Object { $_.TargetHealth.State -eq 'healthy' }).Count -lt 1)) {
    throw 'Runtime validation failed: health endpoint, ECS running count, or ALB target health was not as expected.'
}

Write-Host "Runtime validation passed: endpoint, ECS service, and ALB target are healthy."
