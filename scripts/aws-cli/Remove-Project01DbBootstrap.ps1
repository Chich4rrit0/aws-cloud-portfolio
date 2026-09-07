[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute,

    [switch]$ConfirmDestruction
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$instanceName = 'portfolio-p01-db-bootstrap'
$roleName = 'portfolio-p01-db-bootstrap-role'
$instanceProfileName = 'portfolio-p01-db-bootstrap-profile'
$inlinePolicyName = 'Project01BootstrapDatabaseCredential'
$managedPolicyArn = 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'

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
}

function Get-BootstrapInstances {
    $response = Invoke-AwsJson -Arguments @(
        'ec2', 'describe-instances',
        '--filters',
        "Name=tag:Name,Values=$instanceName",
        'Name=instance-state-name,Values=pending,running,stopping,stopped'
    )
    return @($response.Reservations | ForEach-Object { $_.Instances })
}

function Get-InstanceProfileIfExists {
    $output = & aws iam get-instance-profile '--instance-profile-name' $instanceProfileName '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json' 2>&1
    if ($LASTEXITCODE -eq 0) {
        return ($output | ConvertFrom-Json).InstanceProfile
    }
    if (($output | Out-String) -match 'NoSuchEntity') {
        return $null
    }
    throw "Could not query instance profile '$instanceProfileName'."
}

function Test-RoleExists {
    & aws iam get-role '--role-name' $roleName '--profile' $ProfileName '--region' $Region '--no-cli-pager' 1>$null 2>$null
    return $LASTEXITCODE -eq 0
}

if (-not $Execute -or -not $ConfirmDestruction) {
    [PSCustomObject]@{
        Mode                  = 'Dry run - no resource will be deleted'
        InstanceName          = $instanceName
        RootVolumeBehavior    = 'Deleted automatically on instance termination'
        InstanceProfileName   = $instanceProfileName
        RoleName              = $roleName
        PreservedResources    = 'RDS and both Parameter Store SecureStrings'
    }
    return
}

$instances = @(Get-BootstrapInstances)
if ($instances.Count -gt 1) {
    throw "Expected at most one active bootstrap instance named '$instanceName'."
}

$volumeId = $null
if ($instances.Count -eq 1) {
    $instance = $instances[0]
    $volumeId = @($instance.BlockDeviceMappings | Where-Object { $_.DeviceName -eq '/dev/xvda' })[0].Ebs.VolumeId
    Invoke-AwsCommand -Arguments @('ec2', 'terminate-instances', '--instance-ids', $instance.InstanceId)
    Invoke-AwsCommand -Arguments @('ec2', 'wait', 'instance-terminated', '--instance-ids', $instance.InstanceId)
}

if ($null -ne $volumeId) {
    $volumeOutput = & aws ec2 describe-volumes '--volume-ids' $volumeId '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json' 2>&1
    if ($LASTEXITCODE -eq 0) {
        throw "Root volume '$volumeId' still exists after instance termination; it was not deleted manually."
    }
    if (($volumeOutput | Out-String) -notmatch 'InvalidVolume.NotFound') {
        throw "Could not verify deletion of root volume '$volumeId'."
    }
}

$profile = Get-InstanceProfileIfExists
if ($null -ne $profile) {
    foreach ($attachedRole in @($profile.Roles)) {
        Invoke-AwsCommand -Arguments @(
            'iam', 'remove-role-from-instance-profile',
            '--instance-profile-name', $instanceProfileName,
            '--role-name', $attachedRole.RoleName
        )
    }
    Invoke-AwsCommand -Arguments @('iam', 'delete-instance-profile', '--instance-profile-name', $instanceProfileName)
}

if (Test-RoleExists) {
    Invoke-AwsCommand -Arguments @('iam', 'delete-role-policy', '--role-name', $roleName, '--policy-name', $inlinePolicyName)
    Invoke-AwsCommand -Arguments @('iam', 'detach-role-policy', '--role-name', $roleName, '--policy-arn', $managedPolicyArn)
    Invoke-AwsCommand -Arguments @('iam', 'delete-role', '--role-name', $roleName)
}

[PSCustomObject]@{
    InstanceTerminated       = $instances.Count -eq 1
    RootVolumeDeleted        = $null -ne $volumeId
    InstanceProfileDeleted   = $null -ne $profile
    BootstrapRoleDeleted     = $true
    PreservedResources       = 'RDS and both Parameter Store SecureStrings'
}
