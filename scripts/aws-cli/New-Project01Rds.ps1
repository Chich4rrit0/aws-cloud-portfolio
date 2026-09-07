[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectName = 'aws-cloud-portfolio'
$vpcName = 'portfolio-p01-vpc'
$dbSubnetGroupName = 'portfolio-p01-db-subnet-group'
$dbIdentifier = 'portfolio-p01-postgres'
$dbSecurityGroupName = 'portfolio-p01-sg-db'
$parameterPath = '/portfolio/project-01/database/password'
$engineVersion = '18.3'
$masterUsername = 'taskmanager_admin'
$initialDatabaseName = 'taskmanager'
$tags = @(
    'Key=Name,Value=portfolio-p01-postgres',
    'Key=Project,Value=aws-cloud-portfolio',
    'Key=ProjectNumber,Value=01',
    'Key=Environment,Value=development',
    'Key=ManagedBy,Value=aws-cli'
)

function Format-AwsArgumentsForError {
    param([string[]]$Arguments)

    $sensitiveArguments = @('--value', '--master-user-password')
    $redactNextValue = $false
    $formatted = foreach ($argument in $Arguments) {
        if ($redactNextValue) {
            $redactNextValue = $false
            '***redacted***'
            continue
        }
        if ($argument -in $sensitiveArguments) {
            $redactNextValue = $true
        }
        $argument
    }
    return $formatted -join ' '
}

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $(Format-AwsArgumentsForError -Arguments $Arguments)"
    }
    return $rawOutput | ConvertFrom-Json
}

function Invoke-AwsCommand {
    param([string[]]$Arguments)

    $output = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $(Format-AwsArgumentsForError -Arguments $Arguments)`n$($output | Out-String)"
    }
}

function Get-DbInstanceIfExists {
    $output = & aws rds describe-db-instances '--db-instance-identifier' $dbIdentifier '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json' 2>&1
    if ($LASTEXITCODE -eq 0) {
        return ($output | ConvertFrom-Json).DBInstances[0]
    }
    if (($output | Out-String) -match 'DBInstanceNotFound') {
        return $null
    }
    throw "Could not query RDS instance '$dbIdentifier'."
}

function Get-DbSubnetGroupIfExists {
    $output = & aws rds describe-db-subnet-groups '--db-subnet-group-name' $dbSubnetGroupName '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json' 2>&1
    if ($LASTEXITCODE -eq 0) {
        return ($output | ConvertFrom-Json).DBSubnetGroups[0]
    }
    if (($output | Out-String) -match 'DBSubnetGroupNotFoundFault') {
        return $null
    }
    throw "Could not query DB subnet group '$dbSubnetGroupName'."
}

function New-RdsMasterPassword {
    # PostgreSQL RDS excludes slash, quotes, @ and spaces. The chosen alphabet
    # additionally avoids shell-sensitive characters while retaining strong entropy.
    $characters = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!#$%&()*+,-.:;<=>?[]^_{}~'
    $passwordCharacters = for ($index = 0; $index -lt 32; $index++) {
        $characters[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32($characters.Length)]
    }
    return -join $passwordCharacters
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode                  = 'Dry run - no AWS resources will be created or changed'
        DbInstanceIdentifier  = $dbIdentifier
        Engine                = "postgres $engineVersion"
        InstanceClass         = 'db.t3.micro'
        Storage               = '20 GiB gp3, encrypted, Single-AZ'
        PubliclyAccessible    = $false
        BackupRetentionDays   = 1
        DeletionProtection    = $false
        DbSubnetGroup         = $dbSubnetGroupName
        PasswordParameterPath = $parameterPath
    }
    return
}

try {
    $existingDb = Get-DbInstanceIfExists
    if ($null -ne $existingDb) {
        [PSCustomObject]@{
            Action               = 'Reused existing RDS instance; no password was changed'
            DbInstanceIdentifier = $existingDb.DBInstanceIdentifier
            Status               = $existingDb.DBInstanceStatus
            PubliclyAccessible   = $existingDb.PubliclyAccessible
        }
        return
    }

    $vpcs = Invoke-AwsJson -Arguments @(
        'ec2', 'describe-vpcs',
        '--filters',
        "Name=tag:Name,Values=$vpcName",
        "Name=tag:Project,Values=$projectName"
    )
    if (@($vpcs.Vpcs).Count -ne 1) {
        throw "Expected exactly one VPC named '$vpcName'."
    }
    $vpcId = $vpcs.Vpcs[0].VpcId

    $subnetResponse = Invoke-AwsJson -Arguments @(
        'ec2', 'describe-subnets',
        '--filters', "Name=vpc-id,Values=$vpcId"
    )
    $privateDbSubnets = @($subnetResponse.Subnets | Where-Object {
        ($_.Tags | Where-Object { $_.Key -eq 'Name' }).Value -like 'portfolio-p01-private-db-*'
    } | Sort-Object AvailabilityZone)
    if ($privateDbSubnets.Count -ne 2 -or @($privateDbSubnets.AvailabilityZone | Select-Object -Unique).Count -ne 2) {
        throw 'Expected two private database subnets in separate Availability Zones.'
    }

    $securityGroups = Invoke-AwsJson -Arguments @(
        'ec2', 'describe-security-groups',
        '--filters',
        "Name=vpc-id,Values=$vpcId",
        "Name=group-name,Values=$dbSecurityGroupName"
    )
    if (@($securityGroups.SecurityGroups).Count -ne 1) {
        throw "Expected exactly one database security group named '$dbSecurityGroupName'."
    }
    $dbSecurityGroupId = $securityGroups.SecurityGroups[0].GroupId

    $subnetGroup = Get-DbSubnetGroupIfExists
    if ($null -eq $subnetGroup) {
        $subnetGroup = Invoke-AwsJson -Arguments ((@(
            'rds', 'create-db-subnet-group',
            '--db-subnet-group-name', $dbSubnetGroupName,
            '--db-subnet-group-description', 'Private database subnets for AWS Cloud Portfolio Project 01.',
            '--subnet-ids'
        ) + @($privateDbSubnets.SubnetId) + @('--tags') + $tags))
        Write-Host "Created DB subnet group $dbSubnetGroupName."
    }
    else {
        Write-Host "Reusing DB subnet group $dbSubnetGroupName."
    }

    $password = New-RdsMasterPassword
    Invoke-AwsCommand -Arguments @(
        'ssm', 'put-parameter',
        '--name', $parameterPath,
        '--type', 'SecureString',
        '--value', $password,
        '--overwrite'
    )
    # Tags are intentionally omitted from put-parameter: the CLI does not allow
    # tagging an overwrite. The parameter value is never written to output.
    Write-Host "Stored the generated database password at $parameterPath."

    $db = Invoke-AwsJson -Arguments ((@(
        'rds', 'create-db-instance',
        '--db-instance-identifier', $dbIdentifier,
        '--engine', 'postgres',
        '--engine-version', $engineVersion,
        '--db-instance-class', 'db.t3.micro',
        '--allocated-storage', '20',
        '--storage-type', 'gp3',
        '--storage-encrypted',
        '--db-name', $initialDatabaseName,
        '--master-username', $masterUsername,
        '--master-user-password', $password,
        '--db-subnet-group-name', $dbSubnetGroupName,
        '--vpc-security-group-ids', $dbSecurityGroupId,
        '--no-publicly-accessible',
        '--backup-retention-period', '1',
        '--no-multi-az',
        '--no-deletion-protection',
        '--no-enable-performance-insights',
        '--auto-minor-version-upgrade',
        '--copy-tags-to-snapshot',
        '--tags'
    ) + $tags))

    [PSCustomObject]@{
        Action               = 'RDS creation requested'
        DbInstanceIdentifier = $db.DBInstance.DBInstanceIdentifier
        Status               = $db.DBInstance.DBInstanceStatus
        PubliclyAccessible   = $db.DBInstance.PubliclyAccessible
        StorageEncrypted     = $db.DBInstance.StorageEncrypted
        DbSubnetGroup        = $db.DBInstance.DBSubnetGroup.DBSubnetGroupName
        PasswordParameterPath = $parameterPath
    }
}
catch {
    Write-Error $_
    throw
}
