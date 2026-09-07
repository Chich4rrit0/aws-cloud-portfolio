[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$commonTags = @(
    @{ Key = 'Project'; Value = 'aws-cloud-portfolio' },
    @{ Key = 'ProjectNumber'; Value = '01' },
    @{ Key = 'Environment'; Value = 'development' },
    @{ Key = 'ManagedBy'; Value = 'aws-cli' }
)

function Get-TagSpecification {
    param([string]$Name)

    $tags = @(@{ Key = 'Name'; Value = $Name }) + $commonTags
    $tagValues = $tags | ForEach-Object { "{Key=$($_.Key),Value=$($_.Value)}" }
    return "ResourceType=security-group,Tags=[$($tagValues -join ',')]"
}

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

function Invoke-AwsPermissionCommand {
    param(
        [string[]]$Arguments,
        [string]$IgnoreErrorCode
    )

    $output = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' 2>&1
    if ($LASTEXITCODE -eq 0) {
        return
    }

    $message = $output | Out-String
    if ($IgnoreErrorCode -and $message -match [regex]::Escape($IgnoreErrorCode)) {
        Write-Host "Already in the desired state: $IgnoreErrorCode."
        return
    }

    throw "AWS CLI command failed: aws $($Arguments -join ' ')`n$message"
}

function Find-Resources {
    param([string[]]$Arguments)

    $resources = @((Invoke-AwsJson -Arguments $Arguments) | Where-Object { $null -ne $_ })
    return ,$resources
}

function Ensure-SecurityGroup {
    param(
        [string]$VpcId,
        [string]$Name,
        [string]$Description
    )

    $groups = Find-Resources -Arguments @(
        'ec2', 'describe-security-groups',
        '--filters', "Name=vpc-id,Values=$VpcId", "Name=group-name,Values=$Name",
        '--query', 'SecurityGroups[]'
    )

    if ($groups.Count -gt 1) {
        throw "More than one Security Group matches '$Name'."
    }

    if ($groups.Count -eq 1) {
        Write-Host "Reusing Security Group $($groups[0].GroupId) ($Name)."
        return $groups[0].GroupId
    }

    $group = Invoke-AwsJson -Arguments @(
        'ec2', 'create-security-group',
        '--group-name', $Name,
        '--description', $Description,
        '--vpc-id', $VpcId,
        '--tag-specifications', (Get-TagSpecification -Name $Name)
    )
    Write-Host "Created Security Group $($group.GroupId) ($Name)."
    return $group.GroupId
}

if (-not $Execute) {
    Write-Host 'Dry run only. No AWS resources were created or changed.'
    return
}

try {
    $vpcs = Find-Resources -Arguments @(
        'ec2', 'describe-vpcs',
        '--filters', 'Name=tag:Name,Values=portfolio-p01-vpc', 'Name=cidr-block,Values=10.20.0.0/16',
        '--query', 'Vpcs[]'
    )
    if ($vpcs.Count -ne 1) {
        throw "Expected exactly one Project 01 VPC; found $($vpcs.Count)."
    }
    $vpcId = $vpcs[0].VpcId

    $albGroupId = Ensure-SecurityGroup -VpcId $vpcId -Name 'portfolio-p01-sg-alb' -Description 'Project 01 Application Load Balancer access'
    $appGroupId = Ensure-SecurityGroup -VpcId $vpcId -Name 'portfolio-p01-sg-app' -Description 'Project 01 application instances access'
    $dbGroupId = Ensure-SecurityGroup -VpcId $vpcId -Name 'portfolio-p01-sg-db' -Description 'Project 01 PostgreSQL database access'

    foreach ($groupId in @($albGroupId, $appGroupId, $dbGroupId)) {
        Invoke-AwsPermissionCommand -Arguments @(
            'ec2', 'revoke-security-group-egress',
            '--group-id', $groupId,
            '--ip-permissions', 'IpProtocol=-1,IpRanges=[{CidrIp=0.0.0.0/0}]'
        ) -IgnoreErrorCode 'InvalidPermission.NotFound'
    }

    Invoke-AwsPermissionCommand -Arguments @(
        'ec2', 'authorize-security-group-ingress',
        '--group-id', $albGroupId,
        '--ip-permissions', 'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0,Description=Temporary_public_HTTP_until_CloudFront}]'
    ) -IgnoreErrorCode 'InvalidPermission.Duplicate'
    Invoke-AwsPermissionCommand -Arguments @(
        'ec2', 'authorize-security-group-egress',
        '--group-id', $albGroupId,
        '--ip-permissions', "IpProtocol=tcp,FromPort=3000,ToPort=3000,UserIdGroupPairs=[{GroupId=$appGroupId,Description=Forward_to_application_instances}]"
    ) -IgnoreErrorCode 'InvalidPermission.Duplicate'

    Invoke-AwsPermissionCommand -Arguments @(
        'ec2', 'authorize-security-group-ingress',
        '--group-id', $appGroupId,
        '--ip-permissions', "IpProtocol=tcp,FromPort=3000,ToPort=3000,UserIdGroupPairs=[{GroupId=$albGroupId,Description=Only_from_ALB}]"
    ) -IgnoreErrorCode 'InvalidPermission.Duplicate'
    Invoke-AwsPermissionCommand -Arguments @(
        'ec2', 'authorize-security-group-egress',
        '--group-id', $appGroupId,
        '--ip-permissions', "IpProtocol=tcp,FromPort=5432,ToPort=5432,UserIdGroupPairs=[{GroupId=$dbGroupId,Description=PostgreSQL_to_database}]"
    ) -IgnoreErrorCode 'InvalidPermission.Duplicate'
    foreach ($port in @(80, 443)) {
        Invoke-AwsPermissionCommand -Arguments @(
            'ec2', 'authorize-security-group-egress',
            '--group-id', $appGroupId,
            '--ip-permissions', "IpProtocol=tcp,FromPort=$port,ToPort=$port,IpRanges=[{CidrIp=0.0.0.0/0,Description=Required_outbound_HTTP_HTTPS}]"
        ) -IgnoreErrorCode 'InvalidPermission.Duplicate'
    }

    Invoke-AwsPermissionCommand -Arguments @(
        'ec2', 'authorize-security-group-ingress',
        '--group-id', $dbGroupId,
        '--ip-permissions', "IpProtocol=tcp,FromPort=5432,ToPort=5432,UserIdGroupPairs=[{GroupId=$appGroupId,Description=Only_from_application_instances}]"
    ) -IgnoreErrorCode 'InvalidPermission.Duplicate'

    [PSCustomObject]@{
        VpcId      = $vpcId
        AlbGroupId = $albGroupId
        AppGroupId = $appGroupId
        DbGroupId  = $dbGroupId
    }
}
catch {
    Write-Error $_
    throw
}
