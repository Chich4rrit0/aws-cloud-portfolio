[CmdletBinding()]
param(
    [Parameter()]
    [string]$Profile = 'portfolio-root-temp',

    [Parameter()]
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = 'Stop'

$tableName = 'portfolio-p02-links'
$logGroupName = '/aws/lambda/portfolio-p02-link-shortener'
$dynamoDbTags = @(
    'Key=Project,Value=aws-cloud-portfolio',
    'Key=ProjectNumber,Value=02',
    'Key=Environment,Value=lab',
    'Key=ManagedBy,Value=aws-cli'
)
$logGroupTags = 'Project=aws-cloud-portfolio,ProjectNumber=02,Environment=lab,ManagedBy=aws-cli'

function Invoke-Aws {
    param([Parameter(Mandatory)][string[]]$Arguments)

    & aws --profile $Profile --region $Region --no-cli-pager @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments -join ' ')"
    }
}

Invoke-Aws -Arguments (@(
    'logs', 'create-log-group',
    '--log-group-name', $logGroupName,
    '--tags', $logGroupTags
))

Invoke-Aws -Arguments @(
    'logs', 'put-retention-policy',
    '--log-group-name', $logGroupName,
    '--retention-in-days', '7'
)

Invoke-Aws -Arguments (@(
    'dynamodb', 'create-table',
    '--table-name', $tableName,
    '--attribute-definitions', 'AttributeName=shortCode,AttributeType=S',
    '--key-schema', 'AttributeName=shortCode,KeyType=HASH',
    '--billing-mode', 'PAY_PER_REQUEST',
    '--table-class', 'STANDARD',
    '--tags'
) + $dynamoDbTags)

Invoke-Aws -Arguments @('dynamodb', 'wait', 'table-exists', '--table-name', $tableName)

Invoke-Aws -Arguments @(
    'dynamodb', 'update-time-to-live',
    '--table-name', $tableName,
    '--time-to-live-specification', 'Enabled=true,AttributeName=expiresAt'
)

Write-Host 'Project 02 data foundation created successfully.'
