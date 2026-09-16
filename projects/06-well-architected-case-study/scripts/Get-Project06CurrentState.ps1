[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = 'Stop'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $output = & aws @Arguments --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS read failed: aws $($Arguments[0..1] -join ' ')"
    }

    return ($output -join "`n") | ConvertFrom-Json
}

try {
    [void](Invoke-AwsJson @('sts', 'get-caller-identity'))
}
catch {
    throw "AWS authentication or read access is unavailable. Run 'aws login --profile $ProfileName' and retry."
}

$vpcs = Invoke-AwsJson @('ec2', 'describe-vpcs', '--filters', 'Name=tag:Name,Values=portfolio-p01-vpc')
$asgs = Invoke-AwsJson @('autoscaling', 'describe-auto-scaling-groups', '--auto-scaling-group-names', 'portfolio-p01-app-asg')
$rdsInstances = Invoke-AwsJson @('rds', 'describe-db-instances')
$loadBalancers = Invoke-AwsJson @('elbv2', 'describe-load-balancers')
$alarms = Invoke-AwsJson @('cloudwatch', 'describe-alarms', '--alarm-names', 'portfolio-p01-alb-no-healthy-targets')
$logGroups = Invoke-AwsJson @('logs', 'describe-log-groups', '--log-group-name-prefix', '/aws/aws-cloud-portfolio/project-01/application')
$distributions = Invoke-AwsJson @('cloudfront', 'list-distributions')

$asg = @($asgs.AutoScalingGroups) | Select-Object -First 1
$rds = @($rdsInstances.DBInstances | Where-Object { $_.DBInstanceIdentifier -eq 'portfolio-p01-postgres' }) | Select-Object -First 1
$alb = @($loadBalancers.LoadBalancers | Where-Object { $_.LoadBalancerName -eq 'portfolio-p01-app-alb' }) | Select-Object -First 1
$alarm = @($alarms.MetricAlarms) | Select-Object -First 1
$logGroup = @($logGroups.logGroups | Where-Object { $_.logGroupName -eq '/aws/aws-cloud-portfolio/project-01/application' }) | Select-Object -First 1
$distribution = @($distributions.DistributionList.Items | Where-Object { $_.Comment -eq 'Project 01 Task Manager frontend and API delivery' }) | Select-Object -First 1

[ordered]@{
    AuditDateUtc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    Vpc = [ordered]@{
        Count = @($vpcs.Vpcs).Count
        States = @($vpcs.Vpcs | ForEach-Object { $_.State })
    }
    AutoScaling = [ordered]@{
        Present = [bool]$asg
        DesiredCapacity = if ($asg) { $asg.DesiredCapacity } else { $null }
        MinSize = if ($asg) { $asg.MinSize } else { $null }
        MaxSize = if ($asg) { $asg.MaxSize } else { $null }
        InServiceCount = if ($asg) { @($asg.Instances | Where-Object { $_.LifecycleState -eq 'InService' }).Count } else { 0 }
    }
    Rds = [ordered]@{
        Present = [bool]$rds
        Status = if ($rds) { $rds.DBInstanceStatus } else { $null }
        MultiAz = if ($rds) { $rds.MultiAZ } else { $null }
        BackupRetentionDays = if ($rds) { $rds.BackupRetentionPeriod } else { $null }
        DeletionProtection = if ($rds) { $rds.DeletionProtection } else { $null }
        PubliclyAccessible = if ($rds) { $rds.PubliclyAccessible } else { $null }
    }
    Alb = [ordered]@{
        Present = [bool]$alb
        State = if ($alb) { $alb.State.Code } else { $null }
        Scheme = if ($alb) { $alb.Scheme } else { $null }
    }
    CloudFront = [ordered]@{
        Present = [bool]$distribution
        Enabled = if ($distribution) { $distribution.Enabled } else { $null }
        Status = if ($distribution) { $distribution.Status } else { $null }
    }
    Alarm = [ordered]@{
        Present = [bool]$alarm
        State = if ($alarm) { $alarm.StateValue } else { $null }
        ConfiguredActionCount = if ($alarm) { @($alarm.AlarmActions).Count + @($alarm.OKActions).Count + @($alarm.InsufficientDataActions).Count } else { 0 }
    }
    ApplicationLogGroup = [ordered]@{
        Present = [bool]$logGroup
        RetentionDays = if ($logGroup) { $logGroup.retentionInDays } else { $null }
    }
} | ConvertTo-Json -Depth 6
