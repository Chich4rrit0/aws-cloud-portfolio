[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$autoScalingGroupName = 'portfolio-p01-app-asg'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

function Get-ApplicationInstanceId {
    $group = Invoke-AwsJson -Arguments @(
        'autoscaling', 'describe-auto-scaling-groups',
        '--auto-scaling-group-names', $autoScalingGroupName
    )
    $instance = @($group.AutoScalingGroups[0].Instances | Where-Object { $_.LifecycleState -eq 'InService' } | Select-Object -First 1)[0]
    if ($null -eq $instance) {
        throw "No InService instance exists in Auto Scaling Group '$autoScalingGroupName'."
    }
    return $instance.InstanceId
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run - no remote validation command will be sent'
        AutoScalingGroup = $autoScalingGroupName
        Checks = 'localhost health endpoint, PostgreSQL-backed create/read/delete, temporary task removed'
        NetworkExposure = 'None; the validation runs through Session Manager'
    }
    return
}

$instanceId = Get-ApplicationInstanceId
$instanceInformation = Invoke-AwsJson -Arguments @(
    'ssm', 'describe-instance-information',
    '--filters', "Key=InstanceIds,Values=$instanceId"
)
if (@($instanceInformation.InstanceInformationList)[0].PingStatus -ne 'Online') {
    throw 'The application instance is not online in Session Manager.'
}

$validationScript = @'
set -Eeuo pipefail

curl --fail --silent --show-error http://127.0.0.1:3000/health
validation_task="$(curl --fail --silent --show-error --request POST http://127.0.0.1:3000/api/tasks --header 'Content-Type: application/json' --data '{"title":"deployment validation","description":"temporary check","status":"todo"}')"
validation_id="$(node -e 'const data = JSON.parse(process.argv[1]); process.stdout.write(data.task.id)' "$validation_task")"
curl --fail --silent --show-error "http://127.0.0.1:3000/api/tasks/$validation_id" >/dev/null
curl --fail --silent --show-error --request DELETE "http://127.0.0.1:3000/api/tasks/$validation_id" >/dev/null
printf '\nDatabase CRUD validation: passed; temporary task removed.\n'
'@

$parameters = @{ commands = @($validationScript) } | ConvertTo-Json -Compress
$command = Invoke-AwsJson -Arguments @(
    'ssm', 'send-command',
    '--instance-ids', $instanceId,
    '--document-name', 'AWS-RunShellScript',
    '--parameters', $parameters,
    '--comment', 'Validate Project 01 Task Manager API and PostgreSQL CRUD'
)

$deadline = (Get-Date).AddMinutes(3)
do {
    Start-Sleep -Seconds 5
    $invocation = Invoke-AwsJson -Arguments @(
        'ssm', 'get-command-invocation',
        '--command-id', $command.Command.CommandId,
        '--instance-id', $instanceId
    )
} while ($invocation.Status -in @('Pending', 'InProgress', 'Delayed') -and (Get-Date) -lt $deadline)

if ($invocation.Status -ne 'Success') {
    throw "Remote validation failed with status '$($invocation.Status)': $($invocation.StandardErrorContent)"
}

[PSCustomObject]@{
    Validation = 'Passed'
    HealthEndpoint = 'Passed through localhost'
    PostgresCrud = 'Passed; temporary task removed'
    NetworkExposure = 'No inbound rule was added'
}
