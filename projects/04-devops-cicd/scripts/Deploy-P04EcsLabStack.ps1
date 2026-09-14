[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$StackName = 'portfolio-p04-ecs-lab',
    [string]$ImageTag = 'sha-f0e12d4587b74973f84669b1a3d87847511a19f1',
    [switch]$Deploy
)

$ErrorActionPreference = 'Stop'
$repositoryName = 'portfolio-p04-task-manager'
$templatePath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\infrastructure\cloudformation\ecs-fargate-lab.yaml')).Path

function Invoke-AwsCli {
    param([string[]]$CliArguments)

    $output = & aws @CliArguments --profile $ProfileName --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($CliArguments[0..1] -join ' ')"
    }

    return ($output -join "`n")
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI was not found in PATH.'
}

$identity = Invoke-AwsCli -CliArguments @('sts', 'get-caller-identity') | ConvertFrom-Json
$accountId = $identity.Account
$budget = Invoke-AwsCli -CliArguments @(
    'budgets', 'describe-budget',
    '--account-id', $accountId,
    '--budget-name', 'portfolio-zero-spend'
) | ConvertFrom-Json
$repository = Invoke-AwsCli -CliArguments @(
    'ecr', 'describe-repositories',
    '--region', $Region,
    '--repository-names', $repositoryName
) | ConvertFrom-Json
$image = Invoke-AwsCli -CliArguments @(
    'ecr', 'describe-images',
    '--region', $Region,
    '--repository-name', $repositoryName,
    '--image-ids', "imageTag=$ImageTag"
) | ConvertFrom-Json

$imageUri = "$($repository.repositories[0].repositoryUri):$ImageTag"
Write-Host "Budget actual spend: USD $($budget.Budget.CalculatedSpend.ActualSpend.Amount) of USD $($budget.Budget.BudgetLimit.Amount)."
Write-Host "Validated immutable image tag: $ImageTag"
Write-Host "Template: $templatePath"

if (-not $Deploy) {
    Write-Host 'Preflight passed. No stack was created. Re-run with -Deploy only after explicit approval.'
    return
}

$existingStackOutput = & aws cloudformation describe-stacks --stack-name $StackName --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
if ($LASTEXITCODE -eq 0) {
    throw "Stack '$StackName' already exists. This script intentionally does not update an existing stack."
}

if (($existingStackOutput -join "`n") -notmatch 'does not exist') {
    throw "Could not determine whether stack '$StackName' exists. Stopping without deployment."
}

& aws cloudformation deploy `
    --stack-name $StackName `
    --template-file $templatePath `
    --parameter-overrides "ImageUri=$imageUri" `
    --capabilities CAPABILITY_NAMED_IAM `
    --tags Project=aws-cloud-portfolio ProjectNumber=04 Environment=devops-lab ManagedBy=CloudFormation `
    --region $Region `
    --profile $ProfileName `
    --no-cli-pager

if ($LASTEXITCODE -ne 0) {
    throw 'CloudFormation deployment failed. Inspect stack events before attempting any corrective action.'
}

Write-Host "Stack '$StackName' deployment completed. Run Test-P04EcsLabRuntime.ps1 before teardown."
