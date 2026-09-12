[CmdletBinding()]
param(
    [string]$Region = 'us-east-1',
    [string]$ProjectPrefix = 'portfolio-p03-e2e'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[PSCustomObject]@{
    Mode = 'Dry run only; no AWS API mutation is performed'
    BootstrapInstance = "$ProjectPrefix-db-bootstrap"
    ApplicationPasswordPath = '/portfolio/project-03-e2e/database/password'
    TemporaryMasterPassword = 'Provided locally at execution time; never written by this dry run'
    RequiredBeforeExecute = 'Foundation deployed, RDS private and available, artifact publication reviewed'
    Cleanup = 'Delete temporary EC2, bootstrap identity and master SecureString after validation'
}
