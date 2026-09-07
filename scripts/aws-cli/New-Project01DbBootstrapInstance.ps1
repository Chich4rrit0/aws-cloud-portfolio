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
$projectName = 'aws-cloud-portfolio'
$subnetName = 'portfolio-p01-public-app-a'
$securityGroupName = 'portfolio-p01-sg-app'
$instanceProfileName = 'portfolio-p01-db-bootstrap-profile'
$dbIdentifier = 'portfolio-p01-postgres'
$instanceName = 'portfolio-p01-db-bootstrap'
$masterPasswordPath = '/portfolio/project-01/database/password'
$applicationPasswordPath = '/portfolio/project-01/database/app-password'
$tags = @(
    "Key=Name,Value=$instanceName",
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

function Get-InstanceIfExists {
    $instances = Invoke-AwsJson -Arguments @(
        'ec2', 'describe-instances',
        '--filters',
        "Name=tag:Name,Values=$instanceName",
        'Name=instance-state-name,Values=pending,running,stopping,stopped'
    )
    return @($instances.Reservations | ForEach-Object { $_.Instances })
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode            = 'Dry run - no EC2 resource will be created'
        InstanceName    = $instanceName
        InstanceType    = 't3.micro'
        RootVolume      = '8 GiB gp3, encrypted, delete on termination'
        Subnet          = $subnetName
        SecurityGroup   = $securityGroupName
        PublicInbound   = 'None'
        InstanceProfile = $instanceProfileName
        Lifecycle       = 'Temporary; terminate after database bootstrap validation'
    }
    return
}

$existingInstances = @(Get-InstanceIfExists)
if ($existingInstances.Count -gt 1) {
    throw "Expected no more than one active bootstrap instance named '$instanceName'."
}
if ($existingInstances.Count -eq 1) {
    [PSCustomObject]@{
        Action     = 'Reused existing bootstrap instance'
        InstanceId = $existingInstances[0].InstanceId
        State      = $existingInstances[0].State.Name
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

$subnets = Invoke-AwsJson -Arguments @(
    'ec2', 'describe-subnets',
    '--filters',
    "Name=vpc-id,Values=$vpcId",
    "Name=tag:Name,Values=$subnetName"
)
if (@($subnets.Subnets).Count -ne 1) {
    throw "Expected exactly one subnet named '$subnetName'."
}

$securityGroups = Invoke-AwsJson -Arguments @(
    'ec2', 'describe-security-groups',
    '--filters',
    "Name=vpc-id,Values=$vpcId",
    "Name=group-name,Values=$securityGroupName"
)
if (@($securityGroups.SecurityGroups).Count -ne 1) {
    throw "Expected exactly one security group named '$securityGroupName'."
}

$db = Invoke-AwsJson -Arguments @('rds', 'describe-db-instances', '--db-instance-identifier', $dbIdentifier)
$dbInstance = $db.DBInstances[0]
if ($dbInstance.DBInstanceStatus -ne 'available' -or $dbInstance.PubliclyAccessible) {
    throw 'RDS must be available and private before bootstrap can run.'
}

$profile = Invoke-AwsJson -Arguments @('iam', 'get-instance-profile', '--instance-profile-name', $instanceProfileName)
$amiId = (Invoke-AwsJson -Arguments @(
    'ssm', 'get-parameter',
    '--name', '/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64'
)).Parameter.Value

$userDataTemplate = @'
#!/bin/bash
set -euo pipefail

dnf install -y postgresql15
install -d -m 0755 /opt/task-manager/certs
curl --fail --silent --show-error --location https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem --output /opt/task-manager/certs/rds-global-bundle.pem

master_password="$(aws ssm get-parameter --name '__MASTER_PARAMETER__' --with-decryption --query 'Parameter.Value' --output text --region '__REGION__')"
app_password="$(openssl rand -hex 32)"
export PGPASSWORD="$master_password"

psql "host=__DB_ENDPOINT__ port=5432 dbname=taskmanager user=taskmanager_admin sslmode=verify-full sslrootcert=/opt/task-manager/certs/rds-global-bundle.pem" --set ON_ERROR_STOP=1 --set app_password="$app_password" <<'SQL'
SELECT 'CREATE ROLE taskmanager_app LOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'taskmanager_app')\gexec
SELECT format('ALTER ROLE taskmanager_app PASSWORD %L', :'app_password')\gexec
GRANT CONNECT ON DATABASE taskmanager TO taskmanager_app;
GRANT USAGE, CREATE ON SCHEMA public TO taskmanager_app;
SQL

unset PGPASSWORD
unset master_password
aws ssm put-parameter --name '__APPLICATION_PARAMETER__' --type SecureString --value "$app_password" --overwrite --region '__REGION__'
unset app_password
echo 'Database bootstrap completed successfully.'
'@
$userData = $userDataTemplate.Replace('__REGION__', $Region).Replace('__DB_ENDPOINT__', $dbInstance.Endpoint.Address).Replace('__MASTER_PARAMETER__', $masterPasswordPath).Replace('__APPLICATION_PARAMETER__', $applicationPasswordPath)
$tagList = ($tags | ForEach-Object { "{$_}" }) -join ','
$instanceTagSpecification = "ResourceType=instance,Tags=[$tagList]"
$volumeTagSpecification = "ResourceType=volume,Tags=[$tagList]"

$launchArguments = @(
    'ec2', 'run-instances',
    '--image-id', $amiId,
    '--instance-type', 't3.micro',
    '--subnet-id', $subnets.Subnets[0].SubnetId,
    '--security-group-ids', $securityGroups.SecurityGroups[0].GroupId,
    '--iam-instance-profile', "Name=$($profile.InstanceProfile.InstanceProfileName)",
    '--metadata-options', 'HttpTokens=required,HttpEndpoint=enabled',
    '--block-device-mappings', 'DeviceName=/dev/xvda,Ebs={VolumeSize=8,VolumeType=gp3,DeleteOnTermination=true,Encrypted=true}',
    '--user-data', $userData,
    '--tag-specifications', $instanceTagSpecification, $volumeTagSpecification
)
$launch = Invoke-AwsJson -Arguments $launchArguments
$publicIp = $null
if ($launch.Instances[0].PSObject.Properties.Name -contains 'PublicIpAddress') {
    $publicIp = $launch.Instances[0].PublicIpAddress
}

[PSCustomObject]@{
    Action     = 'Bootstrap instance creation requested'
    InstanceId = $launch.Instances[0].InstanceId
    State      = $launch.Instances[0].State.Name
    PublicIp   = $publicIp
}
