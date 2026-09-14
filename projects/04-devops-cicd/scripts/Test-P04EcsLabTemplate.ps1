[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = 'Stop'

$templatePath = Join-Path $PSScriptRoot '..\infrastructure\cloudformation\ecs-fargate-lab.yaml'
$resolvedTemplatePath = (Resolve-Path -LiteralPath $templatePath).Path

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI was not found in PATH.'
}

& aws cloudformation validate-template `
    --template-body "file://$resolvedTemplatePath" `
    --region $Region `
    --profile $ProfileName `
    --no-cli-pager `
    --output json

if ($LASTEXITCODE -ne 0) {
    throw 'CloudFormation template validation failed.'
}

Write-Host 'CloudFormation validation passed. No stack was created.'
