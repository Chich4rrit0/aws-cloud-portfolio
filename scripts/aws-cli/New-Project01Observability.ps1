[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute,

    [switch]$WaitForRefresh,

    [switch]$SkipLaunchTemplateUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$logGroupName = '/aws/aws-cloud-portfolio/project-01/application'
$logRetentionDays = 7
$roleName = 'portfolio-p01-ec2-role'
$rolePolicyName = 'Project01WriteApplicationLogs'
$autoScalingGroupName = 'portfolio-p01-app-asg'
$loadBalancerName = 'portfolio-p01-app-alb'
$targetGroupName = 'portfolio-p01-app-tg'
$alarmName = 'portfolio-p01-alb-no-healthy-targets'
$commonTags = @(
    @{ Key = 'Project'; Value = 'aws-cloud-portfolio' },
    @{ Key = 'ProjectNumber'; Value = '01' },
    @{ Key = 'Environment'; Value = 'development' },
    @{ Key = 'ManagedBy'; Value = 'aws-cli' }
)

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

function Get-ExactlyOne {
    param(
        [object[]]$Items,
        [string]$Description
    )

    if (@($Items).Count -ne 1) {
        throw "Expected exactly one $Description; found $(@($Items).Count)."
    }
    return @($Items)[0]
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run - no CloudWatch, IAM or Auto Scaling changes will be made'
        LogGroup = "$logGroupName (Standard, $logRetentionDays-day retention)"
        IamPolicy = "$rolePolicyName grants log delivery only to the Project 01 log group"
        Alarm = "${alarmName}: HealthyHostCount Minimum < 1 for 2 x 60-second periods; no action configured"
        Replacement = if ($SkipLaunchTemplateUpdate) { 'Reuse the current CloudWatch-enabled template and run an instance refresh with 100% minimum healthy capacity' } else { 'New launch template version and instance refresh with 100% minimum healthy capacity; ASG remains min=1, desired=1, max=2' }
    }
    return
}

$identity = Invoke-AwsJson -Arguments @('sts', 'get-caller-identity')
$accountId = $identity.Account
$logGroupArn = "arn:aws:logs:${Region}:${accountId}:log-group:${logGroupName}"
$logStreamArn = "${logGroupArn}:log-stream:*"

$logGroups = Invoke-AwsJson -Arguments @(
    'logs', 'describe-log-groups',
    '--log-group-name-prefix', $logGroupName
)
$matchingLogGroups = @($logGroups.logGroups | Where-Object { $_.logGroupName -eq $logGroupName })
if ($matchingLogGroups.Count -eq 0) {
    Invoke-AwsCommand -Arguments @('logs', 'create-log-group', '--log-group-name', $logGroupName)
    Write-Host "Created log group $logGroupName."
}
elseif ($matchingLogGroups.Count -ne 1) {
    throw "Expected zero or one log group named '$logGroupName'; found $($matchingLogGroups.Count)."
}
else {
    Write-Host "Reusing log group $logGroupName."
}

Invoke-AwsCommand -Arguments @(
    'logs', 'put-retention-policy',
    '--log-group-name', $logGroupName,
    '--retention-in-days', $logRetentionDays
)

$tagMap = @{}
foreach ($tag in $commonTags) { $tagMap[$tag.Key] = $tag.Value }
$tagFile = New-TemporaryFile
try {
    $utf8WithoutBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
    [System.IO.File]::WriteAllText($tagFile, ($tagMap | ConvertTo-Json -Compress), $utf8WithoutBom)
    Invoke-AwsCommand -Arguments @(
        'logs', 'tag-resource',
        '--resource-arn', $logGroupArn,
        '--tags', "file://$tagFile"
    )
}
finally {
    Remove-Item -LiteralPath $tagFile -Force -ErrorAction SilentlyContinue
}

$logPolicy = @{
    Version = '2012-10-17'
    Statement = @(
        @{
            Sid = 'DescribeProjectLogGroups'
            Effect = 'Allow'
            Action = @('logs:DescribeLogGroups')
            Resource = '*'
        },
        @{
            Sid = 'WriteProjectApplicationLogs'
            Effect = 'Allow'
            Action = @('logs:CreateLogStream', 'logs:DescribeLogStreams', 'logs:PutLogEvents')
            Resource = $logStreamArn
        }
    )
}
$policyFile = New-TemporaryFile
try {
    [System.IO.File]::WriteAllText($policyFile, ($logPolicy | ConvertTo-Json -Depth 8), $utf8WithoutBom)
    Invoke-AwsCommand -Arguments @(
        'iam', 'put-role-policy',
        '--role-name', $roleName,
        '--policy-name', $rolePolicyName,
        '--policy-document', "file://$policyFile"
    )
}
finally {
    Remove-Item -LiteralPath $policyFile -Force -ErrorAction SilentlyContinue
}

$loadBalancerResponse = Invoke-AwsJson -Arguments @(
    'elbv2', 'describe-load-balancers',
    '--names', $loadBalancerName
)
$loadBalancer = Get-ExactlyOne -Items @($loadBalancerResponse.LoadBalancers) -Description "Application Load Balancer '$loadBalancerName'"
if ($loadBalancer.State.Code -ne 'active') {
    throw "Application Load Balancer '$loadBalancerName' must be active."
}

$targetGroupResponse = Invoke-AwsJson -Arguments @(
    'elbv2', 'describe-target-groups',
    '--names', $targetGroupName
)
$targetGroup = Get-ExactlyOne -Items @($targetGroupResponse.TargetGroups) -Description "target group '$targetGroupName'"

$loadBalancerDimension = $loadBalancer.LoadBalancerArn.Split(':')[-1].Replace('loadbalancer/', '')
$targetGroupDimension = $targetGroup.TargetGroupArn.Split(':')[-1]

Invoke-AwsCommand -Arguments @(
    'cloudwatch', 'put-metric-alarm',
    '--alarm-name', $alarmName,
    '--alarm-description', 'Project 01 ALB has no healthy application targets for two consecutive minutes.',
    '--namespace', 'AWS/ApplicationELB',
    '--metric-name', 'HealthyHostCount',
    '--dimensions', "Name=LoadBalancer,Value=$loadBalancerDimension", "Name=TargetGroup,Value=$targetGroupDimension",
    '--statistic', 'Minimum',
    '--period', '60',
    '--evaluation-periods', '2',
    '--datapoints-to-alarm', '2',
    '--threshold', '1',
    '--comparison-operator', 'LessThanThreshold',
    '--treat-missing-data', 'notBreaching',
    '--no-actions-enabled',
    '--tags',
    'Key=Project,Value=aws-cloud-portfolio',
    'Key=ProjectNumber,Value=01',
    'Key=Environment,Value=development',
    'Key=ManagedBy,Value=aws-cli'
)

if (-not $SkipLaunchTemplateUpdate) {
    & (Join-Path $PSScriptRoot 'New-Project01ApplicationCompute.ps1') `
        -ProfileName $ProfileName `
        -Region $Region `
        -Execute `
        -CreateNewLaunchTemplateVersion `
        -EnableCloudWatchLogs
    if ($LASTEXITCODE -ne 0) {
        throw 'Creating the CloudWatch-enabled launch template version failed.'
    }
}
else {
    Write-Host 'Reusing the current CloudWatch-enabled launch template version.'
}

$groupResponse = Invoke-AwsJson -Arguments @(
    'autoscaling', 'describe-auto-scaling-groups',
    '--auto-scaling-group-names', $autoScalingGroupName
)
$group = Get-ExactlyOne -Items @($groupResponse.AutoScalingGroups) -Description "Auto Scaling Group '$autoScalingGroupName'"
if ($group.MinSize -ne 1 -or $group.DesiredCapacity -ne 1 -or $group.MaxSize -ne 2) {
    throw 'ASG capacity must remain min=1, desired=1, max=2 before the protected refresh.'
}

if ($SkipLaunchTemplateUpdate) {
    $launchTemplateVersion = $group.LaunchTemplate.Version
    $launchTemplateResponse = Invoke-AwsJson -Arguments @(
        'ec2', 'describe-launch-template-versions',
        '--launch-template-name', $group.LaunchTemplate.LaunchTemplateName,
        '--versions', $launchTemplateVersion
    )
    $launchTemplate = Get-ExactlyOne -Items @($launchTemplateResponse.LaunchTemplateVersions) -Description "launch template version '$launchTemplateVersion'"
    if ([string]::IsNullOrWhiteSpace($launchTemplate.LaunchTemplateData.UserData)) {
        throw 'The current launch template has no user data to configure CloudWatch Logs.'
    }
    $userData = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($launchTemplate.LaunchTemplateData.UserData))
    if ($userData -notmatch 'amazon-cloudwatch-agent' -or $userData -notmatch [regex]::Escape($logGroupName)) {
        throw 'The current launch template is not configured for the Project 01 CloudWatch log group.'
    }
}

Invoke-AwsCommand -Arguments @(
    'autoscaling', 'update-auto-scaling-group',
    '--auto-scaling-group-name', $autoScalingGroupName,
    '--health-check-type', 'ELB',
    '--health-check-grace-period', '300'
)

$refreshPreferences = @{
    MinHealthyPercentage = 100
    MaxHealthyPercentage = 200
    InstanceWarmup = 180
    SkipMatching = $false
} | ConvertTo-Json -Compress
$refreshPreferencesFile = New-TemporaryFile
try {
    [System.IO.File]::WriteAllText($refreshPreferencesFile, $refreshPreferences, $utf8WithoutBom)
    $refresh = Invoke-AwsJson -Arguments @(
        'autoscaling', 'start-instance-refresh',
        '--auto-scaling-group-name', $autoScalingGroupName,
        '--strategy', 'Rolling',
        '--preferences', "file://$refreshPreferencesFile"
    )
}
finally {
    Remove-Item -LiteralPath $refreshPreferencesFile -Force -ErrorAction SilentlyContinue
}

if ($WaitForRefresh) {
    $deadline = (Get-Date).AddMinutes(25)
    do {
        Start-Sleep -Seconds 15
        $refreshResponse = Invoke-AwsJson -Arguments @(
            'autoscaling', 'describe-instance-refreshes',
            '--auto-scaling-group-name', $autoScalingGroupName,
            '--instance-refresh-ids', $refresh.InstanceRefreshId
        )
        $refreshState = $refreshResponse.InstanceRefreshes[0]
        Write-Host "Instance refresh status: $($refreshState.Status) ($($refreshState.PercentageComplete)% complete)."
    } while ($refreshState.Status -in @('Pending', 'InProgress', 'Baking') -and (Get-Date) -lt $deadline)

    if ($refreshState.Status -ne 'Successful') {
        throw "Instance refresh ended with status '$($refreshState.Status)'."
    }
}

[PSCustomObject]@{
    LogGroup = $logGroupName
    LogRetentionDays = $logRetentionDays
    IamPolicy = $rolePolicyName
    Alarm = $alarmName
    AlarmActions = 'Disabled intentionally; no notification endpoint was assumed'
    InstanceRefreshId = $refresh.InstanceRefreshId
    ReplacementProtection = 'Minimum healthy capacity 100%; ASG min=1, desired=1, max=2'
}
