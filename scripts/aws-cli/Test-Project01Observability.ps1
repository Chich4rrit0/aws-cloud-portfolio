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
$targetGroupName = 'portfolio-p01-app-tg'
$logGroupName = '/aws/aws-cloud-portfolio/project-01/application'
$alarmName = 'portfolio-p01-alb-no-healthy-targets'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run - no SSM validation command will be sent'
        Checks = 'ASG capacity and ELB health check, healthy target, CloudWatch Agent, two log streams, and target-health alarm'
        NetworkExposure = 'None; the agent check runs through Session Manager'
    }
    return
}

$groups = Invoke-AwsJson -Arguments @(
    'autoscaling', 'describe-auto-scaling-groups',
    '--auto-scaling-group-names', $autoScalingGroupName
)
$matchingGroups = @($groups.AutoScalingGroups)
if ($matchingGroups.Count -ne 1) {
    throw "Expected exactly one Auto Scaling Group named '$autoScalingGroupName'."
}
$group = $matchingGroups[0]
if ($group.MinSize -ne 1 -or $group.DesiredCapacity -ne 1 -or $group.MaxSize -ne 2) {
    throw 'Expected ASG capacity min=1, desired=1, max=2.'
}
if ($group.HealthCheckType -ne 'ELB') {
    throw 'Expected the Auto Scaling Group to use ELB health checks.'
}
$healthyInstances = @($group.Instances | Where-Object {
    $_.LifecycleState -eq 'InService' -and $_.HealthStatus -eq 'Healthy'
})
if ($healthyInstances.Count -lt 1) {
    throw 'No healthy InService application instance exists.'
}
$instanceId = $healthyInstances[0].InstanceId

$targetGroups = Invoke-AwsJson -Arguments @(
    'elbv2', 'describe-target-groups',
    '--names', $targetGroupName
)
$matchingTargetGroups = @($targetGroups.TargetGroups)
if ($matchingTargetGroups.Count -ne 1) {
    throw "Expected exactly one target group named '$targetGroupName'."
}
$targetHealth = Invoke-AwsJson -Arguments @(
    'elbv2', 'describe-target-health',
    '--target-group-arn', $matchingTargetGroups[0].TargetGroupArn
)
if (@($targetHealth.TargetHealthDescriptions | Where-Object { $_.TargetHealth.State -eq 'healthy' }).Count -lt 1) {
    throw 'No healthy target is registered behind the Application Load Balancer.'
}

$commands = @(
    'set -Eeuo pipefail',
    'systemctl is-active --quiet amazon-cloudwatch-agent',
    'test -s /opt/task-manager/cloudwatch-agent.json',
    'test -f /var/log/task-manager/application.log',
    "grep -Fq '$logGroupName' /opt/task-manager/cloudwatch-agent.json",
    "printf 'CloudWatch agent configuration: passed.\\n'"
)
$parameters = @{ commands = $commands } | ConvertTo-Json -Compress
$command = Invoke-AwsJson -Arguments @(
    'ssm', 'send-command',
    '--instance-ids', $instanceId,
    '--document-name', 'AWS-RunShellScript',
    '--parameters', $parameters,
    '--comment', 'Validate Project 01 CloudWatch Agent configuration'
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
    throw "CloudWatch Agent validation failed with status '$($invocation.Status)': $($invocation.StandardErrorContent)"
}

$logStreams = Invoke-AwsJson -Arguments @(
    'logs', 'describe-log-streams',
    '--log-group-name', $logGroupName,
    '--order-by', 'LastEventTime',
    '--descending'
)
$streamNames = @($logStreams.logStreams | ForEach-Object { $_.logStreamName })
if (@($streamNames | Where-Object { $_ -like '*/application' }).Count -lt 1 -or
    @($streamNames | Where-Object { $_ -like '*/bootstrap' }).Count -lt 1) {
    throw 'Expected both application and bootstrap CloudWatch log streams.'
}

$alarms = Invoke-AwsJson -Arguments @(
    'cloudwatch', 'describe-alarms',
    '--alarm-names', $alarmName
)
$matchingAlarms = @($alarms.MetricAlarms)
if ($matchingAlarms.Count -ne 1) {
    throw "Expected exactly one alarm named '$alarmName'."
}
if ($matchingAlarms[0].ActionsEnabled) {
    throw 'The baseline alarm must not have actions enabled before a notification endpoint is approved.'
}

[PSCustomObject]@{
    Validation = 'Passed'
    AsgCapacity = 'min=1, desired=1, max=2'
    AsgHealthCheck = 'ELB'
    HealthyTarget = 'Passed'
    CloudWatchAgent = 'Passed through Session Manager'
    LogDelivery = 'Application and bootstrap streams found'
    Alarm = "$alarmName is $($matchingAlarms[0].StateValue) with actions disabled"
}
