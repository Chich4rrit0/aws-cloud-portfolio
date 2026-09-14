[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$StackName = 'portfolio-p04-ecs-lab',
    [switch]$ApproveDestroy
)

$ErrorActionPreference = 'Stop'

if (-not $ApproveDestroy) {
    throw 'Destructive operation blocked. Re-run only with -ApproveDestroy after explicit authorization.'
}

if ($StackName -ne 'portfolio-p04-ecs-lab') {
    throw 'This teardown script is intentionally restricted to the exact Project 4 laboratory stack name.'
}

& aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --profile $ProfileName `
    --no-cli-pager `
    --output json | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Stack '$StackName' was not found or could not be inspected. No deletion was requested."
}

Write-Host "Deleting only CloudFormation stack '$StackName' and its managed Project 4 resources."
& aws cloudformation delete-stack `
    --stack-name $StackName `
    --region $Region `
    --profile $ProfileName `
    --no-cli-pager

if ($LASTEXITCODE -ne 0) {
    throw 'CloudFormation deletion request failed.'
}

& aws cloudformation wait stack-delete-complete `
    --stack-name $StackName `
    --region $Region `
    --profile $ProfileName `
    --no-cli-pager

if ($LASTEXITCODE -ne 0) {
    throw 'Stack deletion did not complete successfully. Inspect CloudFormation events; do not retry blindly.'
}

Write-Host 'CloudFormation stack deletion completed. ECR image and OIDC publisher identity remain outside this stack.'
