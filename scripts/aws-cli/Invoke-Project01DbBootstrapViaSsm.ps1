[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$instanceName = 'portfolio-p01-db-bootstrap'
$dbIdentifier = 'portfolio-p01-postgres'
$masterPasswordPath = '/portfolio/project-01/database/password'
$applicationPasswordPath = '/portfolio/project-01/database/app-password'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode               = 'Dry run - no command will be sent to EC2'
        InstanceName       = $instanceName
        DocumentName       = 'AWS-RunShellScript'
        DatabaseIdentifier = $dbIdentifier
        Result             = 'Creates taskmanager_app and stores its password without outputting either password'
    }
    return
}

$instances = Invoke-AwsJson -Arguments @(
    'ec2', 'describe-instances',
    '--filters',
    "Name=tag:Name,Values=$instanceName",
    'Name=instance-state-name,Values=running'
)
$runningInstances = @($instances.Reservations | ForEach-Object { $_.Instances })
if ($runningInstances.Count -ne 1) {
    throw "Expected exactly one running bootstrap instance named '$instanceName'."
}

$db = Invoke-AwsJson -Arguments @('rds', 'describe-db-instances', '--db-instance-identifier', $dbIdentifier)
$dbInstance = $db.DBInstances[0]
if ($dbInstance.DBInstanceStatus -ne 'available' -or $dbInstance.PubliclyAccessible) {
    throw 'RDS must be available and private before bootstrap can run.'
}

$bootstrapScriptTemplate = @'
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
$bootstrapScript = $bootstrapScriptTemplate.Replace('__REGION__', $Region).Replace('__DB_ENDPOINT__', $dbInstance.Endpoint.Address).Replace('__MASTER_PARAMETER__', $masterPasswordPath).Replace('__APPLICATION_PARAMETER__', $applicationPasswordPath)
$parametersJson = @{ commands = @($bootstrapScript) } | ConvertTo-Json -Compress
$command = Invoke-AwsJson -Arguments @(
    'ssm', 'send-command',
    '--document-name', 'AWS-RunShellScript',
    '--instance-ids', $runningInstances[0].InstanceId,
    '--parameters', $parametersJson,
    '--comment', 'Bootstrap the Project 01 PostgreSQL application credential.'
)

[PSCustomObject]@{
    Action    = 'Bootstrap command sent through Session Manager'
    CommandId = $command.Command.CommandId
    Status    = $command.Command.Status
}
