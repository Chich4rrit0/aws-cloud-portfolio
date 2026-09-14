[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$StackName = 'portfolio-p05-observability'
)

$ErrorActionPreference = 'Stop'

function Invoke-AwsJson {
    param([string[]]$Arguments)
    $output = & aws @Arguments --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "AWS CLI failed: aws $($Arguments[0..1] -join ' ')" }
    return ($output -join "`n") | ConvertFrom-Json
}

$stack = Invoke-AwsJson @('cloudformation', 'describe-stacks', '--stack-name', $StackName)
if ($stack.Stacks[0].StackStatus -ne 'CREATE_COMPLETE') { throw "Expected CREATE_COMPLETE but received $($stack.Stacks[0].StackStatus)." }

$dashboard = Invoke-AwsJson @('cloudwatch', 'get-dashboard', '--dashboard-name', 'portfolio-p05-observability')
if ($dashboard.DashboardBody -notmatch 'P2 Lambda health' -or $dashboard.DashboardBody -notmatch 'P4 ALB availability') { throw 'Dashboard does not contain the expected P2 and P4 panels.' }

$expectedAlarms = @('portfolio-p05-p02-lambda-errors', 'portfolio-p05-p02-http-api-5xx', 'portfolio-p05-p02-dynamodb-throttles')
$alarms = Invoke-AwsJson @('cloudwatch', 'describe-alarms', '--alarm-names', $expectedAlarms)
if (@($alarms.MetricAlarms).Count -ne $expectedAlarms.Count) { throw 'One or more expected P5 alarms are missing.' }
if (@($alarms.MetricAlarms | Where-Object { @($_.AlarmActions).Count -gt 0 }).Count -ne 0) { throw 'A P5 alarm unexpectedly has an automated action.' }

$queries = Invoke-AwsJson @('logs', 'describe-query-definitions', '--query-definition-name-prefix', 'portfolio-p05-')
if (@($queries.queryDefinitions | Where-Object { $_.name -in @('portfolio-p05-p02-lambda-errors', 'portfolio-p05-p04-ecs-task-events') }).Count -ne 2) { throw 'One or more expected saved Logs Insights query definitions are missing.' }

Write-Host 'Project 5 baseline validation passed: dashboard, three no-action alarms, and two saved queries are present.'
