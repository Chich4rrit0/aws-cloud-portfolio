[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$vpcName = 'portfolio-p01-vpc'
$albSecurityGroupName = 'portfolio-p01-sg-alb'
$loadBalancerName = 'portfolio-p01-app-alb'
$targetGroupName = 'portfolio-p01-app-tg'
$autoScalingGroupName = 'portfolio-p01-app-asg'
$tags = @(
    'Key=Name,Value=portfolio-p01-app-alb',
    'Key=Project,Value=aws-cloud-portfolio',
    'Key=ProjectNumber,Value=01',
    'Key=Environment,Value=development',
    'Key=ManagedBy,Value=aws-cli'
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

function Get-TagValue {
    param([object]$Resource, [string]$Key)

    return ($Resource.Tags | Where-Object { $_.Key -eq $Key } | Select-Object -First 1).Value
}

function Get-ExistingTargetGroup {
    $output = & aws elbv2 describe-target-groups '--names' $targetGroupName '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json' 2>&1
    if ($LASTEXITCODE -eq 0) {
        return ($output | ConvertFrom-Json).TargetGroups[0]
    }
    if (($output | Out-String) -match 'TargetGroupNotFound') {
        return $null
    }
    throw "Could not query target group '$targetGroupName'."
}

function Get-ExistingLoadBalancer {
    $output = & aws elbv2 describe-load-balancers '--names' $loadBalancerName '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json' 2>&1
    if ($LASTEXITCODE -eq 0) {
        return ($output | ConvertFrom-Json).LoadBalancers[0]
    }
    if (($output | Out-String) -match 'LoadBalancerNotFound') {
        return $null
    }
    throw "Could not query load balancer '$loadBalancerName'."
}

function Wait-ForLoadBalancerActive {
    param([string]$LoadBalancerArn)

    $deadline = (Get-Date).AddMinutes(5)
    do {
        $loadBalancer = (Invoke-AwsJson -Arguments @(
            'elbv2', 'describe-load-balancers',
            '--load-balancer-arns', $LoadBalancerArn
        )).LoadBalancers[0]
        if ($loadBalancer.State.Code -eq 'active') {
            return $loadBalancer
        }
        Start-Sleep -Seconds 10
    } while ((Get-Date) -lt $deadline)

    throw "Load Balancer '$loadBalancerName' did not become active within five minutes."
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run - no ALB, Target Group or listener will be created'
        LoadBalancer = "$loadBalancerName (internet-facing, HTTP 80)"
        TargetGroup = "$targetGroupName (HTTP 3000, health check /health)"
        AutoScalingGroup = $autoScalingGroupName
        SecurityBoundary = 'Internet -> ALB:80 -> app security group:3000 only'
        CostNote = 'ALB hourly and LCU charges begin when created'
    }
    return
}

try {
    $vpcResponse = Invoke-AwsJson -Arguments @(
        'ec2', 'describe-vpcs',
        '--filters', "Name=tag:Name,Values=$vpcName", 'Name=cidr-block,Values=10.20.0.0/16'
    )
    $vpcs = @($vpcResponse.Vpcs)
    if ($vpcs.Count -ne 1) { throw "Expected exactly one Project 01 VPC; found $($vpcs.Count)." }
    $vpcId = $vpcs[0].VpcId

    $subnetResponse = Invoke-AwsJson -Arguments @('ec2', 'describe-subnets', '--filters', "Name=vpc-id,Values=$vpcId")
    $edgeSubnets = @($subnetResponse.Subnets | Where-Object { (Get-TagValue -Resource $_ -Key 'Name') -like 'portfolio-p01-public-edge-*' } | Sort-Object AvailabilityZone)
    if ($edgeSubnets.Count -ne 2 -or @($edgeSubnets.AvailabilityZone | Select-Object -Unique).Count -ne 2) {
        throw 'Expected two public edge subnets in separate Availability Zones.'
    }

    $securityGroupResponse = Invoke-AwsJson -Arguments @(
        'ec2', 'describe-security-groups',
        '--filters', "Name=vpc-id,Values=$vpcId", "Name=group-name,Values=$albSecurityGroupName"
    )
    $securityGroups = @($securityGroupResponse.SecurityGroups)
    if ($securityGroups.Count -ne 1) { throw "Expected exactly one ALB security group named '$albSecurityGroupName'." }

    $targetGroup = Get-ExistingTargetGroup
    if ($null -eq $targetGroup) {
        $targetGroupArguments = @(
            'elbv2', 'create-target-group',
            '--name', $targetGroupName,
            '--protocol', 'HTTP',
            '--port', '3000',
            '--vpc-id', $vpcId,
            '--target-type', 'instance',
            '--health-check-protocol', 'HTTP',
            '--health-check-path', '/health',
            '--matcher', 'HttpCode=200',
            '--health-check-interval-seconds', '30',
            '--health-check-timeout-seconds', '5',
            '--healthy-threshold-count', '2',
            '--unhealthy-threshold-count', '2',
            '--tags'
        ) + $tags
        $targetGroup = (Invoke-AwsJson -Arguments $targetGroupArguments).TargetGroups[0]
        Write-Host "Created target group $targetGroupName."
    }
    else {
        Write-Host "Reusing target group $targetGroupName."
    }

    $loadBalancer = Get-ExistingLoadBalancer
    if ($null -eq $loadBalancer) {
        $loadBalancerArguments = @(
            'elbv2', 'create-load-balancer',
            '--name', $loadBalancerName,
            '--type', 'application',
            '--scheme', 'internet-facing',
            '--ip-address-type', 'ipv4',
            '--subnets'
        ) + @($edgeSubnets.SubnetId) + @(
            '--security-groups', $securityGroups[0].GroupId,
            '--tags'
        ) + $tags
        $loadBalancer = (Invoke-AwsJson -Arguments $loadBalancerArguments).LoadBalancers[0]
        Write-Host "Created Application Load Balancer $loadBalancerName."
    }
    else {
        Write-Host "Reusing Application Load Balancer $loadBalancerName."
    }

    $loadBalancer = Wait-ForLoadBalancerActive -LoadBalancerArn $loadBalancer.LoadBalancerArn

    $listeners = Invoke-AwsJson -Arguments @('elbv2', 'describe-listeners', '--load-balancer-arn', $loadBalancer.LoadBalancerArn)
    $httpListener = @($listeners.Listeners | Where-Object { $_.Port -eq 80 -and $_.Protocol -eq 'HTTP' } | Select-Object -First 1)[0]
    if ($null -eq $httpListener) {
        Invoke-AwsCommand -Arguments @(
            'elbv2', 'create-listener',
            '--load-balancer-arn', $loadBalancer.LoadBalancerArn,
            '--protocol', 'HTTP',
            '--port', '80',
            '--default-actions', "Type=forward,TargetGroupArn=$($targetGroup.TargetGroupArn)"
        )
        Write-Host 'Created HTTP listener on port 80.'
    }
    else {
        Write-Host 'Reusing existing HTTP listener on port 80.'
    }

    Invoke-AwsCommand -Arguments @(
        'autoscaling', 'attach-load-balancer-target-groups',
        '--auto-scaling-group-name', $autoScalingGroupName,
        '--target-group-arns', $targetGroup.TargetGroupArn
    )

    [PSCustomObject]@{
        LoadBalancer = $loadBalancerName
        DnsName = $loadBalancer.DNSName
        TargetGroup = $targetGroupName
        HealthCheckPath = '/health'
        Listener = 'HTTP 80 -> target port 3000'
        AutoScalingGroup = $autoScalingGroupName
        SecurityBoundary = 'Internet -> ALB only; EC2 accepts port 3000 from ALB security group only'
    }
}
catch {
    Write-Error $_
    throw
}
