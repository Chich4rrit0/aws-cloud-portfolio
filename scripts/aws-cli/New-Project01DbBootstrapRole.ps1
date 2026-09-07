[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$roleName = 'portfolio-p01-db-bootstrap-role'
$instanceProfileName = 'portfolio-p01-db-bootstrap-profile'
$masterPasswordPath = '/portfolio/project-01/database/password'
$applicationPasswordPath = '/portfolio/project-01/database/app-password'
$managedPolicyArn = 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'
$tags = @(
    'Key=Name,Value=portfolio-p01-db-bootstrap-role',
    'Key=Project,Value=aws-cloud-portfolio',
    'Key=ProjectNumber,Value=01',
    'Key=Environment,Value=development',
    'Key=ManagedBy,Value=aws-cli',
    'Key=Lifecycle,Value=temporary'
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
}

function Get-RoleIfExists {
    $output = & aws iam get-role '--role-name' $roleName '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json' 2>&1
    if ($LASTEXITCODE -eq 0) {
        return ($output | ConvertFrom-Json).Role
    }
    if (($output | Out-String) -match 'NoSuchEntity') {
        return $null
    }
    throw "Could not query IAM role '$roleName'."
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

if (-not $Execute) {
    [PSCustomObject]@{
        Mode                   = 'Dry run - no IAM resources will be created or changed'
        RoleName               = $roleName
        InstanceProfileName    = $instanceProfileName
        MasterPasswordReadPath = $masterPasswordPath
        AppPasswordWritePath   = $applicationPasswordPath
        Lifecycle              = 'Temporary; delete after bootstrap validation'
    }
    return
}

$trustPolicy = @{
    Version = '2012-10-17'
    Statement = @(
        @{
            Effect = 'Allow'
            Principal = @{ Service = 'ec2.amazonaws.com' }
            Action = 'sts:AssumeRole'
        }
    )
} | ConvertTo-Json -Compress -Depth 5

$role = Get-RoleIfExists
if ($null -eq $role) {
    $role = (Invoke-AwsJson -Arguments ((@(
        'iam', 'create-role',
        '--role-name', $roleName,
        '--assume-role-policy-document', $trustPolicy,
        '--tags'
    ) + $tags))).Role
    Write-Host "Created IAM role $roleName."
}
else {
    Invoke-AwsCommand -Arguments @(
        'iam', 'update-assume-role-policy',
        '--role-name', $roleName,
        '--policy-document', $trustPolicy
    )
    Write-Host "Reusing IAM role $roleName."
}

$attachedPolicies = Invoke-AwsJson -Arguments @('iam', 'list-attached-role-policies', '--role-name', $roleName)
if (@($attachedPolicies.AttachedPolicies | Where-Object { $_.PolicyArn -eq $managedPolicyArn }).Count -eq 0) {
    Invoke-AwsCommand -Arguments @('iam', 'attach-role-policy', '--role-name', $roleName, '--policy-arn', $managedPolicyArn)
}

$accountId = (Invoke-AwsJson -Arguments @('sts', 'get-caller-identity')).Account
$bootstrapPolicy = @{
    Version = '2012-10-17'
    Statement = @(
        @{
            Sid = 'ReadOnlyRdsMasterPasswordForBootstrap'
            Effect = 'Allow'
            Action = @('ssm:GetParameter')
            Resource = "arn:aws:ssm:${Region}:${accountId}:parameter$masterPasswordPath"
        },
        @{
            Sid = 'StoreOnlyApplicationPassword'
            Effect = 'Allow'
            Action = @('ssm:PutParameter')
            Resource = "arn:aws:ssm:${Region}:${accountId}:parameter$applicationPasswordPath"
        }
    )
} | ConvertTo-Json -Compress -Depth 5
Invoke-AwsCommand -Arguments @(
    'iam', 'put-role-policy',
    '--role-name', $roleName,
    '--policy-name', 'Project01BootstrapDatabaseCredential',
    '--policy-document', $bootstrapPolicy
)

$instanceProfile = Get-InstanceProfileIfExists
if ($null -eq $instanceProfile) {
    $instanceProfile = (Invoke-AwsJson -Arguments ((@(
        'iam', 'create-instance-profile',
        '--instance-profile-name', $instanceProfileName,
        '--tags'
    ) + $tags))).InstanceProfile
    Write-Host "Created instance profile $instanceProfileName."
}
else {
    Write-Host "Reusing instance profile $instanceProfileName."
}

if (@($instanceProfile.Roles | Where-Object { $_.RoleName -eq $roleName }).Count -eq 0) {
    Invoke-AwsCommand -Arguments @('iam', 'add-role-to-instance-profile', '--instance-profile-name', $instanceProfileName, '--role-name', $roleName)
}

[PSCustomObject]@{
    RoleName               = $roleName
    InstanceProfileName    = $instanceProfileName
    ManagedPolicy          = 'AmazonSSMManagedInstanceCore'
    MasterPasswordReadPath = $masterPasswordPath
    AppPasswordWritePath   = $applicationPasswordPath
}
