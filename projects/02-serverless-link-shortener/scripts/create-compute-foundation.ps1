[CmdletBinding()]
param(
    [Parameter()]
    [string]$Profile = 'portfolio-root-temp',

    [Parameter()]
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$artifactPath = Join-Path $projectRoot 'app\dist\lambda.zip'
$tableName = 'portfolio-p02-links'
$logGroupName = '/aws/lambda/portfolio-p02-link-shortener'
$roleName = 'portfolio-p02-lambda-role'
$policyName = 'portfolio-p02-lambda-runtime'
$functionName = 'portfolio-p02-link-shortener'
$iamTags = @(
    'Key=Project,Value=aws-cloud-portfolio',
    'Key=ProjectNumber,Value=02',
    'Key=Environment,Value=lab',
    'Key=ManagedBy,Value=aws-cli'
)
$lambdaTags = 'Project=aws-cloud-portfolio,ProjectNumber=02,Environment=lab,ManagedBy=aws-cli'

function Invoke-Aws {
    param([Parameter(Mandatory)][string[]]$Arguments)

    & aws --profile $Profile --region $Region --no-cli-pager @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments -join ' ')"
    }
}

if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
    throw "Missing Lambda artifact: $artifactPath"
}

$accountId = (& aws --profile $Profile --region $Region --no-cli-pager sts get-caller-identity --query 'Account' --output text)
if ($LASTEXITCODE -ne 0) {
    throw 'Could not retrieve AWS account context.'
}

$tableArn = (& aws --profile $Profile --region $Region --no-cli-pager dynamodb describe-table --table-name $tableName --query 'Table.TableArn' --output text)
if ($LASTEXITCODE -ne 0) {
    throw "Required DynamoDB table was not found: $tableName"
}

$trustPolicy = '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
$runtimePolicy = @{
    Version = '2012-10-17'
    Statement = @(
        @{
            Sid = 'WriteProjectLogs'
            Effect = 'Allow'
            Action = @('logs:CreateLogStream', 'logs:PutLogEvents')
            Resource = "arn:aws:logs:$Region`:$accountId`:log-group:$logGroupName`:*"
        },
        @{
            Sid = 'AccessProjectLinksOnly'
            Effect = 'Allow'
            Action = @('dynamodb:GetItem', 'dynamodb:PutItem', 'dynamodb:DeleteItem')
            Resource = $tableArn
        }
    )
} | ConvertTo-Json -Compress -Depth 10

$roleArn = (& aws --profile $Profile --region $Region --no-cli-pager iam create-role --role-name $roleName --assume-role-policy-document $trustPolicy --tags $iamTags --query 'Role.Arn' --output text)
if ($LASTEXITCODE -ne 0) {
    throw "Could not create IAM role: $roleName"
}

Invoke-Aws -Arguments @(
    'iam', 'put-role-policy',
    '--role-name', $roleName,
    '--policy-name', $policyName,
    '--policy-document', $runtimePolicy
)

Start-Sleep -Seconds 10

Invoke-Aws -Arguments @(
    'lambda', 'create-function',
    '--function-name', $functionName,
    '--runtime', 'nodejs22.x',
    '--architectures', 'arm64',
    '--role', $roleArn,
    '--handler', 'src/lambda-handler.handler',
    '--zip-file', "fileb://$artifactPath",
    '--memory-size', '128',
    '--timeout', '3',
    '--environment', "Variables={LINKS_TABLE_NAME=$tableName}",
    '--tags', $lambdaTags
)

Invoke-Aws -Arguments @(
    'lambda', 'put-function-concurrency',
    '--function-name', $functionName,
    '--reserved-concurrent-executions', '0'
)

Invoke-Aws -Arguments @('lambda', 'wait', 'function-active-v2', '--function-name', $functionName)

Write-Output 'Project 02 compute foundation created successfully.'
