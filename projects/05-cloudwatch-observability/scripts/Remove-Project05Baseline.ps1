[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$StackName = 'portfolio-p05-observability',
    [switch]$Destroy
)

$ErrorActionPreference = 'Stop'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $output = & aws @Arguments --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments[0..1] -join ' ')"
    }

    return ($output -join "`n") | ConvertFrom-Json
}

$stack = Invoke-AwsJson @('cloudformation', 'describe-stacks', '--stack-name', $StackName)
if ($stack.Stacks[0].StackStatus -notmatch 'COMPLETE') {
    throw "Stack '$StackName' is not in a stable COMPLETE state. Review its events before any deletion."
}

$resources = Invoke-AwsJson @('cloudformation', 'describe-stack-resources', '--stack-name', $StackName)
$expectedTypes = @(
    'AWS::CloudWatch::Dashboard',
    'AWS::CloudWatch::Alarm',
    'AWS::Logs::QueryDefinition'
)

if (@($resources.StackResources | Where-Object { $_.ResourceType -notin $expectedTypes }).Count -gt 0) {
    throw "Stack '$StackName' contains an unexpected resource type. Stopping without deletion."
}

Write-Host "Stack '$StackName' is $($stack.Stacks[0].StackStatus)."
Write-Host 'Resources in scope:'
$resources.StackResources |
    Select-Object LogicalResourceId, ResourceType, ResourceStatus |
    Format-Table -AutoSize |
    Out-Host

if (-not $Destroy) {
    Write-Host 'Preview completed. No AWS resources were deleted. Re-run with -Destroy only after explicit approval.'
    return
}

if (-not $PSCmdlet.ShouldProcess("CloudFormation stack '$StackName'", 'Delete Project 5 observability resources')) {
    Write-Host 'Deletion was not confirmed. No AWS resources were deleted.'
    return
}

& aws cloudformation delete-stack --stack-name $StackName --region $Region --profile $ProfileName --no-cli-pager
if ($LASTEXITCODE -ne 0) {
    throw "AWS CLI failed to delete stack '$StackName'."
}

& aws cloudformation wait stack-delete-complete --stack-name $StackName --region $Region --profile $ProfileName --no-cli-pager
if ($LASTEXITCODE -ne 0) {
    throw "Stack '$StackName' did not reach DELETE_COMPLETE. Inspect CloudFormation events before retrying."
}

$alarms = Invoke-AwsJson @('cloudwatch', 'describe-alarms', '--alarm-name-prefix', 'portfolio-p05-')
$dashboards = Invoke-AwsJson @('cloudwatch', 'list-dashboards', '--dashboard-name-prefix', 'portfolio-p05-')
$queries = Invoke-AwsJson @('logs', 'describe-query-definitions', '--query-definition-name-prefix', 'portfolio-p05-')

if (@($alarms.MetricAlarms).Count -ne 0 -or @($dashboards.DashboardEntries).Count -ne 0 -or @($queries.queryDefinitions).Count -ne 0) {
    throw 'CloudFormation deleted the stack, but one or more P5 CloudWatch resources remain. Inspect before taking further action.'
}

Write-Host 'Teardown completed. No Project 5 dashboard, alarms, or saved queries remain.'
