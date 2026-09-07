[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute,

    [switch]$CreateNewLaunchTemplateVersion
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$vpcName = 'portfolio-p01-vpc'
$appSecurityGroupName = 'portfolio-p01-sg-app'
$instanceProfileName = 'portfolio-p01-ec2-profile'
$dbIdentifier = 'portfolio-p01-postgres'
$applicationPasswordPath = '/portfolio/project-01/database/app-password'
$launchTemplateName = 'portfolio-p01-app-launch-template'
$autoScalingGroupName = 'portfolio-p01-app-asg'
$amiParameterName = '/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64'
$applicationUser = 'taskmanager'
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

function Get-TagValue {
    param(
        [object]$Resource,
        [string]$Key
    )

    return ($Resource.Tags | Where-Object { $_.Key -eq $Key } | Select-Object -First 1).Value
}

function Get-ProjectResources {
    param([string[]]$Arguments)

    return @((Invoke-AwsJson -Arguments $Arguments) | Where-Object { $null -ne $_ })
}

function Get-ExistingLaunchTemplate {
    $output = & aws ec2 describe-launch-templates '--launch-template-names' $launchTemplateName '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json' 2>&1
    if ($LASTEXITCODE -eq 0) {
        return ($output | ConvertFrom-Json).LaunchTemplates[0]
    }
    if (($output | Out-String) -match 'InvalidLaunchTemplateName.NotFoundException') {
        return $null
    }
    throw "Could not query launch template '$launchTemplateName'."
}

function Get-ExistingAutoScalingGroup {
    $groupResponse = Invoke-AwsJson -Arguments @(
        'autoscaling', 'describe-auto-scaling-groups',
        '--auto-scaling-group-names', $autoScalingGroupName
    )
    $groups = @($groupResponse.AutoScalingGroups)
    if ($groups.Count -eq 0) {
        return $null
    }
    return $groups[0]
}

function Get-TagSpecifications {
    param([string]$ResourceType)

    $tags = @(@{ Key = 'Name'; Value = "portfolio-p01-$ResourceType" }) + $commonTags
    return @{
        ResourceType = $ResourceType
        Tags = $tags
    }
}

function New-ApplicationUserData {
    param(
        [string]$ArtifactBucket,
        [string]$ArtifactKey,
        [string]$DbEndpoint
    )

    $script = @"
#!/bin/bash
set -Eeuo pipefail

exec > >(tee -a /var/log/project-01-bootstrap.log | logger -t project-01-bootstrap -s 2>/dev/console) 2>&1

# Amazon Linux 2023 already includes curl-minimal. Installing the full curl
# package conflicts with it, so only the missing runtime packages are added.
dnf install -y nodejs20 unzip

id -u $applicationUser >/dev/null 2>&1 || useradd --system --create-home --shell /sbin/nologin $applicationUser
install -d -o root -g $applicationUser -m 0750 /opt/task-manager /opt/task-manager/certs

aws s3 cp 's3://$ArtifactBucket/$ArtifactKey' /opt/task-manager/release.zip --region '$Region'
unzip -oq /opt/task-manager/release.zip -d /opt/task-manager

cd /opt/task-manager/app
npm ci --omit=dev

curl --fail --silent --show-error --location 'https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem' --output /opt/task-manager/certs/rds-ca.pem
chown -R root:$applicationUser /opt/task-manager
chmod -R g-w,o-rwx /opt/task-manager

cat >/opt/task-manager/start.sh <<'EOF'
#!/bin/bash
set -Eeuo pipefail

export NODE_ENV=production
export PORT=3000
export TASK_STORE=postgres
export DB_HOST='$DbEndpoint'
export DB_PORT=5432
export DB_NAME=taskmanager
export DB_USER=taskmanager_app
export DB_SSL=true
export DB_SSL_CA_PATH=/opt/task-manager/certs/rds-ca.pem
export DB_PASSWORD="`$(aws ssm get-parameter --name '$applicationPasswordPath' --with-decryption --region '$Region' --query 'Parameter.Value' --output text)"

exec /usr/bin/node src/server.js
EOF

chown root:$applicationUser /opt/task-manager/start.sh
chmod 0750 /opt/task-manager/start.sh

cat >/etc/systemd/system/task-manager.service <<'EOF'
[Unit]
Description=AWS Cloud Portfolio Task Manager API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=taskmanager
Group=taskmanager
WorkingDirectory=/opt/task-manager/app
ExecStart=/opt/task-manager/start.sh
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now task-manager.service
"@

    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($script))
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode                   = 'Dry run - no Launch Template, Auto Scaling Group or EC2 instance will be created'
        LaunchTemplate         = $launchTemplateName
        AutoScalingGroup       = $autoScalingGroupName
        Capacity               = 'min=1, desired=1, max=2'
        Instance               = 't3.micro, Amazon Linux 2023, 8 GiB encrypted gp3'
        Access                 = 'Session Manager only; no inbound security-group rule is added'
        Deployment             = 'Private S3 release ZIP, application SSM password, PostgreSQL over TLS'
        PublicIpv4             = 'Assigned by the existing public app subnets for outbound SSM, S3 and package retrieval'
        ExistingTemplateAction  = if ($CreateNewLaunchTemplateVersion) { 'Create a replacement bootstrap version and update the existing ASG' } else { 'Reuse existing template and ASG if present' }
    }
    return
}

try {
    $vpcs = Get-ProjectResources -Arguments @(
        'ec2', 'describe-vpcs',
        '--filters', "Name=tag:Name,Values=$vpcName", 'Name=cidr-block,Values=10.20.0.0/16',
        '--query', 'Vpcs[]'
    )
    if ($vpcs.Count -ne 1) {
        throw "Expected exactly one Project 01 VPC; found $($vpcs.Count)."
    }
    $vpcId = $vpcs[0].VpcId

    $subnets = Get-ProjectResources -Arguments @(
        'ec2', 'describe-subnets',
        '--filters', "Name=vpc-id,Values=$vpcId",
        '--query', 'Subnets[]'
    )
    $appSubnets = @($subnets | Where-Object { (Get-TagValue -Resource $_ -Key 'Name') -like 'portfolio-p01-public-app-*' } | Sort-Object AvailabilityZone)
    if ($appSubnets.Count -ne 2 -or @($appSubnets.AvailabilityZone | Select-Object -Unique).Count -ne 2) {
        throw 'Expected two public application subnets in separate Availability Zones.'
    }

    $securityGroups = Get-ProjectResources -Arguments @(
        'ec2', 'describe-security-groups',
        '--filters', "Name=vpc-id,Values=$vpcId", "Name=group-name,Values=$appSecurityGroupName",
        '--query', 'SecurityGroups[]'
    )
    if ($securityGroups.Count -ne 1) {
        throw "Expected exactly one application security group named '$appSecurityGroupName'."
    }
    $appSecurityGroupId = $securityGroups[0].GroupId

    $instanceProfile = Invoke-AwsJson -Arguments @(
        'iam', 'get-instance-profile',
        '--instance-profile-name', $instanceProfileName
    )
    if (@($instanceProfile.InstanceProfile.Roles).Count -ne 1) {
        throw "Expected exactly one role in instance profile '$instanceProfileName'."
    }

    $db = Invoke-AwsJson -Arguments @(
        'rds', 'describe-db-instances',
        '--db-instance-identifier', $dbIdentifier
    )
    $dbInstance = $db.DBInstances[0]
    if ($dbInstance.DBInstanceStatus -ne 'available' -or $dbInstance.PubliclyAccessible) {
        throw 'The private RDS instance must be available before application compute is created.'
    }

    $parameter = Invoke-AwsJson -Arguments @(
        'ssm', 'get-parameter',
        '--name', $applicationPasswordPath
    )
    if ($parameter.Parameter.Type -ne 'SecureString') {
        throw 'The application database password parameter must be a SecureString.'
    }

    $accountId = (Invoke-AwsJson -Arguments @('sts', 'get-caller-identity')).Account
    $artifactBucket = "portfolio-p01-artifacts-$accountId-$Region"
    $artifactList = Invoke-AwsJson -Arguments @(
        's3api', 'list-objects-v2',
        '--bucket', $artifactBucket,
        '--prefix', 'releases/task-manager-'
    )
    $artifact = @($artifactList.Contents | Sort-Object LastModified -Descending | Select-Object -First 1)[0]
    if ($null -eq $artifact -or $artifact.Key -notlike 'releases/*') {
        throw 'Expected at least one deployment ZIP under the private releases/ prefix.'
    }

    $amiId = (Invoke-AwsJson -Arguments @(
        'ssm', 'get-parameter',
        '--name', $amiParameterName
    )).Parameter.Value

    $launchTemplate = Get-ExistingLaunchTemplate
    if ($null -eq $launchTemplate -or $CreateNewLaunchTemplateVersion) {
        $userData = New-ApplicationUserData -ArtifactBucket $artifactBucket -ArtifactKey $artifact.Key -DbEndpoint $dbInstance.Endpoint.Address
        $launchTemplateData = @{
            ImageId = $amiId
            InstanceType = 't3.micro'
            IamInstanceProfile = @{ Name = $instanceProfileName }
            SecurityGroupIds = @($appSecurityGroupId)
            UserData = $userData
            MetadataOptions = @{
                HttpEndpoint = 'enabled'
                HttpTokens = 'required'
                HttpPutResponseHopLimit = 1
                InstanceMetadataTags = 'disabled'
            }
            BlockDeviceMappings = @(
                @{
                    DeviceName = '/dev/xvda'
                    Ebs = @{
                        DeleteOnTermination = $true
                        Encrypted = $true
                        VolumeSize = 8
                        VolumeType = 'gp3'
                    }
                }
            )
            TagSpecifications = @(
                (Get-TagSpecifications -ResourceType 'instance'),
                (Get-TagSpecifications -ResourceType 'volume')
            )
        }

        $temporaryFile = New-TemporaryFile
        try {
            $launchTemplateData | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $temporaryFile -Encoding utf8NoBOM
            if ($null -eq $launchTemplate) {
                $createdTemplate = Invoke-AwsJson -Arguments @(
                    'ec2', 'create-launch-template',
                    '--launch-template-name', $launchTemplateName,
                    '--version-description', 'Initial private-S3 PostgreSQL deployment',
                    '--launch-template-data', "file://$temporaryFile"
                )
                $launchTemplate = $createdTemplate.LaunchTemplate
                $launchTemplateVersionNumber = $launchTemplate.LatestVersionNumber
                Write-Host "Created launch template $launchTemplateName."
            }
            else {
                $newVersion = Invoke-AwsJson -Arguments @(
                    'ec2', 'create-launch-template-version',
                    '--launch-template-name', $launchTemplateName,
                    '--source-version', "$($launchTemplate.LatestVersionNumber)",
                    '--version-description', 'Fix Amazon Linux curl-minimal bootstrap conflict',
                    '--launch-template-data', "file://$temporaryFile"
                )
                $launchTemplateVersionNumber = $newVersion.LaunchTemplateVersion.VersionNumber
                Write-Host "Created launch template version $launchTemplateVersionNumber with the corrected bootstrap."
            }
        }
        finally {
            Remove-Item -LiteralPath $temporaryFile -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        $launchTemplateVersionNumber = $launchTemplate.LatestVersionNumber
        Write-Host "Reusing launch template $launchTemplateName."
    }

    $autoScalingGroup = Get-ExistingAutoScalingGroup
    if ($null -eq $autoScalingGroup) {
        Invoke-AwsCommand -Arguments @(
            'autoscaling', 'create-auto-scaling-group',
            '--auto-scaling-group-name', $autoScalingGroupName,
            '--launch-template', "LaunchTemplateName=$launchTemplateName,Version=$launchTemplateVersionNumber",
            '--min-size', '1',
            '--desired-capacity', '1',
            '--max-size', '2',
            '--vpc-zone-identifier', ($appSubnets.SubnetId -join ','),
            '--health-check-type', 'EC2',
            '--health-check-grace-period', '300',
            '--tags',
            "ResourceId=$autoScalingGroupName,ResourceType=auto-scaling-group,Key=Name,Value=portfolio-p01-app,PropagateAtLaunch=true",
            "ResourceId=$autoScalingGroupName,ResourceType=auto-scaling-group,Key=Project,Value=aws-cloud-portfolio,PropagateAtLaunch=true",
            "ResourceId=$autoScalingGroupName,ResourceType=auto-scaling-group,Key=ProjectNumber,Value=01,PropagateAtLaunch=true",
            "ResourceId=$autoScalingGroupName,ResourceType=auto-scaling-group,Key=Environment,Value=development,PropagateAtLaunch=true",
            "ResourceId=$autoScalingGroupName,ResourceType=auto-scaling-group,Key=ManagedBy,Value=aws-cli,PropagateAtLaunch=true"
        )
        Write-Host "Created Auto Scaling Group $autoScalingGroupName with desired capacity 1."
    }
    else {
        if ($CreateNewLaunchTemplateVersion) {
            Invoke-AwsCommand -Arguments @(
                'autoscaling', 'update-auto-scaling-group',
                '--auto-scaling-group-name', $autoScalingGroupName,
                '--launch-template', "LaunchTemplateName=$launchTemplateName,Version=$launchTemplateVersionNumber"
            )
            Write-Host "Updated Auto Scaling Group $autoScalingGroupName to launch template version $launchTemplateVersionNumber."
        }
        else {
            Write-Host "Reusing Auto Scaling Group $autoScalingGroupName."
        }
    }

    [PSCustomObject]@{
        LaunchTemplate = $launchTemplateName
        AutoScalingGroup = $autoScalingGroupName
        DesiredCapacity = 1
        MaximumCapacity = 2
        InstanceType = 't3.micro'
        ArtifactKey = $artifact.Key
        DatabaseConnection = 'Private RDS endpoint over TLS; password retrieved at runtime from Parameter Store'
        InboundAccess = 'No direct inbound access; application security group remains ALB-only'
    }
}
catch {
    Write-Error $_
    throw
}
