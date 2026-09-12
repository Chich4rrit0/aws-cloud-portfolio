[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ProfileName,

    [Parameter(Mandatory)]
    [ValidatePattern('^pl-[0-9a-f]+$')]
    [string]$CloudFrontOriginPrefixListId,

    [Parameter(Mandatory)]
    [ValidateCount(2, 2)]
    [string[]]$AvailabilityZones,

    [string]$TerraformExecutable = 'C:\AWS\tools\terraform\1.16.2\terraform.exe',
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$foundationRoot = Join-Path $projectRoot 'terraform\environments\e2e-foundation'

if ($DryRun) {
    [PSCustomObject]@{
        Mode = 'Dry run only; Terraform and AWS are not called'
        FoundationRoot = $foundationRoot
        RequiredInputs = 'AWS profile, two available AZ names, console-verified CloudFront prefix-list ID, locally prompted RDS master password'
        SecretHandling = 'The master password is held only in the current PowerShell process as TF_VAR_database_master_password and cleared in finally.'
        Persistence = 'No .tfvars or saved .tfplan file is created.'
        NextGate = 'Inspect the interactive Terraform plan; apply still requires explicit approval.'
    }
    return
}

if (-not (Test-Path -LiteralPath $TerraformExecutable -PathType Leaf)) {
    throw "Terraform executable was not found: $TerraformExecutable"
}

$previousLocation = Get-Location
$previousAwsProfile = $env:AWS_PROFILE
$previousLoadConfig = $env:AWS_SDK_LOAD_CONFIG
$previousMasterPassword = $env:TF_VAR_database_master_password
$previousAvailabilityZones = $env:TF_VAR_availability_zones
$previousPrefixListId = $env:TF_VAR_cloudfront_origin_prefix_list_id

try {
    $masterPasswordSecure = Read-Host 'RDS master password (not displayed, saved, or sent to Git)' -AsSecureString
    $masterPassword = [System.Net.NetworkCredential]::new('', $masterPasswordSecure).Password
    if ([string]::IsNullOrWhiteSpace($masterPassword)) {
        throw 'A non-empty RDS master password is required to produce the Foundation plan.'
    }

    $env:AWS_PROFILE = $ProfileName
    $env:AWS_SDK_LOAD_CONFIG = '1'
    $env:TF_VAR_database_master_password = $masterPassword
    $env:TF_VAR_availability_zones = ($AvailabilityZones | ConvertTo-Json -Compress)
    $env:TF_VAR_cloudfront_origin_prefix_list_id = $CloudFrontOriginPrefixListId

    Set-Location $foundationRoot
    & $TerraformExecutable init -backend=false -input=false -no-color
    if ($LASTEXITCODE -ne 0) { throw 'Terraform initialization failed.' }
    & $TerraformExecutable validate -no-color
    if ($LASTEXITCODE -ne 0) { throw 'Terraform validation failed.' }
    & $TerraformExecutable plan -input=false -no-color
    if ($LASTEXITCODE -ne 0) { throw 'Terraform plan failed.' }
}
finally {
    Set-Location $previousLocation
    $env:AWS_PROFILE = $previousAwsProfile
    $env:AWS_SDK_LOAD_CONFIG = $previousLoadConfig
    $env:TF_VAR_database_master_password = $previousMasterPassword
    $env:TF_VAR_availability_zones = $previousAvailabilityZones
    $env:TF_VAR_cloudfront_origin_prefix_list_id = $previousPrefixListId
    $masterPassword = $null
}

Write-Host 'Foundation plan completed. No Terraform apply was executed and no plan file was saved.'
