[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$StackName = 'portfolio-p04-ecs-lab'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')
$workflowPath = Join-Path $projectRoot '..\..\.github\workflows\project-04-deploy-ecs.yml'

if (-not (Test-Path -LiteralPath $workflowPath)) {
    throw 'The Project 04 ECS deployment workflow was not found.'
}

$workflow = Get-Content -LiteralPath $workflowPath -Raw
foreach ($requiredText in @('workflow_dispatch:', 'AWS_P04_ECS_DEPLOY_ROLE_ARN', 'register-task-definition', 'update-service', 'rolloutState', '15 minutes')) {
    if ($workflow -notmatch [regex]::Escape($requiredText)) {
        throw "Workflow is missing required CD control: $requiredText"
    }
}

$stack = & aws cloudformation describe-stacks --stack-name $StackName --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
if ($LASTEXITCODE -ne 0) {
    throw 'AWS CLI failed to describe the temporary lab stack.'
}
$stackJson = ($stack -join "`n") | ConvertFrom-Json
if ($stackJson.Stacks[0].StackStatus -ne 'UPDATE_COMPLETE') {
    throw "Expected UPDATE_COMPLETE but received $($stackJson.Stacks[0].StackStatus)."
}

$alarms = & aws cloudwatch describe-alarms --alarm-name-prefix 'portfolio-p04-ecs-lab' --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
if ($LASTEXITCODE -ne 0) {
    throw 'AWS CLI failed to describe the Project 4 alarms.'
}
$alarmNames = @((($alarms -join "`n") | ConvertFrom-Json).MetricAlarms.AlarmName)
foreach ($expectedAlarm in @('portfolio-p04-ecs-lab-high-cpu', 'portfolio-p04-ecs-lab-unhealthy-target')) {
    if ($alarmNames -notcontains $expectedAlarm) {
        throw "Expected alarm was not found: $expectedAlarm"
    }
}

Write-Host 'CD artifacts validation passed: workflow controls, updated stack, and alarms are present.'
