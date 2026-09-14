[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$StackName = 'portfolio-p05-observability',
    [switch]$Deploy
)

$ErrorActionPreference = 'Stop'
$templatePath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\infrastructure\cloudformation\observability-baseline.yaml')).Path

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $output = & aws @Arguments --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments[0..1] -join ' ')"
    }

    return ($output -join "`n") | ConvertFrom-Json
}

$identity = Invoke-AwsJson @('sts', 'get-caller-identity')
$budget = Invoke-AwsJson @('budgets', 'describe-budget', '--account-id', $identity.Account, '--budget-name', 'portfolio-zero-spend')
$dashboards = Invoke-AwsJson @('cloudwatch', 'list-dashboards')
$alarms = Invoke-AwsJson @('cloudwatch', 'describe-alarms')

$p2Api = (Invoke-AwsJson @('apigatewayv2', 'get-apis')).Items | Where-Object { $_.Name -eq 'portfolio-p02-link-shortener-api' } | Select-Object -First 1
if (-not $p2Api) { throw 'Expected Project 2 HTTP API was not found. Stopping without deployment.' }
$p2Stage = (Invoke-AwsJson @('apigatewayv2', 'get-stages', '--api-id', $p2Api.ApiId)).Items | Where-Object { $_.StageName -eq '$default' } | Select-Object -First 1
if (-not $p2Stage) { throw 'Expected Project 2 $default HTTP API stage was not found. Stopping without deployment.' }

$p2Function = Invoke-AwsJson @('lambda', 'get-function-configuration', '--function-name', 'portfolio-p02-link-shortener')
$p2Table = Invoke-AwsJson @('dynamodb', 'describe-table', '--table-name', 'portfolio-p02-links')
$p4Stack = Invoke-AwsJson @('cloudformation', 'describe-stacks', '--stack-name', 'portfolio-p04-ecs-lab')
$p4Service = Invoke-AwsJson @('ecs', 'describe-services', '--cluster', 'portfolio-p04-ecs-lab', '--services', 'portfolio-p04-task-manager')
$p4LoadBalancer = Invoke-AwsJson @('elbv2', 'describe-load-balancers', '--names', 'portfolio-p04-ecs-lab-alb')
$p4TargetGroup = Invoke-AwsJson @('elbv2', 'describe-target-groups', '--names', 'portfolio-p04-ecs-lab-tg')
$p4LoadBalancerFullName = ($p4LoadBalancer.LoadBalancers[0].LoadBalancerArn -split 'loadbalancer/', 2)[1]
$p4TargetGroupFullName = ($p4TargetGroup.TargetGroups[0].TargetGroupArn -split 'targetgroup/', 2)[1]

if ($p2Function.State -ne 'Active' -or $p2Table.Table.TableStatus -ne 'ACTIVE' -or $p4Stack.Stacks[0].StackStatus -notmatch 'COMPLETE' -or $p4Service.services[0].runningCount -ne 1 -or [string]::IsNullOrWhiteSpace($p4LoadBalancerFullName) -or [string]::IsNullOrWhiteSpace($p4TargetGroupFullName)) {
    throw 'One or more source resources are not healthy enough for this baseline. Stopping without deployment.'
}

$existingDashboardCount = @($dashboards.DashboardEntries).Count
$existingAlarmMetricCount = @($alarms.MetricAlarms).Count
Write-Host "Budget actual spend: USD $($budget.Budget.CalculatedSpend.ActualSpend.Amount) of USD $($budget.Budget.BudgetLimit.Amount)."
Write-Host "Current custom dashboards: $existingDashboardCount; current metric alarms: $existingAlarmMetricCount."
Write-Host 'Baseline adds one dashboard and three alarm resources using four standard-resolution metric alarms.'

if (-not $Deploy) {
    Write-Host 'Preflight passed. No CloudWatch resources were created. Re-run with -Deploy after explicit approval.'
    return
}

$existingStack = & aws cloudformation describe-stacks --stack-name $StackName --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
if ($LASTEXITCODE -eq 0) { throw "Stack '$StackName' already exists. This script intentionally does not update it." }
if (($existingStack -join "`n") -notmatch 'does not exist') { throw 'Could not safely determine whether the Project 5 stack exists.' }

& aws cloudformation deploy `
    --stack-name $StackName `
    --template-file $templatePath `
    --parameter-overrides `
      "P2FunctionName=$($p2Function.FunctionName)" `
      "P2HttpApiId=$($p2Api.ApiId)" `
      "P2HttpApiStage=$($p2Stage.StageName)" `
      "P2TableName=$($p2Table.Table.TableName)" `
      'P4ClusterName=portfolio-p04-ecs-lab' `
      'P4ServiceName=portfolio-p04-task-manager' `
      "P4LoadBalancerFullName=$p4LoadBalancerFullName" `
      "P4TargetGroupFullName=$p4TargetGroupFullName" `
      'P4UnhealthyTargetAlarmName=portfolio-p04-ecs-lab-unhealthy-target' `
      'P4CpuAlarmName=portfolio-p04-ecs-lab-high-cpu' `
    --tags Project=aws-cloud-portfolio ProjectNumber=05 Environment=observability-lab ManagedBy=CloudFormation `
    --region $Region `
    --profile $ProfileName `
    --no-cli-pager

if ($LASTEXITCODE -ne 0) { throw 'CloudFormation deployment failed. Inspect stack events before attempting a correction.' }

Write-Host "Stack '$StackName' deployment completed. Run Test-Project05Baseline.ps1 to verify it."
