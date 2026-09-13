[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ProfileName,

    [Parameter(Mandatory)]
    [string]$VpcId,

    [Parameter(Mandatory)]
    [string]$PublicApplicationSubnetId,

    [Parameter(Mandatory)]
    [string]$DatabaseSecurityGroupId,

    [Parameter(Mandatory)]
    [string]$DatabaseEndpoint,

    [string]$DatabaseName = 'taskmanager',
    [string]$MasterUsername = 'portfolio_master',
    [string]$Region = 'us-east-1',
    [string]$ProjectPrefix = 'portfolio-p03-e2e',
    [string]$ApplicationPasswordParameterName = '/portfolio/project-03-e2e/database/password',
    [string]$TemporaryMasterPasswordParameterName = '/portfolio/project-03-e2e/bootstrap/master-password',
    [switch]$Execute,
    [switch]$RetainOnFailure
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resourceNames = [PSCustomObject]@{
    SecurityGroupName  = "$ProjectPrefix-db-bootstrap-sg"
    RoleName           = "$ProjectPrefix-db-bootstrap-role"
    InstanceProfileName = "$ProjectPrefix-db-bootstrap-profile"
    InstanceName       = "$ProjectPrefix-db-bootstrap"
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run only; no AWS API mutation is performed'
        Prerequisites = 'Foundation applied; RDS available; outputs supplied from e2e-foundation state'
        CreatesTemporarily = "$($resourceNames.SecurityGroupName), $($resourceNames.RoleName), $($resourceNames.InstanceProfileName), $($resourceNames.InstanceName), $TemporaryMasterPasswordParameterName"
        CreatesForRuntime = $ApplicationPasswordParameterName
        Network = 'No SSH or inbound administration rule. PostgreSQL only to the E2E database SG and HTTPS egress for Session Manager.'
        Cleanup = 'On success, automatically deletes the temporary EC2, role, profile, security group and master parameter. The application password remains for Runtime.'
        FailurePolicy = 'Automatic cleanup unless -RetainOnFailure is explicitly supplied for diagnosis.'
    }
    return
}

function Invoke-Aws {
    param([Parameter(Mandatory)][string[]]$Arguments)

    & aws @Arguments --profile $ProfileName --region $Region --no-cli-pager
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments[0..([Math]::Min(1, $Arguments.Count - 1))] -join ' ')"
    }
}

function Get-AwsText {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $result = (& aws @Arguments --profile $ProfileName --region $Region --no-cli-pager --output text | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments[0..([Math]::Min(1, $Arguments.Count - 1))] -join ' ')"
    }
    return $result
}

function Invoke-AwsBestEffort {
    param([Parameter(Mandatory)][string[]]$Arguments)

    & aws @Arguments --profile $ProfileName --region $Region --no-cli-pager | Out-Null
    return $LASTEXITCODE -eq 0
}

function Write-Utf8JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object]$Value
    )

    $json = $Value | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Wait-ForSsmManagedInstance {
    param([Parameter(Mandatory)][string]$InstanceId)

    $deadline = (Get-Date).AddMinutes(12)
    do {
        $managedInstanceId = Get-AwsText @(
            'ssm', 'describe-instance-information',
            '--filters', "Key=InstanceIds,Values=$InstanceId",
            '--query', 'InstanceInformationList[0].InstanceId'
        )
        if ($managedInstanceId -eq $InstanceId) { return }
        Start-Sleep -Seconds 15
    } while ((Get-Date) -lt $deadline)

    throw "Instance $InstanceId did not become available in Session Manager within 12 minutes."
}

function Wait-ForSsmCommand {
    param(
        [Parameter(Mandatory)][string]$CommandId,
        [Parameter(Mandatory)][string]$InstanceId
    )

    $deadline = (Get-Date).AddMinutes(15)
    do {
        $status = Get-AwsText @(
            'ssm', 'get-command-invocation',
            '--command-id', $CommandId,
            '--instance-id', $InstanceId,
            '--query', 'Status'
        )
        if ($status -eq 'Success') { return }
        if ($status -in @('Cancelled', 'Failed', 'TimedOut', 'Cancelling')) {
            throw "Database bootstrap command ended with status $status. Check Session Manager command details without exposing secrets."
        }
        Start-Sleep -Seconds 10
    } while ((Get-Date) -lt $deadline)

    throw "Database bootstrap command $CommandId did not finish within 15 minutes."
}

function Remove-BootstrapResources {
    param(
        [string]$InstanceId,
        [string]$SecurityGroupId,
        [string]$DatabaseSecurityGroupId,
        [string]$DatabaseIngressRulesFile,
        [string]$RoleName,
        [string]$InstanceProfileName,
        [string]$TemporaryMasterParameterName
    )

    if ($InstanceId) {
        Invoke-AwsBestEffort @('ec2', 'terminate-instances', '--instance-ids', $InstanceId) | Out-Null
        Invoke-AwsBestEffort @('ec2', 'wait', 'instance-terminated', '--instance-ids', $InstanceId) | Out-Null
    }
    if ($TemporaryMasterParameterName) {
        Invoke-AwsBestEffort @('ssm', 'delete-parameter', '--name', $TemporaryMasterParameterName) | Out-Null
    }
    if ($DatabaseSecurityGroupId -and $SecurityGroupId -and $DatabaseIngressRulesFile) {
        Invoke-AwsBestEffort @('ec2', 'revoke-security-group-ingress', '--group-id', $DatabaseSecurityGroupId, '--ip-permissions', "file://$DatabaseIngressRulesFile") | Out-Null
    }
    if ($InstanceProfileName -and $RoleName) {
        Invoke-AwsBestEffort @('iam', 'remove-role-from-instance-profile', '--instance-profile-name', $InstanceProfileName, '--role-name', $RoleName) | Out-Null
    }
    if ($InstanceProfileName) {
        Invoke-AwsBestEffort @('iam', 'delete-instance-profile', '--instance-profile-name', $InstanceProfileName) | Out-Null
    }
    if ($RoleName) {
        Invoke-AwsBestEffort @('iam', 'detach-role-policy', '--role-name', $RoleName, '--policy-arn', 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore') | Out-Null
        Invoke-AwsBestEffort @('iam', 'delete-role-policy', '--role-name', $RoleName, '--policy-name', 'BootstrapDatabaseAccess') | Out-Null
        Invoke-AwsBestEffort @('iam', 'delete-role', '--role-name', $RoleName) | Out-Null
    }
    if ($SecurityGroupId) {
        Invoke-AwsBestEffort @('ec2', 'delete-security-group', '--group-id', $SecurityGroupId) | Out-Null
    }
}

$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("project-03-e2e-bootstrap-" + [guid]::NewGuid().ToString('N'))
$instanceId = $null
$securityGroupId = $null
$roleNameCreated = $null
$instanceProfileNameCreated = $null
$temporaryMasterParameterNameCreated = $null
$databaseIngressRulesFile = $null
$masterPasswordPlainText = $null
$success = $false

try {
    New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null

    $accountId = Get-AwsText @('sts', 'get-caller-identity', '--query', 'Account')
    $masterPasswordSecure = Read-Host 'RDS master password (not displayed or stored in Git)' -AsSecureString
    $masterPasswordPlainText = [System.Net.NetworkCredential]::new('', $masterPasswordSecure).Password
    if ([string]::IsNullOrWhiteSpace($masterPasswordPlainText)) {
        throw 'A non-empty RDS master password is required.'
    }

    $trustPolicyFile = Join-Path $temporaryDirectory 'trust-policy.json'
    $bootstrapPolicyFile = Join-Path $temporaryDirectory 'bootstrap-policy.json'
    $defaultEgressFile = Join-Path $temporaryDirectory 'default-egress-rule.json'
    $egressRulesFile = Join-Path $temporaryDirectory 'egress-rules.json'
    $databaseIngressRulesFile = Join-Path $temporaryDirectory 'database-ingress-rules.json'
    $instanceTagsFile = Join-Path $temporaryDirectory 'instance-tags.json'
    $commandParametersFile = Join-Path $temporaryDirectory 'command-parameters.json'

    Write-Utf8JsonFile -Path $trustPolicyFile -Value @{
        Version = '2012-10-17'
        Statement = @(@{
            Effect = 'Allow'
            Principal = @{ Service = 'ec2.amazonaws.com' }
            Action = 'sts:AssumeRole'
        })
    }

    Write-Utf8JsonFile -Path $bootstrapPolicyFile -Value @{
        Version = '2012-10-17'
        Statement = @(@{
            Sid = 'ReadTemporaryMasterPassword'
            Effect = 'Allow'
            Action = @('ssm:GetParameter', 'ssm:DeleteParameter')
            Resource = "arn:aws:ssm:$Region`:$accountId`:parameter$TemporaryMasterPasswordParameterName"
        }, @{
            Sid = 'WriteApplicationPassword'
            Effect = 'Allow'
            Action = @('ssm:PutParameter')
            Resource = "arn:aws:ssm:$Region`:$accountId`:parameter$ApplicationPasswordParameterName"
        })
    }

    Write-Utf8JsonFile -Path $defaultEgressFile -Value @(@{
        IpProtocol = '-1'
        IpRanges = @(@{ CidrIp = '0.0.0.0/0' })
    })

    Write-Utf8JsonFile -Path $egressRulesFile -Value @(@{
        IpProtocol = 'tcp'
        FromPort = 5432
        ToPort = 5432
        UserIdGroupPairs = @(@{ GroupId = $DatabaseSecurityGroupId; Description = 'PostgreSQL to isolated E2E RDS only' })
    }, @{
        IpProtocol = 'tcp'
        FromPort = 443
        ToPort = 443
        IpRanges = @(@{ CidrIp = '0.0.0.0/0'; Description = 'HTTPS for Session Manager and Parameter Store' })
    })

    Write-Utf8JsonFile -Path $instanceTagsFile -Value @(@{
        ResourceType = 'instance'
        Tags = @(
            @{ Key = 'Name'; Value = $resourceNames.InstanceName },
            @{ Key = 'Project'; Value = 'aws-cloud-portfolio' },
            @{ Key = 'ProjectNumber'; Value = '03' },
            @{ Key = 'Environment'; Value = 'e2e' },
            @{ Key = 'Purpose'; Value = 'temporary-database-bootstrap' },
            @{ Key = 'ManagedBy'; Value = 'manual-e2e-script' }
        )
    }, @{
        ResourceType = 'volume'
        Tags = @(
            @{ Key = 'Project'; Value = 'aws-cloud-portfolio' },
            @{ Key = 'ProjectNumber'; Value = '03' },
            @{ Key = 'Environment'; Value = 'e2e' },
            @{ Key = 'Purpose'; Value = 'temporary-database-bootstrap' }
        )
    })

    Invoke-Aws @('ssm', 'put-parameter', '--name', $TemporaryMasterPasswordParameterName, '--type', 'SecureString', '--value', $masterPasswordPlainText) | Out-Null
    $temporaryMasterParameterNameCreated = $TemporaryMasterPasswordParameterName
    Invoke-Aws @('iam', 'create-role', '--role-name', $resourceNames.RoleName, '--assume-role-policy-document', "file://$trustPolicyFile") | Out-Null
    $roleNameCreated = $resourceNames.RoleName
    Invoke-Aws @('iam', 'attach-role-policy', '--role-name', $resourceNames.RoleName, '--policy-arn', 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore') | Out-Null
    Invoke-Aws @('iam', 'put-role-policy', '--role-name', $resourceNames.RoleName, '--policy-name', 'BootstrapDatabaseAccess', '--policy-document', "file://$bootstrapPolicyFile") | Out-Null
    Invoke-Aws @('iam', 'create-instance-profile', '--instance-profile-name', $resourceNames.InstanceProfileName) | Out-Null
    $instanceProfileNameCreated = $resourceNames.InstanceProfileName
    Invoke-Aws @('iam', 'add-role-to-instance-profile', '--instance-profile-name', $resourceNames.InstanceProfileName, '--role-name', $resourceNames.RoleName) | Out-Null

    $securityGroupId = Get-AwsText @('ec2', 'create-security-group', '--group-name', $resourceNames.SecurityGroupName, '--description', 'Temporary Project 03 E2E PostgreSQL bootstrap access only.', '--vpc-id', $VpcId, '--query', 'GroupId')
    Invoke-Aws @('ec2', 'create-tags', '--resources', $securityGroupId, '--tags', "Key=Name,Value=$($resourceNames.SecurityGroupName)", 'Key=Project,Value=aws-cloud-portfolio', 'Key=ProjectNumber,Value=03', 'Key=Environment,Value=e2e', 'Key=Purpose,Value=temporary-database-bootstrap') | Out-Null
    Invoke-Aws @('ec2', 'revoke-security-group-egress', '--group-id', $securityGroupId, '--ip-permissions', "file://$defaultEgressFile") | Out-Null
    Invoke-Aws @('ec2', 'authorize-security-group-egress', '--group-id', $securityGroupId, '--ip-permissions', "file://$egressRulesFile") | Out-Null
    Write-Utf8JsonFile -Path $databaseIngressRulesFile -Value @(@{
        IpProtocol = 'tcp'
        FromPort = 5432
        ToPort = 5432
        UserIdGroupPairs = @(@{ GroupId = $securityGroupId; Description = 'Temporary Project 03 E2E database bootstrap only' })
    })
    Invoke-Aws @('ec2', 'authorize-security-group-ingress', '--group-id', $DatabaseSecurityGroupId, '--ip-permissions', "file://$databaseIngressRulesFile") | Out-Null

    Start-Sleep -Seconds 10
    $amiId = Get-AwsText @('ssm', 'get-parameter', '--name', '/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64', '--query', 'Parameter.Value')
    $instanceId = Get-AwsText @(
        'ec2', 'run-instances',
        '--image-id', $amiId,
        '--instance-type', 't3.micro',
        '--subnet-id', $PublicApplicationSubnetId,
        '--security-group-ids', $securityGroupId,
        '--iam-instance-profile', "Name=$($resourceNames.InstanceProfileName)",
        '--metadata-options', 'HttpTokens=required,HttpEndpoint=enabled',
        '--tag-specifications', "file://$instanceTagsFile",
        '--query', 'Instances[0].InstanceId'
    )
    Invoke-Aws @('ec2', 'wait', 'instance-running', '--instance-ids', $instanceId)
    Wait-ForSsmManagedInstance -InstanceId $instanceId

    $remoteScriptTemplate = @'
set -euo pipefail
sudo dnf install -y postgresql15
master_password="$(aws ssm get-parameter --name __MASTER_PARAMETER__ --with-decryption --query Parameter.Value --output text --region __REGION__)"
app_password="$(openssl rand -hex 32)"
export PGPASSWORD="$master_password"
psql "host=__DATABASE_ENDPOINT__ port=5432 dbname=__DATABASE_NAME__ user=__MASTER_USERNAME__ sslmode=require" -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'taskmanager_app') THEN
    CREATE ROLE taskmanager_app LOGIN;
  END IF;
END
\$\$;
ALTER ROLE taskmanager_app WITH PASSWORD '$app_password';
GRANT CONNECT ON DATABASE __DATABASE_NAME__ TO taskmanager_app;
GRANT USAGE, CREATE ON SCHEMA public TO taskmanager_app;
SQL
aws ssm put-parameter --name __APPLICATION_PARAMETER__ --type SecureString --value "$app_password" --region __REGION__
aws ssm delete-parameter --name __MASTER_PARAMETER__ --region __REGION__
unset PGPASSWORD master_password app_password
'@
    $remoteScript = $remoteScriptTemplate.
        Replace('__MASTER_PARAMETER__', $TemporaryMasterPasswordParameterName).
        Replace('__APPLICATION_PARAMETER__', $ApplicationPasswordParameterName).
        Replace('__DATABASE_ENDPOINT__', $DatabaseEndpoint).
        Replace('__DATABASE_NAME__', $DatabaseName).
        Replace('__MASTER_USERNAME__', $MasterUsername).
        Replace('__REGION__', $Region)
    Write-Utf8JsonFile -Path $commandParametersFile -Value @{ commands = @($remoteScript) }

    $commandId = Get-AwsText @(
        'ssm', 'send-command',
        '--document-name', 'AWS-RunShellScript',
        '--instance-ids', $instanceId,
        '--comment', 'Project 03 E2E database bootstrap; no secret output is requested.',
        '--parameters', "file://$commandParametersFile",
        '--query', 'Command.CommandId'
    )
    Wait-ForSsmCommand -CommandId $commandId -InstanceId $instanceId
    $success = $true
}
catch {
    $failure = $_
    if (-not $RetainOnFailure) {
        Remove-BootstrapResources -InstanceId $instanceId -SecurityGroupId $securityGroupId -DatabaseSecurityGroupId $DatabaseSecurityGroupId -DatabaseIngressRulesFile $databaseIngressRulesFile -RoleName $roleNameCreated -InstanceProfileName $instanceProfileNameCreated -TemporaryMasterParameterName $temporaryMasterParameterNameCreated
    }
    throw $failure
}
finally {
    if ($success) {
        Remove-BootstrapResources -InstanceId $instanceId -SecurityGroupId $securityGroupId -DatabaseSecurityGroupId $DatabaseSecurityGroupId -DatabaseIngressRulesFile $databaseIngressRulesFile -RoleName $roleNameCreated -InstanceProfileName $instanceProfileNameCreated -TemporaryMasterParameterName $temporaryMasterParameterNameCreated
    }
    $masterPasswordPlainText = $null
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

[PSCustomObject]@{
    Status = 'Database bootstrap succeeded and temporary bootstrap resources were removed.'
    ApplicationPasswordParameter = $ApplicationPasswordParameterName
    NextStep = 'Run the Runtime Terraform stage using the Foundation outputs and published artifact key.'
}
