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
$policyName = 'portfolio-p01-cpu-target-tracking-demo'
$loadUnitName = 'project-01-autoscaling-demo'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

function Invoke-AwsCommand {
    param([string[]]$Arguments)

    $output = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')`n$($output | Out-String)"
    }
    return $output
}

function Get-ApplicationGroup {
    $response = Invoke-AwsJson -Arguments @(
        'autoscaling', 'describe-auto-scaling-groups',
        '--auto-scaling-group-names', $autoScalingGroupName
    )
    $groups = @($response.AutoScalingGroups)
    if ($groups.Count -ne 1) {
        throw "Expected exactly one Auto Scaling Group named '$autoScalingGroupName'."
    }
    return $groups[0]
}

function Get-HealthyTargetCount {
    $targetGroupResponse = Invoke-AwsJson -Arguments @(
        'elbv2', 'describe-target-groups',
        '--names', $targetGroupName
    )
    $targetGroups = @($targetGroupResponse.TargetGroups)
    if ($targetGroups.Count -ne 1) {
        throw "Expected exactly one target group named '$targetGroupName'."
    }
    $targetHealth = Invoke-AwsJson -Arguments @(
        'elbv2', 'describe-target-health',
        '--target-group-arn', $targetGroups[0].TargetGroupArn
    )
    return @($targetHealth.TargetHealthDescriptions | Where-Object { $_.TargetHealth.State -eq 'healthy' }).Count
}

function Send-RunShellCommand {
    param(
        [string]$InstanceId,
        [string[]]$Commands,
        [string]$Comment
    )

    $parameters = @{ commands = $Commands } | ConvertTo-Json -Compress
    $parametersFile = New-TemporaryFile
    $utf8WithoutBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
    try {
        [System.IO.File]::WriteAllText($parametersFile, $parameters, $utf8WithoutBom)
        $command = Invoke-AwsJson -Arguments @(
            'ssm', 'send-command',
            '--instance-ids', $InstanceId,
            '--document-name', 'AWS-RunShellScript',
            '--parameters', "file://$parametersFile",
            '--comment', $Comment
        )
    }
    finally {
        Remove-Item -LiteralPath $parametersFile -Force -ErrorAction SilentlyContinue
    }

    $deadline = (Get-Date).AddMinutes(3)
    do {
        Start-Sleep -Seconds 5
        $invocation = Invoke-AwsJson -Arguments @(
            'ssm', 'get-command-invocation',
            '--command-id', $command.Command.CommandId,
            '--instance-id', $InstanceId
        )
    } while ($invocation.Status -in @('Pending', 'InProgress', 'Delayed') -and (Get-Date) -lt $deadline)

    if ($invocation.Status -ne 'Success') {
        throw "Session Manager command failed with status '$($invocation.Status)': $($invocation.StandardErrorContent)"
    }
}

function Remove-DemoPolicy {
    Invoke-AwsCommand -Arguments @(
        'autoscaling', 'delete-policy',
        '--auto-scaling-group-name', $autoScalingGroupName,
        '--policy-name', $policyName
    )
    Write-Host "Deleted temporary scaling policy $policyName."
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run - no scaling policy, load command, or Auto Scaling change will be made'
        Policy = "$policyName uses ASGAverageCPUUtilization with a target of 30%"
        Load = 'Two CPU workers via Session Manager, automatically limited to 15 minutes'
        Success = 'ASG reaches desired capacity 2 and both ALB targets become healthy'
        Cleanup = 'Stop load, wait up to 15 minutes for automatic scale-in to one, then delete the temporary policy'
        Safety = 'No third instance; no forced instance termination if automatic scale-in does not complete'
    }
    return
}

$group = Get-ApplicationGroup
if ($group.MinSize -ne 1 -or $group.DesiredCapacity -ne 1 -or $group.MaxSize -ne 2) {
    throw 'Demo requires ASG capacity min=1, desired=1, max=2 before it starts.'
}
if ($group.HealthCheckType -ne 'ELB') {
    throw 'Demo requires ELB health checks before it starts.'
}
$initialInstances = @($group.Instances | Where-Object { $_.LifecycleState -eq 'InService' -and $_.HealthStatus -eq 'Healthy' })
if ($initialInstances.Count -ne 1) {
    throw 'Demo requires exactly one healthy InService instance before it starts.'
}

$existingPolicies = Invoke-AwsJson -Arguments @(
    'autoscaling', 'describe-policies',
    '--auto-scaling-group-name', $autoScalingGroupName,
    '--policy-names', $policyName
)
if (@($existingPolicies.ScalingPolicies).Count -ne 0) {
    throw "Temporary policy '$policyName' already exists. Inspect or remove it before starting another demo."
}

$policyConfiguration = @{
    TargetValue = 30.0
    PredefinedMetricSpecification = @{
        PredefinedMetricType = 'ASGAverageCPUUtilization'
    }
    DisableScaleIn = $false
}
$configurationFile = New-TemporaryFile
$utf8WithoutBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
[System.IO.File]::WriteAllText(
    $configurationFile,
    ($policyConfiguration | ConvertTo-Json -Depth 6),
    $utf8WithoutBom
)

$policyCreated = $false
try {
    Invoke-AwsCommand -Arguments @(
        'autoscaling', 'put-scaling-policy',
        '--auto-scaling-group-name', $autoScalingGroupName,
        '--policy-name', $policyName,
        '--policy-type', 'TargetTrackingScaling',
        '--estimated-instance-warmup', '180',
        '--target-tracking-configuration', "file://$configurationFile"
    )
    $policyCreated = $true
    Write-Host "Created temporary target tracking policy $policyName."
}
finally {
    Remove-Item -LiteralPath $configurationFile -Force -ErrorAction SilentlyContinue
}

try {
    Send-RunShellCommand -InstanceId $initialInstances[0].InstanceId -Comment 'Start bounded Project 01 Auto Scaling CPU demonstration' -Commands @(
        'set -Eeuo pipefail',
        "systemctl stop $loadUnitName.service 2>/dev/null || true",
        ('systemd-run --unit={0} --collect --property=CPUQuota=200% /bin/bash -lc ''timeout 900s bash -c "yes > /dev/null & yes > /dev/null & wait"''' -f $loadUnitName),
        "systemctl is-active --quiet $loadUnitName.service",
        "printf 'Bounded CPU load started; it will stop automatically after 15 minutes.\\n'"
    )
    Write-Host 'Bounded CPU load is running. Waiting for ASG scale-out and two healthy ALB targets.'

    $scaleOutDeadline = (Get-Date).AddMinutes(20)
    $scaledOut = $false
    do {
        Start-Sleep -Seconds 30
        $currentGroup = Get-ApplicationGroup
        $healthyTargetCount = Get-HealthyTargetCount
        $inServiceCount = @($currentGroup.Instances | Where-Object { $_.LifecycleState -eq 'InService' -and $_.HealthStatus -eq 'Healthy' }).Count
        Write-Host "Scale-out status: desired=$($currentGroup.DesiredCapacity), healthy-in-service=$inServiceCount, healthy-targets=$healthyTargetCount."
        if ($currentGroup.DesiredCapacity -eq 2 -and $inServiceCount -ge 2 -and $healthyTargetCount -ge 2) {
            $scaledOut = $true
            break
        }
    } while ((Get-Date) -lt $scaleOutDeadline)

    if (-not $scaledOut) {
        Send-RunShellCommand -InstanceId $initialInstances[0].InstanceId -Comment 'Stop Project 01 Auto Scaling CPU demonstration after scale-out timeout' -Commands @(
            "systemctl stop $loadUnitName.service 2>/dev/null || true",
            "printf 'Bounded CPU load stopped.\\n'"
        )
        Remove-DemoPolicy
        throw 'Scale-out did not complete within 20 minutes. The temporary policy was removed; no forced capacity reduction was performed.'
    }

    Send-RunShellCommand -InstanceId $initialInstances[0].InstanceId -Comment 'Stop Project 01 Auto Scaling CPU demonstration after successful scale-out' -Commands @(
        "systemctl stop $loadUnitName.service 2>/dev/null || true",
        "printf 'Bounded CPU load stopped.\\n'"
    )
    Write-Host 'Scale-out verified. CPU load stopped; waiting for automatic scale-in.'

    $scaleInDeadline = (Get-Date).AddMinutes(15)
    $scaledIn = $false
    do {
        Start-Sleep -Seconds 30
        $currentGroup = Get-ApplicationGroup
        $healthyTargetCount = Get-HealthyTargetCount
        $inServiceCount = @($currentGroup.Instances | Where-Object { $_.LifecycleState -eq 'InService' -and $_.HealthStatus -eq 'Healthy' }).Count
        Write-Host "Scale-in status: desired=$($currentGroup.DesiredCapacity), healthy-in-service=$inServiceCount, healthy-targets=$healthyTargetCount."
        if ($currentGroup.DesiredCapacity -eq 1 -and $inServiceCount -eq 1 -and $healthyTargetCount -eq 1) {
            $scaledIn = $true
            break
        }
    } while ((Get-Date) -lt $scaleInDeadline)

    Remove-DemoPolicy
    if (-not $scaledIn) {
        throw 'Automatic scale-in did not complete within 15 minutes. The policy was removed, but capacity was not forced down; explicit approval is required before terminating any instance.'
    }

    $activities = Invoke-AwsJson -Arguments @(
        'autoscaling', 'describe-scaling-activities',
        '--auto-scaling-group-name', $autoScalingGroupName,
        '--max-records', '10'
    )
    $scaleOutActivity = @($activities.Activities | Where-Object { $_.Description -match 'Launching a new EC2 instance' } | Select-Object -First 1)
    $scaleInActivity = @($activities.Activities | Where-Object { $_.Description -match 'Terminating EC2 instance' } | Select-Object -First 1)

    [PSCustomObject]@{
        Demonstration = 'Passed'
        ScaleOut = 'ASG reached two healthy instances and two healthy ALB targets'
        ScaleIn = 'ASG returned automatically to one healthy instance and one healthy ALB target'
        TemporaryPolicy = 'Deleted after the demonstration'
        ScaleOutActivityRecorded = $scaleOutActivity.Count -eq 1
        ScaleInActivityRecorded = $scaleInActivity.Count -eq 1
    }
}
catch {
    if ($policyCreated) {
        $policyCheck = Invoke-AwsJson -Arguments @(
            'autoscaling', 'describe-policies',
            '--auto-scaling-group-name', $autoScalingGroupName,
            '--policy-names', $policyName
        )
        if (@($policyCheck.ScalingPolicies).Count -eq 1) {
            Write-Warning "Temporary policy '$policyName' still exists and must be removed after diagnosis."
        }
    }
    throw
}
